package repository

import (
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/jmoiron/sqlx"
)

type UserRepository interface {
	Create(user *model.User) error
	GetByID(id uuid.UUID) (*model.User, error)
	GetByUsername(username string) (*model.User, error)
	GetByEmail(email string) (*model.User, error)
	GetAll(page, limit int) ([]*model.User, int, error)
	Update(user *model.User) error
	Delete(id uuid.UUID) error
	Search(query string, page, limit int) ([]*model.User, int, error)
	GetByRole(role string, page, limit int) ([]*model.User, int, error)
	UpdateLastLogin(id uuid.UUID) error
}

type userRepository struct {
	db *sqlx.DB
}

func NewUserRepository(db *sqlx.DB) UserRepository {
	return &userRepository{db: db}
}

func (r *userRepository) Create(user *model.User) error {
	user.ID = uuid.New()
	user.CreatedAt = time.Now()
	user.UpdatedAt = time.Now()

	query := `
		INSERT INTO users (id, username, email, first_name, last_name, role, is_active, created_at, updated_at)
		VALUES (:id, :username, :email, :first_name, :last_name, :role, :is_active, :created_at, :updated_at)`

	_, err := r.db.NamedExec(query, user)
	return err
}

func (r *userRepository) GetByID(id uuid.UUID) (*model.User, error) {
	var user model.User
	query := `SELECT * FROM users WHERE id = $1 AND deleted_at IS NULL`
	err := r.db.Get(&user, query, id)
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) GetByUsername(username string) (*model.User, error) {
	var user model.User
	query := `SELECT * FROM users WHERE username = $1 AND deleted_at IS NULL`
	err := r.db.Get(&user, query, username)
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) GetByEmail(email string) (*model.User, error) {
	var user model.User
	query := `SELECT * FROM users WHERE email = $1 AND deleted_at IS NULL`
	err := r.db.Get(&user, query, email)
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) GetAll(page, limit int) ([]*model.User, int, error) {
	offset := (page - 1) * limit

	// Get total count
	var total int
	countQuery := `SELECT COUNT(*) FROM users WHERE deleted_at IS NULL`
	err := r.db.Get(&total, countQuery)
	if err != nil {
		return nil, 0, err
	}

	// Get users with pagination
	var users []*model.User
	query := `
		SELECT * FROM users 
		WHERE deleted_at IS NULL 
		ORDER BY created_at DESC 
		LIMIT $1 OFFSET $2`
	
	err = r.db.Select(&users, query, limit, offset)
	if err != nil {
		return nil, 0, err
	}

	return users, total, nil
}

func (r *userRepository) Update(user *model.User) error {
	user.UpdatedAt = time.Now()

	query := `
		UPDATE users 
		SET username = :username, email = :email, first_name = :first_name, 
		    last_name = :last_name, role = :role, is_active = :is_active, 
		    last_login_at = :last_login_at, updated_at = :updated_at
		WHERE id = :id AND deleted_at IS NULL`

	result, err := r.db.NamedExec(query, user)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return fmt.Errorf("user not found or already deleted")
	}

	return nil
}

func (r *userRepository) Delete(id uuid.UUID) error {
	query := `UPDATE users SET deleted_at = CURRENT_TIMESTAMP WHERE id = $1 AND deleted_at IS NULL`
	result, err := r.db.Exec(query, id)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return fmt.Errorf("user not found or already deleted")
	}

	return nil
}

func (r *userRepository) Search(query string, page, limit int) ([]*model.User, int, error) {
	offset := (page - 1) * limit
	searchPattern := "%" + strings.ToLower(query) + "%"

	// Get total count
	var total int
	countQuery := `
		SELECT COUNT(*) FROM users 
		WHERE deleted_at IS NULL 
		AND (LOWER(username) LIKE $1 OR LOWER(email) LIKE $1 OR LOWER(first_name) LIKE $1 OR LOWER(last_name) LIKE $1)`
	
	err := r.db.Get(&total, countQuery, searchPattern)
	if err != nil {
		return nil, 0, err
	}

	// Get users with search and pagination
	var users []*model.User
	searchQuery := `
		SELECT * FROM users 
		WHERE deleted_at IS NULL 
		AND (LOWER(username) LIKE $1 OR LOWER(email) LIKE $1 OR LOWER(first_name) LIKE $1 OR LOWER(last_name) LIKE $1)
		ORDER BY created_at DESC 
		LIMIT $2 OFFSET $3`
	
	err = r.db.Select(&users, searchQuery, searchPattern, limit, offset)
	if err != nil {
		return nil, 0, err
	}

	return users, total, nil
}

func (r *userRepository) GetByRole(role string, page, limit int) ([]*model.User, int, error) {
	offset := (page - 1) * limit

	// Get total count
	var total int
	countQuery := `SELECT COUNT(*) FROM users WHERE role = $1 AND deleted_at IS NULL`
	err := r.db.Get(&total, countQuery, role)
	if err != nil {
		return nil, 0, err
	}

	// Get users with pagination
	var users []*model.User
	query := `
		SELECT * FROM users 
		WHERE role = $1 AND deleted_at IS NULL 
		ORDER BY created_at DESC 
		LIMIT $2 OFFSET $3`
	
	err = r.db.Select(&users, query, role, limit, offset)
	if err != nil {
		return nil, 0, err
	}

	return users, total, nil
}

func (r *userRepository) UpdateLastLogin(id uuid.UUID) error {
	query := `UPDATE users SET last_login_at = NOW(), updated_at = NOW() WHERE id = $1 AND deleted_at IS NULL`
	_, err := r.db.Exec(query, id)
	return err
}