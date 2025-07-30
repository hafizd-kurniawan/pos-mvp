package service

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type JWTClaims struct {
	UserID   uuid.UUID `json:"user_id"`
	Username string    `json:"username"`
	Role     string    `json:"role"`
	jwt.RegisteredClaims
}

type AuthService struct {
	jwtSecret     []byte
	tokenDuration time.Duration
}

func NewAuthService(jwtSecret string, tokenDuration time.Duration) *AuthService {
	return &AuthService{
		jwtSecret:     []byte(jwtSecret),
		tokenDuration: tokenDuration,
	}
}

// HashPassword creates a bcrypt hash of the password
func (s *AuthService) HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(bytes), err
}

// CheckPassword compares a password with its hash
func (s *AuthService) CheckPassword(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

// GenerateToken creates a new JWT token
func (s *AuthService) GenerateToken(userID uuid.UUID, username, role string) (string, time.Time, error) {
	expirationTime := time.Now().Add(s.tokenDuration)
	
	claims := &JWTClaims{
		UserID:   userID,
		Username: username,
		Role:     role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expirationTime),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    "car-showroom-pos",
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(s.jwtSecret)
	
	return tokenString, expirationTime, err
}

// ValidateToken validates a JWT token and returns the claims
func (s *AuthService) ValidateToken(tokenString string) (*JWTClaims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return s.jwtSecret, nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*JWTClaims); ok && token.Valid {
		// Check if token is expired
		if claims.ExpiresAt.Time.Before(time.Now()) {
			return nil, errors.New("token is expired")
		}
		return claims, nil
	}

	return nil, errors.New("invalid token")
}

// GenerateRefreshToken creates a refresh token (longer duration)
func (s *AuthService) GenerateRefreshToken(userID uuid.UUID) (string, time.Time, error) {
	expirationTime := time.Now().Add(7 * 24 * time.Hour) // 7 days
	
	claims := &jwt.RegisteredClaims{
		Subject:   userID.String(),
		ExpiresAt: jwt.NewNumericDate(expirationTime),
		IssuedAt:  jwt.NewNumericDate(time.Now()),
		Issuer:    "car-showroom-pos-refresh",
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(s.jwtSecret)
	
	return tokenString, expirationTime, err
}