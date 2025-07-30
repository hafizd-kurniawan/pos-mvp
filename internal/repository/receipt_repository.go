package repository

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/jmoiron/sqlx"
)

type ReceiptRepository interface {
	Create(receipt *model.Receipt) error
	GetByID(id uuid.UUID) (*model.Receipt, error)
	GetAll(limit, offset int) ([]model.Receipt, error)
	Update(receipt *model.Receipt) error
	Delete(id uuid.UUID) error
	SoftDelete(id uuid.UUID) error
	GetByTransactionID(transactionID uuid.UUID) (*model.Receipt, error)
	GetByReceiptNumber(receiptNumber string) (*model.Receipt, error)
	Search(query string, limit, offset int) ([]model.Receipt, error)
	Count() (int, error)
}

type receiptRepository struct {
	db *sqlx.DB
}

func NewReceiptRepository(db *sqlx.DB) ReceiptRepository {
	return &receiptRepository{db: db}
}

func (r *receiptRepository) Create(receipt *model.Receipt) error {
	receipt.ID = uuid.New()
	receipt.CreatedAt = time.Now()
	receipt.UpdatedAt = time.Now()

	query := `
		INSERT INTO receipts (id, transaction_id, receipt_number, issue_date, customer_name, 
		                     customer_email, customer_phone, car_brand, car_model, car_year, 
		                     car_vin, sale_price, discount_amount, tax_amount, total_amount, 
		                     payment_method, created_at, updated_at)
		VALUES (:id, :transaction_id, :receipt_number, :issue_date, :customer_name, 
		        :customer_email, :customer_phone, :car_brand, :car_model, :car_year, 
		        :car_vin, :sale_price, :discount_amount, :tax_amount, :total_amount, 
		        :payment_method, :created_at, :updated_at)`

	_, err := r.db.NamedExec(query, receipt)
	return err
}

func (r *receiptRepository) GetByID(id uuid.UUID) (*model.Receipt, error) {
	var receipt model.Receipt
	query := `
		SELECT id, transaction_id, receipt_number, issue_date, customer_name, customer_email,
		       customer_phone, car_brand, car_model, car_year, car_vin, sale_price,
		       discount_amount, tax_amount, total_amount, payment_method,
		       created_at, updated_at, deleted_at
		FROM receipts 
		WHERE id = $1 AND deleted_at IS NULL`

	err := r.db.Get(&receipt, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("receipt not found")
		}
		return nil, err
	}
	return &receipt, nil
}

func (r *receiptRepository) GetAll(limit, offset int) ([]model.Receipt, error) {
	var receipts []model.Receipt
	query := `
		SELECT id, transaction_id, receipt_number, issue_date, customer_name, customer_email,
		       customer_phone, car_brand, car_model, car_year, car_vin, sale_price,
		       discount_amount, tax_amount, total_amount, payment_method,
		       created_at, updated_at, deleted_at
		FROM receipts 
		WHERE deleted_at IS NULL
		ORDER BY issue_date DESC
		LIMIT $1 OFFSET $2`

	err := r.db.Select(&receipts, query, limit, offset)
	return receipts, err
}

func (r *receiptRepository) Update(receipt *model.Receipt) error {
	receipt.UpdatedAt = time.Now()

	query := `
		UPDATE receipts 
		SET transaction_id = :transaction_id, receipt_number = :receipt_number, 
		    issue_date = :issue_date, customer_name = :customer_name, 
		    customer_email = :customer_email, customer_phone = :customer_phone,
		    car_brand = :car_brand, car_model = :car_model, car_year = :car_year,
		    car_vin = :car_vin, sale_price = :sale_price, discount_amount = :discount_amount,
		    tax_amount = :tax_amount, total_amount = :total_amount, 
		    payment_method = :payment_method, updated_at = :updated_at
		WHERE id = :id AND deleted_at IS NULL`

	result, err := r.db.NamedExec(query, receipt)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return fmt.Errorf("receipt not found or already deleted")
	}

	return nil
}

func (r *receiptRepository) Delete(id uuid.UUID) error {
	query := `DELETE FROM receipts WHERE id = $1`
	result, err := r.db.Exec(query, id)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return fmt.Errorf("receipt not found")
	}

	return nil
}

func (r *receiptRepository) SoftDelete(id uuid.UUID) error {
	query := `
		UPDATE receipts 
		SET deleted_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
		WHERE id = $1 AND deleted_at IS NULL`

	result, err := r.db.Exec(query, id)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return fmt.Errorf("receipt not found or already deleted")
	}

	return nil
}

func (r *receiptRepository) GetByTransactionID(transactionID uuid.UUID) (*model.Receipt, error) {
	var receipt model.Receipt
	query := `
		SELECT id, transaction_id, receipt_number, issue_date, customer_name, customer_email,
		       customer_phone, car_brand, car_model, car_year, car_vin, sale_price,
		       discount_amount, tax_amount, total_amount, payment_method,
		       created_at, updated_at, deleted_at
		FROM receipts 
		WHERE transaction_id = $1 AND deleted_at IS NULL`

	err := r.db.Get(&receipt, query, transactionID)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("receipt not found")
		}
		return nil, err
	}
	return &receipt, nil
}

func (r *receiptRepository) GetByReceiptNumber(receiptNumber string) (*model.Receipt, error) {
	var receipt model.Receipt
	query := `
		SELECT id, transaction_id, receipt_number, issue_date, customer_name, customer_email,
		       customer_phone, car_brand, car_model, car_year, car_vin, sale_price,
		       discount_amount, tax_amount, total_amount, payment_method,
		       created_at, updated_at, deleted_at
		FROM receipts 
		WHERE receipt_number = $1 AND deleted_at IS NULL`

	err := r.db.Get(&receipt, query, receiptNumber)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("receipt not found")
		}
		return nil, err
	}
	return &receipt, nil
}

func (r *receiptRepository) Search(query string, limit, offset int) ([]model.Receipt, error) {
	var receipts []model.Receipt
	searchQuery := `
		SELECT id, transaction_id, receipt_number, issue_date, customer_name, customer_email,
		       customer_phone, car_brand, car_model, car_year, car_vin, sale_price,
		       discount_amount, tax_amount, total_amount, payment_method,
		       created_at, updated_at, deleted_at
		FROM receipts 
		WHERE (receipt_number ILIKE '%' || $1 || '%' OR customer_name ILIKE '%' || $1 || '%' 
		       OR customer_email ILIKE '%' || $1 || '%' OR car_brand ILIKE '%' || $1 || '%' 
		       OR car_model ILIKE '%' || $1 || '%' OR car_vin ILIKE '%' || $1 || '%')
		AND deleted_at IS NULL
		ORDER BY issue_date DESC
		LIMIT $2 OFFSET $3`

	err := r.db.Select(&receipts, searchQuery, query, limit, offset)
	return receipts, err
}

func (r *receiptRepository) Count() (int, error) {
	var count int
	query := `SELECT COUNT(*) FROM receipts WHERE deleted_at IS NULL`
	err := r.db.Get(&count, query)
	return count, err
}