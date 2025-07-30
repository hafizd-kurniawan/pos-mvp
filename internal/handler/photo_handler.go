package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/hafizd-kurniawan/pos-mvp/internal/service"
)

type PhotoHandler struct {
	photoService service.PhotoService
}

func NewPhotoHandler(photoService service.PhotoService) *PhotoHandler {
	return &PhotoHandler{
		photoService: photoService,
	}
}

// UploadPhoto godoc
// @Summary Upload a photo
// @Description Upload a photo for a specific entity (car, work order, etc.)
// @Tags photos
// @Accept multipart/form-data
// @Produce json
// @Param entity_type formData string true "Entity type (car, workorder, etc.)"
// @Param entity_id formData string true "Entity ID"
// @Param photo_type formData string true "Photo type (front, back, interior, engine, damage, before, after)"
// @Param caption formData string false "Photo caption"
// @Param uploaded_by formData string true "User ID who uploaded"
// @Param file formData file true "Photo file"
// @Success 201 {object} APIResponse{data=model.Photo}
// @Failure 400 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Router /api/photos/upload [post]
func (h *PhotoHandler) UploadPhoto(c *gin.Context) {
	entityType := c.PostForm("entity_type")
	entityIDStr := c.PostForm("entity_id")
	photoType := c.PostForm("photo_type")
	caption := c.PostForm("caption")
	uploadedByStr := c.PostForm("uploaded_by")

	if entityType == "" || entityIDStr == "" || photoType == "" || uploadedByStr == "" {
		ErrorResponse(c, http.StatusBadRequest, "entity_type, entity_id, photo_type, and uploaded_by are required", nil)
		return
	}

	entityID, err := uuid.Parse(entityIDStr)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid entity_id", err)
		return
	}

	uploadedBy, err := uuid.Parse(uploadedByStr)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid uploaded_by", err)
		return
	}

	file, err := c.FormFile("file")
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "File is required", err)
		return
	}

	photo, err := h.photoService.UploadPhoto(entityType, entityID, photoType, caption, uploadedBy, file)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, "Failed to upload photo", err)
		return
	}

	SuccessResponse(c, http.StatusCreated, "Photo uploaded successfully", photo)
}

// GetPhoto godoc
// @Summary Get photo by ID
// @Description Get a specific photo by its ID
// @Tags photos
// @Produce json
// @Param id path string true "Photo ID"
// @Success 200 {object} APIResponse{data=model.Photo}
// @Failure 400 {object} APIResponse
// @Failure 404 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Router /api/photos/{id} [get]
func (h *PhotoHandler) GetPhoto(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid photo ID", err)
		return
	}

	photo, err := h.photoService.GetPhotoByID(id)
	if err != nil {
		if err.Error() == "photo not found" {
			ErrorResponse(c, http.StatusNotFound, "Photo not found", err)
			return
		}
		ErrorResponse(c, http.StatusInternalServerError, "Failed to get photo", err)
		return
	}

	SuccessResponse(c, http.StatusOK, "Photo retrieved successfully", photo)
}

// GetPhotosByEntity godoc
// @Summary Get photos by entity
// @Description Get all photos for a specific entity
// @Tags photos
// @Produce json
// @Param entity_type path string true "Entity type"
// @Param entity_id path string true "Entity ID"
// @Success 200 {object} APIResponse{data=[]model.Photo}
// @Failure 400 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Router /api/photos/entity/{entity_type}/{entity_id} [get]
func (h *PhotoHandler) GetPhotosByEntity(c *gin.Context) {
	entityType := c.Param("entity_type")
	entityIDStr := c.Param("entity_id")

	entityID, err := uuid.Parse(entityIDStr)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid entity_id", err)
		return
	}

	photos, err := h.photoService.GetPhotosByEntity(entityType, entityID)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, "Failed to get entity photos", err)
		return
	}

	SuccessResponse(c, http.StatusOK, "Entity photos retrieved successfully", photos)
}

// GetPrimaryPhoto godoc
// @Summary Get primary photo
// @Description Get the primary photo for a specific entity
// @Tags photos
// @Produce json
// @Param entity_type path string true "Entity type"
// @Param entity_id path string true "Entity ID"
// @Success 200 {object} APIResponse{data=model.Photo}
// @Failure 400 {object} APIResponse
// @Failure 404 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Router /api/photos/primary/{entity_type}/{entity_id} [get]
func (h *PhotoHandler) GetPrimaryPhoto(c *gin.Context) {
	entityType := c.Param("entity_type")
	entityIDStr := c.Param("entity_id")

	entityID, err := uuid.Parse(entityIDStr)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid entity_id", err)
		return
	}

	photo, err := h.photoService.GetPrimaryPhoto(entityType, entityID)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, "Failed to get primary photo", err)
		return
	}

	if photo == nil {
		ErrorResponse(c, http.StatusNotFound, "No primary photo found", nil)
		return
	}

	SuccessResponse(c, http.StatusOK, "Primary photo retrieved successfully", photo)
}

