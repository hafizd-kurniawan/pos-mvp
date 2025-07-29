package model

import (
	"time"

	"github.com/google/uuid"
)

// AuthRequest represents login request
type AuthRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// AuthResponse represents login response with JWT token
type AuthResponse struct {
	Token        string    `json:"token"`
	RefreshToken string    `json:"refresh_token"`
	ExpiresAt    time.Time `json:"expires_at"`
	User         User      `json:"user"`
}

// Session represents user session information
type Session struct {
	BaseModel
	UserID       uuid.UUID `json:"user_id" db:"user_id"`
	SessionToken string    `json:"session_token" db:"session_token"`
	IPAddress    string    `json:"ip_address" db:"ip_address"`
	UserAgent    string    `json:"user_agent" db:"user_agent"`
	ExpiresAt    time.Time `json:"expires_at" db:"expires_at"`
	IsActive     bool      `json:"is_active" db:"is_active"`
}

// ActivityLog represents activity logging for audit trail
type ActivityLog struct {
	BaseModel
	UserID       *uuid.UUID `json:"user_id,omitempty" db:"user_id"`
	Action       string     `json:"action" db:"action"`               // CREATE, UPDATE, DELETE, LOGIN, LOGOUT
	EntityType   string     `json:"entity_type" db:"entity_type"`     // car, customer, transaction, etc.
	EntityID     *uuid.UUID `json:"entity_id,omitempty" db:"entity_id"`
	IPAddress    string     `json:"ip_address" db:"ip_address"`
	UserAgent    string     `json:"user_agent" db:"user_agent"`
	Description  string     `json:"description" db:"description"`
	OldValues    string     `json:"old_values,omitempty" db:"old_values"` // JSON string
	NewValues    string     `json:"new_values,omitempty" db:"new_values"` // JSON string
}

// Update User model to include password
type UserWithAuth struct {
	User
	Password string `json:"password,omitempty" db:"password"`
}