# Sistem Rod: Stat Lengkap + Kepemilikan Pemain

## Tujuan
Setiap rod punya 3 stat: **Luck %** (peluang ikan rarity tinggi), **Speed %** (mempercepat reel), **Weight kg** (batas berat ikan yang bisa ditarik). Pemain baru gratis **Starter Rod**; rod lain harus dibeli pakai coins, dan pemain bisa ganti-ganti rod yang dipakai.

## Stat tiap rod (angka awal, bisa dikoreksi)

| Rod | Luck | Speed | Weight | Harga (coins) |
|---|---|---|---|---|
| Starter | 0% | 0% | 10 kg | Gratis |
| Uncommon | 5% | 10% | 40 kg | 500 |
| Rare | 12% | 20% | 100 kg | 2.000 |
| Epic | 22% | 35% | 250 kg | 8.000 |
| Legendary | 35% | 50% | 600 kg | 25.000 |
| Mythic | 50% | 70% | 1.500 kg | 80.000 |

Cara kerja stat:
- **Luck %**: menaikkan bobot rarity rare/epic/legendary/mythic sebesar persentase itu saat roll tangkapan.
- **Speed %**: durasi reel dikurangi persentase itu (dasar 1.5 detik, monster 5.5 detik).
- **Weight**: ikan dengan berat minimum di atas batas rod tidak bisa tertangkap (seperti sistem cap sekarang).

## Perubahan database (migrasi)
- Tabel `rod_tiers`: tambah kolom `luck_percent`, `speed_percent`, `price_coins`; isi 6 rod sesuai tabel.
- Tabel baru `player_rods`: daftar rod yang dimiliki tiap pemain (wallet + rod id + flag `equipped`).
- Fungsi database: `buy_rod(wallet, rod_id)` — cek coins, potong saldo, tambah rod; `equip_rod(wallet, rod_id)` — tandai rod aktif; starter rod otomatis diberikan saat profil baru dibuat (trigger/insert default).
- RLS + GRANT sesuai standar; pemain hanya bisa membaca/mengubah rod miliknya lewat fungsi server.

## Perubahan game
- `fishRules.ts`: `RodTier` dapat field luck/speed/price; fallback data diperbarui.
- `useGameStore.ts` / `Angler.tsx`: rollFish memakai luck rod; durasi reel di Angler dipercepat oleh speed rod; weight cap pakai rod yang equipped (bukan `ACTIVE_ROD_TIER` konstan).
- Store baru `useRodStore`: daftar rod milik pemain + rod aktif, refresh setelah beli/equip.
- Shop (NPC Marlo atau toko terpisah): daftar rod dijual dengan harga & stat, tombol beli (nonaktif jika coins kurang / sudah dimiliki), tombol pakai rod.
- Hotbar/HUD: tampilkan rod aktif beserta statnya.

## Verifikasi
- Cek build OK, lalu uji di preview: pemain baru dapat Starter Rod, beli rod mengurangi coins, ganti rod mengubah kecepatan reel dan batas berat.
