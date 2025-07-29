package repository

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/jmoiron/sqlx"
)

type CustomerRepository interface {
	Create(customer *model.Customer) error
	GetByID(id uuid.UUID) (*model.Customer, error)
	GetAll(limit, offset int) ([]model.Customer, error)
	Update(customer *model.Customer) error
	Delete(id uuid.UUID) error
	SoftDelete(id uuid.UUID) error
	GetByEmail(email string) (*model.Customer, error)
	Search(query string, limit, offset int) ([]model.Customer, error)
	Count() (int, error)
}

type customerRepository struct {
	db *sqlx.DB
}

func NewCustomerRepository(db *sqlx.DB) CustomerRepository {
	return &customerRepository{db: db}
}

func (r *customerRepository) Create(customer *model.Customer) error {
	customer.ID = uuid.New()
	customer.CreatedAt = time.Now()
	customer.UpdatedAt = time.Now()

	query := `
		INSERT INTO customers (id, first_name, last_name, email, phone, address, city, state, zip_code, date_of_birth, created_at, updated_at)
		VALUES (:id, :first_name, :last_name, :email, :phone, :address, :city, :state, :zip_code, :date_of_birth, :created_at, :updated_at)`

	_, err := r.db.NamedExec(query, customer)
	return err
}

func (r *customerRepository) GetByID(id uuid.UUID) (*model.Customer, error) {
	var customer model.Customer
	query := `
		SELECT id, first_name, last_name, email, phone, address, city, state, zip_code, date_of_birth,
		       created_at, updated_at, deleted_at
		FROM customers 
		WHERE id = $1 AND deleted_at IS NULL`

	err := r.db.Get(&customer, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("customer not found")
		}
		return nil, err
	}
	return &customer, nil
}

func (r *customerRepository) GetAll(limit, offset int) ([]model.Customer, error) {
	var customers []model.Customer
	query := `
		SELECT id, first_name, last_name, email, phone, address, city, state, zip_code, date_of_birth,
		       created_at, updated_at, deleted_at
		FROM customers 
		WHERE deleted_at IS NULL
		ORDER BY created_at DESC
		LIMIT $1 OFFSET $2`

	err := r.db.Select(&customers, query, limit, offset)
	return customers, err
}

func (r *customerRepository) Update(customer *model.Customer) error {
	customer.UpdatedAt = time.Now()

	query := `
		UPDATE customers 
		SET first_name = :first_name, last_name = :last_name, email = :email, phone = :phone,
		    address = :address, city = :city, state = :state, zip_code = :zip_code, 
		    date_of_birth = :date_of_birth, updated_at = :updated_at
		WHERE id = :id AND deleted_at IS NULL`

	result, err := r.db.NamedExec(query, customer)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return fmt.Errorf("customer not found or already deleted")
	}

	return nil
}

func (r *customerRepository) Delete(id uuid.UUID) error {
	query := `DELETE FROM customers WHERE id = $1`
	result, err := r.db.Exec(query, id)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return fmt.Errorf("customer not found")
	}

	return nil
}

func (r *customerRepository) SoftDelete(id uuid.UUID) error {
	query := `
		UPDATE customers 
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
		return fmt.Errorf("customer not found or already deleted")
	}

	return nil
}

func (r *customerRepository) GetByEmail(email string) (*model.Customer, error) {
	var customer model.Customer
	query := `
		SELECT id, first_name, last_name, email, phone, address, city, state, zip_code, date_of_birth,
		       created_at, updated_at, deleted_at
		FROM customers 
		WHERE email = $1 AND deleted_at IS NULL`

	err := r.db.Get(&customer, query, email)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("customer not found")
		}
		return nil, err
	}
	return &customer, nil
}

func (r *customerRepository) Search(query string, limit, offset int) ([]model.Customer, error) {
	var customers []model.Customer
	searchQuery := `
		SELECT id, first_name, last_name, email, phone, address, city, state, zip_code, date_of_birth,
		       created_at, updated_at, deleted_at
		FROM customers 
		WHERE (first_name ILIKE '%' || $1 || '%' OR last_name ILIKE '%' || $1 || '%' OR email ILIKE '%' || $1 || '%' OR phone ILIKE '%' || $1 || '%')
		AND deleted_at IS NULL
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3`

	err := r.db.Select(&customers, searchQuery, query, limit, offset)
	return customers, err
}

func (r *customerRepository) Count() (int, error) {
	var count int
	query := `SELECT COUNT(*) FROM customers WHERE deleted_at IS NULL`
	err := r.db.Get(&count, query)
	return count, err
}