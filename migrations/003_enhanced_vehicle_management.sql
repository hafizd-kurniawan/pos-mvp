-- Add missing fields to cars table for enhanced vehicle management
ALTER TABLE cars ADD COLUMN IF NOT EXISTS license_plate VARCHAR(20);
ALTER TABLE cars ADD COLUMN IF NOT EXISTS engine_number VARCHAR(50);
ALTER TABLE cars ADD COLUMN IF NOT EXISTS fuel_type VARCHAR(20) DEFAULT 'gasoline';
ALTER TABLE cars ADD COLUMN IF NOT EXISTS transmission VARCHAR(20) DEFAULT 'manual';
ALTER TABLE cars ADD COLUMN IF NOT EXISTS condition VARCHAR(20) DEFAULT 'good';
ALTER TABLE cars ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE cars ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES customers(id);

-- Create unique index for license plate
CREATE UNIQUE INDEX IF NOT EXISTS idx_cars_license_plate ON cars(license_plate) WHERE deleted_at IS NULL AND license_plate IS NOT NULL;

-- Create index for customer_id to improve performance
CREATE INDEX IF NOT EXISTS idx_cars_customer_id ON cars(customer_id) WHERE deleted_at IS NULL;

-- Add missing customer_code field to customers table
ALTER TABLE customers ADD COLUMN IF NOT EXISTS customer_code VARCHAR(20) UNIQUE;

-- Update existing cars to have default values for required fields
UPDATE cars SET fuel_type = 'gasoline' WHERE fuel_type IS NULL;
UPDATE cars SET transmission = 'manual' WHERE transmission IS NULL;
UPDATE cars SET condition = 'good' WHERE condition IS NULL;

-- Add password field to users table if not exists (for authentication)
ALTER TABLE users ADD COLUMN IF NOT EXISTS password VARCHAR(255);

-- Update status enum to include in_repair
-- Note: PostgreSQL doesn't have easy enum modification, so we allow any varchar
-- The application layer will validate the allowed values

-- Create indexes for better performance on new fields
CREATE INDEX IF NOT EXISTS idx_cars_fuel_type ON cars(fuel_type) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_cars_transmission ON cars(transmission) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_cars_condition ON cars(condition) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_customers_customer_code ON customers(customer_code) WHERE deleted_at IS NULL;