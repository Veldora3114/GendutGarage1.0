-- =============================================================================
-- SISTEM INFORMASI MANAJEMEN BENGKEL MOTOR GENDUT GARAGE
-- FILE DDL DATABASE SCHEMA (SUPABASE / POSTGRESQL)
-- Repositori Resmi: https://github.com/Veldora3114/GendutGarage1.0
-- Disusun oleh: Raihan Alfisa Saugi (NPM: 4522210037)
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. TABEL PROFILES (Daftar Pengguna & Hak Akses Multi-Role)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'owner', 'kasir', 'montir', 'pelanggan')),
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 2. TABEL VEHICLES (Data Sepeda Motor Pelanggan)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.vehicles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    plate_number VARCHAR(15) NOT NULL UNIQUE,
    brand VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year INT CHECK (year >= 1990 AND year <= 2030),
    engine_capacity INT DEFAULT 110,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 3. TABEL SERVICE_TYPES (Kategori Utama Servis)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.service_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    base_price DECIMAL(12, 2) NOT NULL DEFAULT 0,
    description TEXT
);

-- -----------------------------------------------------------------------------
-- 4. TABEL SERVICE_SUBTYPES (Rincian Sub-Kategori Servis)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.service_subtypes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_type_id UUID NOT NULL REFERENCES public.service_types(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    duration_minutes INT DEFAULT 30,
    price DECIMAL(12, 2) NOT NULL DEFAULT 0
);

-- -----------------------------------------------------------------------------
-- 5. TABEL PARTS (Master Data Suku Cadang / Sparepart & Stok Kritis)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.parts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sku VARCHAR(30) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    purchase_price DECIMAL(12, 2) NOT NULL DEFAULT 0,
    selling_price DECIMAL(12, 2) NOT NULL DEFAULT 0,
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    min_stock_threshold INT NOT NULL DEFAULT 3,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 6. TABEL BOOKINGS (Reservasi Servis & Upgrade Mesin Pelanggan)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
    service_type_id UUID REFERENCES public.service_types(id) ON DELETE SET NULL,
    booking_date DATE NOT NULL,
    time_slot TIME NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'checked_in', 'cancelled')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 7. TABEL JOBS (Manajemen Pekerjaan Servis Montir)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
    mechanic_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    cashier_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    priority VARCHAR(20) NOT NULL DEFAULT 'normal' CHECK (priority IN ('normal', 'high', 'urgent')),
    status VARCHAR(20) NOT NULL DEFAULT 'waiting' CHECK (status IN ('waiting', 'in_progress', 'pending_parts', 'done')),
    estimated_minutes INT DEFAULT 45,
    mechanic_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 8. TABEL STOCK_MOVEMENTS (Mutasi Keluar-Masuk Stok Sparepart)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.stock_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    part_id UUID NOT NULL REFERENCES public.parts(id) ON DELETE CASCADE,
    job_id UUID REFERENCES public.jobs(id) ON DELETE SET NULL,
    movement_type VARCHAR(10) NOT NULL CHECK (movement_type IN ('in', 'out')),
    quantity INT NOT NULL CHECK (quantity > 0),
    notes TEXT,
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 9. TABEL INVOICES & INVOICE_ITEMS (Nota Tagihan & Transaksi Kasir)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.profiles(id),
    cashier_id UUID NOT NULL REFERENCES public.profiles(id),
    invoice_number VARCHAR(30) UNIQUE NOT NULL,
    total_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
    final_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'unpaid' CHECK (status IN ('unpaid', 'paid', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.invoice_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
    item_type VARCHAR(20) NOT NULL CHECK (item_type IN ('service', 'part')),
    item_name VARCHAR(100) NOT NULL,
    unit_price DECIMAL(12, 2) NOT NULL DEFAULT 0,
    quantity INT NOT NULL DEFAULT 1,
    subtotal DECIMAL(12, 2) NOT NULL DEFAULT 0
);

-- -----------------------------------------------------------------------------
-- 10. TABEL PAYMENTS (Pembayaran Transaksi)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
    payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('cash', 'qris', 'transfer')),
    amount_paid DECIMAL(12, 2) NOT NULL DEFAULT 0,
    change_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'success',
    paid_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 11. TABEL ATTENDANCE (Absensi Pegawai 4 Titik Waktu)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    clock_in TIMESTAMP WITH TIME ZONE,
    break_out TIMESTAMP WITH TIME ZONE,
    break_in TIMESTAMP WITH TIME ZONE,
    clock_out TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'present',
    notes TEXT,
    UNIQUE(user_id, date)
);

-- -----------------------------------------------------------------------------
-- 12. TABEL CUSTOMER_REWARDS (Poin Reward & Tier Loyalitas Pelanggan)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.customer_rewards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE,
    total_points INT NOT NULL DEFAULT 0,
    loyalty_tier VARCHAR(20) NOT NULL DEFAULT 'Bronze' CHECK (loyalty_tier IN ('Bronze', 'Silver', 'Gold', 'Platinum')),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- ROW LEVEL SECURITY (RLS) POLICIES
-- -----------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_rewards ENABLE ROW LEVEL SECURITY;

-- Kebijakan RLS Profiles
CREATE POLICY "Public profiles are viewable by authenticated users" ON public.profiles
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Kebijakan RLS Vehicles
CREATE POLICY "Pelanggan dapat melihat kendaraan sendiri, Staf melihat semua" ON public.vehicles
    FOR SELECT USING (
        auth.uid() = user_id OR 
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'owner', 'kasir', 'montir'))
    );

CREATE POLICY "Pelanggan dapat menambahkan kendaraan sendiri" ON public.vehicles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Kebijakan RLS Bookings
CREATE POLICY "Akses Booking Pelanggan & Staf" ON public.bookings
    FOR SELECT USING (
        auth.uid() = customer_id OR 
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'owner', 'kasir', 'montir'))
    );

-- Trigger Otomatis Update Stok saat Mutasi Stok Out
CREATE OR REPLACE FUNCTION update_part_stock()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.movement_type = 'out' THEN
        UPDATE public.parts SET stock_quantity = stock_quantity - NEW.quantity WHERE id = NEW.part_id;
    ELSIF NEW.movement_type = 'in' THEN
        UPDATE public.parts SET stock_quantity = stock_quantity + NEW.quantity WHERE id = NEW.part_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_part_stock
AFTER INSERT ON public.stock_movements
FOR EACH ROW EXECUTE FUNCTION update_part_stock();