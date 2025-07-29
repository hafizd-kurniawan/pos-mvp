package model

import (
	"time"

	"github.com/google/uuid"
)

// Base model with common fields including soft delete
type BaseModel struct {
	ID        uuid.UUID  `json:"id" db:"id"`
	CreatedAt time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt time.Time  `json:"updated_at" db:"updated_at"`
	DeletedAt *time.Time `json:"deleted_at,omitempty" db:"deleted_at"`
}

// Car represents a car in the showroom inventory
type Car struct {
	BaseModel
	Brand       string  `json:"brand" db:"brand"`
	Model       string  `json:"model" db:"model"`
	Year        int     `json:"year" db:"year"`
	Color       string  `json:"color" db:"color"`
	Price       float64 `json:"price" db:"price"`
	Mileage     int     `json:"mileage" db:"mileage"`
	VIN         string  `json:"vin" db:"vin"`
	Status      string  `json:"status" db:"status"` // available, sold, reserved
	Description string  `json:"description" db:"description"`
}

// Customer represents a customer
type Customer struct {
	BaseModel
	FirstName   string `json:"first_name" db:"first_name"`
	LastName    string `json:"last_name" db:"last_name"`
	Email       string `json:"email" db:"email"`
	Phone       string `json:"phone" db:"phone"`
	Address     string `json:"address" db:"address"`
	City        string `json:"city" db:"city"`
	State       string `json:"state" db:"state"`
	ZipCode     string `json:"zip_code" db:"zip_code"`
	DateOfBirth *time.Time `json:"date_of_birth,omitempty" db:"date_of_birth"`
}

// Transaction represents a sale transaction
type Transaction struct {
	BaseModel
	CustomerID      uuid.UUID `json:"customer_id" db:"customer_id"`
	CarID           uuid.UUID `json:"car_id" db:"car_id"`
	SalePrice       float64   `json:"sale_price" db:"sale_price"`
	DiscountAmount  float64   `json:"discount_amount" db:"discount_amount"`
	TaxAmount       float64   `json:"tax_amount" db:"tax_amount"`
	TotalAmount     float64   `json:"total_amount" db:"total_amount"`
	PaymentMethod   string    `json:"payment_method" db:"payment_method"` // cash, credit, financing
	TransactionDate time.Time `json:"transaction_date" db:"transaction_date"`
	SalesPersonID   *uuid.UUID `json:"sales_person_id,omitempty" db:"sales_person_id"`
	Notes           string    `json:"notes" db:"notes"`
	Status          string    `json:"status" db:"status"` // pending, completed, cancelled
}

// Receipt represents a receipt for a transaction
type Receipt struct {
	BaseModel
	TransactionID   uuid.UUID `json:"transaction_id" db:"transaction_id"`
	ReceiptNumber   string    `json:"receipt_number" db:"receipt_number"`
	IssueDate       time.Time `json:"issue_date" db:"issue_date"`
	CustomerName    string    `json:"customer_name" db:"customer_name"`
	CustomerEmail   string    `json:"customer_email" db:"customer_email"`
	CustomerPhone   string    `json:"customer_phone" db:"customer_phone"`
	CarBrand        string    `json:"car_brand" db:"car_brand"`
	CarModel        string    `json:"car_model" db:"car_model"`
	CarYear         int       `json:"car_year" db:"car_year"`
	CarVIN          string    `json:"car_vin" db:"car_vin"`
	SalePrice       float64   `json:"sale_price" db:"sale_price"`
	DiscountAmount  float64   `json:"discount_amount" db:"discount_amount"`
	TaxAmount       float64   `json:"tax_amount" db:"tax_amount"`
	TotalAmount     float64   `json:"total_amount" db:"total_amount"`
	PaymentMethod   string    `json:"payment_method" db:"payment_method"`
}

// User represents system users (sales people, managers, etc.)
type User struct {
	BaseModel
	Username    string    `json:"username" db:"username"`
	Email       string    `json:"email" db:"email"`
	FirstName   string    `json:"first_name" db:"first_name"`
	LastName    string    `json:"last_name" db:"last_name"`
	Role        string    `json:"role" db:"role"` // salesperson, manager, admin
	IsActive    bool      `json:"is_active" db:"is_active"`
	LastLoginAt *time.Time `json:"last_login_at,omitempty" db:"last_login_at"`
}

// Helper method to check if a record is soft deleted
func (b BaseModel) IsDeleted() bool {
	return b.DeletedAt != nil
}

// Helper method to soft delete a record
func (b *BaseModel) SoftDelete() {
	now := time.Now()
	b.DeletedAt = &now
	b.UpdatedAt = now
}

