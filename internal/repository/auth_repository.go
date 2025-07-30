package repository

import (
	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/jmoiron/sqlx"
)

type SessionRepository struct {
	db *sqlx.DB
}

func NewSessionRepository(db *sqlx.DB) *SessionRepository {
	return &SessionRepository{db: db}
}

func (r *SessionRepository) Create(session *model.Session) error {
	query := `
		INSERT INTO sessions (user_id, session_token, ip_address, user_agent, expires_at, is_active)
		VALUES (:user_id, :session_token, :ip_address, :user_agent, :expires_at, :is_active)
		RETURNING id, created_at, updated_at`
	
	stmt, err := r.db.PrepareNamed(query)
	if err != nil {
		return err
	}
	defer stmt.Close()
	
	return stmt.Get(session, session)
}

func (r *SessionRepository) GetByToken(token string) (*model.Session, error) {
	session := &model.Session{}
	query := `SELECT * FROM sessions WHERE session_token = $1 AND is_active = true AND expires_at > NOW() AND deleted_at IS NULL`
	
	err := r.db.Get(session, query, token)
	return session, err
}

func (r *SessionRepository) DeactivateSession(token string) error {
	query := `UPDATE sessions SET is_active = false, updated_at = NOW() WHERE session_token = $1`
	_, err := r.db.Exec(query, token)
	return err
}

func (r *SessionRepository) CleanupExpiredSessions() error {
	query := `UPDATE sessions SET is_active = false, updated_at = NOW() WHERE expires_at < NOW() AND is_active = true`
	_, err := r.db.Exec(query)
	return err
}

type ActivityLogRepository struct {
	db *sqlx.DB
}

func NewActivityLogRepository(db *sqlx.DB) *ActivityLogRepository {
	return &ActivityLogRepository{db: db}
}

func (r *ActivityLogRepository) Create(log *model.ActivityLog) error {
	query := `
		INSERT INTO activity_logs (user_id, action, entity_type, entity_id, ip_address, user_agent, description, old_values, new_values)
		VALUES (:user_id, :action, :entity_type, :entity_id, :ip_address, :user_agent, :description, :old_values, :new_values)
		RETURNING id, created_at, updated_at`
	
	stmt, err := r.db.PrepareNamed(query)
	if err != nil {
		return err
	}
	defer stmt.Close()
	
	return stmt.Get(log, log)
}

func (r *ActivityLogRepository) GetByUserID(userID uuid.UUID, page, limit int) ([]model.ActivityLog, int, error) {
	logs := []model.ActivityLog{}
	
	// Get total count
	var total int
	countQuery := `SELECT COUNT(*) FROM activity_logs WHERE user_id = $1 AND deleted_at IS NULL`
	err := r.db.Get(&total, countQuery, userID)
	if err != nil {
		return logs, 0, err
	}
	
	// Get paginated results
	offset := (page - 1) * limit
	query := `
		SELECT * FROM activity_logs 
		WHERE user_id = $1 AND deleted_at IS NULL 
		ORDER BY created_at DESC 
		LIMIT $2 OFFSET $3`
	
	err = r.db.Select(&logs, query, userID, limit, offset)
	return logs, total, err
}

func (r *ActivityLogRepository) GetByEntity(entityType string, entityID uuid.UUID, page, limit int) ([]model.ActivityLog, int, error) {
	logs := []model.ActivityLog{}
	
	// Get total count
	var total int
	countQuery := `SELECT COUNT(*) FROM activity_logs WHERE entity_type = $1 AND entity_id = $2 AND deleted_at IS NULL`
	err := r.db.Get(&total, countQuery, entityType, entityID)
	if err != nil {
		return logs, 0, err
	}
	
	// Get paginated results
	offset := (page - 1) * limit
	query := `
		SELECT * FROM activity_logs 
		WHERE entity_type = $1 AND entity_id = $2 AND deleted_at IS NULL 
		ORDER BY created_at DESC 
		LIMIT $3 OFFSET $4`
	
	err = r.db.Select(&logs, query, entityType, entityID, limit, offset)
	return logs, total, err
}