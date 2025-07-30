package service

import (
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/hafizd-kurniawan/pos-mvp/internal/repository"
)

type TransactionService interface {
	CreateTransaction(req CreateTransactionRequest) (*model.Transaction, *model.Receipt, error)
	GetTransactionByID(id uuid.UUID) (*model.Transaction, error)
	GetAllTransactions(page, limit int) ([]model.Transaction, int, error)
	UpdateTransaction(id uuid.UUID, req CreateTransactionRequest) (*model.Transaction, error)
	DeleteTransaction(id uuid.UUID) error
	SoftDeleteTransaction(id uuid.UUID) error
	GetTransactionsByCustomer(customerID uuid.UUID, page, limit int) ([]model.Transaction, int, error)
	GetTransactionsByDateRange(startDate, endDate time.Time, page, limit int) ([]model.Transaction, int, error)
	CompleteTransaction(id uuid.UUID) (*model.Transaction, *model.Receipt, error)
}

type transactionService struct {
	transactionRepo repository.TransactionRepository
	carRepo         repository.CarRepository
	customerRepo    repository.CustomerRepository
	receiptRepo     repository.ReceiptRepository
}

func NewTransactionService(
	transactionRepo repository.TransactionRepository,
	carRepo repository.CarRepository,
	customerRepo repository.CustomerRepository,
	receiptRepo repository.ReceiptRepository,
) TransactionService {
	return &transactionService{
		transactionRepo: transactionRepo,
		carRepo:         carRepo,
		customerRepo:    customerRepo,
		receiptRepo:     receiptRepo,
	}
}

func (s *transactionService) CreateTransaction(req CreateTransactionRequest) (*model.Transaction, *model.Receipt, error) {
	// Verify customer exists
	customer, err := s.customerRepo.GetByID(req.CustomerID)
	if err != nil {
		return nil, nil, fmt.Errorf("customer not found: %w", err)
	}

	// Verify car exists and is available
	car, err := s.carRepo.GetByID(req.CarID)
	if err != nil {
		return nil, nil, fmt.Errorf("car not found: %w", err)
	}

	if car.Status != "available" {
		return nil, nil, fmt.Errorf("car is not available for sale")
	}

	// Calculate total amount
	totalAmount := req.SalePrice - req.DiscountAmount + req.TaxAmount

	transaction := &model.Transaction{
		CustomerID:      req.CustomerID,
		CarID:           req.CarID,
		SalePrice:       req.SalePrice,
		DiscountAmount:  req.DiscountAmount,
		TaxAmount:       req.TaxAmount,
		TotalAmount:     totalAmount,
		PaymentMethod:   req.PaymentMethod,
		TransactionDate: time.Now(),
		SalesPersonID:   req.SalesPersonID,
		Notes:           req.Notes,
		Status:          "pending",
	}

	err = s.transactionRepo.Create(transaction)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to create transaction: %w", err)
	}

	// Generate receipt
	receipt, err := s.generateReceipt(transaction, customer, car)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to generate receipt: %w", err)
	}

	return transaction, receipt, nil
}

func (s *transactionService) GetTransactionByID(id uuid.UUID) (*model.Transaction, error) {
	transaction, err := s.transactionRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get transaction: %w", err)
	}
	return transaction, nil
}

func (s *transactionService) GetAllTransactions(page, limit int) ([]model.Transaction, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}

	offset := (page - 1) * limit

	transactions, err := s.transactionRepo.GetAll(limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get transactions: %w", err)
	}

	total, err := s.transactionRepo.Count()
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count transactions: %w", err)
	}

	return transactions, total, nil
}

