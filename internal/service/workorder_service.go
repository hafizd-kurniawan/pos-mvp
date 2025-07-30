package service

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/hafizd-kurniawan/pos-mvp/internal/repository"
)

type WorkOrderService struct {
	workOrderRepo     *repository.WorkOrderRepository
	workOrderItemRepo *repository.WorkOrderItemRepository
	sparepartRepo     *repository.SparepartRepository
	stockMovementRepo *repository.StockMovementRepository
	activityLogRepo   *repository.ActivityLogRepository
}

func NewWorkOrderService(
	workOrderRepo *repository.WorkOrderRepository,
	workOrderItemRepo *repository.WorkOrderItemRepository,
	sparepartRepo *repository.SparepartRepository,
	stockMovementRepo *repository.StockMovementRepository,
	activityLogRepo *repository.ActivityLogRepository,
) *WorkOrderService {
	return &WorkOrderService{
		workOrderRepo:     workOrderRepo,
		workOrderItemRepo: workOrderItemRepo,
		sparepartRepo:     sparepartRepo,
		stockMovementRepo: stockMovementRepo,
		activityLogRepo:   activityLogRepo,
	}
}

func (s *WorkOrderService) CreateWorkOrder(workOrder *model.WorkOrder, userID uuid.UUID, ipAddress, userAgent string) error {
	workOrder.ID = uuid.New()
	workOrder.CreatedAt = time.Now()
	workOrder.UpdatedAt = time.Now()
	workOrder.Status = "pending"
	workOrder.Progress = 0
	
	// Generate work order number
	workOrderNumber, err := s.workOrderRepo.GenerateWorkOrderNumber()
	if err != nil {
		return err
	}
	workOrder.WorkOrderNumber = workOrderNumber
	
	// Calculate total cost
	workOrder.TotalCost = workOrder.LaborCost + workOrder.PartsCost
	
	err = s.workOrderRepo.Create(workOrder)
	if err != nil {
		return err
	}
	
	// Log activity
	s.logActivity(userID, "CREATE", "work_order", &workOrder.ID, ipAddress, userAgent, 
		fmt.Sprintf("Created work order: %s", workOrder.WorkOrderNumber), "", workOrder)
	
	return nil
}

func (s *WorkOrderService) GetWorkOrderByID(id uuid.UUID) (*model.WorkOrder, error) {
	return s.workOrderRepo.GetByID(id)
}

func (s *WorkOrderService) GetWorkOrderByNumber(workOrderNumber string) (*model.WorkOrder, error) {
	return s.workOrderRepo.GetByNumber(workOrderNumber)
}

func (s *WorkOrderService) GetAllWorkOrders(page, limit int) ([]model.WorkOrder, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}
	
	return s.workOrderRepo.GetAll(page, limit)
}

func (s *WorkOrderService) GetWorkOrdersByCarID(carID uuid.UUID, page, limit int) ([]model.WorkOrder, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}
	
	return s.workOrderRepo.GetByCarID(carID, page, limit)
}

func (s *WorkOrderService) GetWorkOrdersByMechanicID(mechanicID uuid.UUID, page, limit int) ([]model.WorkOrder, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}
	
	return s.workOrderRepo.GetByMechanicID(mechanicID, page, limit)
}

func (s *WorkOrderService) GetWorkOrdersByStatus(status string, page, limit int) ([]model.WorkOrder, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}
	
	return s.workOrderRepo.GetByStatus(status, page, limit)
}

func (s *WorkOrderService) UpdateWorkOrderProgress(id uuid.UUID, progress int, userID uuid.UUID, ipAddress, userAgent string) error {
	// Get current work order
	workOrder, err := s.workOrderRepo.GetByID(id)
	if err != nil {
		return err
	}
	
	// Determine status based on progress
	var status string
	switch {
	case progress == 0:
		status = "pending"
	case progress >= 100:
		status = "completed"
		progress = 100
	default:
		status = "in_progress"
	}
	
	err = s.workOrderRepo.UpdateProgress(id, progress, status)
	if err != nil {
		return err
	}
	
	// Log activity
	s.logActivity(userID, "UPDATE", "work_order", &id, ipAddress, userAgent, 
		fmt.Sprintf("Updated progress for work order %s: %d%% (%s)", workOrder.WorkOrderNumber, progress, status),
		fmt.Sprintf(`{"progress": %d, "status": "%s"}`, workOrder.Progress, workOrder.Status),
		fmt.Sprintf(`{"progress": %d, "status": "%s"}`, progress, status))
	
	return nil
}

