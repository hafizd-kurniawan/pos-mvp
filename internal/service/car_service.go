package service

import (
	"fmt"

	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/hafizd-kurniawan/pos-mvp/internal/repository"
)

type CarService interface {
	CreateCar(req CreateCarRequest) (*model.Car, error)
	GetCarByID(id uuid.UUID) (*model.Car, error)
	GetAllCars(page, limit int) ([]model.Car, int, error)
	UpdateCar(id uuid.UUID, req UpdateCarRequest) (*model.Car, error)
	DeleteCar(id uuid.UUID) error
	SoftDeleteCar(id uuid.UUID) error
	GetCarsByStatus(status string, page, limit int) ([]model.Car, int, error)
	SearchCars(query string, page, limit int) ([]model.Car, int, error)
}

type carService struct {
	carRepo repository.CarRepository
}

func NewCarService(carRepo repository.CarRepository) CarService {
	return &carService{
		carRepo: carRepo,
	}
}

func (s *carService) CreateCar(req CreateCarRequest) (*model.Car, error) {
	car := &model.Car{
		Brand:       req.Brand,
		Model:       req.Model,
		Year:        req.Year,
		Color:       req.Color,
		Price:       req.Price,
		Mileage:     req.Mileage,
		VIN:         req.VIN,
		Status:      req.Status,
		Description: req.Description,
	}

	// Set default status if not provided
	if car.Status == "" {
		car.Status = "available"
	}

	err := s.carRepo.Create(car)
	if err != nil {
		return nil, fmt.Errorf("failed to create car: %w", err)
	}

	return car, nil
}

func (s *carService) GetCarByID(id uuid.UUID) (*model.Car, error) {
	car, err := s.carRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get car: %w", err)
	}
	return car, nil
}

func (s *carService) GetAllCars(page, limit int) ([]model.Car, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}

	offset := (page - 1) * limit

	cars, err := s.carRepo.GetAll(limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get cars: %w", err)
	}

	total, err := s.carRepo.Count()
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count cars: %w", err)
	}

	return cars, total, nil
}

func (s *carService) UpdateCar(id uuid.UUID, req UpdateCarRequest) (*model.Car, error) {
	// Get existing car
	existingCar, err := s.carRepo.GetByID(id)
	if err != nil {
		return nil, fmt.Errorf("failed to get existing car: %w", err)
	}

	// Update only provided fields
	if req.Brand != "" {
		existingCar.Brand = req.Brand
	}
	if req.Model != "" {
		existingCar.Model = req.Model
	}
	if req.Year != 0 {
		existingCar.Year = req.Year
	}
	if req.Color != "" {
		existingCar.Color = req.Color
	}
	if req.Price != 0 {
		existingCar.Price = req.Price
	}
	if req.Mileage != 0 {
		existingCar.Mileage = req.Mileage
	}
	if req.VIN != "" {
		existingCar.VIN = req.VIN
	}
	if req.Status != "" {
		existingCar.Status = req.Status
	}
	if req.Description != "" {
		existingCar.Description = req.Description
	}

	err = s.carRepo.Update(existingCar)
	if err != nil {
		return nil, fmt.Errorf("failed to update car: %w", err)
	}

	return existingCar, nil
}

func (s *carService) DeleteCar(id uuid.UUID) error {
	err := s.carRepo.Delete(id)
	if err != nil {
		return fmt.Errorf("failed to delete car: %w", err)
	}
	return nil
}

func (s *carService) SoftDeleteCar(id uuid.UUID) error {
	err := s.carRepo.SoftDelete(id)
	if err != nil {
		return fmt.Errorf("failed to soft delete car: %w", err)
	}
	return nil
}

func (s *carService) GetCarsByStatus(status string, page, limit int) ([]model.Car, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}

	offset := (page - 1) * limit

	cars, err := s.carRepo.GetByStatus(status, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get cars by status: %w", err)
	}

	total, err := s.carRepo.Count()
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count cars: %w", err)
	}

	return cars, total, nil
}

func (s *carService) SearchCars(query string, page, limit int) ([]model.Car, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}

	offset := (page - 1) * limit

	cars, err := s.carRepo.Search(query, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to search cars: %w", err)
	}

	total, err := s.carRepo.Count()
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count cars: %w", err)
	}

	return cars, total, nil
}