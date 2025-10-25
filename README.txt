# 🎓 Mavi Site Projesi - Database

Üniversite kampüslerindeki duyuruları, proje ilanlarını, kulüp etkinliklerini ve mesajlaşmayı yönetmek için PostgreSQL veritabanı.

## 📋 Veritabanı Yapısı

### Ana Tablolar

1. **Role** - Kullanıcı rolleri (student, teacher, admin, moderator, club_president)
2. **User** - Kullanıcı yönetimi
3. **UserRole** - User-Role many-to-many ilişkisi
4. **Category** - Duyuru kategorileri (Akademik, Etkinlik, Kulüp, Spor, Kariyer, Sosyal, Genel)
5. **GeneralAnnouncement** - Ana duyuru tablosu (inheritance parent)
6. **ProjectAnnouncement** - Proje duyuruları (inheritance child)
7. **ClubAnnouncement** - Kulüp duyuruları (inheritance child)
8. **Image** - Duyuru resimleri (multiple images per announcement)
9. **Comment** - Yorumlar (nested/iç içe yorum desteği)
10. **Like** - Beğeni sistemi
11. **Message** - Kullanıcılar arası mesajlaşma

### Özellikler

✅ **Kullanıcı Rolleri**: Ayrı tablo, many-to-many ilişki  
✅ **Inheritance Yapısı**: GeneralAnnouncement → ProjectAnnouncement/ClubAnnouncement  
✅ **Multiple Images**: Her duyuruya birden fazla resim  
✅ **İç İçe Yorumlar**: Yorumlara cevap verme  
✅ **Mesajlaşma**: Kullanıcılar arası direkt mesaj  
✅ **View'lar**: API için hazır sorgular  

## 🚀 Kurulum

### Gereksinimler
- Docker Desktop yüklü olmalı

### Adımlar

1. **Repository'yi klonlayın:**
   ```bash
   git clone https://github.com/borabln/mavisiteproje.git
   cd mavisiteproje
   ```

2. **Docker Desktop'ı başlatın**

3. **Container'ları başlatın:**
   ```bash
   docker-compose up -d
   ```

4. **Kurulumu kontrol edin:**
   ```bash
   docker ps
   ```
   İki container görmelisiniz: `university_postgres` ve `university_pgadmin`

## 🔌 Bağlantı Bilgileri

### Backend için PostgreSQL Bağlantısı

```
Host: localhost (local development)
Port: 5432
Database: mavisiteproje
Username: borabln
Password: 20333039362aA_
```

### docker-compose içinde (Backend container'ından):

```
Host: database (veya postgres)
Port: 5432
Database: mavisiteproje
Username: borabln
Password: 20333039362aA_
```

### Connection String Örnekleri

**Node.js (pg):**
```javascript
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'mavisiteproje',
  user: process.env.DB_USER || 'borabln',
  password: process.env.DB_PASSWORD
});
```

**Python (psycopg2):**
```python
import psycopg2
import os

conn = psycopg2.connect(
    host=os.getenv('DB_HOST', 'localhost'),
    port=os.getenv('DB_PORT', '5432'),
    database=os.getenv('DB_NAME', 'mavisiteproje'),
    user=os.getenv('DB_USER', 'borabln'),
    password=os.getenv('DB_PASSWORD')
)
```

## 🎨 pgAdmin Web Arayüzü

### Erişim
Tarayıcıdan: **http://localhost:5050**

### Giriş Bilgileri
- **Email:** bulunbora@gmail.com
- **Password:** 20333039362aA_

### Sunucu Ekleme

1. Sol tarafta "Servers" üzerine sağ tıklayın
2. **Register** → **Server**
3. **General** sekmesi:
   - Name: `Mavi Site DB`
4. **Connection** sekmesi:
   - Host name/address: `postgres` (dikkat: localhost değil!)
   - Port: `5432`
   - Maintenance database: `mavisiteproje`
   - Username: `borabln`
   - Password: `20333039362aA_`
5. **Save** butonuna tıklayın

### Tabloları Görüntüleme
Servers → Mavi Site DB → Databases → mavisiteproje → Schemas → public → Tables

## 📊 Veritabanı Şeması Detayları

### Inheritance Yapısı

```
GeneralAnnouncement (parent)
├── ProjectAnnouncement (child) - Proje duyuruları için ek alanlar
└── ClubAnnouncement (child) - Kulüp duyuruları için ek alanlar
```

