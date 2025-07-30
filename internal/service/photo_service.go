package service

import (
	"fmt"
	"io"
	"mime/multipart"
	"os"
	"path/filepath"
	"strings"

	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/hafizd-kurniawan/pos-mvp/internal/repository"
)

type PhotoService interface {
	UploadPhoto(entityType string, entityID uuid.UUID, photoType string, caption string, uploadedBy uuid.UUID, file *multipart.FileHeader) (*model.Photo, error)
	GetPhotoByID(id uuid.UUID) (*model.Photo, error)
	GetPhotosByEntity(entityType string, entityID uuid.UUID) ([]model.Photo, error)
	GetPrimaryPhoto(entityType string, entityID uuid.UUID) (*model.Photo, error)
	GetPhotosByType(entityType string, entityID uuid.UUID, photoType string) ([]model.Photo, error)
	GetAllPhotos(page, limit int) ([]model.Photo, *PaginationInfo, error)
	UpdatePhoto(photo *model.Photo) (*model.Photo, error)
	DeletePhoto(id uuid.UUID) error
	SetPrimaryPhoto(entityType string, entityID uuid.UUID, photoID uuid.UUID) error
}

type photoService struct {
	photoRepo   repository.PhotoRepository
	uploadPath  string
	maxFileSize int64
}

func NewPhotoService(photoRepo repository.PhotoRepository) PhotoService {
	return &photoService{
		photoRepo:   photoRepo,
		uploadPath:  "./uploads/photos", // Default upload path
		maxFileSize: 10 * 1024 * 1024,   // 10MB default max file size
	}
}

func (s *photoService) UploadPhoto(entityType string, entityID uuid.UUID, photoType string, caption string, uploadedBy uuid.UUID, file *multipart.FileHeader) (*model.Photo, error) {
	// Validate file size
	if file.Size > s.maxFileSize {
		return nil, fmt.Errorf("file size exceeds maximum limit of %d bytes", s.maxFileSize)
	}
	
	// Validate file type
	allowedTypes := []string{"image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp"}
	contentType := file.Header.Get("Content-Type")
	if !s.isAllowedFileType(contentType, allowedTypes) {
		return nil, fmt.Errorf("unsupported file type: %s", contentType)
	}
	
	// Create upload directory if it doesn't exist
	uploadDir := filepath.Join(s.uploadPath, entityType, entityID.String())
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create upload directory: %w", err)
	}
	
	// Generate unique filename
	fileExt := filepath.Ext(file.Filename)
	fileName := fmt.Sprintf("%s_%s%s", photoType, uuid.New().String(), fileExt)
	filePath := filepath.Join(uploadDir, fileName)
	
	// Save file
	src, err := file.Open()
	if err != nil {
		return nil, fmt.Errorf("failed to open uploaded file: %w", err)
	}
	defer src.Close()
	
	dst, err := os.Create(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to create destination file: %w", err)
	}
	defer dst.Close()
	
	if _, err := io.Copy(dst, src); err != nil {
		return nil, fmt.Errorf("failed to save file: %w", err)
	}
	
	// Create photo record
	photo := &model.Photo{
		EntityType: entityType,
		EntityID:   entityID,
		FileName:   fileName,
		FilePath:   filePath,
		FileSize:   file.Size,
		MimeType:   contentType,
		PhotoType:  photoType,
		IsPrimary:  false, // Will be set separately if needed
		Caption:    caption,
		UploadedBy: uploadedBy,
	}
	
	err = s.photoRepo.Create(photo)
	if err != nil {
		// Clean up file if database save fails
		os.Remove(filePath)
		return nil, fmt.Errorf("failed to save photo record: %w", err)
	}
	
	return photo, nil
}

func (s *photoService) GetPhotoByID(id uuid.UUID) (*model.Photo, error) {
	photo, err := s.photoRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get photo: %w", err)
	}
	
	if photo == nil {
		return nil, fmt.Errorf("photo not found")
	}
	
	return photo, nil
}

