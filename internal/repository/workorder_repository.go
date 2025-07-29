package repository

import (
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/jmoiron/sqlx"
)

type WorkOrderRepository struct {
	db *sqlx.DB
}

func NewWorkOrderRepository(db *sqlx.DB) *WorkOrderRepository {
	return &WorkOrderRepository{db: db}
}

func (r *WorkOrderRepository) Create(workOrder *model.WorkOrder) error {
	query := `
		INSERT INTO work_orders (work_order_number, car_id, mechanic_id, assigned_by, description, labor_cost, parts_cost, total_cost, status, progress, notes)
		VALUES (:work_order_number, :car_id, :mechanic_id, :assigned_by, :description, :labor_cost, :parts_cost, :total_cost, :status, :progress, :notes)
		RETURNING id, created_at, updated_at`
	
	stmt, err := r.db.PrepareNamed(query)
	if err != nil {
		return err
	}
	defer stmt.Close()
	
	return stmt.Get(workOrder, workOrder)
}

func (r *WorkOrderRepository) GetByID(id uuid.UUID) (*model.WorkOrder, error) {
	workOrder := &model.WorkOrder{}
	query := `SELECT * FROM work_orders WHERE id = $1 AND deleted_at IS NULL`
	
	err := r.db.Get(workOrder, query, id)
	return workOrder, err
}

func (r *WorkOrderRepository) GetByNumber(workOrderNumber string) (*model.WorkOrder, error) {
	workOrder := &model.WorkOrder{}
	query := `SELECT * FROM work_orders WHERE work_order_number = $1 AND deleted_at IS NULL`
	
	err := r.db.Get(workOrder, query, workOrderNumber)
	return workOrder, err
}

func (r *WorkOrderRepository) GetAll(page, limit int) ([]model.WorkOrder, int, error) {
	workOrders := []model.WorkOrder{}
	
	// Get total count
	var total int
	countQuery := `SELECT COUNT(*) FROM work_orders WHERE deleted_at IS NULL`
	err := r.db.Get(&total, countQuery)
	if err != nil {
		return workOrders, 0, err
	}
	
	// Get paginated results
	offset := (page - 1) * limit
	query := `
		SELECT * FROM work_orders 
		WHERE deleted_at IS NULL 
		ORDER BY created_at DESC 
		LIMIT $1 OFFSET $2`
	
	err = r.db.Select(&workOrders, query, limit, offset)
	return workOrders, total, err
}

func (r *WorkOrderRepository) GetByCarID(carID uuid.UUID, page, limit int) ([]model.WorkOrder, int, error) {
	workOrders := []model.WorkOrder{}
	
	// Get total count
	var total int
	countQuery := `SELECT COUNT(*) FROM work_orders WHERE car_id = $1 AND deleted_at IS NULL`
	err := r.db.Get(&total, countQuery, carID)
	if err != nil {
		return workOrders, 0, err
	}
	
	// Get paginated results
	offset := (page - 1) * limit
	query := `
		SELECT * FROM work_orders 
		WHERE car_id = $1 AND deleted_at IS NULL 
		ORDER BY created_at DESC 
		LIMIT $2 OFFSET $3`
	
	err = r.db.Select(&workOrders, query, carID, limit, offset)
	return workOrders, total, err
}

func (r *WorkOrderRepository) GetByMechanicID(mechanicID uuid.UUID, page, limit int) ([]model.WorkOrder, int, error) {
	workOrders := []model.WorkOrder{}
	
	// Get total count
	var total int
	countQuery := `SELECT COUNT(*) FROM work_orders WHERE mechanic_id = $1 AND deleted_at IS NULL`
	err := r.db.Get(&total, countQuery, mechanicID)
	if err != nil {
		return workOrders, 0, err
	}
	
	// Get paginated results
	offset := (page - 1) * limit
	query := `
		SELECT * FROM work_orders 
		WHERE mechanic_id = $1 AND deleted_at IS NULL 
		ORDER BY created_at DESC 
		LIMIT $2 OFFSET $3`
	
	err = r.db.Select(&workOrders, query, mechanicID, limit, offset)
	return workOrders, total, err
}

