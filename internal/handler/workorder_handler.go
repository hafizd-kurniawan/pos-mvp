package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/model"
	"github.com/hafizd-kurniawan/pos-mvp/internal/service"
)

type WorkOrderHandler struct {
	workOrderService *service.WorkOrderService
}

func NewWorkOrderHandler(workOrderService *service.WorkOrderService) *WorkOrderHandler {
	return &WorkOrderHandler{
		workOrderService: workOrderService,
	}
}

// CreateWorkOrder creates a new work order
func (h *WorkOrderHandler) CreateWorkOrder(c *gin.Context) {
	var workOrder model.WorkOrder
	if err := c.ShouldBindJSON(&workOrder); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
			"error":   err.Error(),
		})
		return
	}

	userID, _ := getUserFromContext(c)
	ipAddress := c.ClientIP()
	userAgent := c.GetHeader("User-Agent")

	// Set assigned_by to current user
	workOrder.AssignedBy = userID

	err := h.workOrderService.CreateWorkOrder(&workOrder, userID, ipAddress, userAgent)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to create work order",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Work order created successfully",
		"data":    workOrder,
	})
}

// GetAllWorkOrders retrieves all work orders with pagination
func (h *WorkOrderHandler) GetAllWorkOrders(c *gin.Context) {
	page := getPageFromQuery(c)
	limit := getLimitFromQuery(c)

	workOrders, total, err := h.workOrderService.GetAllWorkOrders(page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to retrieve work orders",
			"error":   err.Error(),
		})
		return
	}

	pagination := createPaginationInfo(page, limit, total)

	c.JSON(http.StatusOK, gin.H{
		"success":    true,
		"message":    "Work orders retrieved successfully",
		"data":       workOrders,
		"pagination": pagination,
	})
}

// GetWorkOrder retrieves a work order by ID
func (h *WorkOrderHandler) GetWorkOrder(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid work order ID",
			"error":   err.Error(),
		})
		return
	}

	workOrder, err := h.workOrderService.GetWorkOrderByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"message": "Work order not found",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Work order retrieved successfully",
		"data":    workOrder,
	})
}

// GetWorkOrderByNumber retrieves a work order by work order number
func (h *WorkOrderHandler) GetWorkOrderByNumber(c *gin.Context) {
	workOrderNumber := c.Query("number")
	if workOrderNumber == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Work order number is required",
		})
		return
	}

	workOrder, err := h.workOrderService.GetWorkOrderByNumber(workOrderNumber)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"message": "Work order not found",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Work order retrieved successfully",
		"data":    workOrder,
	})
}

// GetWorkOrdersByCarID retrieves work orders for a specific car
func (h *WorkOrderHandler) GetWorkOrdersByCarID(c *gin.Context) {
	carIDStr := c.Param("car_id")
	carID, err := uuid.Parse(carIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid car ID",
			"error":   err.Error(),
		})
		return
	}

	page := getPageFromQuery(c)
	limit := getLimitFromQuery(c)

	workOrders, total, err := h.workOrderService.GetWorkOrdersByCarID(carID, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to retrieve work orders",
			"error":   err.Error(),
		})
		return
	}

	pagination := createPaginationInfo(page, limit, total)

	c.JSON(http.StatusOK, gin.H{
		"success":    true,
		"message":    "Work orders retrieved successfully",
		"data":       workOrders,
		"pagination": pagination,
	})
}

// GetWorkOrdersByMechanicID retrieves work orders for a specific mechanic
func (h *WorkOrderHandler) GetWorkOrdersByMechanicID(c *gin.Context) {
	mechanicIDStr := c.Param("mechanic_id")
	mechanicID, err := uuid.Parse(mechanicIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid mechanic ID",
			"error":   err.Error(),
		})
		return
	}

	page := getPageFromQuery(c)
	limit := getLimitFromQuery(c)

	workOrders, total, err := h.workOrderService.GetWorkOrdersByMechanicID(mechanicID, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to retrieve work orders",
			"error":   err.Error(),
		})
		return
	}

	pagination := createPaginationInfo(page, limit, total)

	c.JSON(http.StatusOK, gin.H{
		"success":    true,
		"message":    "Work orders retrieved successfully",
		"data":       workOrders,
		"pagination": pagination,
	})
}

