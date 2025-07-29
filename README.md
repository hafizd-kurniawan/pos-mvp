# Car Showroom POS System

A comprehensive Point of Sale system for car showrooms built with Golang, Gin framework, and PostgreSQL. This system provides complete car inventory management, customer management, sales transactions, and receipt generation with soft delete functionality.

## Features

- 🚗 **Car Inventory Management**: Full CRUD operations with search and filtering
- 👥 **Customer Management**: Complete customer information system
- 💰 **Sales Transactions**: Buy/sell functionality with automatic receipt generation
- 🧾 **Receipt System**: Comprehensive receipt management and retrieval
- 🔍 **Search & Filter**: Advanced search capabilities across all entities
- 📄 **Pagination**: Efficient pagination for large datasets
- 🗑️ **Soft Delete**: Safe deletion with data recovery capability
- 🏗️ **Clean Architecture**: Separation of concerns with repository, service, and handler layers

## Quick Start

### Prerequisites

- Go 1.21+
- Docker & Docker Compose
- PostgreSQL (or use provided Docker setup)

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd pos-mvp
   ```

2. **Start PostgreSQL**
   ```bash
   docker compose up -d
   ```

3. **Configure environment** (optional)
   ```bash
   cp .env.example .env
   # Edit .env if needed
   ```

4. **Run the application**
   ```bash
   go run cmd/main.go
   ```

The API will be available at `http://localhost:8080`

### Using Make Commands

```bash
make help          # Show available commands
make db-up         # Start PostgreSQL
make run           # Run the application
make build         # Build the application
make test          # Run tests
```

## API Usage

### Health Check
```bash
curl http://localhost:8080/health
```

### Create a Car
```bash
curl -X POST http://localhost:8080/api/cars \
  -H "Content-Type: application/json" \
  -d '{
    "brand": "Toyota",
    "model": "Camry",
    "year": 2023,
    "color": "Silver",
    "price": 28500.00,
    "mileage": 15000,
    "vin": "1HGBH41JXMN109186",
    "status": "available",
    "description": "Excellent condition, single owner"
  }'
```

### Get All Cars
```bash
curl http://localhost:8080/api/cars
```

### Create a Customer
```bash
curl -X POST http://localhost:8080/api/customers \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@email.com",
    "phone": "555-1234",
    "address": "123 Main St",
    "city": "Anytown",
    "state": "CA",
    "zip_code": "12345"
  }'
```

### Create a Transaction
```bash
curl -X POST http://localhost:8080/api/transactions \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "customer-uuid-here",
    "car_id": "car-uuid-here",
    "sale_price": 28500.00,
    "discount_amount": 1000.00,
    "tax_amount": 2275.00,
    "payment_method": "financing"
  }'
```

## API Documentation

Complete API documentation is available in [`docs/API_DOCUMENTATION.md`](docs/API_DOCUMENTATION.md)

## Architecture

```
├── cmd/                 # Application entry point
├── internal/
│   ├── config/         # Configuration management
│   ├── handler/        # HTTP handlers (Gin)
│   ├── model/          # Data models
│   ├── repository/     # Data access layer (SQLX)
│   └── service/        # Business logic layer
├── migrations/         # Database migrations
├── docs/              # Documentation
└── docker-compose.yml # PostgreSQL setup
```

## Tech Stack

- **Language**: Go 1.21+
- **Framework**: Gin (HTTP web framework)
- **Database**: PostgreSQL with SQLX
- **Architecture**: Clean Architecture pattern

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DB_HOST` | Database host | `localhost` |
| `DB_PORT` | Database port | `5432` |
| `DB_USER` | Database user | `postgres` |
| `DB_PASSWORD` | Database password | `password` |
| `DB_NAME` | Database name | `car_showroom_pos` |
| `SERVER_PORT` | Server port | `8080` |

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.
