package service

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/hafizd-kurniawan/pos-mvp/internal/repository"
)

type UserService interface {
	CreateUser(user *model.User) error
	GetUserByID(id uuid.UUID) (*model.User, error)
	GetUserByUsername(username string) (*model.User, error)
	GetUserByEmail(email string) (*model.User, error)
	GetAllUsers(page, limit int) ([]*model.User, *PaginationInfo, error)
	UpdateUser(user *model.User) error
	DeleteUser(id uuid.UUID) error
	SearchUsers(query string, page, limit int) ([]*model.User, *PaginationInfo, error)
	GetUsersByRole(role string, page, limit int) ([]*model.User, *PaginationInfo, error)
	UpdateLastLogin(id uuid.UUID) error
}

type userService struct {
	userRepo repository.UserRepository
}

func NewUserService(userRepo repository.UserRepository) UserService {
	return &userService{
		userRepo: userRepo,
	}
}

func (s *userService) CreateUser(user *model.User) error {
	// Validate required fields
	if user.Username == "" {
		return errors.New("username is required")
	}
	if user.Email == "" {
		return errors.New("email is required")
	}
	if user.FirstName == "" {
		return errors.New("first name is required")
	}
	if user.LastName == "" {
		return errors.New("last name is required")
	}

	// Validate role
	validRoles := map[string]bool{
		"admin":       true,
		"manager":     true,
		"salesperson": true,
	}
	if !validRoles[user.Role] {
		return errors.New("invalid role. Must be one of: admin, manager, salesperson")
	}

	// Check if username already exists
	existingUser, _ := s.userRepo.GetByUsername(user.Username)
	if existingUser != nil {
		return errors.New("username already exists")
	}

	// Check if email already exists
	existingUser, _ = s.userRepo.GetByEmail(user.Email)
	if existingUser != nil {
		return errors.New("email already exists")
	}

	// Set default values
	if user.Role == "" {
		user.Role = "salesperson"
	}
	user.IsActive = true

	return s.userRepo.Create(user)
}

func (s *userService) GetUserByID(id uuid.UUID) (*model.User, error) {
	return s.userRepo.GetByID(id)
}

func (s *userService) GetUserByUsername(username string) (*model.User, error) {
	if username == "" {
		return nil, errors.New("username is required")
	}
	return s.userRepo.GetByUsername(username)
}

func (s *userService) GetUserByEmail(email string) (*model.User, error) {
	if email == "" {
		return nil, errors.New("email is required")
	}
	return s.userRepo.GetByEmail(email)
}

func (s *userService) GetAllUsers(page, limit int) ([]*model.User, *PaginationInfo, error) {
	// Set default pagination values
	if page <= 0 {
		page = 1
	}
	if limit <= 0 || limit > 100 {
		limit = 10
	}

	users, total, err := s.userRepo.GetAll(page, limit)
	if err != nil {
		return nil, nil, err
	}

	pagination := CalculatePagination(page, limit, total)
	return users, pagination, nil
}

func (s *userService) UpdateUser(user *model.User) error {
	// Validate required fields
	if user.Username == "" {
		return errors.New("username is required")
	}
	if user.Email == "" {
		return errors.New("email is required")
	}
	if user.FirstName == "" {
		return errors.New("first name is required")
	}
	if user.LastName == "" {
		return errors.New("last name is required")
	}

	// Validate role
	validRoles := map[string]bool{
		"admin":       true,
		"manager":     true,
		"salesperson": true,
	}
	if !validRoles[user.Role] {
		return errors.New("invalid role. Must be one of: admin, manager, salesperson")
	}

	// Check if user exists
	existingUser, err := s.userRepo.GetByID(user.ID)
	if err != nil {
		return errors.New("user not found")
	}

	// Check if username is being changed and if it conflicts with another user
	if existingUser.Username != user.Username {
		existingUserByUsername, _ := s.userRepo.GetByUsername(user.Username)
		if existingUserByUsername != nil && existingUserByUsername.ID != user.ID {
			return errors.New("username already exists")
		}
	}

	// Check if email is being changed and if it conflicts with another user
	if existingUser.Email != user.Email {
		existingUserByEmail, _ := s.userRepo.GetByEmail(user.Email)
		if existingUserByEmail != nil && existingUserByEmail.ID != user.ID {
			return errors.New("email already exists")
		}
	}

	return s.userRepo.Update(user)
}

func (s *userService) DeleteUser(id uuid.UUID) error {
	// Check if user exists
	_, err := s.userRepo.GetByID(id)
	if err != nil {
		return errors.New("user not found")
	}

	return s.userRepo.Delete(id)
}

func (s *userService) SearchUsers(query string, page, limit int) ([]*model.User, *PaginationInfo, error) {
	if query == "" {
		return s.GetAllUsers(page, limit)
	}

	// Set default pagination values
	if page <= 0 {
		page = 1
	}
	if limit <= 0 || limit > 100 {
		limit = 10
	}

	users, total, err := s.userRepo.Search(query, page, limit)
	if err != nil {
		return nil, nil, err
	}

	pagination := CalculatePagination(page, limit, total)
	return users, pagination, nil
}

func (s *userService) GetUsersByRole(role string, page, limit int) ([]*model.User, *PaginationInfo, error) {
	// Validate role
	validRoles := map[string]bool{
		"admin":       true,
		"manager":     true,
		"salesperson": true,
	}
	if !validRoles[role] {
		return nil, nil, errors.New("invalid role. Must be one of: admin, manager, salesperson")
	}

	// Set default pagination values
	if page <= 0 {
		page = 1
	}
	if limit <= 0 || limit > 100 {
		limit = 10
	}

	users, total, err := s.userRepo.GetByRole(role, page, limit)
	if err != nil {
		return nil, nil, err
	}

	pagination := CalculatePagination(page, limit, total)
	return users, pagination, nil
}

func (s *userService) UpdateLastLogin(id uuid.UUID) error {
	user, err := s.userRepo.GetByID(id)
	if err != nil {
		return errors.New("user not found")
	}

	now := time.Now()
	user.LastLoginAt = &now
	
	return s.userRepo.Update(user)
}