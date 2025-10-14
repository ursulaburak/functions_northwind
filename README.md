# Northwind PostgreSQL Fonksiyonları

## Amaç
Bu proje, Northwind veritabanı üzerinde PostgreSQL fonksiyonlarını uygulamalı olarak öğrenmek için geliştirilmiştir. 10 farklı fonksiyon ile veritabanı işlemleri, hesaplamalar ve raporlama işlevleri gerçekleştirilmiştir.

## Tasarım Kararları

### Dil Seçimleri
- **SQL**: Basit sorgular ve toplam işlemleri için
- **PL/pgSQL**: Koşullu mantık ve değişken ihtiyacı olan durumlar için

### NULL Yönetimi
- `COALESCE` fonksiyonu ile NULL değerler kontrol edilmiştir
- Olmayan kayıtlar için uygun varsayılan değerler döndürülmüştür (0 veya NULL)

### Performans Optimizasyonu
- İndeksli sütunlar üzerinde filtreleme yapılmıştır
- Gereksiz JOIN'lerden kaçınılmıştır
- Aggregate fonksiyonlar etkin şekilde kullanılmıştır

## Köşe Durumları (Corner Cases)
1. **Olmayan ID'ler**: Tüm fonksiyonlar geçersiz ID'ler için uygun şekilde davranır
2. **NULL tarihler**: Tarih parametreleri NULL olduğunda tüm zaman aralığı kabul edilir
3. **Boş sonuç setleri**: Boş veri için uygun dönüş değerleri sağlanır
4. **Stok hesaplamaları**: UnitsOnOrder NULL ise 0 olarak kabul edilir

## Test Stratejisi
Her fonksiyon için en az iki test senaryosu:
- Normal çalışma durumu
- Sınır/edge case durumu (olmayan kayıt, boş veri vb.)

## Kullanım
SQL dosyasını PostgreSQL'de çalıştırarak tüm fonksiyonları oluşturabilirsiniz. Test çağrılarını yorum satırlarından kaldırarak fonksiyonları test edebilirsiniz.
