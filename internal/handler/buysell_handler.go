package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/service"
)

type BuySellHandler struct {
	invoiceService     service.InvoiceService
	carService         service.CarService
	customerService    service.CustomerService
	transactionService service.TransactionService
}

func NewBuySellHandler(
	invoiceService service.InvoiceService,
	carService service.CarService,
	customerService service.CustomerService,
	transactionService service.TransactionService,
) *BuySellHandler {
	return &BuySellHandler{
		invoiceService:     invoiceService,
		carService:         carService,
		customerService:    customerService,
		transactionService: transactionService,
	}
}

// PurchaseVehicle godoc
// @Summary Purchase vehicle from customer
// @Description Create a purchase invoice when buying a vehicle from a customer
// @Tags buy-sell
// @Accept json
// @Produce json
// @Param request body object{customer_id=string,car_id=string,amount=number,payment_method=string,notes=string,created_by=string} true "Purchase request"
// @Success 201 {object} APIResponse{data=object{invoice=model.Invoice,car=model.Car}}
// @Failure 400 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Router /api/buy-sell/purchase [post]
func (h *BuySellHandler) PurchaseVehicle(c *gin.Context) {
	var request struct {
		CustomerID    *string `json:"customer_id,omitempty"`
		CarID         string  `json:"car_id" binding:"required"`
		Amount        float64 `json:"amount" binding:"required"`
		PaymentMethod string  `json:"payment_method" binding:"required"`
		Notes         string  `json:"notes"`
		CreatedBy     string  `json:"created_by" binding:"required"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	carID, err := uuid.Parse(request.CarID)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid car_id", err)
		return
	}

	createdBy, err := uuid.Parse(request.CreatedBy)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid created_by", err)
		return
	}

	var customerID *uuid.UUID
	if request.CustomerID != nil && *request.CustomerID != "" {
		id, err := uuid.Parse(*request.CustomerID)
		if err != nil {
			ErrorResponse(c, http.StatusBadRequest, "Invalid customer_id", err)
			return
		}
		customerID = &id
	}

	// Verify car exists
	car, err := h.carService.GetCarByID(carID)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Car not found", err)
		return
	}

	// Create purchase invoice
	invoice, err := h.invoiceService.CreatePurchaseInvoice(
		customerID,
		&carID,
		request.Amount,
		request.PaymentMethod,
		request.Notes,
		createdBy,
	)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, "Failed to create purchase invoice", err)
		return
	}

	// Update car status to purchased/available for repair
	car.Status = "in_repair" // Car goes to repair after purchase
	updateReq := service.UpdateCarRequest{
		Brand:       car.Brand,
		Model:       car.Model,
		Year:        car.Year,
		Color:       car.Color,
		Price:       car.Price,
		Mileage:     car.Mileage,
		VIN:         car.VIN,
		Status:      "in_repair",
		Description: car.Description,
	}
	_, err = h.carService.UpdateCar(car.ID, updateReq)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, "Failed to update car status", err)
		return
	}

	response := map[string]interface{}{
		"invoice": invoice,
		"car":     car,
	}

	SuccessResponse(c, http.StatusCreated, "Vehicle purchased successfully", response)
}

// SellVehicle godoc
// @Summary Sell vehicle to customer
// @Description Create a sales invoice when selling a vehicle to a customer
// @Tags buy-sell
// @Accept json
// @Produce json
// @Param request body object{customer_id=string,car_id=string,amount=number,discount_amount=number,payment_method=string,notes=string,created_by=string} true "Sales request"
// @Success 201 {object} APIResponse{data=object{invoice=model.Invoice,car=model.Car,transaction=model.Transaction}}
// @Failure 400 {object} APIResponse
// @Failure 500 {object} APIResponse
// @Router /api/buy-sell/sell [post]
func (h *BuySellHandler) SellVehicle(c *gin.Context) {
	var request struct {
		CustomerID     string  `json:"customer_id" binding:"required"`
		CarID          string  `json:"car_id" binding:"required"`
		Amount         float64 `json:"amount" binding:"required"`
		DiscountAmount float64 `json:"discount_amount"`
		PaymentMethod  string  `json:"payment_method" binding:"required"`
		Notes          string  `json:"notes"`
		CreatedBy      string  `json:"created_by" binding:"required"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	customerID, err := uuid.Parse(request.CustomerID)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid customer_id", err)
		return
	}

	carID, err := uuid.Parse(request.CarID)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid car_id", err)
		return
	}

	createdBy, err := uuid.Parse(request.CreatedBy)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Invalid created_by", err)
		return
	}

	// Verify customer exists
	customer, err := h.customerService.GetCustomerByID(customerID)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Customer not found", err)
		return
	}

	// Verify car exists and is available
	car, err := h.carService.GetCarByID(carID)
	if err != nil {
		ErrorResponse(c, http.StatusBadRequest, "Car not found", err)
		return
	}

	if car.Status == "sold" {
		ErrorResponse(c, http.StatusBadRequest, "Car is already sold", nil)
		return
	}

	// Create sales invoice
	invoice, err := h.invoiceService.CreateSalesInvoice(
		&customerID,
		&carID,
		request.Amount,
		request.DiscountAmount,
		request.PaymentMethod,
		request.Notes,
		createdBy,
	)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, "Failed to create sales invoice", err)
		return
	}

	// Create transaction record (maintaining compatibility with existing system)
	transactionReq := service.CreateTransactionRequest{
		CustomerID:     customerID,
		CarID:          carID,
		SalePrice:      request.Amount - request.DiscountAmount,
		DiscountAmount: request.DiscountAmount,
		TaxAmount:      0, // No tax for now
		PaymentMethod:  request.PaymentMethod,
		SalesPersonID:  &createdBy,
		Notes:          request.Notes,
	}
	transaction, _, err := h.transactionService.CreateTransaction(transactionReq)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, "Failed to create transaction record", err)
		return
	}

	// Update car status to sold
	car.Status = "sold"
	updateReq := service.UpdateCarRequest{
		Brand:       car.Brand,
		Model:       car.Model,
		Year:        car.Year,
		Color:       car.Color,
		Price:       car.Price,
		Mileage:     car.Mileage,
		VIN:         car.VIN,
		Status:      "sold",
		Description: car.Description,
	}
	_, err = h.carService.UpdateCar(car.ID, updateReq)
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, "Failed to update car status", err)
		return
	}

	response := map[string]interface{}{
		"invoice":     invoice,
		"car":         car,
		"transaction": transaction,
		"customer":    customer,
	}

	SuccessResponse(c, http.StatusCreated, "Vehicle sold successfully", response)
}

