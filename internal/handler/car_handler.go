package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/hafizd-kurniawan/pos-mvp/internal/service"
)

type CarHandler struct {
	carService service.CarService
}

func NewCarHandler(carService service.CarService) *CarHandler {
	return &CarHandler{
		carService: carService,
	}
}

// CreateCar godoc
// @Summary Create a new car
// @Description Create a new car in the inventory
// @Tags cars
// @Accept json
// @Produce json
// @Param car body service.CreateCarRequest true "Car data"
// @Success 201 {object} service.APIResponse
// @Failure 400 {object} service.APIResponse
// @Failure 500 {object} service.APIResponse
// @Router /api/cars [post]
func (h *CarHandler) CreateCar(c *gin.Context) {
	var req service.CreateCarRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid request data", err.Error()))
		return
	}

	car, err := h.carService.CreateCar(req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, service.ErrorResponse("Failed to create car", err.Error()))
		return
	}

	c.JSON(http.StatusCreated, service.SuccessResponse("Car created successfully", car))
}

// GetCar godoc
// @Summary Get car by ID
// @Description Get a car by its ID
// @Tags cars
// @Accept json
// @Produce json
// @Param id path string true "Car ID"
// @Success 200 {object} service.APIResponse
// @Failure 400 {object} service.APIResponse
// @Failure 404 {object} service.APIResponse
// @Router /api/cars/{id} [get]
func (h *CarHandler) GetCar(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid car ID", err.Error()))
		return
	}

	car, err := h.carService.GetCarByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, service.ErrorResponse("Car not found", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.SuccessResponse("Car retrieved successfully", car))
}

// GetAllCars godoc
// @Summary Get all cars
// @Description Get all cars with pagination
// @Tags cars
// @Accept json
// @Produce json
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} service.PaginatedResponse
// @Failure 500 {object} service.APIResponse
// @Router /api/cars [get]
func (h *CarHandler) GetAllCars(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	cars, total, err := h.carService.GetAllCars(page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, service.ErrorResponse("Failed to get cars", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.PaginatedSuccessResponse("Cars retrieved successfully", cars, page, limit, total))
}

// UpdateCar godoc
// @Summary Update car
// @Description Update car information
// @Tags cars
// @Accept json
// @Produce json
// @Param id path string true "Car ID"
// @Param car body service.UpdateCarRequest true "Car data"
// @Success 200 {object} service.APIResponse
// @Failure 400 {object} service.APIResponse
// @Failure 404 {object} service.APIResponse
// @Failure 500 {object} service.APIResponse
// @Router /api/cars/{id} [put]
func (h *CarHandler) UpdateCar(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid car ID", err.Error()))
		return
	}

	var req service.UpdateCarRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid request data", err.Error()))
		return
	}

	car, err := h.carService.UpdateCar(id, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, service.ErrorResponse("Failed to update car", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.SuccessResponse("Car updated successfully", car))
}

// DeleteCar godoc
// @Summary Delete car
// @Description Soft delete a car
// @Tags cars
// @Accept json
// @Produce json
// @Param id path string true "Car ID"
// @Success 200 {object} service.APIResponse
// @Failure 400 {object} service.APIResponse
// @Failure 404 {object} service.APIResponse
// @Failure 500 {object} service.APIResponse
// @Router /api/cars/{id} [delete]
func (h *CarHandler) DeleteCar(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Invalid car ID", err.Error()))
		return
	}

	err = h.carService.SoftDeleteCar(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, service.ErrorResponse("Failed to delete car", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.SuccessResponse("Car deleted successfully", nil))
}

// GetCarsByStatus godoc
// @Summary Get cars by status
// @Description Get cars filtered by status with pagination
// @Tags cars
// @Accept json
// @Produce json
// @Param status path string true "Car status"
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} service.PaginatedResponse
// @Failure 500 {object} service.APIResponse
// @Router /api/cars/status/{status} [get]
func (h *CarHandler) GetCarsByStatus(c *gin.Context) {
	status := c.Param("status")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	cars, total, err := h.carService.GetCarsByStatus(status, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, service.ErrorResponse("Failed to get cars by status", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.PaginatedSuccessResponse("Cars retrieved successfully", cars, page, limit, total))
}

// SearchCars godoc
// @Summary Search cars
// @Description Search cars by brand, model, or color
// @Tags cars
// @Accept json
// @Produce json
// @Param q query string true "Search query"
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} service.PaginatedResponse
// @Failure 400 {object} service.APIResponse
// @Failure 500 {object} service.APIResponse
// @Router /api/cars/search [get]
func (h *CarHandler) SearchCars(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, service.ErrorResponse("Search query is required", ""))
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	cars, total, err := h.carService.SearchCars(query, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, service.ErrorResponse("Failed to search cars", err.Error()))
		return
	}

	c.JSON(http.StatusOK, service.PaginatedSuccessResponse("Cars retrieved successfully", cars, page, limit, total))
}