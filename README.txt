# 🎓 Üniversite Duyuru Sistemi - Veritabanı

Üniversite kampüslerindeki duyuruları, etkinlikleri ve ikinci el ürün satışlarını yönetmek için PostgreSQL veritabanı.

## 📋 Veritabanı Yapısı

### Ana Tablolar

1. **User** - Kullanıcı yönetimi (öğrenci, öğretmen, admin)
2. **Category** - Duyuru kategorileri (Akademik, Etkinlik, Kulüp, vs.)
3. **Proclamation** - Duyurular ve ilanlar
4. **Liker** - Duyuru beğeni sistemi
5. **ProclamationComment** - Duyuru yorumları (iç içe yorum desteği)
6. **Product** - İkinci el ürün satış sistemi
7. **ProductComment** - Ürün yorumları ve fiyat teklifleri
8. **Message** - Kullanıcılar arası mesajlaşma

### Özellikler

✅ **Kullanıcı Rolleri**: student, teacher, admin, moderator  
✅ **Kategori Sistemi**: Renkli ve ikonlu kategoriler  
✅ **Beğeni Sistemi**: Duyuruları beğenme  
✅ **İç İçe Yorumlar**: Yorumlara cevap verme  
✅ **Mesajlaşma**: Kullanıcılar arası direkt mesaj  
✅ **Ürün Satış**: İkinci el ürün pazarı  
✅ **Fiyat Teklifi**: Ürünlere yorum ile teklif verme  
✅ **View'lar**: Hazır istatistik sorguları

## 🚀 Kurulum

### Gereksinimler
- Docker Desktop yüklü olmalı

### Adımlar

1. **Bu dosyaları bir klasöre koyun:**
   - `docker-compose.yml`
   - `init.sql`
   - `README.md`

2. **Docker Desktop'ı başlatın**

3. **Terminali/Komut istemini açın ve klasöre gidin:**
   ```bash
   cd masaustu/proje-klasoru
   ```

4. **Docker container'ları başlatın:**
   ```bash
   docker-compose up -d
   ```

5. **Kurulumu kontrol edin:**
   ```bash
   docker ps
   ```
   İki container görmelisiniz: `university_postgres` ve `university_pgadmin`

## 🔌 Bağlantı Bilgileri

### Backend için PostgreSQL Bağlantısı

```
Host: localhost
Port: 5432
Database: university_announcements
Username: universite_admin
Password: GuvenliSifre2025!
```

### Connection String Örnekleri

**Node.js (pg):**
```javascript
const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'university_announcements',
  user: 'postgres',
  password: 'universite123'
});
```

**Python (psycopg2):**
```python
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    port=5432,
    database="university_announcements",
    user="postgres",
    password="universite123"
)
```

**Java (JDBC):**
```java
String url = "jdbc:postgresql://localhost:5432/university_announcements";
String user = "postgres";
String password = "universite123";

Connection conn = DriverManager.getConnection(url, user, password);
```

## 🎨 pgAdmin Web Arayüzü

### Erişim
Tarayıcıdan şu adrese gidin: **http://localhost:5050**

### Giriş Bilgileri
- **Email:** admin@universite.com
- **Password:** admin123

### Sunucu Ekleme

1. Sol tarafta "Servers" üzerine sağ tıklayın
2. **Register** → **Server**
3. **General** sekmesi:
   - Name: `Universite DB`
4. **Connection** sekmesi:
   - Host name/address: `postgres` (dikkat: localhost değil!)
   - Port: `5432`
   - Maintenance database: `university_announcements`
   - Username: `postgres`
   - Password: `universite123`
5. **Save** butonuna tıklayın

### Tabloları Görüntüleme
Servers → Universite DB → Databases → university_announcements → Schemas → public → Tables

## 📊 Örnek Sorgular

### En Çok Beğenilen Duyurular
```sql
SELECT * FROM proclamation_with_likes 
ORDER BY like_count DESC 
LIMIT 10;
```

### Kullanıcı İstatistikleri
```sql
SELECT * FROM user_statistics 
ORDER BY proclamation_count DESC;
```

### Son 7 Günün Duyuruları
```sql
SELECT 
    p.title,
    c.category_name,
    u.name || ' ' || u.surname AS author,
    p.date_posted
FROM "Proclamation" p
JOIN "User" u ON p.user_id = u.user_id
JOIN "Category" c ON p.category_id = c.category_id
WHERE p.date_posted >= NOW() - INTERVAL '7 days'
ORDER BY p.date_posted DESC;
```

### Kategorilere Göre Duyuru Sayısı
```sql
SELECT 
    c.category_name,
    COUNT(p.proclamation_id) AS announcement_count
FROM "Category" c
LEFT JOIN "Proclamation" p ON c.category_id = p.category_id
GROUP BY c.category_id
ORDER BY announcement_count DESC;
```

## 👥 Test Kullanıcıları

| Email | Şifre | Role |
|-------|-------|------|
| admin@universite.com | password | admin |
| ahmet@ogrenci.com | password | student |
| ayse@ogrenci.com | password | student |
| mehmet@ogretmen.com | password | teacher |

*Not: Şifreler bcrypt ile hashlenmiştir ($2a$10$...). Test için "password" şifresini kullanabilirsiniz.*

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

# Veritabanını sıfırla (DİKKAT: Tüm veriler silinir!)
docker-compose down -v
docker-compose up -d

# Container'ların durumunu kontrol et
docker ps

# PostgreSQL container'ına bağlan
docker exec -it university_postgres psql -U postgres -d university_announcements
```

## 🔧 Sorun Giderme

### Port 5432 zaten kullanılıyor
Bilgisayarınızda zaten PostgreSQL yüklüyse, `docker-compose.yml` dosyasında port numarasını değiştirin:
```yaml
ports:
  - "5433:5432"  # 5433 yerine başka bir port kullanın
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
- Birkaç saniye bekleyin, container'lar başlatılırken zaman alabilir

## 📱 Mobil/Web Uygulama İçin API Endpointleri Önerileri

Projenizi geliştirirken bu endpointleri oluşturabilirsiniz:

### Duyurular
- `GET /api/proclamations` - Tüm duyuruları listele
- `GET /api/proclamations/:id` - Tek duyuru detayı
- `POST /api/proclamations` - Yeni duyuru oluştur
- `PUT /api/proclamations/:id` - Duyuru güncelle
- `DELETE /api/proclamations/:id` - Duyuru sil
- `POST /api/proclamations/:id/like` - Duyuru beğen
- `POST /api/proclamations/:id/comments` - Yorum ekle

### Kategoriler
- `GET /api/categories` - Tüm kategoriler

### Kullanıcılar
- `POST /api/auth/register` - Kayıt ol
- `POST /api/auth/login` - Giriş yap
- `GET /api/users/:id` - Kullanıcı profili

### Ürünler
- `GET /api/products` - Tüm ürünler
- `POST /api/products` - Yeni ürün ekle
- `POST /api/products/:id/offer` - Fiyat teklifi yap

### Mesajlar
- `GET /api/messages` - Mesajlarım
- `POST /api/messages` - Mesaj gönder
- `PUT /api/messages/:id/read` - Mesajı okundu olarak işaretle

## 📞 Destek

Sorunlarınız için:
1. GitHub Issues kullanın
2. Ekip içi Slack/Discord kanalına yazın
3. README.md dosyasını güncel tutun

---

**Hazırlayan:** Proje Ekibi  
**Tarih:** Ekim 2025  
**Versiyon:** 1.0