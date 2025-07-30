package repository

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/jmoiron/sqlx"
)

type InvoiceRepository interface {
	Create(invoice *model.Invoice) error
	GetByID(id uuid.UUID) (*model.Invoice, error)
	GetByNumber(invoiceNumber string) (*model.Invoice, error)
	GetAll(limit, offset int) ([]model.Invoice, error)
	Update(invoice *model.Invoice) error
	Delete(id uuid.UUID) error
	GetByCustomerID(customerID uuid.UUID, limit, offset int) ([]model.Invoice, error)
	GetByType(invoiceType string, limit, offset int) ([]model.Invoice, error)
	GetByDateRange(startDate, endDate time.Time, limit, offset int) ([]model.Invoice, error)
	Count() (int, error)
	GenerateInvoiceNumber(invoiceType string) (string, error)
}

type invoiceRepository struct {
	db *sqlx.DB
}

func NewInvoiceRepository(db *sqlx.DB) InvoiceRepository {
	return &invoiceRepository{db: db}
}

func (r *invoiceRepository) Create(invoice *model.Invoice) error {
	query := `
		INSERT INTO invoices (id, invoice_number, invoice_type, customer_id, car_id, amount, 
			tax_amount, discount_amount, total_amount, payment_method, payment_proof, 
			status, due_date, paid_date, notes, created_by, created_at, updated_at)
		VALUES (:id, :invoice_number, :invoice_type, :customer_id, :car_id, :amount, 
			:tax_amount, :discount_amount, :total_amount, :payment_method, :payment_proof, 
			:status, :due_date, :paid_date, :notes, :created_by, :created_at, :updated_at)
	`
	
	if invoice.ID == uuid.Nil {
		invoice.ID = uuid.New()
	}
	
	now := time.Now()
	invoice.CreatedAt = now
	invoice.UpdatedAt = now
	
	_, err := r.db.NamedExec(query, invoice)
	return err
}

func (r *invoiceRepository) GetByID(id uuid.UUID) (*model.Invoice, error) {
	var invoice model.Invoice
	query := `
		SELECT * FROM invoices 
		WHERE id = $1 AND deleted_at IS NULL
	`
	
	err := r.db.Get(&invoice, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	
	return &invoice, nil
}

func (r *invoiceRepository) GetByNumber(invoiceNumber string) (*model.Invoice, error) {
	var invoice model.Invoice
	query := `
		SELECT * FROM invoices 
		WHERE invoice_number = $1 AND deleted_at IS NULL
	`
	
	err := r.db.Get(&invoice, query, invoiceNumber)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	
	return &invoice, nil
}

func (r *invoiceRepository) GetAll(limit, offset int) ([]model.Invoice, error) {
	var invoices []model.Invoice
	query := `
		SELECT * FROM invoices 
		WHERE deleted_at IS NULL 
		ORDER BY created_at DESC 
		LIMIT $1 OFFSET $2
	`
	
	err := r.db.Select(&invoices, query, limit, offset)
	return invoices, err
}

func (r *invoiceRepository) Update(invoice *model.Invoice) error {
	query := `
		UPDATE invoices SET 
			invoice_type = :invoice_type,
			customer_id = :customer_id,
			car_id = :car_id,
			amount = :amount,
			tax_amount = :tax_amount,
			discount_amount = :discount_amount,
			total_amount = :total_amount,
			payment_method = :payment_method,
			payment_proof = :payment_proof,
			status = :status,
			due_date = :due_date,
			paid_date = :paid_date,
			notes = :notes,
			updated_at = :updated_at
		WHERE id = :id AND deleted_at IS NULL
	`
	
	invoice.UpdatedAt = time.Now()
	_, err := r.db.NamedExec(query, invoice)
	return err
}

func (r *invoiceRepository) Delete(id uuid.UUID) error {
	query := `
		UPDATE invoices SET 
			deleted_at = $1, 
			updated_at = $1 
		WHERE id = $2
	`
	
	now := time.Now()
	_, err := r.db.Exec(query, now, id)
	return err
}

func (r *invoiceRepository) GetByCustomerID(customerID uuid.UUID, limit, offset int) ([]model.Invoice, error) {
	var invoices []model.Invoice
	query := `
		SELECT * FROM invoices 
		WHERE customer_id = $1 AND deleted_at IS NULL 
		ORDER BY created_at DESC 
		LIMIT $2 OFFSET $3
	`
	
	err := r.db.Select(&invoices, query, customerID, limit, offset)
	return invoices, err
}

func (r *invoiceRepository) GetByType(invoiceType string, limit, offset int) ([]model.Invoice, error) {
	var invoices []model.Invoice
	query := `
		SELECT * FROM invoices 
		WHERE invoice_type = $1 AND deleted_at IS NULL 
		ORDER BY created_at DESC 
		LIMIT $2 OFFSET $3
	`
	
	err := r.db.Select(&invoices, query, invoiceType, limit, offset)
	return invoices, err
}

func (r *invoiceRepository) GetByDateRange(startDate, endDate time.Time, limit, offset int) ([]model.Invoice, error) {
	var invoices []model.Invoice
	query := `
		SELECT * FROM invoices 
		WHERE created_at >= $1 AND created_at <= $2 AND deleted_at IS NULL 
		ORDER BY created_at DESC 
		LIMIT $3 OFFSET $4
	`
	
	err := r.db.Select(&invoices, query, startDate, endDate, limit, offset)
	return invoices, err
}

func (r *invoiceRepository) Count() (int, error) {
	var count int
	query := `SELECT COUNT(*) FROM invoices WHERE deleted_at IS NULL`
	
	err := r.db.Get(&count, query)
	return count, err
}

func (r *invoiceRepository) GenerateInvoiceNumber(invoiceType string) (string, error) {
	var prefix string
	switch invoiceType {
	case "purchase":
		prefix = "PUR"
	case "sale":
		prefix = "SAL"
	default:
		return "", fmt.Errorf("invalid invoice type: %s", invoiceType)
	}
	
	today := time.Now().Format("20060102")
	
	// Get the count of invoices for this type today
	query := `
		SELECT COUNT(*) FROM invoices 
		WHERE invoice_type = $1 
		AND DATE(created_at) = CURRENT_DATE 
		AND deleted_at IS NULL
	`
	
	var count int
	err := r.db.Get(&count, query, invoiceType)
	if err != nil {
		return "", err
	}
	
	// Increment for next number
	count++
	
	return fmt.Sprintf("%s-%s-%03d", prefix, today, count), nil
}