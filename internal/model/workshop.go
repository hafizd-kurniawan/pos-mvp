package model

import (
	"time"

	"github.com/google/uuid"
)

// WorkOrder represents a work order for vehicle repairs
type WorkOrder struct {
	BaseModel
	WorkOrderNumber string     `json:"work_order_number" db:"work_order_number"` // WO-20250724-003
	CarID           uuid.UUID  `json:"car_id" db:"car_id"`
	MechanicID      *uuid.UUID `json:"mechanic_id,omitempty" db:"mechanic_id"`
	AssignedBy      uuid.UUID  `json:"assigned_by" db:"assigned_by"` // Admin/Manager who assigned
	Description     string     `json:"description" db:"description"`
	LaborCost       float64    `json:"labor_cost" db:"labor_cost"`
	PartsCost       float64    `json:"parts_cost" db:"parts_cost"`
	TotalCost       float64    `json:"total_cost" db:"total_cost"`
	Status          string     `json:"status" db:"status"` // pending, in_progress, completed, cancelled
	Progress        int        `json:"progress" db:"progress"` // 0-100 percentage
	StartDate       *time.Time `json:"start_date,omitempty" db:"start_date"`
	CompletedDate   *time.Time `json:"completed_date,omitempty" db:"completed_date"`
	Notes           string     `json:"notes" db:"notes"`
}

// WorkOrderItem represents parts used in a work order
type WorkOrderItem struct {
	BaseModel
	WorkOrderID   uuid.UUID `json:"work_order_id" db:"work_order_id"`
	SparepartID   uuid.UUID `json:"sparepart_id" db:"sparepart_id"`
	Quantity      int       `json:"quantity" db:"quantity"`
	UnitPrice     float64   `json:"unit_price" db:"unit_price"`
	TotalPrice    float64   `json:"total_price" db:"total_price"`
	UsedDate      time.Time `json:"used_date" db:"used_date"`
}

// Sparepart represents spare parts inventory
type Sparepart struct {
	BaseModel
	PartNumber    string  `json:"part_number" db:"part_number"`
	Name          string  `json:"name" db:"name"`
	Description   string  `json:"description" db:"description"`
	Brand         string  `json:"brand" db:"brand"`
	Category      string  `json:"category" db:"category"`
	Stock         int     `json:"stock" db:"stock"`
	MinStock      int     `json:"min_stock" db:"min_stock"`     // Alert threshold
	CostPrice     float64 `json:"cost_price" db:"cost_price"`
	SalePrice     float64 `json:"sale_price" db:"sale_price"`
	MarkupPercent float64 `json:"markup_percent" db:"markup_percent"`
	Location      string  `json:"location" db:"location"`
	Barcode       string  `json:"barcode" db:"barcode"`
}

// StockMovement represents stock movement history
type StockMovement struct {
	BaseModel
	SparepartID   uuid.UUID  `json:"sparepart_id" db:"sparepart_id"`
	MovementType  string     `json:"movement_type" db:"movement_type"` // IN, OUT, ADJUSTMENT
	Quantity      int        `json:"quantity" db:"quantity"`
	Reference     string     `json:"reference" db:"reference"`         // WO number, PO number, etc.
	ReferenceID   *uuid.UUID `json:"reference_id,omitempty" db:"reference_id"`
	UserID        uuid.UUID  `json:"user_id" db:"user_id"`
	Notes         string     `json:"notes" db:"notes"`
	PreviousStock int        `json:"previous_stock" db:"previous_stock"`
	NewStock      int        `json:"new_stock" db:"new_stock"`
}

// Photo represents vehicle/damage photos
type Photo struct {
	BaseModel
	EntityType  string     `json:"entity_type" db:"entity_type"` // car, workorder, damage
	EntityID    uuid.UUID  `json:"entity_id" db:"entity_id"`
	FileName    string     `json:"file_name" db:"file_name"`
	FilePath    string     `json:"file_path" db:"file_path"`
	FileSize    int64      `json:"file_size" db:"file_size"`
	MimeType    string     `json:"mime_type" db:"mime_type"`
	PhotoType   string     `json:"photo_type" db:"photo_type"`     // front, back, interior, engine, damage
	IsPrimary   bool       `json:"is_primary" db:"is_primary"`
	Caption     string     `json:"caption" db:"caption"`
	UploadedBy  uuid.UUID  `json:"uploaded_by" db:"uploaded_by"`
}

// Invoice represents purchase/sales invoices
type Invoice struct {
	BaseModel
	InvoiceNumber string     `json:"invoice_number" db:"invoice_number"` // PUR-20250724-001, SAL-20250724-004
	InvoiceType   string     `json:"invoice_type" db:"invoice_type"`     // purchase, sale
	CustomerID    *uuid.UUID `json:"customer_id,omitempty" db:"customer_id"`
	CarID         *uuid.UUID `json:"car_id,omitempty" db:"car_id"`
	Amount        float64    `json:"amount" db:"amount"`
	TaxAmount     float64    `json:"tax_amount" db:"tax_amount"`
	DiscountAmount float64   `json:"discount_amount" db:"discount_amount"`
	TotalAmount   float64    `json:"total_amount" db:"total_amount"`
	PaymentMethod string     `json:"payment_method" db:"payment_method"`
	PaymentProof  string     `json:"payment_proof,omitempty" db:"payment_proof"` // File path for transfer receipt
	Status        string     `json:"status" db:"status"` // draft, sent, paid, overdue
	DueDate       *time.Time `json:"due_date,omitempty" db:"due_date"`
	PaidDate      *time.Time `json:"paid_date,omitempty" db:"paid_date"`
	Notes         string     `json:"notes" db:"notes"`
	CreatedBy     uuid.UUID  `json:"created_by" db:"created_by"`
}

// Customer with additional CRM fields
type CustomerEnhanced struct {
	Customer
	CustomerCode string  `json:"customer_code" db:"customer_code"` // CR-0001, CR-0002
	TotalPurchases int   `json:"total_purchases" db:"total_purchases"`
	TotalSales     int   `json:"total_sales" db:"total_sales"`
	TotalRevenue   float64 `json:"total_revenue" db:"total_revenue"`
}