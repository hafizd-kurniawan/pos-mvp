# Car Showroom POS API Documentation

A comprehensive Point of Sale system for car showrooms built with Golang, Gin framework, and PostgreSQL.

## Features

- **Car Inventory Management**: Full CRUD operations with soft delete
- **Customer Management**: Complete customer information management
- **Sales Transactions**: Buy/sell functionality with receipt generation
- **Receipt System**: Automatic receipt generation and management
- **Search & Filter**: Advanced search capabilities across all entities
- **Pagination**: Efficient pagination for large datasets
- **Soft Delete**: Safe deletion with ability to recover data

## Tech Stack

- **Language**: Go 1.21+
- **Framework**: Gin (HTTP web framework)
- **Database**: PostgreSQL with SQLX
- **Architecture**: Clean Architecture (Repository, Service, Handler layers)

## API Endpoints

### Health Check

```
GET /health
```

Returns the health status of the API.

### Cars

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/cars` | Create a new car |
| GET | `/api/cars` | Get all cars (paginated) |
| GET | `/api/cars/{id}` | Get car by ID |
| PUT | `/api/cars/{id}` | Update car information |
| DELETE | `/api/cars/{id}` | Soft delete car |
| GET | `/api/cars/status/{status}` | Get cars by status |
| GET | `/api/cars/search?q={query}` | Search cars |

### Customers

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/customers` | Create a new customer |
| GET | `/api/customers` | Get all customers (paginated) |
| GET | `/api/customers/{id}` | Get customer by ID |
| PUT | `/api/customers/{id}` | Update customer information |
| DELETE | `/api/customers/{id}` | Soft delete customer |
| GET | `/api/customers/email?email={email}` | Get customer by email |
| GET | `/api/customers/search?q={query}` | Search customers |

### Transactions

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/transactions` | Create a new transaction |
| GET | `/api/transactions` | Get all transactions (paginated) |
| GET | `/api/transactions/{id}` | Get transaction by ID |
| PUT | `/api/transactions/{id}` | Update transaction |
| DELETE | `/api/transactions/{id}` | Soft delete transaction |
| GET | `/api/transactions/customer/{customer_id}` | Get transactions by customer |
| GET | `/api/transactions/date-range?start_date={date}&end_date={date}` | Get transactions by date range |
| POST | `/api/transactions/{id}/complete` | Complete transaction and mark car as sold |

### Receipts

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/receipts` | Get all receipts (paginated) |
| GET | `/api/receipts/{id}` | Get receipt by ID |
| GET | `/api/receipts/transaction/{transaction_id}` | Get receipt by transaction ID |
| GET | `/api/receipts/number?number={receipt_number}` | Get receipt by number |
| GET | `/api/receipts/search?q={query}` | Search receipts |
| DELETE | `/api/receipts/{id}` | Soft delete receipt |

## Request/Response Format

### Standard Response Structure

```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {
    // Response data
  },
  "error": "" // Only present if success is false
}
```

### Paginated Response Structure

```json
{
  "success": true,
  "message": "Data retrieved successfully",
  "data": [
    // Array of items
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 100,
    "total_pages": 10,
    "has_next": true,
    "has_prev": false
  }
}
```

## Sample Requests

### Create Car

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

### Create Customer

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
    "zip_code": "12345",
    "date_of_birth": "1985-06-15"
  }'
```

### Create Transaction

```bash
curl -X POST http://localhost:8080/api/transactions \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "123e4567-e89b-12d3-a456-426614174000",
    "car_id": "123e4567-e89b-12d3-a456-426614174001",
    "sale_price": 28500.00,
    "discount_amount": 1000.00,
    "tax_amount": 2275.00,
    "payment_method": "financing",
    "notes": "Customer financing approved"
  }'
```

## Query Parameters

### Pagination
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 10, max: 100)

### Search
- `q`: Search query string

### Date Range
- `start_date`: Start date in YYYY-MM-DD format
- `end_date`: End date in YYYY-MM-DD format

## Car Status Values
- `available`: Car is available for sale
- `sold`: Car has been sold
- `reserved`: Car is reserved for a customer

## Payment Methods
- `cash`: Cash payment
- `credit`: Credit card payment
- `financing`: Financing/loan

## Transaction Status Values
- `pending`: Transaction is pending completion
- `completed`: Transaction is completed
- `cancelled`: Transaction has been cancelled

## Database Schema

The system uses PostgreSQL with the following main tables:
- `cars`: Car inventory information
- `customers`: Customer information
- `transactions`: Sales transaction records
- `receipts`: Receipt information
- `users`: System users (sales people, managers, etc.)

All tables include soft delete functionality with `deleted_at` timestamp.

## Environment Variables

```bash
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=password
DB_NAME=car_showroom_pos
DB_SSLMODE=disable

# Server Configuration  
SERVER_HOST=localhost
SERVER_PORT=8080

# JWT Configuration (for future auth implementation)
JWT_SECRET=your-secret-key-here

# Environment
ENVIRONMENT=development
```

## Running the Application

1. Set up PostgreSQL database
2. Copy `.env.example` to `.env` and configure
3. Run database migrations
4. Start the application:

```bash
go run cmd/main.go
```

## Docker Support

Use the provided `docker-compose.yml` to run PostgreSQL:

```bash
docker-compose up -d
```

## Development

The application follows clean architecture principles:
- **Models**: Data structures and domain entities
- **Repository**: Data access layer using SQLX
- **Service**: Business logic layer
- **Handler**: HTTP handlers using Gin framework

All operations support soft delete for data safety and audit trails.