// GetPurchaseInvoices godoc
// @Summary Get all purchase invoices
// @Description Get all purchase invoices with pagination
// @Tags buy-sell
// @Produce json
// @Param page query int false "Page number (default 1)"
// @Param limit query int false "Number of items per page (default 10)"
// @Success 200 {object} APIResponseWithPagination{data=[]model.Invoice}
// @Failure 500 {object} APIResponse
// @Router /api/buy-sell/purchases [get]
func (h *BuySellHandler) GetPurchaseInvoices(c *gin.Context) {
	page := c.DefaultQuery("page", "1")
	limit := c.DefaultQuery("limit", "10")

	// Forward to invoice handler with type filter
	c.Params = append(c.Params, gin.Param{Key: "type", Value: "purchase"})
	c.Request.URL.RawQuery = "page=" + page + "&limit=" + limit

	// Use invoice service directly
	invoiceHandler := NewInvoiceHandler(h.invoiceService)
	invoiceHandler.GetInvoicesByType(c)
}

// GetSalesInvoices godoc
// @Summary Get all sales invoices
// @Description Get all sales invoices with pagination
// @Tags buy-sell
// @Produce json
// @Param page query int false "Page number (default 1)"
// @Param limit query int false "Number of items per page (default 10)"
// @Success 200 {object} APIResponseWithPagination{data=[]model.Invoice}
// @Failure 500 {object} APIResponse
// @Router /api/buy-sell/sales [get]
func (h *BuySellHandler) GetSalesInvoices(c *gin.Context) {
	page := c.DefaultQuery("page", "1")
	limit := c.DefaultQuery("limit", "10")

	// Forward to invoice handler with type filter
	c.Params = append(c.Params, gin.Param{Key: "type", Value: "sale"})
	c.Request.URL.RawQuery = "page=" + page + "&limit=" + limit

	// Use invoice service directly
	invoiceHandler := NewInvoiceHandler(h.invoiceService)
	invoiceHandler.GetInvoicesByType(c)
}

// GetAvailableCars godoc
// @Summary Get available cars for sale
// @Description Get all cars that are available for sale
// @Tags buy-sell
// @Produce json
// @Success 200 {object} APIResponse{data=[]model.Car}
// @Failure 500 {object} APIResponse
// @Router /api/buy-sell/available-cars [get]
func (h *BuySellHandler) GetAvailableCars(c *gin.Context) {
	// Use car service to get available cars
	cars, _, err := h.carService.GetCarsByStatus("available", 1, 100) // Get up to 100 available cars
	if err != nil {
		ErrorResponse(c, http.StatusInternalServerError, "Failed to get available cars", err)
		return
	}

	SuccessResponse(c, http.StatusOK, "Available cars retrieved successfully", cars)
}