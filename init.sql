-- ================================================================
-- ÜNİVERSİTE DUYURU SİSTEMİ VERİTABANI
-- ER Diyagramına Göre Oluşturulmuştur
-- ================================================================

-- Extension'ları aktifleştir
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ================================================================
-- 1. USER TABLOSU
-- ================================================================

CREATE TABLE "User" (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    surname VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    password VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    university VARCHAR(150),
    department VARCHAR(100),
    class VARCHAR(50),
    role VARCHAR(50) DEFAULT 'student',
    profile_photo TEXT,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT uk_user_email UNIQUE (email),
    CONSTRAINT chk_role CHECK (role IN ('student', 'teacher', 'admin', 'moderator'))
);

-- User tablosu için index'ler
CREATE INDEX idx_user_email ON "User"(email);
CREATE INDEX idx_user_role ON "User"(role);
CREATE INDEX idx_user_university ON "User"(university);

-- ================================================================
-- 2. CATEGORY TABLOSU
-- ================================================================

CREATE TABLE "Category" (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    
    -- Constraints
    CONSTRAINT uk_category_name UNIQUE (category_name)
);

-- ================================================================
-- 3. PROCLAMATION TABLOSU (Duyurular)
-- ================================================================

CREATE TABLE "Proclamation" (
    proclamation_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    city VARCHAR(100),
    date_posted TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status_photo TEXT,
    
    -- Foreign Keys
    CONSTRAINT fk_proclamation_category FOREIGN KEY (category_id) 
        REFERENCES "Category"(category_id) ON DELETE RESTRICT,
    CONSTRAINT fk_proclamation_user FOREIGN KEY (user_id) 
        REFERENCES "User"(user_id) ON DELETE CASCADE
);

-- Proclamation için index'ler
CREATE INDEX idx_proclamation_category ON "Proclamation"(category_id);
CREATE INDEX idx_proclamation_user ON "Proclamation"(user_id);
CREATE INDEX idx_proclamation_date ON "Proclamation"(date_posted DESC);
CREATE INDEX idx_proclamation_city ON "Proclamation"(city);

-- ================================================================
-- 4. LIKER TABLOSU (Beğeniler)
-- ================================================================

CREATE TABLE "Liker" (
    like_id SERIAL PRIMARY KEY,
    proclamation_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    date_liked TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign Keys
    CONSTRAINT fk_liker_proclamation FOREIGN KEY (proclamation_id) 
        REFERENCES "Proclamation"(proclamation_id) ON DELETE CASCADE,
    CONSTRAINT fk_liker_user FOREIGN KEY (user_id) 
        REFERENCES "User"(user_id) ON DELETE CASCADE,
    
    -- Bir kullanıcı bir duyuruyu sadece 1 kez beğenebilir
    CONSTRAINT uk_liker_proclamation_user UNIQUE (proclamation_id, user_id)
);

-- Liker için index'ler
CREATE INDEX idx_liker_proclamation ON "Liker"(proclamation_id);
CREATE INDEX idx_liker_user ON "Liker"(user_id);

-- ================================================================
-- 5. PROCLAMATION COMMENT TABLOSU (Duyuru Yorumları)
-- ================================================================

