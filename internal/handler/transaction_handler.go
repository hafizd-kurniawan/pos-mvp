package handler

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/service"
)

type TransactionHandler struct {
	transactionService service.TransactionService
}

func NewTransactionHandler(transactionService service.TransactionService) *TransactionHandler {
	return &TransactionHandler{
		transactionService: transactionService,
	}
}

// CreateTransaction godoc
// @Summary Create a new transaction
// @Description Create a new sale transaction
// @Tags transactions
// @Accept json
// @Produce json
// @Param transaction body service.CreateTransactionRequest true "Transaction data"
// @Success 201 {object} service.APIResponse
// @Failure 400 {object} service.APIResponse
// @Failure 500 {object} service.APIResponse
// @Router /api/transactions [post]
func (h *TransactionHandler) CreateTransaction(c *gin.Context) {
	var req service.CreateTransactionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid request data", err.Error()))
		return
	}

	transaction, receipt, err := h.transactionService.CreateTransaction(req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, service.ErrorResponse("Failed to create transaction", err.Error()))
		return
	}

	response := map[string]interface{}{
		"transaction": transaction,
		"receipt":     receipt,
	}

	c.JSON(http.StatusCreated, service.SuccessResponse("Transaction created successfully", response))
}

// GetTransaction godoc
// @Summary Get transaction by ID
// @Description Get a transaction by its ID
// @Tags transactions
// @Accept json
// @Produce json
// @Param id path string true "Transaction ID"
// @Success 200 {object} service.APIResponse
// @Failure 400 {object} service.APIResponse
// @Failure 404 {object} service.APIResponse
// @Router /api/transactions/{id} [get]
func (h *TransactionHandler) GetTransaction(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid transaction ID", err.Error()))
		return
	}

	transaction, err := h.transactionService.GetTransactionByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, service.ErrorResponse("Transaction not found", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.SuccessResponse("Transaction retrieved successfully", transaction))
}

// GetAllTransactions godoc
// @Summary Get all transactions
// @Description Get all transactions with pagination
// @Tags transactions
// @Accept json
// @Produce json
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} service.PaginatedResponse
// @Failure 500 {object} service.APIResponse
// @Router /api/transactions [get]
func (h *TransactionHandler) GetAllTransactions(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	transactions, total, err := h.transactionService.GetAllTransactions(page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, service.ErrorResponse("Failed to get transactions", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.PaginatedSuccessResponse("Transactions retrieved successfully", transactions, page, limit, total))
}

// UpdateTransaction godoc
// @Summary Update transaction
// @Description Update transaction information
// @Tags transactions
// @Accept json
// @Produce json
// @Param id path string true "Transaction ID"
// @Param transaction body service.CreateTransactionRequest true "Transaction data"
// @Success 200 {object} service.APIResponse
// @Failure 400 {object} service.APIResponse
// @Failure 404 {object} service.APIResponse
// @Failure 500 {object} service.APIResponse
// @Router /api/transactions/{id} [put]
func (h *TransactionHandler) UpdateTransaction(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid transaction ID", err.Error()))
		return
	}

	var req service.CreateTransactionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid request data", err.Error()))
		return
	}

	transaction, err := h.transactionService.UpdateTransaction(id, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, service.ErrorResponse("Failed to update transaction", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.SuccessResponse("Transaction updated successfully", transaction))
}

// DeleteTransaction godoc
// @Summary Delete transaction
// @Description Soft delete a transaction
// @Tags transactions
// @Accept json
// @Produce json
// @Param id path string true "Transaction ID"
// @Success 200 {object} service.APIResponse
// @Failure 400 {object} service.APIResponse
// @Failure 404 {object} service.APIResponse
// @Failure 500 {object} service.APIResponse
// @Router /api/transactions/{id} [delete]
func (h *TransactionHandler) DeleteTransaction(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid transaction ID", err.Error()))
		return
	}

	err = h.transactionService.SoftDeleteTransaction(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, service.ErrorResponse("Failed to delete transaction", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.SuccessResponse("Transaction deleted successfully", nil))
}

// GetTransactionsByCustomer godoc
// @Summary Get transactions by customer
// @Description Get all transactions for a specific customer
// @Tags transactions
// @Accept json
// @Produce json
// @Param customer_id path string true "Customer ID"
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} service.PaginatedResponse
// @Failure 400 {object} service.APIResponse
// @Failure 500 {object} service.APIResponse
// @Router /api/transactions/customer/{customer_id} [get]
func (h *TransactionHandler) GetTransactionsByCustomer(c *gin.Context) {
	customerIDStr := c.Param("customer_id")
	customerID, err := uuid.Parse(customerIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid customer ID", err.Error()))
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	transactions, total, err := h.transactionService.GetTransactionsByCustomer(customerID, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, service.ErrorResponse("Failed to get transactions", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.PaginatedSuccessResponse("Transactions retrieved successfully", transactions, page, limit, total))
}

// GetTransactionsByDateRange godoc
// @Summary Get transactions by date range
// @Description Get transactions within a specific date range
// @Tags transactions
// @Accept json
// @Produce json
// @Param start_date query string true "Start date (YYYY-MM-DD)"
// @Param end_date query string true "End date (YYYY-MM-DD)"
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} service.PaginatedResponse
// @Failure 400 {object} service.APIResponse
// @Failure 500 {object} service.APIResponse
// @Router /api/transactions/date-range [get]
func (h *TransactionHandler) GetTransactionsByDateRange(c *gin.Context) {
	startDateStr := c.Query("start_date")
	endDateStr := c.Query("end_date")

	if startDateStr == "" || endDateStr == "" {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Start date and end date are required", ""))
		return
	}

	startDate, err := time.Parse("2006-01-02", startDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid start date format, expected YYYY-MM-DD", err.Error()))
		return
	}

	endDate, err := time.Parse("2006-01-02", endDateStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid end date format, expected YYYY-MM-DD", err.Error()))
		return
	}

	// Set end date to end of day
	endDate = endDate.Add(23*time.Hour + 59*time.Minute + 59*time.Second)

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	transactions, total, err := h.transactionService.GetTransactionsByDateRange(startDate, endDate, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, service.ErrorResponse("Failed to get transactions", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.PaginatedSuccessResponse("Transactions retrieved successfully", transactions, page, limit, total))
}

// CompleteTransaction godoc
// @Summary Complete transaction
// @Description Mark a transaction as completed and update car status to sold
// @Tags transactions
// @Accept json
// @Produce json
// @Param id path string true "Transaction ID"
// @Success 200 {object} service.APIResponse
// @Failure 400 {object} service.APIResponse
// @Failure 404 {object} service.APIResponse
// @Failure 500 {object} service.APIResponse
// @Router /api/transactions/{id}/complete [post]
func (h *TransactionHandler) CompleteTransaction(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid transaction ID", err.Error()))
		return
	}

	transaction, receipt, err := h.transactionService.CompleteTransaction(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, service.ErrorResponse("Failed to complete transaction", err.Error()))
		return
	}

	response := map[string]interface{}{
		"transaction": transaction,
		"receipt":     receipt,
	}

	c.JSON(http.StatusOK, service.SuccessResponse("Transaction completed successfully", response))
}