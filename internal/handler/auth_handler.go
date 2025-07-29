package handler

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/hafizd-kurniawan/pos-mvp/internal/repository"
	"github.com/hafizd-kurniawan/pos-mvp/internal/service"
)

type AuthHandler struct {
	authService     *service.AuthService
	userRepo        repository.UserRepository
	sessionRepo     *repository.SessionRepository
	activityLogRepo *repository.ActivityLogRepository
}

func NewAuthHandler(authService *service.AuthService, userRepo repository.UserRepository, sessionRepo *repository.SessionRepository, activityLogRepo *repository.ActivityLogRepository) *AuthHandler {
	return &AuthHandler{
		authService:     authService,
		userRepo:        userRepo,
		sessionRepo:     sessionRepo,
		activityLogRepo: activityLogRepo,
	}
}

// Login handles user authentication
func (h *AuthHandler) Login(c *gin.Context) {
	var req model.AuthRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
			"error":   err.Error(),
		})
		return
	}

	// Get user by username
	user, err := h.userRepo.GetByUsername(req.Username)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Invalid username or password",
			"error":   "Authentication failed",
		})
		return
	}

	// Check if user is active
	if !user.IsActive {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Account is deactivated",
			"error":   "Account access denied",
		})
		return
	}

	// Verify password
	if !h.authService.CheckPassword(req.Password, user.Password) {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Invalid username or password",
			"error":   "Authentication failed",
		})
		return
	}

	// Generate JWT token
	token, expiresAt, err := h.authService.GenerateToken(user.ID, user.Username, user.Role)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to generate token",
			"error":   err.Error(),
		})
		return
	}

	// Generate refresh token
	refreshToken, _, err := h.authService.GenerateRefreshToken(user.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to generate refresh token",
			"error":   err.Error(),
		})
		return
	}

	// Create session record
	session := &model.Session{
		UserID:       user.ID,
		SessionToken: token,
		IPAddress:    c.ClientIP(),
		UserAgent:    c.GetHeader("User-Agent"),
		ExpiresAt:    expiresAt,
		IsActive:     true,
	}
	session.ID = uuid.New()
	session.CreatedAt = time.Now()
	session.UpdatedAt = time.Now()

	err = h.sessionRepo.Create(session)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to create session",
			"error":   err.Error(),
		})
		return
	}

	// Update last login time
	err = h.userRepo.UpdateLastLogin(user.ID)
	if err != nil {
		// Log error but don't fail the login
	}

	// Log login activity
	h.logActivity(user.ID, "LOGIN", "user", &user.ID, c.ClientIP(), c.GetHeader("User-Agent"), 
		"User logged in", "", "")

	// Remove password from response
	user.Password = ""

	response := model.AuthResponse{
		Token:        token,
		RefreshToken: refreshToken,
		ExpiresAt:    expiresAt,
		User:         *user,
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Login successful",
		"data":    response,
	})
}

// Logout handles user logout
func (h *AuthHandler) Logout(c *gin.Context) {
	// Get token from header
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Authorization header missing",
		})
		return
	}

	// Extract token (remove "Bearer " prefix)
	var token string
	if len(authHeader) > 7 && authHeader[:7] == "Bearer " {
		token = authHeader[7:]
	} else {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Invalid authorization header format",
		})
		return
	}

	// Validate token to get user info
	claims, err := h.authService.ValidateToken(token)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Invalid token",
			"error":   err.Error(),
		})
		return
	}

	// Deactivate session
	err = h.sessionRepo.DeactivateSession(token)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to logout",
			"error":   err.Error(),
		})
		return
	}

	// Log logout activity
	h.logActivity(claims.UserID, "LOGOUT", "user", &claims.UserID, c.ClientIP(), c.GetHeader("User-Agent"), 
		"User logged out", "", "")

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Logout successful",
	})
}

// ValidateToken validates a JWT token
func (h *AuthHandler) ValidateToken(c *gin.Context) {
	// Get token from header
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Authorization header missing",
		})
		return
	}

	// Extract token (remove "Bearer " prefix)
	var token string
	if len(authHeader) > 7 && authHeader[:7] == "Bearer " {
		token = authHeader[7:]
	} else {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Invalid authorization header format",
		})
		return
	}

	// Validate token
	claims, err := h.authService.ValidateToken(token)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Invalid token",
			"error":   err.Error(),
		})
		return
	}

	// Check if session is still active
	session, err := h.sessionRepo.GetByToken(token)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Session not found or expired",
		})
		return
	}

	if !session.IsActive {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Session is not active",
		})
		return
	}

	// Get user info
	user, err := h.userRepo.GetByID(claims.UserID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "User not found",
		})
		return
	}

	// Remove password from response
	user.Password = ""

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Token is valid",
		"data": gin.H{
			"user":    user,
			"claims":  claims,
			"session": session,
		},
	})
}

// GetActivityLogs retrieves activity logs for a user
func (h *AuthHandler) GetActivityLogs(c *gin.Context) {
	userIDStr := c.Param("user_id")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
			"error":   err.Error(),
		})
		return
	}

	page := getPageFromQuery(c)
	limit := getLimitFromQuery(c)

	logs, total, err := h.activityLogRepo.GetByUserID(userID, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to retrieve activity logs",
			"error":   err.Error(),
		})
		return
	}

	pagination := createPaginationInfo(page, limit, total)

	c.JSON(http.StatusOK, gin.H{
		"success":    true,
		"message":    "Activity logs retrieved successfully",
		"data":       logs,
		"pagination": pagination,
	})
}

func (h *AuthHandler) logActivity(userID uuid.UUID, action, entityType string, entityID *uuid.UUID, ipAddress, userAgent, description, oldValues, newValues string) {
	log := &model.ActivityLog{
		UserID:      &userID,
		Action:      action,
		EntityType:  entityType,
		EntityID:    entityID,
		IPAddress:   ipAddress,
		UserAgent:   userAgent,
		Description: description,
		OldValues:   oldValues,
		NewValues:   newValues,
	}
	log.ID = uuid.New()
	log.CreatedAt = time.Now()
	log.UpdatedAt = time.Now()

	h.activityLogRepo.Create(log)
}