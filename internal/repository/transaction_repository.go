package repository

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/jmoiron/sqlx"
)

type TransactionRepository interface {
	Create(transaction *model.Transaction) error
	GetByID(id uuid.UUID) (*model.Transaction, error)
	GetAll(limit, offset int) ([]model.Transaction, error)
	Update(transaction *model.Transaction) error
	Delete(id uuid.UUID) error
	SoftDelete(id uuid.UUID) error
	GetByCustomerID(customerID uuid.UUID, limit, offset int) ([]model.Transaction, error)
	GetByDateRange(startDate, endDate time.Time, limit, offset int) ([]model.Transaction, error)
	GetByStatus(status string, limit, offset int) ([]model.Transaction, error)
	Count() (int, error)
}

type transactionRepository struct {
	db *sqlx.DB
}

func NewTransactionRepository(db *sqlx.DB) TransactionRepository {
	return &transactionRepository{db: db}
}

func (r *transactionRepository) Create(transaction *model.Transaction) error {
	transaction.ID = uuid.New()
	transaction.CreatedAt = time.Now()
	transaction.UpdatedAt = time.Now()

	query := `
		INSERT INTO transactions (id, customer_id, car_id, sale_price, discount_amount, tax_amount, 
		                         total_amount, payment_method, transaction_date, sales_person_id, 
		                         notes, status, created_at, updated_at)
		VALUES (:id, :customer_id, :car_id, :sale_price, :discount_amount, :tax_amount, 
		        :total_amount, :payment_method, :transaction_date, :sales_person_id, 
		        :notes, :status, :created_at, :updated_at)`

	_, err := r.db.NamedExec(query, transaction)
	return err
}

func (r *transactionRepository) GetByID(id uuid.UUID) (*model.Transaction, error) {
	var transaction model.Transaction
	query := `
		SELECT id, customer_id, car_id, sale_price, discount_amount, tax_amount, total_amount,
		       payment_method, transaction_date, sales_person_id, notes, status,
		       created_at, updated_at, deleted_at
		FROM transactions 
		WHERE id = $1 AND deleted_at IS NULL`

	err := r.db.Get(&transaction, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("transaction not found")
		}
		return nil, err
	}
	return &transaction, nil
}

func (r *transactionRepository) GetAll(limit, offset int) ([]model.Transaction, error) {
	var transactions []model.Transaction
	query := `
		SELECT id, customer_id, car_id, sale_price, discount_amount, tax_amount, total_amount,
		       payment_method, transaction_date, sales_person_id, notes, status,
		       created_at, updated_at, deleted_at
		FROM transactions 
		WHERE deleted_at IS NULL
		ORDER BY transaction_date DESC
		LIMIT $1 OFFSET $2`

	err := r.db.Select(&transactions, query, limit, offset)
	return transactions, err
}

func (r *transactionRepository) Update(transaction *model.Transaction) error {
	transaction.UpdatedAt = time.Now()

	query := `
		UPDATE transactions 
		SET customer_id = :customer_id, car_id = :car_id, sale_price = :sale_price, 
		    discount_amount = :discount_amount, tax_amount = :tax_amount, total_amount = :total_amount,
		    payment_method = :payment_method, transaction_date = :transaction_date, 
		    sales_person_id = :sales_person_id, notes = :notes, status = :status, updated_at = :updated_at
		WHERE id = :id AND deleted_at IS NULL`

	result, err := r.db.NamedExec(query, transaction)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return fmt.Errorf("transaction not found or already deleted")
	}

	return nil
}

func (r *transactionRepository) Delete(id uuid.UUID) error {
	query := `DELETE FROM transactions WHERE id = $1`
	result, err := r.db.Exec(query, id)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return fmt.Errorf("transaction not found")
	}

	return nil
}

func (r *transactionRepository) SoftDelete(id uuid.UUID) error {
	query := `
		UPDATE transactions 
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
		return fmt.Errorf("transaction not found or already deleted")
	}

	return nil
}

func (r *transactionRepository) GetByCustomerID(customerID uuid.UUID, limit, offset int) ([]model.Transaction, error) {
	var transactions []model.Transaction
	query := `
		SELECT id, customer_id, car_id, sale_price, discount_amount, tax_amount, total_amount,
		       payment_method, transaction_date, sales_person_id, notes, status,
		       created_at, updated_at, deleted_at
		FROM transactions 
		WHERE customer_id = $1 AND deleted_at IS NULL
		ORDER BY transaction_date DESC
		LIMIT $2 OFFSET $3`

	err := r.db.Select(&transactions, query, customerID, limit, offset)
	return transactions, err
}

func (r *transactionRepository) GetByDateRange(startDate, endDate time.Time, limit, offset int) ([]model.Transaction, error) {
	var transactions []model.Transaction
	query := `
		SELECT id, customer_id, car_id, sale_price, discount_amount, tax_amount, total_amount,
		       payment_method, transaction_date, sales_person_id, notes, status,
		       created_at, updated_at, deleted_at
		FROM transactions 
		WHERE transaction_date >= $1 AND transaction_date <= $2 AND deleted_at IS NULL
		ORDER BY transaction_date DESC
		LIMIT $3 OFFSET $4`

	err := r.db.Select(&transactions, query, startDate, endDate, limit, offset)
	return transactions, err
}

func (r *transactionRepository) GetByStatus(status string, limit, offset int) ([]model.Transaction, error) {
	var transactions []model.Transaction
	query := `
		SELECT id, customer_id, car_id, sale_price, discount_amount, tax_amount, total_amount,
		       payment_method, transaction_date, sales_person_id, notes, status,
		       created_at, updated_at, deleted_at
		FROM transactions 
		WHERE status = $1 AND deleted_at IS NULL
		ORDER BY transaction_date DESC
		LIMIT $2 OFFSET $3`

	err := r.db.Select(&transactions, query, status, limit, offset)
	return transactions, err
}

func (r *transactionRepository) Count() (int, error) {
	var count int
	query := `SELECT COUNT(*) FROM transactions WHERE deleted_at IS NULL`
	err := r.db.Get(&count, query)
	return count, err
}