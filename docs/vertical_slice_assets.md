# Vertical Slice — Asset attesi

Struttura predisposta per ospitare i 3 asset del primo vertical slice visivo.
Finché i PNG reali non sono presenti, **la scena di test non va creata** (vedi nota in fondo).

## 1. Nomi esatti dei file attesi
- `assets/backgrounds/bg_auto_notte.png`
- `assets/characters/daniel/char_daniel_caldo.png`
- `assets/characters/daniel/char_daniel_freddo.png`

## 2. Risoluzioni attese
- `bg_auto_notte.png` → **1920x1080** (senza alpha)
- `char_daniel_caldo.png` → **circa 1000x1500, con alpha**
- `char_daniel_freddo.png` → **circa 1000x1500, con alpha**

## 3. Regole importanti
- `char_daniel_caldo.png` e `char_daniel_freddo.png` devono avere lo **stesso bounding box**;
- **stesso ancoraggio**;
- **stesso crop**;
- **sfondo trasparente** (alpha pulito sui ritratti);
- **nessun testo / watermark / firma** nelle immagini.

> Conseguenza: caldo e freddo devono potersi scambiare in engine **senza spostare la figura**. Differiscono solo per luce/grading ed espressione (stessa identità di Daniel).

## 4. Procedura per aggiungere gli asset
1. Copiare i PNG nelle cartelle corrette (vedi §1).
2. `git add assets/ docs/vertical_slice_assets.md`
3. `git commit -m "Add vertical slice asset placeholders"`
4. `git push`
5. Su Windows: `git pull`
6. Aprire Godot e lasciare che importi automaticamente gli asset (si genereranno i `.import`).

## 5. Nota
Finché i PNG reali non sono presenti, **la scena di test non va ancora creata**. Le cartelle contengono `.gdkeep` solo per essere tracciate da Git; `art_src/` ha un `.gdignore` (Godot la ignora) ed è destinata ai sorgenti a layer (.kra/.psd), non agli export.
