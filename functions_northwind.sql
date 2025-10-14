-- functions_northwind.sql
-- Northwind veritabanı için PostgreSQL fonksiyonları
-- Her fonksiyon nw_ öneki ile başlar ve test örnekleri içerir

-- 1) Ürün Aktif mi?
-- Amaç: Verilen ürünün satışta (discontinued=false) olup olmadığını döndürür
-- Kullanılan tablolar: products
-- Parametreler: p_product_id - kontrol edilecek ürün ID'si
-- Dönüş türü: boolean (NULL, true veya false)
-- Dil: SQL - basit bir sorgu yeterli
CREATE OR REPLACE FUNCTION nw_is_product_active(p_product_id int)
RETURNS boolean
LANGUAGE sql
AS $$
    SELECT discontinued = 0 
    FROM products 
    WHERE product_id = p_product_id;
$$;

--Aktif ürünler için:
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'products'
ORDER BY ordinal_position;


-- Test çağrıları:
-- SELECT nw_is_product_active(1); -- ProductID 1 için sonuç beklenir (true/false)
-- SELECT nw_is_product_active(9999); -- Olmayan ürün için NULL beklenir

-- 2) Tedarikçi Ürün Sayısı
-- Amaç: Bir tedarikçinin kaç ürünü olduğunu verir
-- Kullanılan tablolar: products
-- Parametreler: p_supplier_id - tedarikçi ID'si
-- Dönüş türü: int - ürün sayısı
-- Dil: SQL - basit COUNT işlemi
CREATE OR REPLACE FUNCTION nw_supplier_product_count(p_supplier_id int)
RETURNS int
LANGUAGE sql
AS $$
    SELECT COUNT(*)::int
    FROM products
    WHERE supplier_id = p_supplier_id;
$$;

-- Tüm tedarikçilerin ürün sayısı:
SELECT 
    s.supplier_id,
    s.company_name as tedarikci_adi,
    nw_supplier_product_count(s.supplier_id) as urun_sayisi
FROM suppliers s
ORDER BY urun_sayisi DESC;

--Belirli bir tedarikçi için ürün sayısı:
SELECT 
    s.supplier_id,
    s.company_name,
    nw_supplier_product_count(s.supplier_id) as urun_sayisi
FROM suppliers s
WHERE s.supplier_id = 1;

-- Test çağrıları:
-- SELECT nw_supplier_product_count(1); -- SupplierID 1 için ürün sayısı (≥0)
-- SELECT nw_supplier_product_count(9999); -- Olmayan tedarikçi için 0 beklenir

-- 3) Müşterinin Yıllık Sipariş Adedi
-- Amaç: Bir müşterinin belirtilen yılda verdiği sipariş sayısı
-- Kullanılan tablolar: orders
-- Parametreler: p_customer_id - müşteri ID'si, p_year - yıl
-- Dönüş türü: int - sipariş sayısı
-- Dil: SQL - tarih filtresi ile COUNT
CREATE OR REPLACE FUNCTION nw_customer_order_count(p_customer_id text, p_year int)
RETURNS int
LANGUAGE plpgsql
AS $$
DECLARE
    v_count integer;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM orders
    WHERE customer_id = p_customer_id 
    AND EXTRACT(YEAR FROM orderdate) = p_year;
    
    RETURN v_count;
END;
$$;

SELECT column_name, data_type
FROM information_schema.columns 
WHERE table_name = 'orders'
ORDER BY ordinal_position;


-- Test çağrıları:
-- SELECT nw_customer_order_count('ALFKI', 1997); -- ALFKI için 1997'de ≥1 sipariş beklenir
-- SELECT nw_customer_order_count('XXXXX', 1997); -- Olmayan müşteri için 0 beklenir

-- 4) Müşterinin Son Sipariş Tarihi
-- Amaç: Müşterinin en son sipariş tarihini döndürür
-- Kullanılan tablolar: orders
-- Parametreler: p_customer_id - müşteri ID'si
-- Dönüş türü: date - son sipariş tarihi
-- Dil: SQL - MAX fonksiyonu ile
CREATE OR REPLACE FUNCTION nw_customer_last_order_date(p_customer_id text)
RETURNS date
LANGUAGE sql
AS $$
    SELECT MAX(order_date)
    FROM orders
    WHERE customer_id = p_customer_id;