func (r *WorkOrderRepository) GetByStatus(status string, page, limit int) ([]model.WorkOrder, int, error) {
	workOrders := []model.WorkOrder{}
	
	// Get total count
	var total int
	countQuery := `SELECT COUNT(*) FROM work_orders WHERE status = $1 AND deleted_at IS NULL`
	err := r.db.Get(&total, countQuery, status)
	if err != nil {
		return workOrders, 0, err
	}
	
	// Get paginated results
	offset := (page - 1) * limit
	query := `
		SELECT * FROM work_orders 
		WHERE status = $1 AND deleted_at IS NULL 
		ORDER BY created_at DESC 
		LIMIT $2 OFFSET $3`
	
	err = r.db.Select(&workOrders, query, status, limit, offset)
	return workOrders, total, err
}

func (r *WorkOrderRepository) UpdateProgress(id uuid.UUID, progress int, status string) error {
	var query string
	var args []interface{}
	
	if status == "completed" {
		query = `UPDATE work_orders SET progress = $1, status = $2, completed_date = NOW(), updated_at = NOW() WHERE id = $3 AND deleted_at IS NULL`
		args = []interface{}{progress, status, id}
	} else if status == "in_progress" && progress > 0 {
		query = `UPDATE work_orders SET progress = $1, status = $2, start_date = COALESCE(start_date, NOW()), updated_at = NOW() WHERE id = $3 AND deleted_at IS NULL`
		args = []interface{}{progress, status, id}
	} else {
		query = `UPDATE work_orders SET progress = $1, status = $2, updated_at = NOW() WHERE id = $3 AND deleted_at IS NULL`
		args = []interface{}{progress, status, id}
	}
	
	_, err := r.db.Exec(query, args...)
	return err
}

func (r *WorkOrderRepository) Update(workOrder *model.WorkOrder) error {
	query := `
		UPDATE work_orders SET 
		work_order_number = :work_order_number, car_id = :car_id, mechanic_id = :mechanic_id, 
		assigned_by = :assigned_by, description = :description, labor_cost = :labor_cost, 
		parts_cost = :parts_cost, total_cost = :total_cost, status = :status, 
		progress = :progress, notes = :notes, updated_at = NOW()
		WHERE id = :id AND deleted_at IS NULL`
	
	_, err := r.db.NamedExec(query, workOrder)
	return err
}

func (r *WorkOrderRepository) Delete(id uuid.UUID) error {
	query := `UPDATE work_orders SET deleted_at = NOW(), updated_at = NOW() WHERE id = $1`
	_, err := r.db.Exec(query, id)
	return err
}

func (r *WorkOrderRepository) GenerateWorkOrderNumber() (string, error) {
	// Generate work order number in format: WO-YYYYMMDD-XXX
	now := time.Now()
	dateStr := now.Format("20060102")
	
	// Get the count of work orders created today
	var count int
	query := `
		SELECT COUNT(*) FROM work_orders 
		WHERE work_order_number LIKE $1 AND deleted_at IS NULL`
	
	pattern := fmt.Sprintf("WO-%s-%%", dateStr)
	err := r.db.Get(&count, query, pattern)
	if err != nil {
		return "", err
	}
	
	// Increment count and format with leading zeros
	count++
	workOrderNumber := fmt.Sprintf("WO-%s-%03d", dateStr, count)
	
	return workOrderNumber, nil
}

type WorkOrderItemRepository struct {
	db *sqlx.DB
}

func NewWorkOrderItemRepository(db *sqlx.DB) *WorkOrderItemRepository {
	return &WorkOrderItemRepository{db: db}
}

func (r *WorkOrderItemRepository) Create(item *model.WorkOrderItem) error {
	query := `
		INSERT INTO work_order_items (work_order_id, sparepart_id, quantity, unit_price, total_price, used_date)
		VALUES (:work_order_id, :sparepart_id, :quantity, :unit_price, :total_price, :used_date)
		RETURNING id, created_at, updated_at`
	
	stmt, err := r.db.PrepareNamed(query)
	if err != nil {
		return err
	}
	defer stmt.Close()
	
	return stmt.Get(item, item)
}

func (r *WorkOrderItemRepository) GetByWorkOrderID(workOrderID uuid.UUID) ([]model.WorkOrderItem, error) {
	items := []model.WorkOrderItem{}
	query := `
		SELECT * FROM work_order_items 
		WHERE work_order_id = $1 AND deleted_at IS NULL 
		ORDER BY used_date ASC`
	
	err := r.db.Select(&items, query, workOrderID)
	return items, err
}

func (r *WorkOrderItemRepository) Delete(id uuid.UUID) error {
	query := `UPDATE work_order_items SET deleted_at = NOW(), updated_at = NOW() WHERE id = $1`
	_, err := r.db.Exec(query, id)
	return err
}