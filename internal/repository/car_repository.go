package repository

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/jmoiron/sqlx"
)

type CarRepository interface {
	Create(car *model.Car) error
	GetByID(id uuid.UUID) (*model.Car, error)
	GetAll(limit, offset int) ([]model.Car, error)
	Update(car *model.Car) error
	Delete(id uuid.UUID) error
	SoftDelete(id uuid.UUID) error
	GetByStatus(status string, limit, offset int) ([]model.Car, error)
	Search(query string, limit, offset int) ([]model.Car, error)
	Count() (int, error)
	GetByCustomer(customerID uuid.UUID) ([]model.Car, error)
}

type carRepository struct {
	db *sqlx.DB
}

func NewCarRepository(db *sqlx.DB) CarRepository {
	return &carRepository{db: db}
}

func (r *carRepository) Create(car *model.Car) error {
	car.ID = uuid.New()
	car.CreatedAt = time.Now()
	car.UpdatedAt = time.Now()

	query := `
		INSERT INTO cars (id, brand, model, year, color, price, mileage, vin, status, description, created_at, updated_at)
		VALUES (:id, :brand, :model, :year, :color, :price, :mileage, :vin, :status, :description, :created_at, :updated_at)`

	_, err := r.db.NamedExec(query, car)
	return err
}

func (r *carRepository) GetByID(id uuid.UUID) (*model.Car, error) {
	var car model.Car
	query := `
		SELECT id, brand, model, year, color, price, mileage, vin, status, description, 
		       created_at, updated_at, deleted_at
		FROM cars 
		WHERE id = $1 AND deleted_at IS NULL`

	err := r.db.Get(&car, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("car not found")
		}
		return nil, err
	}
	return &car, nil
}

func (r *carRepository) GetAll(limit, offset int) ([]model.Car, error) {
	var cars []model.Car
	query := `
		SELECT id, brand, model, year, color, price, mileage, vin, status, description,
		       created_at, updated_at, deleted_at
		FROM cars 
		WHERE deleted_at IS NULL
		ORDER BY created_at DESC
		LIMIT $1 OFFSET $2`

	err := r.db.Select(&cars, query, limit, offset)
	return cars, err
}

func (r *carRepository) Update(car *model.Car) error {
	car.UpdatedAt = time.Now()

	query := `
		UPDATE cars 
		SET brand = :brand, model = :model, year = :year, color = :color, 
		    price = :price, mileage = :mileage, vin = :vin, status = :status, 
		    description = :description, updated_at = :updated_at
		WHERE id = :id AND deleted_at IS NULL`

	result, err := r.db.NamedExec(query, car)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return fmt.Errorf("car not found or already deleted")
	}

	return nil
}

func (r *carRepository) Delete(id uuid.UUID) error {
	query := `DELETE FROM cars WHERE id = $1`
	result, err := r.db.Exec(query, id)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return fmt.Errorf("car not found")
	}

	return nil
}

func (r *carRepository) SoftDelete(id uuid.UUID) error {
	query := `
		UPDATE cars 
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
		return fmt.Errorf("car not found or already deleted")
	}

	return nil
}

func (r *carRepository) GetByStatus(status string, limit, offset int) ([]model.Car, error) {
	var cars []model.Car
	query := `
		SELECT id, brand, model, year, color, price, mileage, vin, status, description,
		       created_at, updated_at, deleted_at
		FROM cars 
		WHERE status = $1 AND deleted_at IS NULL
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3`

	err := r.db.Select(&cars, query, status, limit, offset)
	return cars, err
}

func (r *carRepository) Search(query string, limit, offset int) ([]model.Car, error) {
	var cars []model.Car
	searchQuery := `
		SELECT id, brand, model, year, color, price, mileage, vin, status, description,
		       created_at, updated_at, deleted_at
		FROM cars 
		WHERE (brand ILIKE '%' || $1 || '%' OR model ILIKE '%' || $1 || '%' OR color ILIKE '%' || $1 || '%')
		AND deleted_at IS NULL
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3`

	err := r.db.Select(&cars, searchQuery, query, limit, offset)
	return cars, err
}

func (r *carRepository) Count() (int, error) {
	var count int
	query := `SELECT COUNT(*) FROM cars WHERE deleted_at IS NULL`
	err := r.db.Get(&count, query)
	return count, err
}

func (r *carRepository) GetByCustomer(customerID uuid.UUID) ([]model.Car, error) {
	var cars []model.Car
	query := `
		SELECT c.id, c.brand, c.model, c.year, c.color, c.price, c.mileage, c.vin, c.status, c.description,
		       c.created_at, c.updated_at, c.deleted_at
		FROM cars c
		INNER JOIN invoices i ON c.id = i.car_id
		WHERE i.customer_id = $1 AND i.invoice_type = 'purchase' AND c.deleted_at IS NULL
		AND c.status IN ('available', 'in_repair')
		ORDER BY c.created_at DESC`

	err := r.db.Select(&cars, query, customerID)
	return cars, err
}