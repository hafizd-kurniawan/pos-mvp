package service

import "github.com/google/uuid"

// Standard API Response structure
type APIResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
}

// Pagination information
type PaginationInfo struct {
	Page       int   `json:"page"`
	Limit      int   `json:"limit"`
	Total      int   `json:"total"`
	TotalPages int   `json:"total_pages"`
	HasNext    bool  `json:"has_next"`
	HasPrev    bool  `json:"has_prev"`
}

// Paginated response
type PaginatedResponse struct {
	Success    bool           `json:"success"`
	Message    string         `json:"message"`
	Data       interface{}    `json:"data"`
	Pagination PaginationInfo `json:"pagination"`
	Error      string         `json:"error,omitempty"`
}

// Create Request DTOs
type CreateCarRequest struct {
	Brand       string  `json:"brand" binding:"required"`
	Model       string  `json:"model" binding:"required"`
	Year        int     `json:"year" binding:"required,min=1900,max=2030"`
	Color       string  `json:"color" binding:"required"`
	Price       float64 `json:"price" binding:"required,gt=0"`
	Mileage     int     `json:"mileage" binding:"min=0"`
	VIN         string  `json:"vin" binding:"required,len=17"`
	Status      string  `json:"status" binding:"omitempty,oneof=available sold reserved"`
	Description string  `json:"description"`
}

type UpdateCarRequest struct {
	Brand       string  `json:"brand"`
	Model       string  `json:"model"`
	Year        int     `json:"year" binding:"omitempty,min=1900,max=2030"`
	Color       string  `json:"color"`
	Price       float64 `json:"price" binding:"omitempty,gt=0"`
	Mileage     int     `json:"mileage" binding:"omitempty,min=0"`
	VIN         string  `json:"vin" binding:"omitempty,len=17"`
	Status      string  `json:"status" binding:"omitempty,oneof=available sold reserved"`
	Description string  `json:"description"`
}

type CreateCustomerRequest struct {
	FirstName   string `json:"first_name" binding:"required"`
	LastName    string `json:"last_name" binding:"required"`
	Email       string `json:"email" binding:"required,email"`
	Phone       string `json:"phone"`
	Address     string `json:"address"`
	City        string `json:"city"`
	State       string `json:"state"`
	ZipCode     string `json:"zip_code"`
	DateOfBirth string `json:"date_of_birth"` // Format: YYYY-MM-DD
}

type UpdateCustomerRequest struct {
	FirstName   string `json:"first_name"`
	LastName    string `json:"last_name"`
	Email       string `json:"email" binding:"omitempty,email"`
	Phone       string `json:"phone"`
	Address     string `json:"address"`
	City        string `json:"city"`
	State       string `json:"state"`
	ZipCode     string `json:"zip_code"`
	DateOfBirth string `json:"date_of_birth"` // Format: YYYY-MM-DD
}

type CreateTransactionRequest struct {
	CustomerID      uuid.UUID `json:"customer_id" binding:"required"`
	CarID           uuid.UUID `json:"car_id" binding:"required"`
	SalePrice       float64   `json:"sale_price" binding:"required,gt=0"`
	DiscountAmount  float64   `json:"discount_amount" binding:"min=0"`
	TaxAmount       float64   `json:"tax_amount" binding:"min=0"`
	PaymentMethod   string    `json:"payment_method" binding:"required,oneof=cash credit financing"`
	SalesPersonID   *uuid.UUID `json:"sales_person_id"`
	Notes           string    `json:"notes"`
}

// Helper functions for creating standard responses
func SuccessResponse(message string, data interface{}) APIResponse {
	return APIResponse{
		Success: true,
		Message: message,
		Data:    data,
	}
}

func ErrorResponse(message string, error string) APIResponse {
	return APIResponse{
		Success: false,
		Message: message,
		Error:   error,
	}
}

func PaginatedSuccessResponse(message string, data interface{}, page, limit, total int) PaginatedResponse {
	totalPages := (total + limit - 1) / limit
	hasNext := page < totalPages
	hasPrev := page > 1

	return PaginatedResponse{
		Success: true,
		Message: message,
		Data:    data,
		Pagination: PaginationInfo{
			Page:       page,
			Limit:      limit,
			Total:      total,
			TotalPages: totalPages,
			HasNext:    hasNext,
			HasPrev:    hasPrev,
		},
	}
}

// Helper function to calculate pagination info
func CalculatePagination(page, limit, total int) *PaginationInfo {
	totalPages := (total + limit - 1) / limit
	hasNext := page < totalPages
	hasPrev := page > 1

	return &PaginationInfo{
		Page:       page,
		Limit:      limit,
		Total:      total,
		TotalPages: totalPages,
		HasNext:    hasNext,
		HasPrev:    hasPrev,
	}
}