package handler

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/hafizd-kurniawan/pos-mvp/internal/service"
)

type InvoiceHandler struct {
	invoiceService service.InvoiceService
}

func NewInvoiceHandler(invoiceService service.InvoiceService) *InvoiceHandler {
	return &InvoiceHandler{
		invoiceService: invoiceService,
	}
}

// CreateInvoice godoc
// @Summary Create a new invoice
// @Description Create a new purchase or sales invoice
// @Tags invoices
// @Accept json
// @Produce json
// @Param invoice body model.Invoice true "Invoice data"
// @Success 201 {object} APIResponse{data=model.Invoice}
// @Failure 400 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Router /api/invoices [post]
func (h *InvoiceHandler) CreateInvoice(c *gin.Context) {
	var invoice model.Invoice
	if err := c.ShouldBindJSON(&invoice); err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	createdInvoice, err := h.invoiceService.CreateInvoice(&invoice)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, "Failed to create invoice", err)
		return
	}

	SuccessResponse(c, http.StatusCreated, "Invoice created successfully", createdInvoice)
}

// GetInvoice godoc
// @Summary Get invoice by ID
// @Description Get a specific invoice by its ID
// @Tags invoices
// @Produce json
// @Param id path string true "Invoice ID"
// @Success 200 {object} APIResponse{data=model.Invoice}
// @Failure 400 {object} APIResponse
// @Failure 404 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Router /api/invoices/{id} [get]
func (h *InvoiceHandler) GetInvoice(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid invoice ID", err)
		return
	}

	invoice, err := h.invoiceService.GetInvoiceByID(id)
	if err != nil {
		if err.Error() == "invoice not found" {
			ErrorResponse(c, http.StatusNotFound, "Invoice not found", err)
			return
		}
		ErrorResponse(c, http.StatusInternalServerError, "Failed to get invoice", err)
		return
	}

	SuccessResponse(c, http.StatusOK, "Invoice retrieved successfully", invoice)
}

// GetInvoiceByNumber godoc
// @Summary Get invoice by number
// @Description Get a specific invoice by its invoice number
// @Tags invoices
// @Produce json
// @Param number query string true "Invoice number"
// @Success 200 {object} APIResponse{data=model.Invoice}
// @Failure 400 {object} APIResponse
// @Failure 404 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Router /api/invoices/number [get]
func (h *InvoiceHandler) GetInvoiceByNumber(c *gin.Context) {
	invoiceNumber := c.Query("number")
	if invoiceNumber == "" {
		ErrorResponse(c, http.StatusBadRequest, "Invoice number is required", nil)
		return
	}

	invoice, err := h.invoiceService.GetInvoiceByNumber(invoiceNumber)
	if err != nil {
		if err.Error() == "invoice not found" {
			ErrorResponse(c, http.StatusNotFound, "Invoice not found", err)
			return
		}
		ErrorResponse(c, http.StatusInternalServerError, "Failed to get invoice", err)
		return
	}

	SuccessResponse(c, http.StatusOK, "Invoice retrieved successfully", invoice)
}

// GetAllInvoices godoc
// @Summary Get all invoices
// @Description Get all invoices with pagination
// @Tags invoices
// @Produce json
// @Param page query int false "Page number (default 1)"
// @Param limit query int false "Number of items per page (default 10)"
// @Success 200 {object} APIResponseWithPagination{data=[]model.Invoice}
// @Failure 500 {object} APIResponse
// @Router /api/invoices [get]
func (h *InvoiceHandler) GetAllInvoices(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	invoices, meta, err := h.invoiceService.GetAllInvoices(page, limit)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, "Failed to get invoices", err)
		return
	}

	SuccessResponseWithPagination(c, http.StatusOK, "Invoices retrieved successfully", invoices, meta)
}

// UpdateInvoice godoc
// @Summary Update an invoice
// @Description Update an existing invoice
// @Tags invoices
// @Accept json
// @Produce json
// @Param id path string true "Invoice ID"
// @Param invoice body model.Invoice true "Updated invoice data"
// @Success 200 {object} APIResponse{data=model.Invoice}
// @Failure 400 {object} APIResponse
// @Failure 404 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Router /api/invoices/{id} [put]
func (h *InvoiceHandler) UpdateInvoice(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid invoice ID", err)
		return
	}

	var invoice model.Invoice
	if err := c.ShouldBindJSON(&invoice); err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	invoice.ID = id
	updatedInvoice, err := h.invoiceService.UpdateInvoice(&invoice)
	if err != nil {
		if err.Error() == "invoice not found" {
			ErrorResponse(c, http.StatusNotFound, "Invoice not found", err)
			return
		}
		ErrorResponse(c, http.StatusInternalServerError, "Failed to update invoice", err)
		return
	}

	SuccessResponse(c, http.StatusOK, "Invoice updated successfully", updatedInvoice)
}