func (s *transactionService) UpdateTransaction(id uuid.UUID, req CreateTransactionRequest) (*model.Transaction, error) {
	// Get existing transaction
	existingTransaction, err := s.transactionRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get existing transaction: %w", err)
	}

	// Update transaction details
	existingTransaction.CustomerID = req.CustomerID
	existingTransaction.CarID = req.CarID
	existingTransaction.SalePrice = req.SalePrice
	existingTransaction.DiscountAmount = req.DiscountAmount
	existingTransaction.TaxAmount = req.TaxAmount
	existingTransaction.TotalAmount = req.SalePrice - req.DiscountAmount + req.TaxAmount
	existingTransaction.PaymentMethod = req.PaymentMethod
	existingTransaction.SalesPersonID = req.SalesPersonID
	existingTransaction.Notes = req.Notes

	err = s.transactionRepo.Update(existingTransaction)
	if err != nil {
		return nil, fmt.Errorf("failed to update transaction: %w", err)
	}

	return existingTransaction, nil
}

func (s *transactionService) DeleteTransaction(id uuid.UUID) error {
	err := s.transactionRepo.Delete(id)
	if err != nil {
		return fmt.Errorf("failed to delete transaction: %w", err)
	}
	return nil
}

func (s *transactionService) SoftDeleteTransaction(id uuid.UUID) error {
	err := s.transactionRepo.SoftDelete(id)
	if err != nil {
		return fmt.Errorf("failed to soft delete transaction: %w", err)
	}
	return nil
}

func (s *transactionService) GetTransactionsByCustomer(customerID uuid.UUID, page, limit int) ([]model.Transaction, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}

	offset := (page - 1) * limit

	transactions, err := s.transactionRepo.GetByCustomerID(customerID, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get transactions by customer: %w", err)
	}

	total, err := s.transactionRepo.Count()
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count transactions: %w", err)
	}

	return transactions, total, nil
}

func (s *transactionService) GetTransactionsByDateRange(startDate, endDate time.Time, page, limit int) ([]model.Transaction, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}

	offset := (page - 1) * limit

	transactions, err := s.transactionRepo.GetByDateRange(startDate, endDate, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get transactions by date range: %w", err)
	}

	total, err := s.transactionRepo.Count()
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count transactions: %w", err)
	}

	return transactions, total, nil
}

func (s *transactionService) CompleteTransaction(id uuid.UUID) (*model.Transaction, *model.Receipt, error) {
	// Get transaction
	transaction, err := s.transactionRepo.GetByID(id)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to get transaction: %w", err)
	}

	if transaction.Status == "completed" {
		return nil, nil, fmt.Errorf("transaction is already completed")
	}

	// Update transaction status
	transaction.Status = "completed"
	err = s.transactionRepo.Update(transaction)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to update transaction status: %w", err)
	}

	// Update car status to sold
	car, err := s.carRepo.GetByID(transaction.CarID)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to get car: %w", err)
	}

	car.Status = "sold"
	err = s.carRepo.Update(car)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to update car status: %w", err)
	}

	// Get receipt
	receipt, err := s.receiptRepo.GetByTransactionID(transaction.ID)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to get receipt: %w", err)
	}

	return transaction, receipt, nil
}

func (s *transactionService) generateReceipt(transaction *model.Transaction, customer *model.Customer, car *model.Car) (*model.Receipt, error) {
	// Generate receipt number
	receiptNumber := fmt.Sprintf("RCP-%s", transaction.ID.String()[:8])

	receipt := &model.Receipt{
		TransactionID:  transaction.ID,
		ReceiptNumber:  receiptNumber,
		IssueDate:      time.Now(),
		CustomerName:   fmt.Sprintf("%s %s", customer.FirstName, customer.LastName),
		CustomerEmail:  customer.Email,
		CustomerPhone:  customer.Phone,
		CarBrand:       car.Brand,
		CarModel:       car.Model,
		CarYear:        car.Year,
		CarVIN:         car.VIN,
		SalePrice:      transaction.SalePrice,
		DiscountAmount: transaction.DiscountAmount,
		TaxAmount:      transaction.TaxAmount,
		TotalAmount:    transaction.TotalAmount,
		PaymentMethod:  transaction.PaymentMethod,
	}

	err := s.receiptRepo.Create(receipt)
	if err != nil {
		return nil, fmt.Errorf("failed to create receipt: %w", err)
	}

	return receipt, nil
}