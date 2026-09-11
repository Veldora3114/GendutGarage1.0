-- =============================================================================
-- MASTER SEED DATA UNTUK GENDUT GARAGE
-- =============================================================================

-- Master Data Kategori Servis
INSERT INTO public.service_types (id, name, category, base_price, description) VALUES
('11111111-1111-1111-1111-111111111111', 'Servis Berkala / Ringan', 'Servis', 45000.00, 'Pembersihan karburator/throttle body, setel rem, cek tekanan ban, dan oli'),
('22222222-2222-2222-2222-222222222222', 'Servis Besar / Overhaul', 'Servis', 150000.00, 'Bongkar mesin total, skir klep, ganti paking, bersihkan ruang bakar'),
('33333333-3333-3333-3333-333333333333', 'Bore Up & Upgrade Mesin', 'Modifikasi', 350000.00, 'Modifikasi kapasitas mesin, porting polished, pangkas head, setel noken as');

-- Master Data Sparepart & Stok Kritis
INSERT INTO public.parts (id, sku, name, category, purchase_price, selling_price, stock_quantity, min_stock_threshold) VALUES
('a1111111-1111-1111-1111-111111111111', 'PRT-OLI-001', 'Oli Mesin Shell Advance 10W-40 0.8L', 'Oli', 42000.00, 55000.00, 25, 5),
('a2222222-2222-2222-2222-222222222222', 'PRT-OLI-022', 'Oli Matic Yamalube Super Sport 1L', 'Oli', 50000.00, 65000.00, 18, 5),
('a3333333-3333-3333-3333-333333333333', 'PRT-REM-003', 'Kampas Rem Depan Honda Beat / Vario', 'Rem', 25000.00, 38000.00, 12, 3),
('a4444444-4444-4444-4444-444444444444', 'PRT-BUS-004', 'Busi NGK CPR9EA-9 (Iridium)', 'Pengapian', 18000.00, 28000.00, 2, 5), -- Peringatan Stok Kritis (2 < 5)
('a5555555-5555-5555-5555-555555555555', 'PRT-CVT-005', 'V-Belt Kit NMAX / Aerox Genuine', 'CVT', 110000.00, 145000.00, 8, 3);