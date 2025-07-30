package service

import (
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/hafizd-kurniawan/pos-mvp/internal/repository"
)

type InvoiceService interface {
	CreateInvoice(invoice *model.Invoice) (*model.Invoice, error)
	GetInvoiceByID(id uuid.UUID) (*model.Invoice, error)
	GetInvoiceByNumber(invoiceNumber string) (*model.Invoice, error)
	GetAllInvoices(page, limit int) ([]model.Invoice, *PaginationInfo, error)
	UpdateInvoice(invoice *model.Invoice) (*model.Invoice, error)
	DeleteInvoice(id uuid.UUID) error
	GetInvoicesByCustomerID(customerID uuid.UUID, page, limit int) ([]model.Invoice, *PaginationInfo, error)
	GetInvoicesByType(invoiceType string, page, limit int) ([]model.Invoice, *PaginationInfo, error)
	GetInvoicesByDateRange(startDate, endDate time.Time, page, limit int) ([]model.Invoice, *PaginationInfo, error)
	CreatePurchaseInvoice(customerID, carID *uuid.UUID, amount float64, paymentMethod, notes string, createdBy uuid.UUID) (*model.Invoice, error)
	CreateSalesInvoice(customerID, carID *uuid.UUID, amount, discountAmount float64, paymentMethod, notes string, createdBy uuid.UUID) (*model.Invoice, error)
	MarkAsPaid(id uuid.UUID, paymentProof string) (*model.Invoice, error)
}

type invoiceService struct {
	invoiceRepo repository.InvoiceRepository
}

func NewInvoiceService(invoiceRepo repository.InvoiceRepository) InvoiceService {
	return &invoiceService{
		invoiceRepo: invoiceRepo,
	}
}

func (s *invoiceService) CreateInvoice(invoice *model.Invoice) (*model.Invoice, error) {
	if invoice.ID == uuid.Nil {
		invoice.ID = uuid.New()
	}
	
	// Generate invoice number if not provided
	if invoice.InvoiceNumber == "" {
		invoiceNumber, err := s.invoiceRepo.GenerateInvoiceNumber(invoice.InvoiceType)
		if err != nil {
			return nil, fmt.Errorf("failed to generate invoice number: %w", err)
		}
		invoice.InvoiceNumber = invoiceNumber
	}
	
	// Set default status if not provided
	if invoice.Status == "" {
		invoice.Status = "draft"
	}
	
	err := s.invoiceRepo.Create(invoice)
	if err != nil {
		return nil, fmt.Errorf("failed to create invoice: %w", err)
	}
	
	return invoice, nil
}

func (s *invoiceService) GetInvoiceByID(id uuid.UUID) (*model.Invoice, error) {
	invoice, err := s.invoiceRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get invoice: %w", err)
	}
	
	if invoice == nil {
		return nil, fmt.Errorf("invoice not found")
	}
	
	return invoice, nil
}

func (s *invoiceService) GetInvoiceByNumber(invoiceNumber string) (*model.Invoice, error) {
	invoice, err := s.invoiceRepo.GetByNumber(invoiceNumber)
	if err != nil {
		return nil, fmt.Errorf("failed to get invoice: %w", err)
	}
	
	if invoice == nil {
		return nil, fmt.Errorf("invoice not found")
	}
	
	return invoice, nil
}

func (s *invoiceService) GetAllInvoices(page, limit int) ([]model.Invoice, *PaginationInfo, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}
	
	offset := (page - 1) * limit
	
	invoices, err := s.invoiceRepo.GetAll(limit, offset)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to get invoices: %w", err)
	}
	
	totalCount, err := s.invoiceRepo.Count()
	if err != nil {
		return nil, nil, fmt.Errorf("failed to count invoices: %w", err)
	}
	
	meta := &PaginationInfo{
		Page:       page,
		Limit:      limit,
		Total:      totalCount,
		TotalPages: (totalCount + limit - 1) / limit,
		HasNext:    page < (totalCount+limit-1)/limit,
		HasPrev:    page > 1,
	}
	
	return invoices, meta, nil
}

func (s *invoiceService) UpdateInvoice(invoice *model.Invoice) (*model.Invoice, error) {
	existingInvoice, err := s.invoiceRepo.GetByID(invoice.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to get invoice: %w", err)
	}
	
	if existingInvoice == nil {
		return nil, fmt.Errorf("invoice not found")
	}
	
	err = s.invoiceRepo.Update(invoice)
	if err != nil {
		return nil, fmt.Errorf("failed to update invoice: %w", err)
	}
	
	return invoice, nil
}

func (s *invoiceService) DeleteInvoice(id uuid.UUID) error {
	existingInvoice, err := s.invoiceRepo.GetByID(id)
	if err != nil {
		return fmt.Errorf("failed to get invoice: %w", err)
	}
	
	if existingInvoice == nil {
		return fmt.Errorf("invoice not found")
	}
	
	err = s.invoiceRepo.Delete(id)
	if err != nil {
		return fmt.Errorf("failed to delete invoice: %w", err)
	}
	
	return nil
}

