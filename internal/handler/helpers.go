package handler

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/hafizd-kurniawan/pos-mvp/internal/service"
)

// PaginationInfo represents pagination information
type PaginationInfo struct {
	Page       int  `json:"page"`
	Limit      int  `json:"limit"`
	Total      int  `json:"total"`
	TotalPages int  `json:"total_pages"`
	HasNext    bool `json:"has_next"`
	HasPrev    bool `json:"has_prev"`
}

// APIResponse represents standard API response structure
type APIResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// APIResponseWithPagination represents paginated API response structure
type APIResponseWithPagination struct {
	Success    bool        `json:"success"`
	Message    string      `json:"message"`
	Data       interface{} `json:"data,omitempty"`
	Pagination interface{} `json:"pagination,omitempty"`
}

// ErrorResponse sends a standard error response
func ErrorResponse(c *gin.Context, statusCode int, message string, err error) {
	response := gin.H{
		"success": false,
		"message": message,
	}
	
	if err != nil {
		response["error"] = err.Error()
	}
	
	c.JSON(statusCode, response)
}

// SuccessResponse sends a standard success response
func SuccessResponse(c *gin.Context, statusCode int, message string, data interface{}) {
	c.JSON(statusCode, gin.H{
		"success": true,
		"message": message,
		"data":    data,
	})
}

// SuccessResponseWithPagination sends a paginated success response
func SuccessResponseWithPagination(c *gin.Context, statusCode int, message string, data interface{}, pagination *service.PaginationInfo) {
	c.JSON(statusCode, gin.H{
		"success":    true,
		"message":    message,
		"data":       data,
		"pagination": pagination,
	})
}

// getPageFromQuery extracts page number from query parameters
func getPageFromQuery(c *gin.Context) int {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	if page < 1 {
		page = 1
	}
	return page
}

// getLimitFromQuery extracts limit from query parameters
func getLimitFromQuery(c *gin.Context) int {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	if limit < 1 {
		limit = 10
	}
	if limit > 100 {
		limit = 100
	}
	return limit
}

// createPaginationInfo creates pagination information
func createPaginationInfo(page, limit, total int) PaginationInfo {
	totalPages := (total + limit - 1) / limit
	if totalPages < 1 {
		totalPages = 1
	}
	
	return PaginationInfo{
		Page:       page,
		Limit:      limit,
		Total:      total,
		TotalPages: totalPages,
		HasNext:    page < totalPages,
		HasPrev:    page > 1,
	}
}