**GeneralAnnouncement** tüm duyuruları tutar, `announcement_type` ile ayırt edilir:
- `general` - Genel duyurular
- `project` - Proje duyuruları (ProjectAnnouncement'ta detaylar)
- `club` - Kulüp duyuruları (ClubAnnouncement'ta detaylar)

### Hazır View'lar (API için)

1. **announcement_details** - Tüm duyuruları beğeni/yorum sayıları ve resimlerle
2. **project_announcement_details** - Proje duyuruları detaylı
3. **club_announcement_details** - Kulüp duyuruları detaylı
4. **user_with_roles** - Kullanıcılar rolleriyle
5. **user_statistics** - Kullanıcı istatistikleri

## 📊 Örnek Sorgular

### En Çok Beğenilen Duyurular
```sql
SELECT 
    announcement_id,
    title,
    announcement_type,
    author_name,
    like_count,
    comment_count
FROM announcement_details 
ORDER BY like_count DESC 
LIMIT 10;
```

### Proje Duyuruları
```sql
SELECT 
    title,
    project_name,
    project_status,
    team_size,
    required_skills,
    like_count
FROM project_announcement_details
WHERE project_status = 'open'
ORDER BY date_posted DESC;
```

### Kulüp Etkinlikleri
```sql
SELECT 
    title,
    club_name,
    meeting_date,
    meeting_location,
    event_type,
    max_participants
FROM club_announcement_details
WHERE meeting_date > NOW()
ORDER BY meeting_date ASC;
```

### Kullanıcı Rolleri
```sql
SELECT 
    full_name,
    email,
    roles
FROM user_with_roles
WHERE 'admin' = ANY(roles);
```

### Son 7 Günün Duyuruları
```sql
SELECT 
    ga.title,
    ga.announcement_type,
    c.category_name,
    u.name || ' ' || u.surname AS author,
    ga.date_posted
FROM "GeneralAnnouncement" ga
JOIN "User" u ON ga.user_id = u.user_id
JOIN "Category" c ON ga.category_id = c.category_id
WHERE ga.date_posted >= NOW() - INTERVAL '7 days'
ORDER BY ga.date_posted DESC;
```

## 👥 Test Kullanıcıları

| Email | Şifre | Roller |
|-------|-------|--------|
| admin@mavisiteproje.com | password123 | admin |
| ahmet@ogrenci.edu.tr | password123 | student |
| ayse@ogrenci.edu.tr | password123 | student |
| mehmet@akademik.edu.tr | password123 | teacher |
| zeynep@ogrenci.edu.tr | password123 | student, club_president |

*Not: Şifreler bcrypt ile hashlenmiştir ($2a$10$...). Backend'de bcrypt.compare() kullanın.*

## 🛠️ Yararlı Komutlar

```bash
# Container'ları başlat
docker-compose up -d

# Container'ları durdur
docker-compose stop

# Container'ları yeniden başlat
docker-compose restart

# Logları görüntüle
docker-compose logs -f

# Sadece database logları
docker-compose logs -f postgres

# Veritabanını sıfırla (DİKKAT: Tüm veriler silinir!)
docker-compose down -v
docker-compose up -d

# Container'ların durumunu kontrol et
docker ps

# PostgreSQL container'ına bağlan
docker exec -it university_postgres psql -U borabln -d mavisiteproje

# Backup al
docker exec university_postgres pg_dump -U borabln mavisiteproje > backup.sql

# Backup'tan geri yükle
cat backup.sql | docker exec -i university_postgres psql -U borabln -d mavisiteproje
```

## 🔧 Sorun Giderme

### Port 5432 zaten kullanılıyor
Bilgisayarınızda zaten PostgreSQL yüklüyse, `docker-compose.yml` dosyasında port numarasını değiştirin:
```yaml
ports:
  - "5433:5432"  # Sol tarafı değiştir
```

### Container başlamıyor
```bash
# Logları kontrol edin
docker-compose logs postgres

# Container'ları tamamen temizleyin
docker-compose down -v
docker-compose up -d
```

### pgAdmin'e bağlanamıyorum
- Host olarak `localhost` değil `postgres` yazın
- Container'ların çalıştığından emin olun: `docker ps`
- Şifreleri doğru girdiğinizden emin olun

## 📱 API Endpoint Önerileri

Backend geliştirirken bu endpointleri oluşturabilirsiniz:

### Authentication
- `POST /api/auth/register` - Kayıt ol
- `POST /api/auth/login` - Giriş yap
- `POST /api/auth/logout` - Çıkış yap
- `GET /api/auth/me` - Mevcut kullanıcı bilgisi

### Duyurular (General)
- `GET /api/announcements` - Tüm duyuruları listele (pagination, filter)
- `GET /api/announcements/:id` - Tek duyuru detayı
- `POST /api/announcements` - Yeni duyuru oluştur
- `PUT /api/announcements/:id` - Duyuru güncelle
- `DELETE /api/announcements/:id` - Duyuru sil
- `POST /api/announcements/:id/like` - Beğen/beğeniyi kaldır
- `GET /api/announcements/:id/comments` - Yorumları getir
- `POST /api/announcements/:id/comments` - Yorum ekle

### Proje Duyuruları
- `GET /api/projects` - Tüm proje duyuruları
- `GET /api/projects/:id` - Proje detayı
- `POST /api/projects` - Yeni proje duyurusu
- `PUT /api/projects/:id` - Proje güncelle

### Kulüp Duyuruları
- `GET /api/clubs` - Tüm kulüp duyuruları
- `GET /api/clubs/:id` - Kulüp etkinliği detayı
- `POST /api/clubs` - Yeni kulüp duyurusu
- `PUT /api/clubs/:id` - Kulüp duyurusu güncelle

### Kategoriler
- `GET /api/categories` - Tüm kategoriler

### Kullanıcılar
- `GET /api/users/:id` - Kullanıcı profili
- `PUT /api/users/:id` - Profil güncelle
- `GET /api/users/:id/announcements` - Kullanıcının duyuruları
- `GET /api/users/:id/statistics` - Kullanıcı istatistikleri

### Mesajlar
- `GET /api/messages` - Mesaj listesi
- `GET /api/messages/conversations/:userId` - Bir kullanıcıyla konuşma
- `POST /api/messages` - Mesaj gönder
- `PUT /api/messages/:id/read` - Okundu işaretle

### Resimler
- `POST /api/images/upload` - Resim yükle
- `DELETE /api/images/:id` - Resim sil

## 🐳 Docker Hub

Database image:
```bash
docker pull borablun/mavisiteproje-db:latest
# veya
docker pull borablun/mavisiteproje-db:v2.0
```
---

**Geliştirici:** Bora (@borabln)  
**Tarih:** 26 Ekim 2025  
**Versiyon:** 2.0