func (s *invoiceService) GetInvoicesByCustomerID(customerID uuid.UUID, page, limit int) ([]model.Invoice, *PaginationInfo, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}
	
	offset := (page - 1) * limit
	
	invoices, err := s.invoiceRepo.GetByCustomerID(customerID, limit, offset)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to get customer invoices: %w", err)
	}
	
	// Note: For simplicity, using total count. In production, you'd want customer-specific count
	totalCount, err := s.invoiceRepo.Count()
	if err != nil {
		return nil, nil, fmt.Errorf("failed to count invoices: %w", err)
	}
	
	meta := &PaginationInfo{
		Page:       page,
		Limit:      limit,
		Total:      totalCount,
		TotalPages: (totalCount + limit - 1) / limit,
		HasNext:    page < (totalCount+limit-1)/limit,
		HasPrev:    page > 1,
	}
	
	return invoices, meta, nil
}

func (s *invoiceService) GetInvoicesByType(invoiceType string, page, limit int) ([]model.Invoice, *PaginationInfo, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}
	
	offset := (page - 1) * limit
	
	invoices, err := s.invoiceRepo.GetByType(invoiceType, limit, offset)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to get invoices by type: %w", err)
	}
	
	// Note: For simplicity, using total count. In production, you'd want type-specific count
	totalCount, err := s.invoiceRepo.Count()
	if err != nil {
		return nil, nil, fmt.Errorf("failed to count invoices: %w", err)
	}
	
	meta := &PaginationInfo{
		Page:       page,
		Limit:      limit,
		Total:      totalCount,
		TotalPages: (totalCount + limit - 1) / limit,
		HasNext:    page < (totalCount+limit-1)/limit,
		HasPrev:    page > 1,
	}
	
	return invoices, meta, nil
}

func (s *invoiceService) GetInvoicesByDateRange(startDate, endDate time.Time, page, limit int) ([]model.Invoice, *PaginationInfo, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}
	
	offset := (page - 1) * limit
	
	invoices, err := s.invoiceRepo.GetByDateRange(startDate, endDate, limit, offset)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to get invoices by date range: %w", err)
	}
	
	// Note: For simplicity, using total count. In production, you'd want date range-specific count
	totalCount, err := s.invoiceRepo.Count()
	if err != nil {
		return nil, nil, fmt.Errorf("failed to count invoices: %w", err)
	}
	
	meta := &PaginationInfo{
		Page:       page,
		Limit:      limit,
		Total:      totalCount,
		TotalPages: (totalCount + limit - 1) / limit,
		HasNext:    page < (totalCount+limit-1)/limit,
		HasPrev:    page > 1,
	}
	
	return invoices, meta, nil
}

func (s *invoiceService) CreatePurchaseInvoice(customerID, carID *uuid.UUID, amount float64, paymentMethod, notes string, createdBy uuid.UUID) (*model.Invoice, error) {
	invoice := &model.Invoice{
		InvoiceType:   "purchase",
		CustomerID:    customerID,
		CarID:         carID,
		Amount:        amount,
		TotalAmount:   amount, // No tax/discount for purchase
		PaymentMethod: paymentMethod,
		Status:        "draft",
		Notes:         notes,
		CreatedBy:     createdBy,
	}
	
	return s.CreateInvoice(invoice)
}

func (s *invoiceService) CreateSalesInvoice(customerID, carID *uuid.UUID, amount, discountAmount float64, paymentMethod, notes string, createdBy uuid.UUID) (*model.Invoice, error) {
	totalAmount := amount - discountAmount
	
	invoice := &model.Invoice{
		InvoiceType:    "sale",
		CustomerID:     customerID,
		CarID:          carID,
		Amount:         amount,
		DiscountAmount: discountAmount,
		TotalAmount:    totalAmount,
		PaymentMethod:  paymentMethod,
		Status:         "draft",
		Notes:          notes,
		CreatedBy:      createdBy,
	}
	
	return s.CreateInvoice(invoice)
}

func (s *invoiceService) MarkAsPaid(id uuid.UUID, paymentProof string) (*model.Invoice, error) {
	invoice, err := s.invoiceRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get invoice: %w", err)
	}
	
	if invoice == nil {
		return nil, fmt.Errorf("invoice not found")
	}
	
	now := time.Now()
	invoice.Status = "paid"
	invoice.PaidDate = &now
	if paymentProof != "" {
		invoice.PaymentProof = paymentProof
	}
	
	err = s.invoiceRepo.Update(invoice)
	if err != nil {
		return nil, fmt.Errorf("failed to update invoice: %w", err)
	}
	
	return invoice, nil
}