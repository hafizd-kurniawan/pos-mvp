package service

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/hafizd-kurniawan/pos-mvp/internal/repository"
)

type SparepartService struct {
	sparepartRepo     *repository.SparepartRepository
	stockMovementRepo *repository.StockMovementRepository
	activityLogRepo   *repository.ActivityLogRepository
}

func NewSparepartService(sparepartRepo *repository.SparepartRepository, stockMovementRepo *repository.StockMovementRepository, activityLogRepo *repository.ActivityLogRepository) *SparepartService {
	return &SparepartService{
		sparepartRepo:     sparepartRepo,
		stockMovementRepo: stockMovementRepo,
		activityLogRepo:   activityLogRepo,
	}
}

func (s *SparepartService) CreateSparepart(sparepart *model.Sparepart, userID uuid.UUID, ipAddress, userAgent string) error {
	sparepart.ID = uuid.New()
	sparepart.CreatedAt = time.Now()
	sparepart.UpdatedAt = time.Now()
	
	// Calculate sale price based on markup if not provided
	if sparepart.SalePrice == 0 && sparepart.MarkupPercent > 0 {
		sparepart.SalePrice = sparepart.CostPrice * (1 + sparepart.MarkupPercent/100)
	}
	
	err := s.sparepartRepo.Create(sparepart)
	if err != nil {
		return err
	}
	
	// Log activity
	s.logActivity(userID, "CREATE", "sparepart", &sparepart.ID, ipAddress, userAgent, fmt.Sprintf("Created sparepart: %s", sparepart.Name), "", sparepart)
	
	return nil
}

func (s *SparepartService) GetSparepartByID(id uuid.UUID) (*model.Sparepart, error) {
	return s.sparepartRepo.GetByID(id)
}

func (s *SparepartService) GetSparepartByPartNumber(partNumber string) (*model.Sparepart, error) {
	return s.sparepartRepo.GetByPartNumber(partNumber)
}

func (s *SparepartService) GetSparepartByBarcode(barcode string) (*model.Sparepart, error) {
	return s.sparepartRepo.GetByBarcode(barcode)
}

func (s *SparepartService) GetAllSpareparts(page, limit int) ([]model.Sparepart, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}
	
	return s.sparepartRepo.GetAll(page, limit)
}

func (s *SparepartService) SearchSpareparts(query string, page, limit int) ([]model.Sparepart, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}
	
	return s.sparepartRepo.Search(query, page, limit)
}

func (s *SparepartService) GetLowStockSpareparts() ([]model.Sparepart, error) {
	return s.sparepartRepo.GetLowStock()
}

func (s *SparepartService) UpdateStock(sparepartID uuid.UUID, newStock int, movementType, reference string, referenceID *uuid.UUID, userID uuid.UUID, notes, ipAddress, userAgent string) error {
	// Get current sparepart
	sparepart, err := s.sparepartRepo.GetByID(sparepartID)
	if err != nil {
		return err
	}
	
	previousStock := sparepart.Stock
	quantity := newStock - previousStock
	
	// Update stock
	err = s.sparepartRepo.UpdateStock(sparepartID, newStock)
	if err != nil {
		return err
	}
	
	// Create stock movement record
	movement := &model.StockMovement{
		SparepartID:   sparepartID,
		MovementType:  movementType,
		Quantity:      quantity,
		Reference:     reference,
		ReferenceID:   referenceID,
		UserID:        userID,
		Notes:         notes,
		PreviousStock: previousStock,
		NewStock:      newStock,
	}
	movement.ID = uuid.New()
	movement.CreatedAt = time.Now()
	movement.UpdatedAt = time.Now()
	
	err = s.stockMovementRepo.Create(movement)
	if err != nil {
		return err
	}
	
	// Log activity
	s.logActivity(userID, "UPDATE", "sparepart", &sparepartID, ipAddress, userAgent, 
		fmt.Sprintf("Stock updated for %s from %d to %d", sparepart.Name, previousStock, newStock), 
		fmt.Sprintf(`{"stock": %d}`, previousStock), 
		fmt.Sprintf(`{"stock": %d}`, newStock))
	
	return nil
}

func (s *SparepartService) UpdateSparepart(sparepart *model.Sparepart, userID uuid.UUID, ipAddress, userAgent string) error {
	// Get old values for logging
	oldSparepart, err := s.sparepartRepo.GetByID(sparepart.ID)
	if err != nil {
		return err
	}
	
	sparepart.UpdatedAt = time.Now()
	
	// Recalculate sale price if markup changed
	if sparepart.MarkupPercent > 0 {
		sparepart.SalePrice = sparepart.CostPrice * (1 + sparepart.MarkupPercent/100)
	}
	
	err = s.sparepartRepo.Update(sparepart)
	if err != nil {
		return err
	}
	
	// Log activity
	oldValues, _ := json.Marshal(oldSparepart)
	newValues, _ := json.Marshal(sparepart)
	s.logActivity(userID, "UPDATE", "sparepart", &sparepart.ID, ipAddress, userAgent, 
		fmt.Sprintf("Updated sparepart: %s", sparepart.Name), string(oldValues), string(newValues))
	
	return nil
}

func (s *SparepartService) DeleteSparepart(id uuid.UUID, userID uuid.UUID, ipAddress, userAgent string) error {
	// Get sparepart for logging
	sparepart, err := s.sparepartRepo.GetByID(id)
	if err != nil {
		return err
	}
	
	err = s.sparepartRepo.Delete(id)
	if err != nil {
		return err
	}
	
	// Log activity
	oldValues, _ := json.Marshal(sparepart)
	s.logActivity(userID, "DELETE", "sparepart", &id, ipAddress, userAgent, 
		fmt.Sprintf("Deleted sparepart: %s", sparepart.Name), string(oldValues), "")
	
	return nil
}

func (s *SparepartService) GetStockMovements(sparepartID uuid.UUID, page, limit int) ([]model.StockMovement, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}
	
	return s.stockMovementRepo.GetBySparepartID(sparepartID, page, limit)
}

func (s *SparepartService) logActivity(userID uuid.UUID, action, entityType string, entityID *uuid.UUID, ipAddress, userAgent, description, oldValues string, newValues interface{}) {
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