func (s *WorkOrderService) AddWorkOrderItem(workOrderID, sparepartID uuid.UUID, quantity int, userID uuid.UUID, ipAddress, userAgent string) error {
	// Get sparepart info
	sparepart, err := s.sparepartRepo.GetByID(sparepartID)
	if err != nil {
		return err
	}
	
	// Check if enough stock
	if sparepart.Stock < quantity {
		return fmt.Errorf("insufficient stock: need %d, have %d", quantity, sparepart.Stock)
	}
	
	// Create work order item
	item := &model.WorkOrderItem{
		WorkOrderID:   workOrderID,
		SparepartID:   sparepartID,
		Quantity:      quantity,
		UnitPrice:     sparepart.SalePrice,
		TotalPrice:    sparepart.SalePrice * float64(quantity),
		UsedDate:      time.Now(),
	}
	item.ID = uuid.New()
	item.CreatedAt = time.Now()
	item.UpdatedAt = time.Now()
	
	err = s.workOrderItemRepo.Create(item)
	if err != nil {
		return err
	}
	
	// Update stock
	newStock := sparepart.Stock - quantity
	err = s.sparepartRepo.UpdateStock(sparepartID, newStock)
	if err != nil {
		return err
	}
	
	// Create stock movement record
	workOrder, _ := s.workOrderRepo.GetByID(workOrderID)
	movement := &model.StockMovement{
		SparepartID:   sparepartID,
		MovementType:  "OUT",
		Quantity:      -quantity,
		Reference:     workOrder.WorkOrderNumber,
		ReferenceID:   &workOrderID,
		UserID:        userID,
		Notes:         fmt.Sprintf("Used in work order %s", workOrder.WorkOrderNumber),
		PreviousStock: sparepart.Stock,
		NewStock:      newStock,
	}
	movement.ID = uuid.New()
	movement.CreatedAt = time.Now()
	movement.UpdatedAt = time.Now()
	
	err = s.stockMovementRepo.Create(movement)
	if err != nil {
		return err
	}
	
	// Update work order parts cost
	items, _ := s.workOrderItemRepo.GetByWorkOrderID(workOrderID)
	var totalPartsCost float64
	for _, item := range items {
		totalPartsCost += item.TotalPrice
	}
	
	workOrder.PartsCost = totalPartsCost
	workOrder.TotalCost = workOrder.LaborCost + workOrder.PartsCost
	s.workOrderRepo.Update(workOrder)
	
	// Log activity
	s.logActivity(userID, "CREATE", "work_order_item", &item.ID, ipAddress, userAgent, 
		fmt.Sprintf("Added %d x %s to work order %s", quantity, sparepart.Name, workOrder.WorkOrderNumber), "", item)
	
	return nil
}

func (s *WorkOrderService) GetWorkOrderItems(workOrderID uuid.UUID) ([]model.WorkOrderItem, error) {
	return s.workOrderItemRepo.GetByWorkOrderID(workOrderID)
}

func (s *WorkOrderService) RemoveWorkOrderItem(itemID uuid.UUID, userID uuid.UUID, ipAddress, userAgent string) error {
	// Get item info for stock restoration
	// TODO: This needs to be implemented to restore stock when removing items
	// items, err := s.workOrderItemRepo.GetByWorkOrderID(uuid.Nil) // This needs to be fixed to get by item ID
	// if err != nil {
	//	return err
	// }
	
	// For now, just delete the item
	err := s.workOrderItemRepo.Delete(itemID)
	if err != nil {
		return err
	}
	
	// Log activity
	s.logActivity(userID, "DELETE", "work_order_item", &itemID, ipAddress, userAgent, 
		"Removed item from work order", "", "")
	
	return nil
}

func (s *WorkOrderService) UpdateWorkOrder(workOrder *model.WorkOrder, userID uuid.UUID, ipAddress, userAgent string) error {
	// Get old values for logging
	oldWorkOrder, err := s.workOrderRepo.GetByID(workOrder.ID)
	if err != nil {
		return err
	}
	
	workOrder.UpdatedAt = time.Now()
	workOrder.TotalCost = workOrder.LaborCost + workOrder.PartsCost
	
	err = s.workOrderRepo.Update(workOrder)
	if err != nil {
		return err
	}
	
	// Log activity
	oldValues, _ := json.Marshal(oldWorkOrder)
	newValues, _ := json.Marshal(workOrder)
	s.logActivity(userID, "UPDATE", "work_order", &workOrder.ID, ipAddress, userAgent, 
		fmt.Sprintf("Updated work order: %s", workOrder.WorkOrderNumber), string(oldValues), string(newValues))
	
	return nil
}

func (s *WorkOrderService) DeleteWorkOrder(id uuid.UUID, userID uuid.UUID, ipAddress, userAgent string) error {
	// Get work order for logging
	workOrder, err := s.workOrderRepo.GetByID(id)
	if err != nil {
		return err
	}
	
	err = s.workOrderRepo.Delete(id)
	if err != nil {
		return err
	}
	
	// Log activity
	oldValues, _ := json.Marshal(workOrder)
	s.logActivity(userID, "DELETE", "work_order", &id, ipAddress, userAgent, 
		fmt.Sprintf("Deleted work order: %s", workOrder.WorkOrderNumber), string(oldValues), "")
	
	return nil
}

func (s *WorkOrderService) logActivity(userID uuid.UUID, action, entityType string, entityID *uuid.UUID, ipAddress, userAgent, description, oldValues string, newValues interface{}) {
	var newValuesStr string
	if newValues != nil {
		if str, ok := newValues.(string); ok {
			newValuesStr = str
		} else {
			if jsonBytes, err := json.Marshal(newValues); err == nil {
				newValuesStr = string(jsonBytes)
			}
		}
	}
	
	log := &model.ActivityLog{
		UserID:      &userID,
		Action:      action,
		EntityType:  entityType,
		EntityID:    entityID,
		IPAddress:   ipAddress,
		UserAgent:   userAgent,
		Description: description,
		OldValues:   oldValues,
		NewValues:   newValuesStr,
	}
	log.ID = uuid.New()
	log.CreatedAt = time.Now()
	log.UpdatedAt = time.Now()
	
	s.activityLogRepo.Create(log)
}