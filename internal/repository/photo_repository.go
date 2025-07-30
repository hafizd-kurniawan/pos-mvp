package repository

import (
	"database/sql"
	"time"

	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/jmoiron/sqlx"
)

type PhotoRepository interface {
	Create(photo *model.Photo) error
	GetByID(id uuid.UUID) (*model.Photo, error)
	GetByEntity(entityType string, entityID uuid.UUID) ([]model.Photo, error)
	GetPrimaryPhoto(entityType string, entityID uuid.UUID) (*model.Photo, error)
	GetByType(entityType string, entityID uuid.UUID, photoType string) ([]model.Photo, error)
	GetAll(limit, offset int) ([]model.Photo, error)
	Update(photo *model.Photo) error
	Delete(id uuid.UUID) error
	SetPrimaryPhoto(entityType string, entityID uuid.UUID, photoID uuid.UUID) error
	Count() (int, error)
}

type photoRepository struct {
	db *sqlx.DB
}

func NewPhotoRepository(db *sqlx.DB) PhotoRepository {
	return &photoRepository{db: db}
}

func (r *photoRepository) Create(photo *model.Photo) error {
	query := `
		INSERT INTO photos (id, entity_type, entity_id, file_name, file_path, file_size, 
			mime_type, photo_type, is_primary, caption, uploaded_by, created_at, updated_at)
		VALUES (:id, :entity_type, :entity_id, :file_name, :file_path, :file_size, 
			:mime_type, :photo_type, :is_primary, :caption, :uploaded_by, :created_at, :updated_at)
	`
	
	if photo.ID == uuid.Nil {
		photo.ID = uuid.New()
	}
	
	now := time.Now()
	photo.CreatedAt = now
	photo.UpdatedAt = now
	
	_, err := r.db.NamedExec(query, photo)
	return err
}

func (r *photoRepository) GetByID(id uuid.UUID) (*model.Photo, error) {
	var photo model.Photo
	query := `
		SELECT * FROM photos 
		WHERE id = $1 AND deleted_at IS NULL
	`
	
	err := r.db.Get(&photo, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	
	return &photo, nil
}

func (r *photoRepository) GetByEntity(entityType string, entityID uuid.UUID) ([]model.Photo, error) {
	var photos []model.Photo
	query := `
		SELECT * FROM photos 
		WHERE entity_type = $1 AND entity_id = $2 AND deleted_at IS NULL 
		ORDER BY is_primary DESC, created_at ASC
	`
	
	err := r.db.Select(&photos, query, entityType, entityID)
	return photos, err
}

func (r *photoRepository) GetPrimaryPhoto(entityType string, entityID uuid.UUID) (*model.Photo, error) {
	var photo model.Photo
	query := `
		SELECT * FROM photos 
		WHERE entity_type = $1 AND entity_id = $2 AND is_primary = true AND deleted_at IS NULL
	`
	
	err := r.db.Get(&photo, query, entityType, entityID)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	
	return &photo, nil
}

func (r *photoRepository) GetByType(entityType string, entityID uuid.UUID, photoType string) ([]model.Photo, error) {
	var photos []model.Photo
	query := `
		SELECT * FROM photos 
		WHERE entity_type = $1 AND entity_id = $2 AND photo_type = $3 AND deleted_at IS NULL 
		ORDER BY is_primary DESC, created_at ASC
	`
	
	err := r.db.Select(&photos, query, entityType, entityID, photoType)
	return photos, err
}

func (r *photoRepository) GetAll(limit, offset int) ([]model.Photo, error) {
	var photos []model.Photo
	query := `
		SELECT * FROM photos 
		WHERE deleted_at IS NULL 
		ORDER BY created_at DESC 
		LIMIT $1 OFFSET $2
	`
	
	err := r.db.Select(&photos, query, limit, offset)
	return photos, err
}

func (r *photoRepository) Update(photo *model.Photo) error {
	query := `
		UPDATE photos SET 
			file_name = :file_name,
			file_path = :file_path,
			file_size = :file_size,
			mime_type = :mime_type,
			photo_type = :photo_type,
			is_primary = :is_primary,
			caption = :caption,
			updated_at = :updated_at
		WHERE id = :id AND deleted_at IS NULL
	`
	
	photo.UpdatedAt = time.Now()
	_, err := r.db.NamedExec(query, photo)
	return err
}

func (r *photoRepository) Delete(id uuid.UUID) error {
	query := `
		UPDATE photos SET 
			deleted_at = $1, 
			updated_at = $1 
		WHERE id = $2
	`
	
	now := time.Now()
	_, err := r.db.Exec(query, now, id)
	return err
}

func (r *photoRepository) SetPrimaryPhoto(entityType string, entityID uuid.UUID, photoID uuid.UUID) error {
	tx, err := r.db.Beginx()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	
	// First, unset all primary photos for this entity
	query1 := `
		UPDATE photos SET 
			is_primary = false, 
			updated_at = $1 
		WHERE entity_type = $2 AND entity_id = $3 AND deleted_at IS NULL
	`
	
	now := time.Now()
	_, err = tx.Exec(query1, now, entityType, entityID)
	if err != nil {
		return err
	}
	
	// Then set the specified photo as primary
	query2 := `
		UPDATE photos SET 
			is_primary = true, 
			updated_at = $1 
		WHERE id = $2 AND deleted_at IS NULL
	`
	
	_, err = tx.Exec(query2, now, photoID)
	if err != nil {
		return err
	}
	
	return tx.Commit()
}

func (r *photoRepository) Count() (int, error) {
	var count int
	query := `SELECT COUNT(*) FROM photos WHERE deleted_at IS NULL`
	
	err := r.db.Get(&count, query)
	return count, err
}