-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'salesperson',
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

-- Create customers table
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    zip_code VARCHAR(20),
    date_of_birth DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

-- Create cars table
CREATE TABLE IF NOT EXISTS cars (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brand VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year INTEGER NOT NULL,
    color VARCHAR(50),
    price DECIMAL(12,2) NOT NULL,
    mileage INTEGER DEFAULT 0,
    vin VARCHAR(17) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'available',
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

-- Create transactions table
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id),
    car_id UUID NOT NULL REFERENCES cars(id),
    sale_price DECIMAL(12,2) NOT NULL,
    discount_amount DECIMAL(12,2) DEFAULT 0,
    tax_amount DECIMAL(12,2) DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sales_person_id UUID REFERENCES users(id),
    notes TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

-- Create receipts table
CREATE TABLE IF NOT EXISTS receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID NOT NULL REFERENCES transactions(id),
    receipt_number VARCHAR(100) UNIQUE NOT NULL,
    issue_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    customer_name VARCHAR(255) NOT NULL,
    customer_email VARCHAR(255),
    customer_phone VARCHAR(20),
    car_brand VARCHAR(100) NOT NULL,
    car_model VARCHAR(100) NOT NULL,
    car_year INTEGER NOT NULL,
    car_vin VARCHAR(17) NOT NULL,
    sale_price DECIMAL(12,2) NOT NULL,
    discount_amount DECIMAL(12,2) DEFAULT 0,
    tax_amount DECIMAL(12,2) DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

-- Create indexes for better performance
CREATE INDEX idx_cars_status ON cars(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_cars_brand_model ON cars(brand, model) WHERE deleted_at IS NULL;
CREATE INDEX idx_customers_email ON customers(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_transactions_customer ON transactions(customer_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_transactions_car ON transactions(car_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_transactions_date ON transactions(transaction_date) WHERE deleted_at IS NULL;
CREATE INDEX idx_receipts_transaction ON receipts(transaction_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_receipts_number ON receipts(receipt_number) WHERE deleted_at IS NULL;

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_cars_updated_at BEFORE UPDATE ON cars
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_receipts_updated_at BEFORE UPDATE ON receipts
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Insert sample data
INSERT INTO users (username, email, first_name, last_name, role) VALUES 
('admin', 'admin@carshowroom.com', 'Admin', 'User', 'admin'),
('john_sales', 'john@carshowroom.com', 'John', 'Smith', 'salesperson'),
('mary_manager', 'mary@carshowroom.com', 'Mary', 'Johnson', 'manager')
ON CONFLICT (username) DO NOTHING;

INSERT INTO cars (brand, model, year, color, price, mileage, vin, status, description) VALUES 
('Toyota', 'Camry', 2023, 'Silver', 28500.00, 15000, '1HGBH41JXMN109186', 'available', 'Excellent condition, single owner'),
('Honda', 'Civic', 2022, 'Blue', 24900.00, 22000, '2HGFB2F5XEH000001', 'available', 'Low mileage, well maintained'),
('Ford', 'Mustang', 2023, 'Red', 35000.00, 8000, '1FA6P8TH4N5100001', 'available', 'Sports car, premium package'),
('BMW', '3 Series', 2022, 'Black', 42000.00, 18000, 'WBA8E1C50JA000001', 'available', 'Luxury sedan, navigation system'),
('Mercedes-Benz', 'C-Class', 2023, 'White', 45000.00, 12000, 'WDDGF4HB8EA000001', 'available', 'Premium features, leather interior')
ON CONFLICT (vin) DO NOTHING;