$$;

-- Test çağrıları:
-- SELECT nw_customer_last_order_date('ALFKI'); -- ALFKI için son sipariş tarihi beklenir
-- SELECT nw_customer_last_order_date('XXXXX'); -- Olmayan müşteri için NULL beklenir

-- 5) Tek Siparişin Brüt Değeri
-- Amaç: Bir siparişin toplam tutarı (indirim hesaplanmış)
-- Kullanılan tablolar: order_details
-- Parametreler: p_order_id - sipariş ID'si
-- Dönüş türü: numeric(12,2) - toplam tutar
-- Dil: SQL - toplam hesaplama
CREATE OR REPLACE FUNCTION nw_order_gross_value(p_order_id int)
RETURNS numeric(12,2)
LANGUAGE sql
AS $$
    SELECT COALESCE(SUM(unit_price * quantity * (1 - discount)), 0)::numeric(12,2)
    FROM order_details
    WHERE order_id = p_order_id;
$$;

-- Test çağrıları:
-- SELECT nw_order_gross_value(10248); -- OrderID 10248 için pozitif değer beklenir
-- SELECT nw_order_gross_value(99999); -- Olmayan sipariş için 0.00 beklenir

-- 6) Ürünün Tarih Aralığı Geliri
-- Amaç: Ürünün belirli bir tarih aralığındaki toplam geliri
-- Kullanılan tablolar: order_details, orders
-- Parametreler: p_product_id - ürün ID'si, p_start - başlangıç tarihi, p_end - bitiş tarihi
-- Dönüş türü: numeric(12,2) - toplam gelir
-- Dil: PL/pgSQL - daha karmaşık JOIN ve filtreleme
CREATE OR REPLACE FUNCTION nw_product_revenue(
    p_product_id int, 
    p_start date DEFAULT '1900-01-01', 
    p_end date DEFAULT '9999-12-31'
)
RETURNS numeric(12,2)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN (
        SELECT COALESCE(SUM(od.unit_price * od.quantity * (1 - od.discount)), 0)::numeric(12,2)
        FROM order_details od
        JOIN orders o ON od.order_id = o.order_id
        WHERE od.product_id = p_product_id
        AND o.order_date BETWEEN p_start AND p_end
    );
END;
$$;

-- Test çağrıları:
-- SELECT nw_product_revenue(1, '1997-01-01', '1997-12-31'); -- ProductID 1 için 1997 geliri
-- SELECT nw_product_revenue(9999); -- Olmayan ürün için 0.00 beklenir

-- 7) Reorder Önerisi
-- Amaç: Ürün için önerilen sipariş miktarı
-- Kullanılan tablolar: products
-- Parametreler: p_product_id - ürün ID'si
-- Dönüş türü: int - önerilen sipariş miktarı
-- Dil: PL/pgSQL - koşullu mantık gerektiği için
CREATE OR REPLACE FUNCTION nw_reorder_suggestion(p_product_id int)
RETURNS int
LANGUAGE plpgsql
AS $$
DECLARE
    v_units_in_stock int;
    v_units_on_order int;
    v_reorder_level int;
BEGIN
    SELECT unitsinstock, COALESCE(unitsonorder, 0), reorderlevel
    INTO v_units_in_stock, v_units_on_order, v_reorder_level
    FROM products
    WHERE productid = p_product_id;
    
    IF NOT FOUND THEN
        RETURN 0;
    END IF;
    
    IF (v_units_in_stock + v_units_on_order) < v_reorder_level THEN
        RETURN v_reorder_level - (v_units_in_stock + v_units_on_order);
    ELSE
        RETURN 0;
    END IF;
END;
$$;

-- Test çağrıları:
-- SELECT nw_reorder_suggestion(1); -- Stok durumuna göre 0 veya pozitif değer beklenir
-- SELECT nw_reorder_suggestion(9999); -- Olmayan ürün için 0 beklenir

