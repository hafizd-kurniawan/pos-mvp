package main

import (
	"log"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/hafizd-kurniawan/pos-mvp/internal/config"
	"github.com/hafizd-kurniawan/pos-mvp/internal/handler"
	"github.com/hafizd-kurniawan/pos-mvp/internal/repository"
	"github.com/hafizd-kurniawan/pos-mvp/internal/service"
	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
)

// @title Car Showroom POS API
// @version 1.0
// @description A Point of Sale system for car showroom with buy/sell functionality and receipt generation
// @host localhost:8080
// @BasePath /
func main() {
	// Load configuration
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// Connect to database
	db, err := sqlx.Connect("postgres", cfg.GetDatabaseURL())
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Initialize repositories
	carRepo := repository.NewCarRepository(db)
	customerRepo := repository.NewCustomerRepository(db)
	transactionRepo := repository.NewTransactionRepository(db)
	receiptRepo := repository.NewReceiptRepository(db)
	userRepo := repository.NewUserRepository(db)
	
	// New repositories for advanced features
	sessionRepo := repository.NewSessionRepository(db)
	activityLogRepo := repository.NewActivityLogRepository(db)
	sparepartRepo := repository.NewSparepartRepository(db)
	stockMovementRepo := repository.NewStockMovementRepository(db)
	workOrderRepo := repository.NewWorkOrderRepository(db)
	workOrderItemRepo := repository.NewWorkOrderItemRepository(db)

	// Initialize services
	carService := service.NewCarService(carRepo)
	customerService := service.NewCustomerService(customerRepo)
	transactionService := service.NewTransactionService(transactionRepo, carRepo, customerRepo, receiptRepo)
	receiptService := service.NewReceiptService(receiptRepo)
	userService := service.NewUserService(userRepo)
	
	// New services for advanced features
	authService := service.NewAuthService(cfg.JWT.Secret, 24*time.Hour)
	sparepartService := service.NewSparepartService(sparepartRepo, stockMovementRepo, activityLogRepo)
	workOrderService := service.NewWorkOrderService(workOrderRepo, workOrderItemRepo, sparepartRepo, stockMovementRepo, activityLogRepo)

	// Initialize handlers
	carHandler := handler.NewCarHandler(carService)
	customerHandler := handler.NewCustomerHandler(customerService)
	transactionHandler := handler.NewTransactionHandler(transactionService)
	receiptHandler := handler.NewReceiptHandler(receiptService)
	userHandler := handler.NewUserHandler(userService)
	
	// New handlers for advanced features
	authHandler := handler.NewAuthHandler(authService, userRepo, sessionRepo, activityLogRepo)
	sparepartHandler := handler.NewSparepartHandler(sparepartService)
	workOrderHandler := handler.NewWorkOrderHandler(workOrderService)

	// Setup Gin router
	r := gin.Default()

	// Add CORS middleware
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// Health check endpoint
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "healthy",
			"message": "Car Showroom POS API is running",
		})
	})

	// API routes
	api := r.Group("/api")
	{
		// Authentication routes
		auth := api.Group("/auth")
		{
			auth.POST("/login", authHandler.Login)
			auth.POST("/logout", authHandler.Logout)
			auth.GET("/validate", authHandler.ValidateToken)
			auth.GET("/activity/:user_id", authHandler.GetActivityLogs)
		}

		// Car routes
		cars := api.Group("/cars")
		{
			cars.POST("", carHandler.CreateCar)
			cars.GET("", carHandler.GetAllCars)
			cars.GET("/:id", carHandler.GetCar)
			cars.PUT("/:id", carHandler.UpdateCar)
			cars.DELETE("/:id", carHandler.DeleteCar)
			cars.GET("/status/:status", carHandler.GetCarsByStatus)
			cars.GET("/search", carHandler.SearchCars)
		}

		// Customer routes
		customers := api.Group("/customers")
		{
			customers.POST("", customerHandler.CreateCustomer)
			customers.GET("", customerHandler.GetAllCustomers)
			customers.GET("/:id", customerHandler.GetCustomer)
			customers.PUT("/:id", customerHandler.UpdateCustomer)
			customers.DELETE("/:id", customerHandler.DeleteCustomer)
			customers.GET("/email", customerHandler.GetCustomerByEmail)
			customers.GET("/search", customerHandler.SearchCustomers)
		}

		// Transaction routes
		transactions := api.Group("/transactions")
		{
			transactions.POST("", transactionHandler.CreateTransaction)
			transactions.GET("", transactionHandler.GetAllTransactions)
			transactions.GET("/:id", transactionHandler.GetTransaction)
			transactions.PUT("/:id", transactionHandler.UpdateTransaction)
			transactions.DELETE("/:id", transactionHandler.DeleteTransaction)
			transactions.GET("/customer/:customer_id", transactionHandler.GetTransactionsByCustomer)
			transactions.GET("/date-range", transactionHandler.GetTransactionsByDateRange)
			transactions.POST("/:id/complete", transactionHandler.CompleteTransaction)
		}

		// Receipt routes
		receipts := api.Group("/receipts")
		{
			receipts.GET("", receiptHandler.GetAllReceipts)
			receipts.GET("/:id", receiptHandler.GetReceipt)
			receipts.GET("/transaction/:transaction_id", receiptHandler.GetReceiptByTransactionID)
			receipts.GET("/number", receiptHandler.GetReceiptByNumber)
			receipts.GET("/search", receiptHandler.SearchReceipts)
			receipts.DELETE("/:id", receiptHandler.DeleteReceipt)
		}

		// User routes
		users := api.Group("/users")
		{
			users.POST("", userHandler.CreateUser)
			users.GET("", userHandler.GetAllUsers)
			users.GET("/:id", userHandler.GetUser)
			users.PUT("/:id", userHandler.UpdateUser)
			users.DELETE("/:id", userHandler.DeleteUser)
			users.GET("/username", userHandler.GetUserByUsername)
			users.GET("/email", userHandler.GetUserByEmail)
			users.GET("/search", userHandler.SearchUsers)
			users.GET("/role/:role", userHandler.GetUsersByRole)
			users.POST("/:id/login", userHandler.UpdateLastLogin)
		}

		// Sparepart routes
		spareparts := api.Group("/spareparts")
		{
			spareparts.POST("", sparepartHandler.CreateSparepart)
			spareparts.GET("", sparepartHandler.GetAllSpareparts)
			spareparts.GET("/:id", sparepartHandler.GetSparepart)
			spareparts.PUT("/:id", sparepartHandler.UpdateSparepart)
			spareparts.DELETE("/:id", sparepartHandler.DeleteSparepart)
			spareparts.GET("/part-number", sparepartHandler.GetSparepartByPartNumber)
			spareparts.GET("/barcode", sparepartHandler.GetSparepartByBarcode)
			spareparts.GET("/search", sparepartHandler.SearchSpareparts)
			spareparts.GET("/low-stock", sparepartHandler.GetLowStockSpareparts)
			spareparts.PUT("/:id/stock", sparepartHandler.UpdateStock)
			spareparts.GET("/:id/movements", sparepartHandler.GetStockMovements)
		}

		// Work Order routes
		workOrders := api.Group("/work-orders")
		{
			workOrders.POST("", workOrderHandler.CreateWorkOrder)
			workOrders.GET("", workOrderHandler.GetAllWorkOrders)
			workOrders.GET("/:id", workOrderHandler.GetWorkOrder)
			workOrders.PUT("/:id", workOrderHandler.UpdateWorkOrder)
			workOrders.DELETE("/:id", workOrderHandler.DeleteWorkOrder)
			workOrders.GET("/number", workOrderHandler.GetWorkOrderByNumber)
			workOrders.GET("/car/:car_id", workOrderHandler.GetWorkOrdersByCarID)
			workOrders.GET("/mechanic/:mechanic_id", workOrderHandler.GetWorkOrdersByMechanicID)
			workOrders.GET("/status/:status", workOrderHandler.GetWorkOrdersByStatus)
			workOrders.PUT("/:id/progress", workOrderHandler.UpdateWorkOrderProgress)
			workOrders.POST("/:id/items", workOrderHandler.AddWorkOrderItem)
			workOrders.GET("/:id/items", workOrderHandler.GetWorkOrderItems)
		}
	}

	// Start server
	log.Printf("Starting server on %s", cfg.GetServerAddress())
	if err := r.Run(cfg.GetServerAddress()); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}