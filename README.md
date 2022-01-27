# Güncellenebilir Kontratlar

Yaygın olan güncelleme kalıplarının açıklama ve örnekleriyle yer aldığı repo.
Testler için [Forge](https://onbjerg.github.io/foundry-book/index.html) kullanıldı.

<br>


## Önemli Not
Repodaki hiçbir kod prodüksiyona hazır değildir ve bilgi vermek amacıyla yazılmıştır.
`Simplified.sol` dosyaları doğrudan çalışması amacıyla değil (çoğu çalışmaz) pattern'ı
basitleştirmek ve notları tutmak amacıyla yazılmıştır.

<br>


## Klasör Düzeni
```
src
|
|-> EIP897
|   Standard proxy pattern'ı 
|
|-> EIP1822
|   Universal Upgradeable Proxy pattern'ı
|
|-> EIP2535
|   Diamond Proxy
|
|-> Beacons
|   Proxy subscription pattern'ı
|
|-> EternalStorage
|   OpenZeppelin'in kullandığı EternalStorage pattern'ı
|
|-> TransparentProxy
|   OpenZeppelin'in transparent proxy'si (EIP1538 ile alakalı değil)
|
|-> Minimal Proxy
|   Minimal proxy pattern'ının açıklaması ve bytecode incelemesi
|
|-> Considerations
|   Upgradeable kontratlarla ilgili dikkate alınması gereken unsurlar
|
|-> test
    Implementasyonların feature testleri
```

<br>


## PR Formatı
İstediğiniz gibi forklayabilir, PR yapabilirsiniz.

Eğer örneği verilmiş bir pattern'ın implementasyonunu yapacaksanız
`test/` klasörü altında testini yazmayı ihmal etmeyin.