package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/hafizd-kurniawan/pos-mvp/internal/service"
)

type SparepartHandler struct {
	sparepartService *service.SparepartService
}

func NewSparepartHandler(sparepartService *service.SparepartService) *SparepartHandler {
	return &SparepartHandler{
		sparepartService: sparepartService,
	}
}

// CreateSparepart creates a new sparepart
func (h *SparepartHandler) CreateSparepart(c *gin.Context) {
	var sparepart model.Sparepart
	if err := c.ShouldBindJSON(&sparepart); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
			"error":   err.Error(),
		})
		return
	}

	// Get user info from context (this would be set by auth middleware)
	userID, _ := getUserFromContext(c)
	ipAddress := c.ClientIP()
	userAgent := c.GetHeader("User-Agent")

	err := h.sparepartService.CreateSparepart(&sparepart, userID, ipAddress, userAgent)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to create sparepart",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Sparepart created successfully",
		"data":    sparepart,
	})
}

// GetAllSpareparts retrieves all spareparts with pagination
func (h *SparepartHandler) GetAllSpareparts(c *gin.Context) {
	page := getPageFromQuery(c)
	limit := getLimitFromQuery(c)

	spareparts, total, err := h.sparepartService.GetAllSpareparts(page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to retrieve spareparts",
			"error":   err.Error(),
		})
		return
	}

	pagination := createPaginationInfo(page, limit, total)

	c.JSON(http.StatusOK, gin.H{
		"success":    true,
		"message":    "Spareparts retrieved successfully",
		"data":       spareparts,
		"pagination": pagination,
	})
}

// GetSparepart retrieves a sparepart by ID
func (h *SparepartHandler) GetSparepart(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid sparepart ID",
			"error":   err.Error(),
		})
		return
	}

	sparepart, err := h.sparepartService.GetSparepartByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"message": "Sparepart not found",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Sparepart retrieved successfully",
		"data":    sparepart,
	})
}

// GetSparepartByPartNumber retrieves a sparepart by part number
func (h *SparepartHandler) GetSparepartByPartNumber(c *gin.Context) {
	partNumber := c.Query("part_number")
	if partNumber == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Part number is required",
		})
		return
	}

	sparepart, err := h.sparepartService.GetSparepartByPartNumber(partNumber)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"message": "Sparepart not found",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Sparepart retrieved successfully",
		"data":    sparepart,
	})
}

// GetSparepartByBarcode retrieves a sparepart by barcode
func (h *SparepartHandler) GetSparepartByBarcode(c *gin.Context) {
	barcode := c.Query("barcode")
	if barcode == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Barcode is required",
		})
		return
	}

	sparepart, err := h.sparepartService.GetSparepartByBarcode(barcode)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"message": "Sparepart not found",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Sparepart retrieved successfully",
		"data":    sparepart,
	})
}

// SearchSpareparts searches spareparts
func (h *SparepartHandler) SearchSpareparts(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Search query is required",
		})
		return
	}

	page := getPageFromQuery(c)
	limit := getLimitFromQuery(c)

	spareparts, total, err := h.sparepartService.SearchSpareparts(query, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to search spareparts",
			"error":   err.Error(),
		})
		return
	}

	pagination := createPaginationInfo(page, limit, total)

	c.JSON(http.StatusOK, gin.H{
		"success":    true,
		"message":    "Spareparts search completed successfully",
		"data":       spareparts,
		"pagination": pagination,
	})
}

// GetLowStockSpareparts retrieves spareparts with low stock
func (h *SparepartHandler) GetLowStockSpareparts(c *gin.Context) {
	spareparts, err := h.sparepartService.GetLowStockSpareparts()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to retrieve low stock spareparts",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Low stock spareparts retrieved successfully",
		"data":    spareparts,
	})
}

// UpdateStock updates sparepart stock
func (h *SparepartHandler) UpdateStock(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid sparepart ID",
			"error":   err.Error(),
		})
		return
	}

	var req struct {
		Stock        int    `json:"stock" binding:"required"`
		MovementType string `json:"movement_type" binding:"required"`
		Reference    string `json:"reference"`
		Notes        string `json:"notes"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
			"error":   err.Error(),
		})
		return
	}

	userID, _ := getUserFromContext(c)
	ipAddress := c.ClientIP()
	userAgent := c.GetHeader("User-Agent")

	err = h.sparepartService.UpdateStock(id, req.Stock, req.MovementType, req.Reference, nil, userID, req.Notes, ipAddress, userAgent)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to update stock",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Stock updated successfully",
	})
}

// UpdateSparepart updates a sparepart
func (h *SparepartHandler) UpdateSparepart(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid sparepart ID",
			"error":   err.Error(),
		})
		return
	}

	var sparepart model.Sparepart
	if err := c.ShouldBindJSON(&sparepart); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
			"error":   err.Error(),
		})
		return
	}

	sparepart.ID = id
	userID, _ := getUserFromContext(c)
	ipAddress := c.ClientIP()
	userAgent := c.GetHeader("User-Agent")

	err = h.sparepartService.UpdateSparepart(&sparepart, userID, ipAddress, userAgent)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to update sparepart",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Sparepart updated successfully",
		"data":    sparepart,
	})
}

// DeleteSparepart soft deletes a sparepart
func (h *SparepartHandler) DeleteSparepart(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid sparepart ID",
			"error":   err.Error(),
		})
		return
	}

	userID, _ := getUserFromContext(c)
	ipAddress := c.ClientIP()
	userAgent := c.GetHeader("User-Agent")

	err = h.sparepartService.DeleteSparepart(id, userID, ipAddress, userAgent)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to delete sparepart",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Sparepart deleted successfully",
	})
}

// GetStockMovements retrieves stock movements for a sparepart
func (h *SparepartHandler) GetStockMovements(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid sparepart ID",
			"error":   err.Error(),
		})
		return
	}

	page := getPageFromQuery(c)
	limit := getLimitFromQuery(c)

	movements, total, err := h.sparepartService.GetStockMovements(id, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to retrieve stock movements",
			"error":   err.Error(),
		})
		return
	}

	pagination := createPaginationInfo(page, limit, total)

	c.JSON(http.StatusOK, gin.H{
		"success":    true,
		"message":    "Stock movements retrieved successfully",
		"data":       movements,
		"pagination": pagination,
	})
}

// Helper function to get user from context (would be set by auth middleware)
func getUserFromContext(c *gin.Context) (uuid.UUID, bool) {
	// This is a placeholder - in a real implementation, 
	// this would extract user info from JWT token via middleware
	userStr := c.GetHeader("X-User-ID")
	if userStr == "" {
		// Default to first user for demo purposes
		return uuid.MustParse("123e4567-e89b-12d3-a456-426614174000"), false
	}
	
	userID, err := uuid.Parse(userStr)
	if err != nil {
		return uuid.MustParse("123e4567-e89b-12d3-a456-426614174000"), false
	}
	
	return userID, true
}