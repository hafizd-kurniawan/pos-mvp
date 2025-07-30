package repository

import (
	"strings"

	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/jmoiron/sqlx"
)

type SparepartRepository struct {
	db *sqlx.DB
}

func NewSparepartRepository(db *sqlx.DB) *SparepartRepository {
	return &SparepartRepository{db: db}
}

func (r *SparepartRepository) Create(sparepart *model.Sparepart) error {
	query := `
		INSERT INTO spareparts (part_number, name, description, brand, category, stock, min_stock, cost_price, sale_price, markup_percent, location, barcode)
		VALUES (:part_number, :name, :description, :brand, :category, :stock, :min_stock, :cost_price, :sale_price, :markup_percent, :location, :barcode)
		RETURNING id, created_at, updated_at`
	
	stmt, err := r.db.PrepareNamed(query)
	if err != nil {
		return err
	}
	defer stmt.Close()
	
	return stmt.Get(sparepart, sparepart)
}

func (r *SparepartRepository) GetByID(id uuid.UUID) (*model.Sparepart, error) {
	sparepart := &model.Sparepart{}
	query := `SELECT * FROM spareparts WHERE id = $1 AND deleted_at IS NULL`
	
	err := r.db.Get(sparepart, query, id)
	return sparepart, err
}

func (r *SparepartRepository) GetByPartNumber(partNumber string) (*model.Sparepart, error) {
	sparepart := &model.Sparepart{}
	query := `SELECT * FROM spareparts WHERE part_number = $1 AND deleted_at IS NULL`
	
	err := r.db.Get(sparepart, query, partNumber)
	return sparepart, err
}

func (r *SparepartRepository) GetByBarcode(barcode string) (*model.Sparepart, error) {
	sparepart := &model.Sparepart{}
	query := `SELECT * FROM spareparts WHERE barcode = $1 AND deleted_at IS NULL`
	
	err := r.db.Get(sparepart, query, barcode)
	return sparepart, err
}

func (r *SparepartRepository) GetAll(page, limit int) ([]model.Sparepart, int, error) {
	spareparts := []model.Sparepart{}
	
	// Get total count
	var total int
	countQuery := `SELECT COUNT(*) FROM spareparts WHERE deleted_at IS NULL`
	err := r.db.Get(&total, countQuery)
	if err != nil {
		return spareparts, 0, err
	}
	
	// Get paginated results
	offset := (page - 1) * limit
	query := `
		SELECT * FROM spareparts 
		WHERE deleted_at IS NULL 
		ORDER BY name ASC 
		LIMIT $1 OFFSET $2`
	
	err = r.db.Select(&spareparts, query, limit, offset)
	return spareparts, total, err
}

func (r *SparepartRepository) Search(query string, page, limit int) ([]model.Sparepart, int, error) {
	spareparts := []model.Sparepart{}
	searchPattern := "%" + strings.ToLower(query) + "%"
	
	// Get total count
	var total int
	countQuery := `
		SELECT COUNT(*) FROM spareparts 
		WHERE (LOWER(name) LIKE $1 OR LOWER(part_number) LIKE $1 OR LOWER(brand) LIKE $1 OR LOWER(category) LIKE $1) 
		AND deleted_at IS NULL`
	err := r.db.Get(&total, countQuery, searchPattern)
	if err != nil {
		return spareparts, 0, err
	}
	
	// Get paginated results
	offset := (page - 1) * limit
	searchQuery := `
		SELECT * FROM spareparts 
		WHERE (LOWER(name) LIKE $1 OR LOWER(part_number) LIKE $1 OR LOWER(brand) LIKE $1 OR LOWER(category) LIKE $1) 
		AND deleted_at IS NULL 
		ORDER BY name ASC 
		LIMIT $2 OFFSET $3`
	
	err = r.db.Select(&spareparts, searchQuery, searchPattern, limit, offset)
	return spareparts, total, err
}

func (r *SparepartRepository) GetLowStock() ([]model.Sparepart, error) {
	spareparts := []model.Sparepart{}
	query := `
		SELECT * FROM spareparts 
		WHERE stock <= min_stock AND deleted_at IS NULL 
		ORDER BY (stock - min_stock) ASC, name ASC`
	
	err := r.db.Select(&spareparts, query)
	return spareparts, err
}

func (r *SparepartRepository) UpdateStock(id uuid.UUID, newStock int) error {
	query := `UPDATE spareparts SET stock = $1, updated_at = NOW() WHERE id = $2 AND deleted_at IS NULL`
	_, err := r.db.Exec(query, newStock, id)
	return err
}

func (r *SparepartRepository) Update(sparepart *model.Sparepart) error {
	query := `
		UPDATE spareparts SET 
		part_number = :part_number, name = :name, description = :description, brand = :brand, 
		category = :category, stock = :stock, min_stock = :min_stock, cost_price = :cost_price, 
		sale_price = :sale_price, markup_percent = :markup_percent, location = :location, 
		barcode = :barcode, updated_at = NOW()
		WHERE id = :id AND deleted_at IS NULL`
	
	_, err := r.db.NamedExec(query, sparepart)
	return err
}

func (r *SparepartRepository) Delete(id uuid.UUID) error {
	query := `UPDATE spareparts SET deleted_at = NOW(), updated_at = NOW() WHERE id = $1`
	_, err := r.db.Exec(query, id)
	return err
}

type StockMovementRepository struct {
	db *sqlx.DB
}

func NewStockMovementRepository(db *sqlx.DB) *StockMovementRepository {
	return &StockMovementRepository{db: db}
}

func (r *StockMovementRepository) Create(movement *model.StockMovement) error {
	query := `
		INSERT INTO stock_movements (sparepart_id, movement_type, quantity, reference, reference_id, user_id, notes, previous_stock, new_stock)
		VALUES (:sparepart_id, :movement_type, :quantity, :reference, :reference_id, :user_id, :notes, :previous_stock, :new_stock)
		RETURNING id, created_at, updated_at`
	
	stmt, err := r.db.PrepareNamed(query)
	if err != nil {
		return err
	}
	defer stmt.Close()
	
	return stmt.Get(movement, movement)
}

func (r *StockMovementRepository) GetBySparepartID(sparepartID uuid.UUID, page, limit int) ([]model.StockMovement, int, error) {
	movements := []model.StockMovement{}
	
	// Get total count
	var total int
	countQuery := `SELECT COUNT(*) FROM stock_movements WHERE sparepart_id = $1 AND deleted_at IS NULL`
	err := r.db.Get(&total, countQuery, sparepartID)
	if err != nil {
		return movements, 0, err
	}
	
	// Get paginated results
	offset := (page - 1) * limit
	query := `
		SELECT * FROM stock_movements 
		WHERE sparepart_id = $1 AND deleted_at IS NULL 
		ORDER BY created_at DESC 
		LIMIT $2 OFFSET $3`
	
	err = r.db.Select(&movements, query, sparepartID, limit, offset)
	return movements, total, err
}