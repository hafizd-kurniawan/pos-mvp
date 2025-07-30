package service

import (
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/hafizd-kurniawan/pos-mvp/internal/repository"
)

type CustomerService interface {
	CreateCustomer(req CreateCustomerRequest) (*model.Customer, error)
	GetCustomerByID(id uuid.UUID) (*model.Customer, error)
	GetAllCustomers(page, limit int) ([]model.Customer, int, error)
	UpdateCustomer(id uuid.UUID, req UpdateCustomerRequest) (*model.Customer, error)
	DeleteCustomer(id uuid.UUID) error
	SoftDeleteCustomer(id uuid.UUID) error
	GetCustomerByEmail(email string) (*model.Customer, error)
	SearchCustomers(query string, page, limit int) ([]model.Customer, int, error)
}

type customerService struct {
	customerRepo repository.CustomerRepository
}

func NewCustomerService(customerRepo repository.CustomerRepository) CustomerService {
	return &customerService{
		customerRepo: customerRepo,
	}
}

func (s *customerService) CreateCustomer(req CreateCustomerRequest) (*model.Customer, error) {
	customer := &model.Customer{
		FirstName: req.FirstName,
		LastName:  req.LastName,
		Email:     req.Email,
		Phone:     req.Phone,
		Address:   req.Address,
		City:      req.City,
		State:     req.State,
		ZipCode:   req.ZipCode,
	}

	// Parse date of birth if provided
	if req.DateOfBirth != "" {
		dob, err := time.Parse("2006-01-02", req.DateOfBirth)
		if err != nil {
			return nil, fmt.Errorf("invalid date of birth format, expected YYYY-MM-DD: %w", err)
		}
		customer.DateOfBirth = &dob
	}

	err := s.customerRepo.Create(customer)
	if err != nil {
		return nil, fmt.Errorf("failed to create customer: %w", err)
	}

	return customer, nil
}

func (s *customerService) GetCustomerByID(id uuid.UUID) (*model.Customer, error) {
	customer, err := s.customerRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get customer: %w", err)
	}
	return customer, nil
}

func (s *customerService) GetAllCustomers(page, limit int) ([]model.Customer, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}

	offset := (page - 1) * limit

	customers, err := s.customerRepo.GetAll(limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get customers: %w", err)
	}

	total, err := s.customerRepo.Count()
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count customers: %w", err)
	}

	return customers, total, nil
}

func (s *customerService) UpdateCustomer(id uuid.UUID, req UpdateCustomerRequest) (*model.Customer, error) {
	// Get existing customer
	existingCustomer, err := s.customerRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get existing customer: %w", err)
	}

	// Update only provided fields
	if req.FirstName != "" {
		existingCustomer.FirstName = req.FirstName
	}
	if req.LastName != "" {
		existingCustomer.LastName = req.LastName
	}
	if req.Email != "" {
		existingCustomer.Email = req.Email
	}
	if req.Phone != "" {
		existingCustomer.Phone = req.Phone
	}
	if req.Address != "" {
		existingCustomer.Address = req.Address
	}
	if req.City != "" {
		existingCustomer.City = req.City
	}
	if req.State != "" {
		existingCustomer.State = req.State
	}
	if req.ZipCode != "" {
		existingCustomer.ZipCode = req.ZipCode
	}

	// Parse date of birth if provided
	if req.DateOfBirth != "" {
		dob, err := time.Parse("2006-01-02", req.DateOfBirth)
		if err != nil {
			return nil, fmt.Errorf("invalid date of birth format, expected YYYY-MM-DD: %w", err)
		}
		existingCustomer.DateOfBirth = &dob
	}

	err = s.customerRepo.Update(existingCustomer)
	if err != nil {
		return nil, fmt.Errorf("failed to update customer: %w", err)
	}

	return existingCustomer, nil
}

func (s *customerService) DeleteCustomer(id uuid.UUID) error {
	err := s.customerRepo.Delete(id)
	if err != nil {
		return fmt.Errorf("failed to delete customer: %w", err)
	}
	return nil
}

func (s *customerService) SoftDeleteCustomer(id uuid.UUID) error {
	err := s.customerRepo.SoftDelete(id)
	if err != nil {
		return fmt.Errorf("failed to soft delete customer: %w", err)
	}
	return nil
}

func (s *customerService) GetCustomerByEmail(email string) (*model.Customer, error) {
	customer, err := s.customerRepo.GetByEmail(email)
	if err != nil {
		return nil, fmt.Errorf("failed to get customer by email: %w", err)
	}
	return customer, nil
}

func (s *customerService) SearchCustomers(query string, page, limit int) ([]model.Customer, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}

	offset := (page - 1) * limit

	customers, err := s.customerRepo.Search(query, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to search customers: %w", err)
	}

	total, err := s.customerRepo.Count()
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count customers: %w", err)
	}

	return customers, total, nil
}