// DeleteInvoice godoc
// @Summary Delete an invoice
// @Description Soft delete an invoice
// @Tags invoices
// @Produce json
// @Param id path string true "Invoice ID"
// @Success 200 {object} APIResponse
// @Failure 400 {object} APIResponse
// @Failure 404 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Router /api/invoices/{id} [delete]
func (h *InvoiceHandler) DeleteInvoice(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid invoice ID", err)
		return
	}

	err = h.invoiceService.DeleteInvoice(id)
	if err != nil {
		if err.Error() == "invoice not found" {
			ErrorResponse(c, http.StatusNotFound, "Invoice not found", err)
			return
		}
		ErrorResponse(c, http.StatusInternalServerError, "Failed to delete invoice", err)
		return
	}

	SuccessResponse(c, http.StatusOK, "Invoice deleted successfully", nil)
}

// GetInvoicesByCustomer godoc
// @Summary Get invoices by customer
// @Description Get all invoices for a specific customer
// @Tags invoices
// @Produce json
// @Param customer_id path string true "Customer ID"
// @Param page query int false "Page number (default 1)"
// @Param limit query int false "Number of items per page (default 10)"
// @Success 200 {object} APIResponseWithPagination{data=[]model.Invoice}
// @Failure 400 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Router /api/invoices/customer/{customer_id} [get]
func (h *InvoiceHandler) GetInvoicesByCustomer(c *gin.Context) {
	customerIDStr := c.Param("customer_id")
	customerID, err := uuid.Parse(customerIDStr)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid customer ID", err)
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	invoices, meta, err := h.invoiceService.GetInvoicesByCustomerID(customerID, page, limit)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, "Failed to get customer invoices", err)
		return
	}

	SuccessResponseWithPagination(c, http.StatusOK, "Customer invoices retrieved successfully", invoices, meta)
}

// GetInvoicesByType godoc
// @Summary Get invoices by type
// @Description Get all invoices of a specific type (purchase/sale)
// @Tags invoices
// @Produce json
// @Param type path string true "Invoice type (purchase/sale)"
// @Param page query int false "Page number (default 1)"
// @Param limit query int false "Number of items per page (default 10)"
// @Success 200 {object} APIResponseWithPagination{data=[]model.Invoice}
// @Failure 400 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Router /api/invoices/type/{type} [get]
func (h *InvoiceHandler) GetInvoicesByType(c *gin.Context) {
	invoiceType := c.Param("type")
	if invoiceType != "purchase" && invoiceType != "sale" {
		ErrorResponse(c, http.StatusBadRequest, "Invalid invoice type. Must be 'purchase' or 'sale'", nil)
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	invoices, meta, err := h.invoiceService.GetInvoicesByType(invoiceType, page, limit)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, "Failed to get invoices by type", err)
		return
	}

	SuccessResponseWithPagination(c, http.StatusOK, "Invoices retrieved successfully", invoices, meta)
}

// GetInvoicesByDateRange godoc
// @Summary Get invoices by date range
// @Description Get all invoices within a specific date range
// @Tags invoices
// @Produce json
// @Param start_date query string true "Start date (YYYY-MM-DD)"
// @Param end_date query string true "End date (YYYY-MM-DD)"
// @Param page query int false "Page number (default 1)"
// @Param limit query int false "Number of items per page (default 10)"
// @Success 200 {object} APIResponseWithPagination{data=[]model.Invoice}
// @Failure 400 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Router /api/invoices/date-range [get]
func (h *InvoiceHandler) GetInvoicesByDateRange(c *gin.Context) {
	startDateStr := c.Query("start_date")
	endDateStr := c.Query("end_date")

	if startDateStr == "" || endDateStr == "" {
		ErrorResponse(c, http.StatusBadRequest, "Both start_date and end_date are required", nil)
		return
	}

	startDate, err := time.Parse("2006-01-02", startDateStr)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid start_date format. Use YYYY-MM-DD", err)
		return
	}

	endDate, err := time.Parse("2006-01-02", endDateStr)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid end_date format. Use YYYY-MM-DD", err)
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	invoices, meta, err := h.invoiceService.GetInvoicesByDateRange(startDate, endDate, page, limit)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, "Failed to get invoices by date range", err)
		return
	}

	SuccessResponseWithPagination(c, http.StatusOK, "Invoices retrieved successfully", invoices, meta)
}

// MarkInvoiceAsPaid godoc
// @Summary Mark invoice as paid
// @Description Mark an invoice as paid and optionally upload payment proof
// @Tags invoices
// @Accept json
// @Produce json
// @Param id path string true "Invoice ID"
// @Param payment body object{payment_proof=string} false "Payment proof file path"
// @Success 200 {object} APIResponse{data=model.Invoice}
// @Failure 400 {object} APIResponse
// @Failure 404 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Router /api/invoices/{id}/paid [post]
func (h *InvoiceHandler) MarkInvoiceAsPaid(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid invoice ID", err)
		return
	}

	var requestBody struct {
		PaymentProof string `json:"payment_proof,omitempty"`
	}
	
	if err := c.ShouldBindJSON(&requestBody); err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	invoice, err := h.invoiceService.MarkAsPaid(id, requestBody.PaymentProof)
	if err != nil {
		if err.Error() == "invoice not found" {
			ErrorResponse(c, http.StatusNotFound, "Invoice not found", err)
			return
		}
		ErrorResponse(c, http.StatusInternalServerError, "Failed to mark invoice as paid", err)
		return
	}

	SuccessResponse(c, http.StatusOK, "Invoice marked as paid successfully", invoice)
}