-- 8) Kategori Bazında En Çok Gelir Getiren Ürünler
-- Amaç: Belirli kategoride en çok gelir getiren ilk N ürünü listeler
-- Kullanılan tablolar: products, order_details, orders
-- Parametreler: p_category_id - kategori ID'si, p_limit - limit sayısı
-- Dönüş türü: TABLE - ürün bilgileri ve gelirleri
-- Dil: SQL - kompleks sorgu için
CREATE OR REPLACE FUNCTION nw_top_products_by_category(
    p_category_id int, 
    p_limit int DEFAULT 5
)
RETURNS TABLE(
    product_id int, 
    product_name text, 
    revenue numeric(12,2)
)
LANGUAGE sql
AS $$
    SELECT 
        p.product_id as product_id,
        p.product_name as product_name,
        COALESCE(SUM(od.unit_price * od.quantity * (1 - od.discount)), 0)::numeric(12,2) as revenue
    FROM products p
    LEFT JOIN order_details od ON p.product_id = od.product_id
    LEFT JOIN orders o ON od.order_id = o.order_id
    WHERE p.category_id = p_category_id
    GROUP BY p.product_id, p.product_name
    ORDER BY revenue DESC
    LIMIT p_limit;
$$;
-- Test çağrıları:
-- SELECT * FROM nw_top_products_by_category(1, 3); -- Kategori 1'den ilk 3 ürün beklenir
-- SELECT * FROM nw_top_products_by_category(9999); -- Olmayan kategori için boş set beklenir

-- 9) Personel Satış Toplamı (Opsiyonel Tarih)
-- Amaç: Bir personelin yaptığı satışların toplam tutarı
-- Kullanılan tablolar: orders, order_details
-- Parametreler: p_employee_id - personel ID'si, p_start - başlangıç tarihi, p_end - bitiş tarihi
-- Dönüş türü: numeric(12,2) - toplam satış tutarı
-- Dil: PL/pgSQL - dinamik tarih filtresi için
CREATE OR REPLACE FUNCTION nw_employee_sales_total(
    p_employee_id int, 
    p_start date DEFAULT NULL, 
    p_end date DEFAULT NULL
)
RETURNS numeric(12,2)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN (
        SELECT COALESCE(SUM(od.unit_price * od.quantity * (1 - od.discount)), 0)::numeric(12,2)
        FROM orders o
        JOIN order_details od ON o.order_id = od.order_id
        WHERE o.employee_id = p_employee_id
        AND (p_start IS NULL OR o.order_date >= p_start)
        AND (p_end IS NULL OR o.order_date <= p_end)
    );
END;
$$;

-- Test çağrıları:
-- SELECT nw_employee_sales_total(1); -- EmployeeID 1 için tüm zamanlar satış toplamı
-- SELECT nw_employee_sales_total(1, '1997-01-01', '1997-12-31'); -- 1997 yılı için satış toplamı

-- 10) Kargocuya Göre Yıllık Siparişler
-- Amaç: Belirtilen kargo firmasının seçilen yıldaki siparişlerini listeler
-- Kullanılan tablolar: orders
-- Parametreler: p_shipper_id - kargo firması ID'si, p_year - yıl
-- Dönüş türü: TABLE - sipariş bilgileri
-- Dil: SQL - filtreleme ve dönüş için
CREATE OR REPLACE FUNCTION nw_orders_by_shipper(
    p_shipper_id int, 
    p_year int
)
RETURNS TABLE(
    order_id int, 
    order_date date, 
    customer_id text, 
    freight numeric(12,2)
)
LANGUAGE sql
AS $$
    SELECT 
        order_id as order_id,
        order_date as order_date,
        customer_id as customer_id,
        freight::numeric(12,2)
    FROM orders
    WHERE ship_via = p_shipper_id
    AND EXTRACT(YEAR FROM order_date) = p_year
    ORDER BY order_date;
$$;

-- Test çağrıları:
-- SELECT * FROM nw_orders_by_shipper(1, 1997); -- ShipperID 1 için 1997 siparişleri beklenir
-- SELECT * FROM nw_orders_by_shipper(999, 1997); -- Olmayan kargocu için boş set beklenir