// GetPhotosByType godoc
// @Summary Get photos by type
// @Description Get all photos of a specific type for an entity
// @Tags photos
// @Produce json
// @Param entity_type path string true "Entity type"
// @Param entity_id path string true "Entity ID"
// @Param photo_type path string true "Photo type"
// @Success 200 {object} APIResponse{data=[]model.Photo}
// @Failure 400 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Router /api/photos/type/{entity_type}/{entity_id}/{photo_type} [get]
func (h *PhotoHandler) GetPhotosByType(c *gin.Context) {
	entityType := c.Param("entity_type")
	entityIDStr := c.Param("entity_id")
	photoType := c.Param("photo_type")

	entityID, err := uuid.Parse(entityIDStr)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid entity_id", err)
		return
	}

	photos, err := h.photoService.GetPhotosByType(entityType, entityID, photoType)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, "Failed to get photos by type", err)
		return
	}

	SuccessResponse(c, http.StatusOK, "Photos retrieved successfully", photos)
}

// GetAllPhotos godoc
// @Summary Get all photos
// @Description Get all photos with pagination
// @Tags photos
// @Produce json
// @Param page query int false "Page number (default 1)"
// @Param limit query int false "Number of items per page (default 10)"
// @Success 200 {object} APIResponseWithPagination{data=[]model.Photo}
// @Failure 500 {object} APIResponse
// @Router /api/photos [get]
func (h *PhotoHandler) GetAllPhotos(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	photos, meta, err := h.photoService.GetAllPhotos(page, limit)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, "Failed to get photos", err)
		return
	}

	SuccessResponseWithPagination(c, http.StatusOK, "Photos retrieved successfully", photos, meta)
}

// UpdatePhoto godoc
// @Summary Update a photo
// @Description Update photo details (caption, type, etc.)
// @Tags photos
// @Accept json
// @Produce json
// @Param id path string true "Photo ID"
// @Param photo body model.Photo true "Updated photo data"
// @Success 200 {object} APIResponse{data=model.Photo}
// @Failure 400 {object} APIResponse
// @Failure 404 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Router /api/photos/{id} [put]
func (h *PhotoHandler) UpdatePhoto(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid photo ID", err)
		return
	}

	var photo model.Photo
	if err := c.ShouldBindJSON(&photo); err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	photo.ID = id
	updatedPhoto, err := h.photoService.UpdatePhoto(&photo)
	if err != nil {
		if err.Error() == "photo not found" {
			ErrorResponse(c, http.StatusNotFound, "Photo not found", err)
			return
		}
		ErrorResponse(c, http.StatusInternalServerError, "Failed to update photo", err)
		return
	}

	SuccessResponse(c, http.StatusOK, "Photo updated successfully", updatedPhoto)
}

// DeletePhoto godoc
// @Summary Delete a photo
// @Description Delete a photo and its file
// @Tags photos
// @Produce json
// @Param id path string true "Photo ID"
// @Success 200 {object} APIResponse
// @Failure 400 {object} APIResponse
// @Failure 404 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Router /api/photos/{id} [delete]
func (h *PhotoHandler) DeletePhoto(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid photo ID", err)
		return
	}

	err = h.photoService.DeletePhoto(id)
	if err != nil {
		if err.Error() == "photo not found" {
			ErrorResponse(c, http.StatusNotFound, "Photo not found", err)
			return
		}
		ErrorResponse(c, http.StatusInternalServerError, "Failed to delete photo", err)
		return
	}

	SuccessResponse(c, http.StatusOK, "Photo deleted successfully", nil)
}

// SetPrimaryPhoto godoc
// @Summary Set primary photo
// @Description Set a photo as the primary photo for an entity
// @Tags photos
// @Accept json
// @Produce json
// @Param entity_type path string true "Entity type"
// @Param entity_id path string true "Entity ID"
// @Param photo_id path string true "Photo ID"
// @Success 200 {object} APIResponse
// @Failure 400 {object} APIResponse
// @Failure 404 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Router /api/photos/primary/{entity_type}/{entity_id}/{photo_id} [post]
func (h *PhotoHandler) SetPrimaryPhoto(c *gin.Context) {
	entityType := c.Param("entity_type")
	entityIDStr := c.Param("entity_id")
	photoIDStr := c.Param("photo_id")

	entityID, err := uuid.Parse(entityIDStr)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid entity_id", err)
		return
	}

	photoID, err := uuid.Parse(photoIDStr)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid photo_id", err)
		return
	}

	err = h.photoService.SetPrimaryPhoto(entityType, entityID, photoID)
	if err != nil {
		if err.Error() == "photo not found" || err.Error() == "photo does not belong to the specified entity" {
			ErrorResponse(c, http.StatusNotFound, err.Error(), err)
			return
		}
		ErrorResponse(c, http.StatusInternalServerError, "Failed to set primary photo", err)
		return
	}

	SuccessResponse(c, http.StatusOK, "Primary photo set successfully", nil)
}