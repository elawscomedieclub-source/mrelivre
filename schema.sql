-- ============================================================
-- BASE DE DONNÉES COMPLÈTE MULTI-RÔLE (4 RÔLES)
-- Compatible : Supabase / Neon / PostgreSQL Cloud
-- Rôles : ADMIN (Administration), DRIVER (Conducteur), CLIENT (Client), SHOP_OWNER (Boutique)
-- ============================================================

-- 1. Table des Utilisateurs Multi-Rôles
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('ADMIN', 'DRIVER', 'CLIENT', 'SHOP_OWNER')),
    language_pref VARCHAR(5) DEFAULT 'FR',
    is_active BOOLEAN DEFAULT TRUE,
    fcm_token VARCHAR(255),
    rating NUMERIC(3, 2) DEFAULT 5.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Table spécifique aux Conducteurs / Livreurs
CREATE TABLE IF NOT EXISTS driver_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    vehicle_type VARCHAR(20) NOT NULL CHECK (vehicle_type IN ('MOTO', 'TAXI', 'AUTO', 'BUS')),
    license_plate VARCHAR(30) NOT NULL,
    is_online BOOLEAN DEFAULT FALSE,
    current_lat NUMERIC(10, 8),
    current_lng NUMERIC(11, 8),
    total_earnings NUMERIC(12, 2) DEFAULT 0.00,
    wallet_balance NUMERIC(12, 2) DEFAULT 0.00,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Table des Boutiques Partenaires
CREATE TABLE IF NOT EXISTS shops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
    shop_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) DEFAULT 'General',
    phone VARCHAR(20),
    location_address VARCHAR(255) NOT NULL,
    location_lat NUMERIC(10, 8),
    location_lng NUMERIC(11, 8),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Table des Stocks et Produits des Boutiques
CREATE TABLE IF NOT EXISTS inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
    product_name VARCHAR(100) NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    low_stock_threshold INT DEFAULT 3,
    image_url VARCHAR(255),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Table des Courses et Livraisons (Interactions Multi-Rôles)
CREATE TABLE IF NOT EXISTS rides_and_deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(20) NOT NULL CHECK (type IN ('DELIVERY', 'PASSENGER_TRANSPORT')),
    client_id UUID REFERENCES users(id),
    driver_id UUID REFERENCES users(id),
    shop_id UUID REFERENCES shops(id), -- Null si course directe
    transport_mode VARCHAR(20) DEFAULT 'MOTO',
    pickup_location VARCHAR(255) NOT NULL,
    destination VARCHAR(255) NOT NULL,
    fare_amount NUMERIC(10, 2) NOT NULL,
    commission_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00, -- 12% a 18% pour Admin
    payment_method VARCHAR(30) DEFAULT 'MOBILE_MONEY', -- T-Money, Flooz, MTN, Orange
    payment_status VARCHAR(20) DEFAULT 'PENDING' CHECK (payment_status IN ('PENDING', 'PAID', 'REFUNDED')),
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'ACCEPTED', 'PICKED_UP', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
    qr_code_hash VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Table des Alertes Sécurité et SOS (Surveillance Admin & IA)
CREATE TABLE IF NOT EXISTS safety_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    ride_id UUID REFERENCES rides_and_deliveries(id),
    hazard_type VARCHAR(50) DEFAULT 'SOS_EMERGENCY',
    location_lat NUMERIC(10, 8),
    location_lng NUMERIC(11, 8),
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'RESOLVED')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
