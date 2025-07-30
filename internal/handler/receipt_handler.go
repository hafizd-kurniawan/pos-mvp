package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/service"
)

type ReceiptHandler struct {
	receiptService service.ReceiptService
}

func NewReceiptHandler(receiptService service.ReceiptService) *ReceiptHandler {
	return &ReceiptHandler{
		receiptService: receiptService,
	}
}

// GetReceipt godoc
// @Summary Get receipt by ID
// @Description Get a receipt by its ID
// @Tags receipts
// @Accept json
// @Produce json
// @Param id path string true "Receipt ID"
// @Success 200 {object} service.APIResponse
// @Failure 400 {object} service.APIResponse
// @Failure 404 {object} service.APIResponse
// @Router /api/receipts/{id} [get]
func (h *ReceiptHandler) GetReceipt(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid receipt ID", err.Error()))
		return
	}

	receipt, err := h.receiptService.GetReceiptByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, service.ErrorResponse("Receipt not found", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.SuccessResponse("Receipt retrieved successfully", receipt))
}

// GetAllReceipts godoc
// @Summary Get all receipts
// @Description Get all receipts with pagination
// @Tags receipts
// @Accept json
// @Produce json
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} service.PaginatedResponse
// @Failure 500 {object} service.APIResponse
// @Router /api/receipts [get]
func (h *ReceiptHandler) GetAllReceipts(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	receipts, total, err := h.receiptService.GetAllReceipts(page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, service.ErrorResponse("Failed to get receipts", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.PaginatedSuccessResponse("Receipts retrieved successfully", receipts, page, limit, total))
}

// GetReceiptByTransactionID godoc
// @Summary Get receipt by transaction ID
// @Description Get a receipt by its transaction ID
// @Tags receipts
// @Accept json
// @Produce json
// @Param transaction_id path string true "Transaction ID"
// @Success 200 {object} service.APIResponse
// @Failure 400 {object} service.APIResponse
// @Failure 404 {object} service.APIResponse
// @Router /api/receipts/transaction/{transaction_id} [get]
func (h *ReceiptHandler) GetReceiptByTransactionID(c *gin.Context) {
	transactionIDStr := c.Param("transaction_id")
	transactionID, err := uuid.Parse(transactionIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid transaction ID", err.Error()))
		return
	}

	receipt, err := h.receiptService.GetReceiptByTransactionID(transactionID)
	if err != nil {
		c.JSON(http.StatusNotFound, service.ErrorResponse("Receipt not found", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.SuccessResponse("Receipt retrieved successfully", receipt))
}

// GetReceiptByNumber godoc
// @Summary Get receipt by receipt number
// @Description Get a receipt by its receipt number
// @Tags receipts
// @Accept json
// @Produce json
// @Param number query string true "Receipt number"
// @Success 200 {object} service.APIResponse
// @Failure 400 {object} service.APIResponse
// @Failure 404 {object} service.APIResponse
// @Router /api/receipts/number [get]
func (h *ReceiptHandler) GetReceiptByNumber(c *gin.Context) {
	receiptNumber := c.Query("number")
	if receiptNumber == "" {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Receipt number parameter is required", ""))
		return
	}

	receipt, err := h.receiptService.GetReceiptByNumber(receiptNumber)
	if err != nil {
		c.JSON(http.StatusNotFound, service.ErrorResponse("Receipt not found", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.SuccessResponse("Receipt retrieved successfully", receipt))
}

// SearchReceipts godoc
// @Summary Search receipts
// @Description Search receipts by receipt number, customer name, email, car details, or VIN
// @Tags receipts
// @Accept json
// @Produce json
// @Param q query string true "Search query"
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} service.PaginatedResponse
// @Failure 400 {object} service.APIResponse
// @Failure 500 {object} service.APIResponse
// @Router /api/receipts/search [get]
func (h *ReceiptHandler) SearchReceipts(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Search query is required", ""))
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	receipts, total, err := h.receiptService.SearchReceipts(query, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, service.ErrorResponse("Failed to search receipts", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.PaginatedSuccessResponse("Receipts retrieved successfully", receipts, page, limit, total))
}

// DeleteReceipt godoc
// @Summary Delete receipt
// @Description Soft delete a receipt
// @Tags receipts
// @Accept json
// @Produce json
// @Param id path string true "Receipt ID"
// @Success 200 {object} service.APIResponse
// @Failure 400 {object} service.APIResponse
// @Failure 404 {object} service.APIResponse
// @Failure 500 {object} service.APIResponse
// @Router /api/receipts/{id} [delete]
func (h *ReceiptHandler) DeleteReceipt(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid receipt ID", err.Error()))
		return
	}

	err = h.receiptService.SoftDeleteReceipt(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, service.ErrorResponse("Failed to delete receipt", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.SuccessResponse("Receipt deleted successfully", nil))
}