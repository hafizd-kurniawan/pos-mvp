package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/service"
)

type CustomerHandler struct {
	customerService service.CustomerService
}

func NewCustomerHandler(customerService service.CustomerService) *CustomerHandler {
	return &CustomerHandler{
		customerService: customerService,
	}
}

// CreateCustomer godoc
// @Summary Create a new customer
// @Description Create a new customer record
// @Tags customers
// @Accept json
// @Produce json
// @Param customer body service.CreateCustomerRequest true "Customer data"
// @Success 201 {object} service.APIResponse
// @Failure 400 {object} service.APIResponse
// @Failure 500 {object} service.APIResponse
// @Router /api/customers [post]
func (h *CustomerHandler) CreateCustomer(c *gin.Context) {
	var req service.CreateCustomerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid request data", err.Error()))
		return
	}

	customer, err := h.customerService.CreateCustomer(req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, service.ErrorResponse("Failed to create customer", err.Error()))
		return
	}

	c.JSON(http.StatusCreated, service.SuccessResponse("Customer created successfully", customer))
}

// GetCustomer godoc
// @Summary Get customer by ID
// @Description Get a customer by their ID
// @Tags customers
// @Accept json
// @Produce json
// @Param id path string true "Customer ID"
// @Success 200 {object} service.APIResponse
// @Failure 400 {object} service.APIResponse
// @Failure 404 {object} service.APIResponse
// @Router /api/customers/{id} [get]
func (h *CustomerHandler) GetCustomer(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid customer ID", err.Error()))
		return
	}

	customer, err := h.customerService.GetCustomerByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, service.ErrorResponse("Customer not found", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.SuccessResponse("Customer retrieved successfully", customer))
}

// GetAllCustomers godoc
// @Summary Get all customers
// @Description Get all customers with pagination
// @Tags customers
// @Accept json
// @Produce json
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} service.PaginatedResponse
// @Failure 500 {object} service.APIResponse
// @Router /api/customers [get]
func (h *CustomerHandler) GetAllCustomers(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	customers, total, err := h.customerService.GetAllCustomers(page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, service.ErrorResponse("Failed to get customers", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.PaginatedSuccessResponse("Customers retrieved successfully", customers, page, limit, total))
}

// UpdateCustomer godoc
// @Summary Update customer
// @Description Update customer information
// @Tags customers
// @Accept json
// @Produce json
// @Param id path string true "Customer ID"
// @Param customer body service.UpdateCustomerRequest true "Customer data"
// @Success 200 {object} service.APIResponse
// @Failure 400 {object} service.APIResponse
// @Failure 404 {object} service.APIResponse
// @Failure 500 {object} service.APIResponse
// @Router /api/customers/{id} [put]
func (h *CustomerHandler) UpdateCustomer(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid customer ID", err.Error()))
		return
	}

	var req service.UpdateCustomerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid request data", err.Error()))
		return
	}

	customer, err := h.customerService.UpdateCustomer(id, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, service.ErrorResponse("Failed to update customer", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.SuccessResponse("Customer updated successfully", customer))
}

// DeleteCustomer godoc
// @Summary Delete customer
// @Description Soft delete a customer
// @Tags customers
// @Accept json
// @Produce json
// @Param id path string true "Customer ID"
// @Success 200 {object} service.APIResponse
// @Failure 400 {object} service.APIResponse
// @Failure 404 {object} service.APIResponse
// @Failure 500 {object} service.APIResponse
// @Router /api/customers/{id} [delete]
func (h *CustomerHandler) DeleteCustomer(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid customer ID", err.Error()))
		return
	}

	err = h.customerService.SoftDeleteCustomer(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, service.ErrorResponse("Failed to delete customer", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.SuccessResponse("Customer deleted successfully", nil))
}

// GetCustomerByEmail godoc
// @Summary Get customer by email
// @Description Get a customer by their email address
// @Tags customers
// @Accept json
// @Produce json
// @Param email query string true "Customer email"
// @Success 200 {object} service.APIResponse
// @Failure 400 {object} service.APIResponse
// @Failure 404 {object} service.APIResponse
// @Router /api/customers/email [get]
func (h *CustomerHandler) GetCustomerByEmail(c *gin.Context) {
	email := c.Query("email")
	if email == "" {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Email parameter is required", ""))
		return
	}

	customer, err := h.customerService.GetCustomerByEmail(email)
	if err != nil {
		c.JSON(http.StatusNotFound, service.ErrorResponse("Customer not found", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.SuccessResponse("Customer retrieved successfully", customer))
}

// SearchCustomers godoc
// @Summary Search customers
// @Description Search customers by name, email, or phone
// @Tags customers
// @Accept json
// @Produce json
// @Param q query string true "Search query"
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} service.PaginatedResponse
// @Failure 400 {object} service.APIResponse
// @Failure 500 {object} service.APIResponse
// @Router /api/customers/search [get]
func (h *CustomerHandler) SearchCustomers(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Search query is required", ""))
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	customers, total, err := h.customerService.SearchCustomers(query, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, service.ErrorResponse("Failed to search customers", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.PaginatedSuccessResponse("Customers retrieved successfully", customers, page, limit, total))
}