CREATE TABLE "ProclamationComment" (
    comment_id SERIAL PRIMARY KEY,
    proclamation_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    parent_comment_id INTEGER,  -- İç içe yorumlar için (null = üst yorum)
    content TEXT NOT NULL,
    date_posted TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign Keys
    CONSTRAINT fk_proc_comment_proclamation FOREIGN KEY (proclamation_id) 
        REFERENCES "Proclamation"(proclamation_id) ON DELETE CASCADE,
    CONSTRAINT fk_proc_comment_user FOREIGN KEY (user_id) 
        REFERENCES "User"(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_proc_comment_parent FOREIGN KEY (parent_comment_id) 
        REFERENCES "ProclamationComment"(comment_id) ON DELETE CASCADE
);

-- ProclamationComment için index'ler
CREATE INDEX idx_proc_comment_proclamation ON "ProclamationComment"(proclamation_id);
CREATE INDEX idx_proc_comment_user ON "ProclamationComment"(user_id);
CREATE INDEX idx_proc_comment_parent ON "ProclamationComment"(parent_comment_id);
CREATE INDEX idx_proc_comment_date ON "ProclamationComment"(date_posted DESC);

-- ================================================================
-- 6. PRODUCT TABLOSU (İkinci El Ürünler)
-- ================================================================

CREATE TABLE "Product" (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    condition VARCHAR(50),
    city VARCHAR(100),
    user_id INTEGER NOT NULL,
    date_posted TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign Keys
    CONSTRAINT fk_product_user FOREIGN KEY (user_id) 
        REFERENCES "User"(user_id) ON DELETE CASCADE,
    
    -- Constraints
    CONSTRAINT chk_price_positive CHECK (price >= 0),
    CONSTRAINT chk_condition CHECK (condition IN ('new', 'like_new', 'good', 'fair', 'poor'))
);

-- Product için index'ler
CREATE INDEX idx_product_user ON "Product"(user_id);
CREATE INDEX idx_product_city ON "Product"(city);
CREATE INDEX idx_product_date ON "Product"(date_posted DESC);
CREATE INDEX idx_product_price ON "Product"(price);

-- ================================================================
-- 7. PRODUCT COMMENT TABLOSU (Ürün Yorumları)
-- ================================================================

CREATE TABLE "ProductComment" (
    comment_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    parent_comment_id INTEGER,  -- İç içe yorumlar için (null = üst yorum)
    content TEXT NOT NULL,
    price_offer DECIMAL(10, 2),  -- Opsiyonel fiyat teklifi
    date_posted TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign Keys
    CONSTRAINT fk_prod_comment_product FOREIGN KEY (product_id) 
        REFERENCES "Product"(product_id) ON DELETE CASCADE,
    CONSTRAINT fk_prod_comment_user FOREIGN KEY (user_id) 
        REFERENCES "User"(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_prod_comment_parent FOREIGN KEY (parent_comment_id) 
        REFERENCES "ProductComment"(comment_id) ON DELETE CASCADE,
    
    -- Constraints
    CONSTRAINT chk_price_offer_positive CHECK (price_offer IS NULL OR price_offer >= 0)
);

-- ProductComment için index'ler
CREATE INDEX idx_prod_comment_product ON "ProductComment"(product_id);
CREATE INDEX idx_prod_comment_user ON "ProductComment"(user_id);
CREATE INDEX idx_prod_comment_parent ON "ProductComment"(parent_comment_id);
CREATE INDEX idx_prod_comment_date ON "ProductComment"(date_posted DESC);

-- ================================================================
-- 8. MESSAGE TABLOSU (Mesajlaşma)
-- ================================================================

CREATE TABLE "Message" (
    message_id SERIAL PRIMARY KEY,
    sender_id INTEGER NOT NULL,
    receiver_id INTEGER NOT NULL,
    content TEXT NOT NULL,
    date_sent TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN DEFAULT FALSE,
    
    -- Foreign Keys
    CONSTRAINT fk_message_sender FOREIGN KEY (sender_id) 
        REFERENCES "User"(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_message_receiver FOREIGN KEY (receiver_id) 
        REFERENCES "User"(user_id) ON DELETE CASCADE,
    
    -- Constraints
    CONSTRAINT chk_different_users CHECK (sender_id != receiver_id)
);

-- Message için index'ler
CREATE INDEX idx_message_sender ON "Message"(sender_id);
CREATE INDEX idx_message_receiver ON "Message"(receiver_id);
CREATE INDEX idx_message_date ON "Message"(date_sent DESC);
CREATE INDEX idx_message_read ON "Message"(is_read);
CREATE INDEX idx_message_conversation ON "Message"(sender_id, receiver_id);

-- ================================================================
-- ÖRNEK VERİLER
-- ================================================================

-- Kategoriler
INSERT INTO "Category" (category_name) VALUES
('Akademik'),
('Etkinlik'),
('Kulüp'),
('Spor'),
('Kariyer'),
('Barınma'),
('Ulaşım'),
('Genel');

-- Kullanıcılar (şifreler bcrypt ile hashlenmiş "password123")
INSERT INTO "User" (name, surname, email, password, city, university, department, class, role) VALUES
('Admin', 'Kullanıcı', 'admin@universite.edu.tr', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Ankara', 'Gazi Üniversitesi', 'Bilgisayar Mühendisliği', '4', 'admin'),
('Ahmet', 'Yılmaz', 'ahmet.yilmaz@ogrenci.edu.tr', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Ankara', 'Gazi Üniversitesi', 'Bilgisayar Mühendisliği', '3', 'student'),
('Ayşe', 'Demir', 'ayse.demir@ogrenci.edu.tr', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'İstanbul', 'İstanbul Teknik Üniversitesi', 'Endüstri Mühendisliği', '2', 'student'),
('Mehmet', 'Kaya', 'mehmet.kaya@akademik.edu.tr', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Ankara', 'Gazi Üniversitesi', 'Bilgisayar Mühendisliği', 'Öğretim Görevlisi', 'teacher'),
('Fatma', 'Şahin', 'fatma.sahin@ogrenci.edu.tr', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'İzmir', 'Ege Üniversitesi', 'Makine Mühendisliği', '4', 'student');

-- Duyurular
INSERT INTO "Proclamation" (title, description, category_id, user_id, city) VALUES
('Vize Sınav Takvimi Açıklandı', 'Güz dönemi vize sınav takvimi açıklanmıştır. Sınavlar 15 Kasım tarihinde başlayacaktır. Detaylar için öğrenci bilgi sistemini kontrol ediniz.', 1, 4, 'Ankara'),
('Kampüs Bahar Şenliği 2025', 'Her yıl geleneksel olarak düzenlediğimiz bahar şenliği bu yıl 15 Mayıs''ta kampüsümüzde gerçekleşecektir. Konser, yarışmalar ve çeşitli etkinlikler sizleri bekliyor!', 2, 1, 'Ankara'),
('Yazılım Kulübü Haftalık Toplantısı', 'Bu hafta Çarşamba günü saat 18:00''de yazılım kulübü toplantımız yapılacaktır. Web geliştirme konusunu işleyeceğiz. Tüm öğrenciler davetlidir.', 3, 2, 'Ankara'),
('Kampüsler Arası Basketbol Turnuvası', 'Üniversiteler arası basketbol turnuvası kayıtları başlamıştır. Takım kaptanları lütfen spor koordinatörlüğüne başvursunlar. Son kayıt: 30 Kasım', 4, 1, 'İstanbul'),
('Staj Fırsatı - Yazılım Geliştirici', 'ABC Teknoloji şirketi yazılım geliştirici stajyerleri arıyor. React ve Node.js deneyimi tercih sebebidir. Başvurular için: kariyer@abc.com', 5, 1, 'İstanbul'),
('Kampüse Yakın 2+1 Daire', 'Kampüse 10 dakika yürüme mesafesinde 2+1 daire. Eşyalı, ısıtmalı. Aylık kira: 8000 TL. İletişim: 0555 123 4567', 6, 5, 'Ankara'),
('Servis Güzergahı Değişikliği', 'Yenimahalle hattı servis güzergahı değiştirilmiştir. Yeni duraklar için kampüs ulaşım ofisine başvurunuz.', 7, 1, 'Ankara'),
('Kütüphane Çalışma Saatleri Güncellendi', 'Merkez kütüphane hafta içi 08:00-22:00, hafta sonu 10:00-20:00 saatleri arasında hizmet verecektir.', 8, 4, 'Ankara');

-- Beğeniler
INSERT INTO "Liker" (proclamation_id, user_id) VALUES
(1, 2), (1, 3), (1, 5),
(2, 2), (2, 3), (2, 5),
(3, 3), (3, 5),
(4, 2), (4, 5),
(5, 2), (5, 3),
(6, 2),
(7, 5),
(8, 2), (8, 3);

-- Yorumlar (üst yorumlar)
INSERT INTO "ProclamationComment" (proclamation_id, user_id, parent_comment_id, content) VALUES
(1, 2, NULL, 'Sınav takvimi için teşekkürler! Hangi gün hangi ders var tam listesi var mı?'),
(1, 3, NULL, 'Mazeret sınavları ne zaman açıklanacak?'),
(2, 2, NULL, 'Harika! Kesinlikle geleceğim 🎉 Hangi sanatçılar gelecek?'),
(2, 5, NULL, 'Geçen seneki şenlik çok eğlenceliydi, bu sene de muhteşem olacak!'),
(3, 3, NULL, 'React mi öğreteceğiz yoksa başka bir framework mü?'),
(5, 2, NULL, 'CV''mi nasıl gönderebilirim? Başvuru linki var mı?'),
(6, 3, NULL, 'Daire hala müsait mi? Görüşmek için iletişime geçebilir miyim?');

-- Alt yorumlar (cevaplar)
INSERT INTO "ProclamationComment" (proclamation_id, user_id, parent_comment_id, content) VALUES
(1, 4, 1, 'Detaylı sınav programı yarın öğrenci bilgi sisteminde yayınlanacak.'),
(1, 4, 2, 'Mazeret sınavları sınav haftasının sonunda açıklanacak.'),
(2, 1, 3, 'Sanatçı isimleri önümüzdeki hafta açıklanacak. Takipte kalın!'),
(3, 2, 5, 'React ve Node.js üzerinden full-stack proje yapacağız. Temel JavaScript bilgisi yeterli.'),
(5, 1, 6, 'CV''nizi kariyer@abc.com adresine gönderebilirsiniz. Konu: Staj Başvurusu');

-- Ürünler
INSERT INTO "Product" (product_name, description, price, condition, city, user_id) VALUES
('Veri Yapıları ve Algoritmalar Kitabı', 'Thomas H. Cormen - Introduction to Algorithms kitabı. Çok az kullanılmış, altı çizili değil. Kapak hafif yıpranmış.', 250.00, 'good', 'Ankara', 2),
('Casio FX-991ES Plus Hesap Makinesi', 'Mühendislik hesap makinesi. 1 yıl kullanıldı, çok temiz durumda. Pil dahil, kutulu.', 350.00, 'like_new', 'Ankara', 3),
('Apple Magic Mouse 2', 'Orijinal Apple mouse. 6 ay kullanıldı, şarj kablosu mevcut. Hiç düşürülmedi, çizik yok.', 1200.00, 'like_new', 'İstanbul', 5),
('Çalışma Masası ve Sandalye', 'IKEA çalışma masası (120x60cm) ve ofis sandalyesi. Masada küçük leke var ama işlevsel. Kampüs içi teslimat yapabilirim.', 800.00, 'good', 'Ankara', 2),
('Logitech C920 Webcam', 'Online ders için aldım, artık ihtiyacım yok. 3 ay kullanıldı, kutulu.', 450.00, 'like_new', 'İzmir', 5);

-- Ürün Yorumları
INSERT INTO "ProductComment" (product_id, user_id, parent_comment_id, content, price_offer) VALUES
(1, 3, NULL, 'Kitap hala satılık mı? 200 TL''ye alabilir miyim?', 200.00),
(1, 5, NULL, 'Hangi baskı bu kitap?', NULL),
(2, 2, NULL, 'Garanti belgesi var mı?', NULL),
(3, 2, NULL, 'İstanbul''dayım, el yüz görebilir miyiz?', NULL),
(4, 3, NULL, 'Sandalye ayarlanabilir mi? Foto atabilir misiniz?', NULL),
(5, 2, NULL, '400 TL son fiyat olur mu?', 400.00);

-- Ürün yorumlarına cevaplar
INSERT INTO "ProductComment" (product_id, user_id, parent_comment_id, content, price_offer) VALUES
(1, 2, 1, '220 TL''ye tamam. Kampüste buluşabiliriz.', NULL),
(1, 2, 2, '3. baskı, 2020 basımı.', NULL),
(2, 3, 3, 'Garanti süresi doldu ama makine sorunsuz çalışıyor.', NULL),
(3, 5, 4, 'Tabii, Kadıköy''de buluşabiliriz. Detaylı fotoları özelden atayım mı?', NULL);

-- Mesajlar
INSERT INTO "Message" (sender_id, receiver_id, content, is_read) VALUES
(2, 3, 'Merhaba, hesap makinesi ilanını gördüm. Hala satılık mı?', TRUE),
(3, 2, 'Merhaba! Evet hala satılıktır. Kampüste buluşabiliriz.', TRUE),
(2, 3, 'Süper! Yarın öğlen 12:00''de kütüphane önünde olur mu?', TRUE),
(3, 2, 'Tamam, yarın görüşürüz 👍', FALSE),
(5, 2, 'Kitap için mesaj atmıştım, 220 TL''ye anlaştık. Ne zaman teslim alabilirim?', FALSE),
(2, 5, 'Bu hafta Çarşamba günü müsaitim. 14:00''da kampüs kafede buluşalım mı?', FALSE);

-- ================================================================
-- VİEW''LAR (Raporlama ve Sorgular İçin)
-- ================================================================

-- 1. Duyuruları beğeni ve yorum sayılarıyla birlikte getir
CREATE OR REPLACE VIEW proclamation_details AS
SELECT 
    p.proclamation_id,
    p.title,
    p.description,
    p.city,
    p.date_posted,
    p.status_photo,
    c.category_name,
    u.name || ' ' || u.surname AS author_name,
    u.email AS author_email,
    u.profile_photo AS author_photo,
    COUNT(DISTINCT l.like_id) AS like_count,
    COUNT(DISTINCT pc.comment_id) AS comment_count
FROM "Proclamation" p
LEFT JOIN "User" u ON p.user_id = u.user_id
LEFT JOIN "Category" c ON p.category_id = c.category_id
LEFT JOIN "Liker" l ON p.proclamation_id = l.proclamation_id
LEFT JOIN "ProclamationComment" pc ON p.proclamation_id = pc.proclamation_id
GROUP BY p.proclamation_id, u.user_id, c.category_id;

-- 2. Kullanıcı istatistikleri
CREATE OR REPLACE VIEW user_statistics AS
SELECT 
    u.user_id,
    u.name || ' ' || u.surname AS full_name,
    u.email,
    u.role,
    u.university,
    u.department,
    COUNT(DISTINCT p.proclamation_id) AS proclamation_count,
    COUNT(DISTINCT pc.comment_id) AS comment_count,
    COUNT(DISTINCT l.like_id) AS likes_given_count,
    COUNT(DISTINCT pr.product_id) AS product_count
FROM "User" u
LEFT JOIN "Proclamation" p ON u.user_id = p.user_id
LEFT JOIN "ProclamationComment" pc ON u.user_id = pc.user_id
LEFT JOIN "Liker" l ON u.user_id = l.user_id
LEFT JOIN "Product" pr ON u.user_id = pr.user_id
GROUP BY u.user_id;

-- 3. Kategori istatistikleri
CREATE OR REPLACE VIEW category_statistics AS
SELECT 
    c.category_id,
    c.category_name,
    COUNT(DISTINCT p.proclamation_id) AS proclamation_count,
    COUNT(DISTINCT l.like_id) AS total_likes,
    COUNT(DISTINCT pc.comment_id) AS total_comments
FROM "Category" c
LEFT JOIN "Proclamation" p ON c.category_id = p.category_id
LEFT JOIN "Liker" l ON p.proclamation_id = l.proclamation_id
LEFT JOIN "ProclamationComment" pc ON p.proclamation_id = pc.proclamation_id
GROUP BY c.category_id
ORDER BY proclamation_count DESC;

-- 4. Ürün detayları yorum sayılarıyla
CREATE OR REPLACE VIEW product_details AS
SELECT 
    pr.product_id,
    pr.product_name,
    pr.description,
    pr.price,
    pr.condition,
    pr.city,
    pr.date_posted,
    u.name || ' ' || u.surname AS seller_name,
    u.email AS seller_email,
    u.phone AS seller_phone,
    COUNT(DISTINCT pc.comment_id) AS comment_count,
    MIN(pc.price_offer) AS lowest_offer,
    MAX(pc.price_offer) AS highest_offer
FROM "Product" pr
LEFT JOIN "User" u ON pr.user_id = u.user_id
LEFT JOIN "ProductComment" pc ON pr.product_id = pc.product_id
GROUP BY pr.product_id, u.user_id;

-- 5. Mesajlaşma özeti (konuşmalar)
CREATE OR REPLACE VIEW message_conversations AS
SELECT 
    LEAST(m.sender_id, m.receiver_id) AS user1_id,
    GREATEST(m.sender_id, m.receiver_id) AS user2_id,
    u1.name || ' ' || u1.surname AS user1_name,
    u2.name || ' ' || u2.surname AS user2_name,
    COUNT(*) AS message_count,
    MAX(m.date_sent) AS last_message_date,
    SUM(CASE WHEN m.is_read = FALSE THEN 1 ELSE 0 END) AS unread_count
FROM "Message" m
LEFT JOIN "User" u1 ON LEAST(m.sender_id, m.receiver_id) = u1.user_id
LEFT JOIN "User" u2 ON GREATEST(m.sender_id, m.receiver_id) = u2.user_id
GROUP BY 
    LEAST(m.sender_id, m.receiver_id),
    GREATEST(m.sender_id, m.receiver_id),
    u1.user_id,
    u2.user_id
ORDER BY last_message_date DESC;

-- ================================================================
-- VERİTABANI BAŞARIYLA OLUŞTURULDU
-- ================================================================

SELECT 
    'Veritabanı başarıyla oluşturuldu!' AS status,
    (SELECT COUNT(*) FROM "User") AS user_count,
    (SELECT COUNT(*) FROM "Category") AS category_count,
    (SELECT COUNT(*) FROM "Proclamation") AS proclamation_count,
    (SELECT COUNT(*) FROM "Product") AS product_count,
    (SELECT COUNT(*) FROM "Message") AS message_count;