func (s *photoService) GetPhotosByEntity(entityType string, entityID uuid.UUID) ([]model.Photo, error) {
	photos, err := s.photoRepo.GetByEntity(entityType, entityID)
	if err != nil {
		return nil, fmt.Errorf("failed to get entity photos: %w", err)
	}
	
	return photos, nil
}

func (s *photoService) GetPrimaryPhoto(entityType string, entityID uuid.UUID) (*model.Photo, error) {
	photo, err := s.photoRepo.GetPrimaryPhoto(entityType, entityID)
	if err != nil {
		return nil, fmt.Errorf("failed to get primary photo: %w", err)
	}
	
	return photo, nil
}

func (s *photoService) GetPhotosByType(entityType string, entityID uuid.UUID, photoType string) ([]model.Photo, error) {
	photos, err := s.photoRepo.GetByType(entityType, entityID, photoType)
	if err != nil {
		return nil, fmt.Errorf("failed to get photos by type: %w", err)
	}
	
	return photos, nil
}

func (s *photoService) GetAllPhotos(page, limit int) ([]model.Photo, *PaginationInfo, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}
	
	offset := (page - 1) * limit
	
	photos, err := s.photoRepo.GetAll(limit, offset)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to get photos: %w", err)
	}
	
	totalCount, err := s.photoRepo.Count()
	if err != nil {
		return nil, nil, fmt.Errorf("failed to count photos: %w", err)
	}
	
	meta := &PaginationInfo{
		Page:       page,
		Limit:      limit,
		Total:      totalCount,
		TotalPages: (totalCount + limit - 1) / limit,
		HasNext:    page < (totalCount+limit-1)/limit,
		HasPrev:    page > 1,
	}
	
	return photos, meta, nil
}

func (s *photoService) UpdatePhoto(photo *model.Photo) (*model.Photo, error) {
	existingPhoto, err := s.photoRepo.GetByID(photo.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to get photo: %w", err)
	}
	
	if existingPhoto == nil {
		return nil, fmt.Errorf("photo not found")
	}
	
	err = s.photoRepo.Update(photo)
	if err != nil {
		return nil, fmt.Errorf("failed to update photo: %w", err)
	}
	
	return photo, nil
}

func (s *photoService) DeletePhoto(id uuid.UUID) error {
	existingPhoto, err := s.photoRepo.GetByID(id)
	if err != nil {
		return fmt.Errorf("failed to get photo: %w", err)
	}
	
	if existingPhoto == nil {
		return fmt.Errorf("photo not found")
	}
	
	// Delete from database first
	err = s.photoRepo.Delete(id)
	if err != nil {
		return fmt.Errorf("failed to delete photo record: %w", err)
	}
	
	// Then try to delete the file (best effort, don't fail if file doesn't exist)
	if existingPhoto.FilePath != "" {
		os.Remove(existingPhoto.FilePath)
	}
	
	return nil
}

func (s *photoService) SetPrimaryPhoto(entityType string, entityID uuid.UUID, photoID uuid.UUID) error {
	// Verify the photo exists and belongs to the entity
	photo, err := s.photoRepo.GetByID(photoID)
	if err != nil {
		return fmt.Errorf("failed to get photo: %w", err)
	}
	
	if photo == nil {
		return fmt.Errorf("photo not found")
	}
	
	if photo.EntityType != entityType || photo.EntityID != entityID {
		return fmt.Errorf("photo does not belong to the specified entity")
	}
	
	err = s.photoRepo.SetPrimaryPhoto(entityType, entityID, photoID)
	if err != nil {
		return fmt.Errorf("failed to set primary photo: %w", err)
	}
	
	return nil
}

func (s *photoService) isAllowedFileType(contentType string, allowedTypes []string) bool {
	for _, allowedType := range allowedTypes {
		if strings.EqualFold(contentType, allowedType) {
			return true
		}
	}
	return false
}