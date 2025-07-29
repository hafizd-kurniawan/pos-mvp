package service

import (
	"fmt"

	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/hafizd-kurniawan/pos-mvp/internal/repository"
)

type ReceiptService interface {
	GetReceiptByID(id uuid.UUID) (*model.Receipt, error)
	GetAllReceipts(page, limit int) ([]model.Receipt, int, error)
	GetReceiptByTransactionID(transactionID uuid.UUID) (*model.Receipt, error)
	GetReceiptByNumber(receiptNumber string) (*model.Receipt, error)
	SearchReceipts(query string, page, limit int) ([]model.Receipt, int, error)
	DeleteReceipt(id uuid.UUID) error
	SoftDeleteReceipt(id uuid.UUID) error
}

type receiptService struct {
	receiptRepo repository.ReceiptRepository
}

func NewReceiptService(receiptRepo repository.ReceiptRepository) ReceiptService {
	return &receiptService{
		receiptRepo: receiptRepo,
	}
}

func (s *receiptService) GetReceiptByID(id uuid.UUID) (*model.Receipt, error) {
	receipt, err := s.receiptRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get receipt: %w", err)
	}
	return receipt, nil
}

func (s *receiptService) GetAllReceipts(page, limit int) ([]model.Receipt, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}

	offset := (page - 1) * limit

	receipts, err := s.receiptRepo.GetAll(limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get receipts: %w", err)
	}

	total, err := s.receiptRepo.Count()
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count receipts: %w", err)
	}

	return receipts, total, nil
}

func (s *receiptService) GetReceiptByTransactionID(transactionID uuid.UUID) (*model.Receipt, error) {
	receipt, err := s.receiptRepo.GetByTransactionID(transactionID)
	if err != nil {
		return nil, fmt.Errorf("failed to get receipt by transaction ID: %w", err)
	}
	return receipt, nil
}

func (s *receiptService) GetReceiptByNumber(receiptNumber string) (*model.Receipt, error) {
	receipt, err := s.receiptRepo.GetByReceiptNumber(receiptNumber)
	if err != nil {
		return nil, fmt.Errorf("failed to get receipt by number: %w", err)
	}
	return receipt, nil
}

func (s *receiptService) SearchReceipts(query string, page, limit int) ([]model.Receipt, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}

	offset := (page - 1) * limit

	receipts, err := s.receiptRepo.Search(query, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to search receipts: %w", err)
	}

	total, err := s.receiptRepo.Count()
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count receipts: %w", err)
	}

	return receipts, total, nil
}

func (s *receiptService) DeleteReceipt(id uuid.UUID) error {
	err := s.receiptRepo.Delete(id)
	if err != nil {
		return fmt.Errorf("failed to delete receipt: %w", err)
	}
	return nil
}

func (s *receiptService) SoftDeleteReceipt(id uuid.UUID) error {
	err := s.receiptRepo.SoftDelete(id)
	if err != nil {
		return fmt.Errorf("failed to soft delete receipt: %w", err)
	}
	return nil
}