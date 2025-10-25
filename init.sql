

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ================================================================
-- 1. ROLE TABLOSU
-- ================================================================

CREATE TABLE "Role" (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Varsayılan roller
INSERT INTO "Role" (role_name, description) VALUES
('student', 'Öğrenci'),
('teacher', 'Öğretim Görevlisi'),
('admin', 'Sistem Yöneticisi'),
('moderator', 'İçerik Moderatörü'),
('club_president', 'Kulüp Başkanı');

-- ================================================================
-- 2. USER TABLOSU
-- ================================================================

CREATE TABLE "User" (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    surname VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    university VARCHAR(150),
    department VARCHAR(100),
    class VARCHAR(50),
    profile_photo TEXT,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP
);

CREATE INDEX idx_user_email ON "User"(email);
CREATE INDEX idx_user_university ON "User"(university);

-- ================================================================
-- 3. USER_ROLE (Many-to-Many İlişkisi)
-- ================================================================

CREATE TABLE "UserRole" (
    user_id INTEGER NOT NULL,
    role_id INTEGER NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES "User"(user_id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES "Role"(role_id) ON DELETE CASCADE
);

-- ================================================================
-- 4. CATEGORY TABLOSU
-- ================================================================

CREATE TABLE "Category" (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    icon VARCHAR(50),
    color VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Kategoriler
INSERT INTO "Category" (category_name, description, icon, color) VALUES
('Akademik', 'Dersler, sınavlar ve akademik duyurular', '📚', '#3B82F6'),
('Etkinlik', 'Kampüs etkinlikleri', '🎉', '#10B981'),
('Kulüp', 'Öğrenci kulüpleri', '🎭', '#8B5CF6'),
('Spor', 'Spor aktiviteleri', '⚽', '#EF4444'),
('Kariyer', 'İş ve staj fırsatları', '💼', '#F59E0B'),
('Sosyal', 'Sosyal etkinlikler', '🎊', '#EC4899'),
('Genel', 'Diğer duyurular', '📢', '#6B7280');

-- ================================================================
-- 5. GENERAL ANNOUNCEMENT (Ana Duyuru Tablosu)
-- ================================================================

CREATE TABLE "GeneralAnnouncement" (
    announcement_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    announcement_type VARCHAR(50) NOT NULL DEFAULT 'general',
    category_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    city VARCHAR(100),
    university VARCHAR(150),
    date_posted TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_updated TIMESTAMP,
    views_count INTEGER DEFAULT 0,
    is_pinned BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMP,
    
    FOREIGN KEY (category_id) REFERENCES "Category"(category_id) ON DELETE RESTRICT,
    FOREIGN KEY (user_id) REFERENCES "User"(user_id) ON DELETE CASCADE,
    
    CONSTRAINT chk_announcement_type CHECK (announcement_type IN ('general', 'project', 'club'))
);

CREATE INDEX idx_announcement_type ON "GeneralAnnouncement"(announcement_type);
CREATE INDEX idx_announcement_category ON "GeneralAnnouncement"(category_id);
CREATE INDEX idx_announcement_user ON "GeneralAnnouncement"(user_id);
CREATE INDEX idx_announcement_date ON "GeneralAnnouncement"(date_posted DESC);
CREATE INDEX idx_announcement_city ON "GeneralAnnouncement"(city);

-- ================================================================
-- 6. PROJECT ANNOUNCEMENT (Proje Duyuruları - Inheritance)
-- ================================================================

CREATE TABLE "ProjectAnnouncement" (
    project_announcement_id SERIAL PRIMARY KEY,
    announcement_id INTEGER NOT NULL UNIQUE,
    project_name VARCHAR(200) NOT NULL,
    project_description TEXT,
    start_date DATE,
    end_date DATE,
    team_size INTEGER,
    required_skills TEXT[],
    project_status VARCHAR(50) DEFAULT 'open',
    
    FOREIGN KEY (announcement_id) REFERENCES "GeneralAnnouncement"(announcement_id) ON DELETE CASCADE,
    
    CONSTRAINT chk_project_status CHECK (project_status IN ('open', 'in_progress', 'completed', 'cancelled'))
);

-- ================================================================
-- 7. CLUB ANNOUNCEMENT (Kulüp Duyuruları - Inheritance)
-- ================================================================

CREATE TABLE "ClubAnnouncement" (
    club_announcement_id SERIAL PRIMARY KEY,
    announcement_id INTEGER NOT NULL UNIQUE,
    club_name VARCHAR(200) NOT NULL,
    club_description TEXT,
    meeting_date TIMESTAMP,
    meeting_location VARCHAR(200),
    event_type VARCHAR(50),
    max_participants INTEGER,
    registration_required BOOLEAN DEFAULT FALSE,
    
    FOREIGN KEY (announcement_id) REFERENCES "GeneralAnnouncement"(announcement_id) ON DELETE CASCADE,
    
    CONSTRAINT chk_event_type CHECK (event_type IN ('meeting', 'workshop', 'seminar', 'social', 'competition', 'other'))
);

-- ================================================================
-- 8. IMAGE TABLOSU (Multiple Images per Announcement)
-- ================================================================

CREATE TABLE "Image" (
    image_id SERIAL PRIMARY KEY,
    announcement_id INTEGER NOT NULL,
    image_url TEXT NOT NULL,
    image_order INTEGER DEFAULT 0,
    caption TEXT,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (announcement_id) REFERENCES "GeneralAnnouncement"(announcement_id) ON DELETE CASCADE
);

CREATE INDEX idx_image_announcement ON "Image"(announcement_id);

-- ================================================================
-- 9. COMMENT TABLOSU (Yorumlar)
-- ================================================================

CREATE TABLE "Comment" (
    comment_id SERIAL PRIMARY KEY,
    announcement_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    parent_comment_id INTEGER,
    content TEXT NOT NULL,
    date_posted TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_updated TIMESTAMP,
    is_edited BOOLEAN DEFAULT FALSE,
    
    FOREIGN KEY (announcement_id) REFERENCES "GeneralAnnouncement"(announcement_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES "User"(user_id) ON DELETE CASCADE,
    FOREIGN KEY (parent_comment_id) REFERENCES "Comment"(comment_id) ON DELETE CASCADE
);

CREATE INDEX idx_comment_announcement ON "Comment"(announcement_id);
CREATE INDEX idx_comment_user ON "Comment"(user_id);
CREATE INDEX idx_comment_parent ON "Comment"(parent_comment_id);
CREATE INDEX idx_comment_date ON "Comment"(date_posted DESC);

-- ================================================================
-- 10. LIKE TABLOSU (Beğeniler)
-- ================================================================

CREATE TABLE "Like" (
    like_id SERIAL PRIMARY KEY,
    announcement_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    date_liked TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (announcement_id) REFERENCES "GeneralAnnouncement"(announcement_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES "User"(user_id) ON DELETE CASCADE,
    
    CONSTRAINT uk_like_announcement_user UNIQUE (announcement_id, user_id)
);

CREATE INDEX idx_like_announcement ON "Like"(announcement_id);
CREATE INDEX idx_like_user ON "Like"(user_id);

-- ================================================================
-- 11. MESSAGE TABLOSU (Mesajlaşma)
-- ================================================================

CREATE TABLE "Message" (
    message_id SERIAL PRIMARY KEY,
    sender_id INTEGER NOT NULL,
    receiver_id INTEGER NOT NULL,
    content TEXT NOT NULL,
    date_sent TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    
    FOREIGN KEY (sender_id) REFERENCES "User"(user_id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES "User"(user_id) ON DELETE CASCADE,
    
    CONSTRAINT chk_different_users CHECK (sender_id != receiver_id)
);

CREATE INDEX idx_message_sender ON "Message"(sender_id);
CREATE INDEX idx_message_receiver ON "Message"(receiver_id);
CREATE INDEX idx_message_date ON "Message"(date_sent DESC);
CREATE INDEX idx_message_read ON "Message"(is_read);

-- ================================================================
-- ÖRNEK VERİLER
-- ================================================================

-- Kullanıcılar (şifre: password123 - bcrypt hash)
INSERT INTO "User" (name, surname, email, password, city, university, department, class) VALUES
('Admin', 'User', 'admin@mavisiteproje.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Ankara', 'Gazi Üniversitesi', 'Bilgisayar Mühendisliği', '4'),
('Ahmet', 'Yılmaz', 'ahmet@ogrenci.edu.tr', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Ankara', 'Gazi Üniversitesi', 'Bilgisayar Mühendisliği', '3'),
('Ayşe', 'Demir', 'ayse@ogrenci.edu.tr', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'İstanbul', 'İTÜ', 'Endüstri Mühendisliği', '2'),
('Mehmet', 'Kaya', 'mehmet@akademik.edu.tr', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Ankara', 'Gazi Üniversitesi', 'Bilgisayar Mühendisliği', 'Öğretim Görevlisi'),
('Zeynep', 'Şahin', 'zeynep@ogrenci.edu.tr', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Ankara', 'Gazi Üniversitesi', 'Bilgisayar Mühendisliği', '4');

-- Kullanıcı Rolleri
INSERT INTO "UserRole" (user_id, role_id) VALUES
(1, 3), -- Admin
(2, 1), -- Student
(3, 1), -- Student
(4, 2), -- Teacher
(5, 1), -- Student
(5, 5); -- Club President

-- Genel Duyurular
INSERT INTO "GeneralAnnouncement" (title, content, announcement_type, category_id, user_id, city, university) VALUES
('Vize Sınav Takvimi Açıklandı', 'Güz dönemi vize sınav takvimi açıklanmıştır. Sınavlar 15 Kasım''da başlayacaktır.', 'general', 1, 4, 'Ankara', 'Gazi Üniversitesi'),
('Bahar Şenliği 2025', 'Kampüsümüzde 15 Mayıs''ta bahar şenliği düzenlenecektir. Tüm öğrenciler davetlidir!', 'general', 2, 1, 'Ankara', 'Gazi Üniversitesi'),
('Web Geliştirme Projesi Ekip Arkadaşı Aranıyor', 'React ve Node.js ile proje geliştireceğiz. İlgilenenlere DM!', 'project', 5, 2, 'Ankara', 'Gazi Üniversitesi'),
('Yazılım Kulübü Toplantısı', 'Bu hafta Çarşamba 18:00''de toplantımız var. AI konusunu işleyeceğiz.', 'club', 3, 5, 'Ankara', 'Gazi Üniversitesi'),
('Kampüsler Arası Futbol Turnuvası', 'Kayıtlar başladı! Son kayıt tarihi: 30 Kasım', 'general', 4, 1, 'İstanbul', 'İTÜ');

-- Proje Duyuru Detayları
INSERT INTO "ProjectAnnouncement" (announcement_id, project_name, project_description, start_date, end_date, team_size, required_skills, project_status) VALUES
(3, 'E-Ticaret Platformu', 'Öğrenciler için ikinci el kitap satış platformu', '2025-11-01', '2026-01-15', 4, ARRAY['React', 'Node.js', 'PostgreSQL', 'Docker'], 'open');

-- Kulüp Duyuru Detayları
INSERT INTO "ClubAnnouncement" (announcement_id, club_name, club_description, meeting_date, meeting_location, event_type, max_participants, registration_required) VALUES
(4, 'Yazılım Kulübü', 'Yazılım geliştirme ve teknoloji konularında etkinlikler düzenleyen kulüp', '2025-11-06 18:00:00', 'Mühendislik Fakültesi A102', 'workshop', 30, TRUE);

-- Resimler
INSERT INTO "Image" (announcement_id, image_url, image_order, caption) VALUES
(2, 'https://example.com/images/bahar-senligi-1.jpg', 1, 'Geçen yılki şenlikten görüntüler'),
(2, 'https://example.com/images/bahar-senligi-2.jpg', 2, 'Sahne gösterisi'),
(4, 'https://example.com/images/yazilim-kulubu.jpg', 1, 'Kulüp logosu');

-- Yorumlar
INSERT INTO "Comment" (announcement_id, user_id, parent_comment_id, content) VALUES
(1, 2, NULL, 'Sınav takvimi için teşekkürler!'),
(1, 3, NULL, 'Hangi dersler var?'),
(1, 4, 2, 'Tüm dersler sisteme yüklenmiştir, kontrol edebilirsiniz.'),
(2, 2, NULL, 'Harika! Kesinlikle geleceğim 🎉'),
(3, 3, NULL, 'React biliyorum, katılabilir miyim?'),
(3, 2, 5, 'Tabii ki! DM at konuşalım.'),
(4, 2, NULL, 'AI konusu çok ilginç, kayıt nasıl oluyor?'),
(4, 5, 7, 'Kulüp başkanı olarak seni ekledim, toplantıda görüşürüz!');

-- Beğeniler
INSERT INTO "Like" (announcement_id, user_id) VALUES
(1, 2), (1, 3), (1, 5),
(2, 2), (2, 3), (2, 4), (2, 5),
(3, 3), (3, 5),
(4, 2), (4, 3), (4, 5),
(5, 2), (5, 5);

-- Mesajlar
INSERT INTO "Message" (sender_id, receiver_id, content, is_read) VALUES
(3, 2, 'Merhaba, proje için iletişime geçmek istiyorum.', TRUE),
(2, 3, 'Merhaba! Tabii, ne zaman müsaitsin?', TRUE),
(3, 2, 'Yarın öğlen kampüste buluşabilir miyiz?', FALSE),
(2, 5, 'Kulüp toplantısına kayıt olmak istiyorum.', TRUE),
(5, 2, 'Harika! Seni listeye ekledim.', FALSE);

-- ================================================================
-- VİEW''LAR (API için hazır sorgular)
-- ================================================================

-- 1. Tüm duyuruları detaylı göster
CREATE OR REPLACE VIEW announcement_details AS
SELECT 
    ga.announcement_id,
    ga.title,
    ga.content,
    ga.announcement_type,
    ga.city,
    ga.university,
    ga.date_posted,
    ga.views_count,
    ga.is_pinned,
    c.category_name,
    u.name || ' ' || u.surname AS author_name,
    u.email AS author_email,
    u.profile_photo AS author_photo,
    COUNT(DISTINCT l.like_id) AS like_count,
    COUNT(DISTINCT com.comment_id) AS comment_count,
    COALESCE(
        json_agg(
            DISTINCT jsonb_build_object(
                'image_id', i.image_id,
                'image_url', i.image_url,
                'caption', i.caption
            )
        ) FILTER (WHERE i.image_id IS NOT NULL),
        '[]'
    ) AS images
FROM "GeneralAnnouncement" ga
LEFT JOIN "User" u ON ga.user_id = u.user_id
LEFT JOIN "Category" c ON ga.category_id = c.category_id
LEFT JOIN "Like" l ON ga.announcement_id = l.announcement_id
LEFT JOIN "Comment" com ON ga.announcement_id = com.announcement_id
LEFT JOIN "Image" i ON ga.announcement_id = i.announcement_id
GROUP BY ga.announcement_id, u.user_id, c.category_id;

-- 2. Proje duyuruları detaylı
CREATE OR REPLACE VIEW project_announcement_details AS
SELECT 
    ad.*,
    pa.project_name,
    pa.project_description,
    pa.start_date,
    pa.end_date,
    pa.team_size,
    pa.required_skills,
    pa.project_status
FROM announcement_details ad
JOIN "ProjectAnnouncement" pa ON ad.announcement_id = pa.announcement_id;

-- 3. Kulüp duyuruları detaylı
CREATE OR REPLACE VIEW club_announcement_details AS
SELECT 
    ad.*,
    ca.club_name,
    ca.club_description,
    ca.meeting_date,
    ca.meeting_location,
    ca.event_type,
    ca.max_participants,
    ca.registration_required
FROM announcement_details ad
JOIN "ClubAnnouncement" ca ON ad.announcement_id = ca.announcement_id;

-- 4. Kullanıcı rolleri
CREATE OR REPLACE VIEW user_with_roles AS
SELECT 
    u.user_id,
    u.name || ' ' || u.surname AS full_name,
    u.email,
    u.university,
    u.department,
    u.profile_photo,
    u.registration_date,
    ARRAY_AGG(r.role_name) AS roles
FROM "User" u
LEFT JOIN "UserRole" ur ON u.user_id = ur.user_id
LEFT JOIN "Role" r ON ur.role_id = r.role_id
GROUP BY u.user_id;

-- 5. Kullanıcı istatistikleri
CREATE OR REPLACE VIEW user_statistics AS
SELECT 
    u.user_id,
    u.name || ' ' || u.surname AS full_name,
    u.email,
    COUNT(DISTINCT ga.announcement_id) AS announcement_count,
    COUNT(DISTINCT c.comment_id) AS comment_count,
    COUNT(DISTINCT l.like_id) AS likes_given
FROM "User" u
LEFT JOIN "GeneralAnnouncement" ga ON u.user_id = ga.user_id
LEFT JOIN "Comment" c ON u.user_id = c.user_id
LEFT JOIN "Like" l ON u.user_id = l.user_id
GROUP BY u.user_id;

-- ================================================================
-- VERİTABANI BAŞARIYLA OLUŞTURULDU
-- ================================================================

SELECT 
    'Veritabanı başarıyla oluşturuldu!' AS status,
    (SELECT COUNT(*) FROM "User") AS user_count,
    (SELECT COUNT(*) FROM "Category") AS category_count,
    (SELECT COUNT(*) FROM "GeneralAnnouncement") AS announcement_count,
    (SELECT COUNT(*) FROM "ProjectAnnouncement") AS project_count,
    (SELECT COUNT(*) FROM "ClubAnnouncement") AS club_count,
    (SELECT COUNT(*) FROM "Comment") AS comment_count,
    (SELECT COUNT(*) FROM "Message") AS message_count;