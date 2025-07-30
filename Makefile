.PHONY: build run test clean db-up db-down db-migrate help

# Build the application
build:
	go build -o bin/car-showroom-pos ./cmd/main.go

# Run the application in development mode
run:
	go run ./cmd/main.go

# Run tests
test:
	go test -v ./...

# Clean build artifacts
clean:
	rm -rf bin/

# Start PostgreSQL database using Docker Compose
db-up:
	docker-compose up -d

# Stop PostgreSQL database
db-down:
	docker-compose down

# Run database migrations (execute SQL files)
db-migrate:
	docker-compose exec postgres psql -U postgres -d car_showroom_pos -f /docker-entrypoint-initdb.d/001_initial_schema.sql

# Install dependencies
deps:
	go mod tidy
	go mod download

# Format code
fmt:
	go fmt ./...

# Lint code
lint:
	golangci-lint run

# Run the application with hot reload (requires air)
dev:
	air

# Generate API documentation (requires swag)
docs:
	swag init -g cmd/main.go

# Install development tools
tools:
	go install github.com/cosmtrek/air@latest
	go install github.com/swaggo/swag/cmd/swag@latest

# Show help
help:
	@echo "Available commands:"
	@echo "  build      Build the application"
	@echo "  run        Run the application"
	@echo "  test       Run tests"
	@echo "  clean      Clean build artifacts"
	@echo "  db-up      Start PostgreSQL database"
	@echo "  db-down    Stop PostgreSQL database"
	@echo "  db-migrate Run database migrations"
	@echo "  deps       Install dependencies"
	@echo "  fmt        Format code"
	@echo "  lint       Lint code"
	@echo "  dev        Run with hot reload"
	@echo "  docs       Generate API documentation"
	@echo "  tools      Install development tools"
	@echo "  help       Show this help message"