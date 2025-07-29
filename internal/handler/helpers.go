package handler

import (
	"strconv"

	"github.com/gin-gonic/gin"
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