// GetWorkOrdersByStatus retrieves work orders by status
func (h *WorkOrderHandler) GetWorkOrdersByStatus(c *gin.Context) {
	status := c.Param("status")
	if status == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Status is required",
		})
		return
	}

	page := getPageFromQuery(c)
	limit := getLimitFromQuery(c)

	workOrders, total, err := h.workOrderService.GetWorkOrdersByStatus(status, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to retrieve work orders",
			"error":   err.Error(),
		})
		return
	}

	pagination := createPaginationInfo(page, limit, total)

	c.JSON(http.StatusOK, gin.H{
		"success":    true,
		"message":    "Work orders retrieved successfully",
		"data":       workOrders,
		"pagination": pagination,
	})
}

// UpdateWorkOrderProgress updates work order progress
func (h *WorkOrderHandler) UpdateWorkOrderProgress(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid work order ID",
			"error":   err.Error(),
		})
		return
	}

	var req struct {
		Progress int `json:"progress" binding:"required,min=0,max=100"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
			"error":   err.Error(),
		})
		return
	}

	userID, _ := getUserFromContext(c)
	ipAddress := c.ClientIP()
	userAgent := c.GetHeader("User-Agent")

	err = h.workOrderService.UpdateWorkOrderProgress(id, req.Progress, userID, ipAddress, userAgent)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to update work order progress",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Work order progress updated successfully",
	})
}

// AddWorkOrderItem adds a part to a work order
func (h *WorkOrderHandler) AddWorkOrderItem(c *gin.Context) {
	workOrderIDStr := c.Param("id")
	workOrderID, err := uuid.Parse(workOrderIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid work order ID",
			"error":   err.Error(),
		})
		return
	}

	var req struct {
		SparepartID uuid.UUID `json:"sparepart_id" binding:"required"`
		Quantity    int       `json:"quantity" binding:"required,min=1"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
			"error":   err.Error(),
		})
		return
	}

	userID, _ := getUserFromContext(c)
	ipAddress := c.ClientIP()
	userAgent := c.GetHeader("User-Agent")

	err = h.workOrderService.AddWorkOrderItem(workOrderID, req.SparepartID, req.Quantity, userID, ipAddress, userAgent)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to add item to work order",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Item added to work order successfully",
	})
}

// GetWorkOrderItems retrieves items for a work order
func (h *WorkOrderHandler) GetWorkOrderItems(c *gin.Context) {
	workOrderIDStr := c.Param("id")
	workOrderID, err := uuid.Parse(workOrderIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid work order ID",
			"error":   err.Error(),
		})
		return
	}

	items, err := h.workOrderService.GetWorkOrderItems(workOrderID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to retrieve work order items",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Work order items retrieved successfully",
		"data":    items,
	})
}

// UpdateWorkOrder updates a work order
func (h *WorkOrderHandler) UpdateWorkOrder(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid work order ID",
			"error":   err.Error(),
		})
		return
	}

	var workOrder model.WorkOrder
	if err := c.ShouldBindJSON(&workOrder); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
			"error":   err.Error(),
		})
		return
	}

	workOrder.ID = id
	userID, _ := getUserFromContext(c)
	ipAddress := c.ClientIP()
	userAgent := c.GetHeader("User-Agent")

	err = h.workOrderService.UpdateWorkOrder(&workOrder, userID, ipAddress, userAgent)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to update work order",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Work order updated successfully",
		"data":    workOrder,
	})
}

// DeleteWorkOrder soft deletes a work order
func (h *WorkOrderHandler) DeleteWorkOrder(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid work order ID",
			"error":   err.Error(),
		})
		return
	}

	userID, _ := getUserFromContext(c)
	ipAddress := c.ClientIP()
	userAgent := c.GetHeader("User-Agent")

	err = h.workOrderService.DeleteWorkOrder(id, userID, ipAddress, userAgent)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to delete work order",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Work order deleted successfully",
	})
}