-- Add password field to users table and new roles
ALTER TABLE users ADD COLUMN IF NOT EXISTS password VARCHAR(255);

-- Create sessions table for session management
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    session_token VARCHAR(500) UNIQUE NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    expires_at TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

-- Create activity_logs table for audit trail
CREATE TABLE IF NOT EXISTS activity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID,
    ip_address VARCHAR(45),
    user_agent TEXT,
    description TEXT,
    old_values JSONB,
    new_values JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

-- Create spareparts table
CREATE TABLE IF NOT EXISTS spareparts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    part_number VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    brand VARCHAR(100),
    category VARCHAR(100),
    stock INTEGER DEFAULT 0,
    min_stock INTEGER DEFAULT 5,
    cost_price DECIMAL(12,2) NOT NULL,
    sale_price DECIMAL(12,2) NOT NULL,
    markup_percent DECIMAL(5,2) DEFAULT 30.00,
    location VARCHAR(100),
    barcode VARCHAR(100) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

-- Create work_orders table
CREATE TABLE IF NOT EXISTS work_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    work_order_number VARCHAR(100) UNIQUE NOT NULL,
    car_id UUID NOT NULL REFERENCES cars(id),
    mechanic_id UUID REFERENCES users(id),
    assigned_by UUID NOT NULL REFERENCES users(id),
    description TEXT NOT NULL,
    labor_cost DECIMAL(12,2) DEFAULT 0,
    parts_cost DECIMAL(12,2) DEFAULT 0,
    total_cost DECIMAL(12,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending',
    progress INTEGER DEFAULT 0,
    start_date TIMESTAMP,
    completed_date TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

-- Create work_order_items table
CREATE TABLE IF NOT EXISTS work_order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    work_order_id UUID NOT NULL REFERENCES work_orders(id),
    sparepart_id UUID NOT NULL REFERENCES spareparts(id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    total_price DECIMAL(12,2) NOT NULL,
    used_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

-- Create stock_movements table
CREATE TABLE IF NOT EXISTS stock_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sparepart_id UUID NOT NULL REFERENCES spareparts(id),
    movement_type VARCHAR(20) NOT NULL,
    quantity INTEGER NOT NULL,
    reference VARCHAR(100),
    reference_id UUID,
    user_id UUID NOT NULL REFERENCES users(id),
    notes TEXT,
    previous_stock INTEGER NOT NULL,
    new_stock INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

-- Create photos table
CREATE TABLE IF NOT EXISTS photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    photo_type VARCHAR(50) NOT NULL,
    is_primary BOOLEAN DEFAULT false,
    caption TEXT,
    uploaded_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

-- Create invoices table
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_number VARCHAR(100) UNIQUE NOT NULL,
    invoice_type VARCHAR(20) NOT NULL,
    customer_id UUID REFERENCES customers(id),
    car_id UUID REFERENCES cars(id),
    amount DECIMAL(12,2) NOT NULL,
    tax_amount DECIMAL(12,2) DEFAULT 0,
    discount_amount DECIMAL(12,2) DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    payment_proof VARCHAR(500),
    status VARCHAR(20) DEFAULT 'draft',
    due_date TIMESTAMP,
    paid_date TIMESTAMP,
    notes TEXT,
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

-- Add customer_code to customers table
ALTER TABLE customers ADD COLUMN IF NOT EXISTS customer_code VARCHAR(20) UNIQUE;

-- Create indexes for performance
CREATE INDEX idx_sessions_user ON sessions(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_sessions_token ON sessions(session_token) WHERE deleted_at IS NULL;
CREATE INDEX idx_activity_logs_user ON activity_logs(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_activity_logs_entity ON activity_logs(entity_type, entity_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_spareparts_part_number ON spareparts(part_number) WHERE deleted_at IS NULL;
CREATE INDEX idx_spareparts_barcode ON spareparts(barcode) WHERE deleted_at IS NULL;
CREATE INDEX idx_work_orders_car ON work_orders(car_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_work_orders_mechanic ON work_orders(mechanic_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_work_orders_number ON work_orders(work_order_number) WHERE deleted_at IS NULL;
CREATE INDEX idx_stock_movements_sparepart ON stock_movements(sparepart_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_photos_entity ON photos(entity_type, entity_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_invoices_number ON invoices(invoice_number) WHERE deleted_at IS NULL;
CREATE INDEX idx_customers_code ON customers(customer_code) WHERE deleted_at IS NULL;

-- Create triggers for updated_at
CREATE TRIGGER update_sessions_updated_at BEFORE UPDATE ON sessions
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_activity_logs_updated_at BEFORE UPDATE ON activity_logs
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_spareparts_updated_at BEFORE UPDATE ON spareparts
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_work_orders_updated_at BEFORE UPDATE ON work_orders
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_work_order_items_updated_at BEFORE UPDATE ON work_order_items
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_stock_movements_updated_at BEFORE UPDATE ON stock_movements
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_photos_updated_at BEFORE UPDATE ON photos
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Update existing users with default password (should be changed in production)
UPDATE users SET password = '$2a$10$N9qo8uLOickgx2ZMRZoMye/JWE0.KKK.gP4.1A9XUEql3yHUgC8fC' WHERE password IS NULL; -- password: "password"

-- Add customer codes to existing customers
DO $$
DECLARE
    customer_rec RECORD;
    counter INTEGER := 1;
BEGIN
    FOR customer_rec IN SELECT id FROM customers WHERE customer_code IS NULL ORDER BY created_at
    LOOP
        UPDATE customers SET customer_code = 'CR-' || LPAD(counter::text, 4, '0') WHERE id = customer_rec.id;
        counter := counter + 1;
    END LOOP;
END $$;

-- Insert sample spareparts
INSERT INTO spareparts (part_number, name, description, brand, category, stock, min_stock, cost_price, sale_price, markup_percent, location, barcode) VALUES 
('BP-001', 'Brake Pad Front', 'Front brake pad set', 'Honda', 'Brake System', 10, 5, 100000, 130000, 30.00, 'A1-01', '1234567890001'),
('BP-002', 'Brake Pad Rear', 'Rear brake pad set', 'Honda', 'Brake System', 8, 5, 85000, 110500, 30.00, 'A1-02', '1234567890002'),
('OF-001', 'Engine Oil Filter', 'Oil filter for engine', 'Honda', 'Engine', 15, 10, 25000, 32500, 30.00, 'B2-01', '1234567890003'),
('AC-001', 'AC Compressor', 'Air conditioning compressor', 'Denso', 'AC System', 3, 2, 750000, 975000, 30.00, 'C3-01', '1234567890004')
ON CONFLICT (part_number) DO NOTHING;