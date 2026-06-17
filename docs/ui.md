# UI minima (Fase 3)

Prima versione giocabile. UI volutamente essenziale: tema di default, nessun asset, nessuna
animazione/audio/effetto, nessun plugin.

## Regola di disaccoppiamento

La UI **non** contiene contenuti né logica narrativa, **non** legge i JSON e **non** conosce i
sistemi interni. Comunica esclusivamente con l'autoload `Game` (chiamate) e con `EventBus`
(segnali). Tutto il testo mostrato proviene dal motore; nei file UI compaiono solo etichette
dell'interfaccia ("Nuova Partita", "Salva", "Carica").

## File

| File | Ruolo |
| --- | --- |
| `scenes/main.tscn` | Scena principale (impostata come `run/main_scene`) |
| `src/ui/main.gd` | Script della UI, attaccato al nodo radice `Main` |

## Struttura dei nodi (`main.tscn`)

Layout in stile visual novel/noir: sfondo e ritratto a tutto schermo, testo e scelte in pannelli
ancorati in basso, comandi di sistema in una barra sottile in alto. Il nodo radice `Main` porta un
`Theme` (sub-resource) che stila i pulsanti — inclusi quelli **generati a runtime** — con
`StyleBoxFlat` (normale/hover/pressed/disabled).

```
Main (Control)                         [script: src/ui/main.gd; theme: noir]
├── Background (TextureRect)            # sfondo a tutto schermo (dietro a tutto)
├── Character (TextureRect)             # ritratto sopra il background
├── Scrim (ColorRect, α0.40)           # velo scuro leggero per la leggibilità
├── TopBar (PanelContainer, in alto)   # barra comandi sottile (StyleBoxFlat)
│   └── TopBarMargin (MarginContainer)
│       └── Controls (HBoxContainer)
│           ├── NewGameButton / SaveButton / LoadButton
│           └── Status (Label)                  # messaggi ed errori (allineati a dx)
└── BottomArea (VBoxContainer, in basso, cresce verso l'alto)
    ├── ChoicesPanel (PanelContainer)           # menu scelte SOPRA il testo (StyleBoxFlat)
    │   └── ChoicesMargin (MarginContainer)
    │       └── ChoicesScroll (ScrollContainer)
    │           └── Choices (VBoxContainer)      # pulsanti scelta generati a runtime
    └── TextPanel (PanelContainer)              # textbox noir, bordo sottile, angoli arrotondati
        └── TextMargin (MarginContainer)
            └── SceneText (RichTextLabel)        # testo della scena
EndingPanel (PanelContainer, nascosto)          # schermata finale (overlay, StyleBoxFlat)
└── EndingMargin (MarginContainer)
    └── EndingVBox (VBoxContainer)
        ├── EndingTitle (Label)
        ├── EndingText (RichTextLabel)           # testo finale + epiloghi
        └── EndingNewGameButton (Button)
```

> Stile gestito **solo** con nodi standard e `StyleBoxFlat`/`Theme` (nessun plugin, nessun asset UI).
> I pannelli (`TextPanel`, `ChoicesPanel`, `TopBar`, `EndingPanel`) usano `StyleBoxFlat` scuri
> semi-trasparenti con bordo sottile in tono ottone; i pulsanti hanno hover/pressed visibili.

## Segnali

In ascolto da `EventBus`:
- `scene_changed(scene_id)` → ridisegna testo e scelte;
- `game_ended(ending_id)` → mostra `EndingPanel`.

I segnali `attribute_changed` e `character_state_changed` non sono usati (gli attributi sono
nascosti e lo stato dei personaggi traspare solo dal testo guidato dai dati).

Dai nodi UI: `pressed` dei pulsanti principali, dei pulsanti scelta (via `_on_choice.bind(id)`) e
del pulsante "Nuova Partita" del finale.

## Flusso

1. **Avvio**: gli autoload caricano per primi → `Game._ready()` esegue `setup()`. `Main._ready()`
   connette i segnali; se `Game.is_ready()` è falso mostra l'errore e disabilita i comandi,
   altrimenti invita a premere Nuova Partita. Nessuna partita parte in automatico.
2. **Nuova Partita** → `Game.new_game()` → `scene_changed` → render.
3. **Scelta** → `Game.choose(id)` → il motore avanza → `scene_changed` o `game_ended`.
4. **Render** → `SceneText` = testo corrente; `Choices` ricostruito (pulsanti `disabled` se la
   scelta non è abilitata, con `tooltip` dal motivo di blocco).
5. **Finale** → `game_ended` → `EndingPanel` con titolo, testo ed epiloghi (letti da `Game`).
6. **Salva / Carica** → `Game.save_game()` / `Game.load_game()` (path interno `user://savegame.json`);
   il caricamento emette `scene_changed` e la UI si aggiorna da sola. Esiti e errori in `Status`.

## Livelli visivi data-driven (campo `visual` delle scene)

La UI mostra uno **sfondo** (`Background`) e un **ritratto** (`Character`) dietro al testo, con uno
`Scrim` semitrasparente per la leggibilità. La scelta degli asset è **guidata dai dati**: ogni scena
può avere un campo opzionale `visual` (vedi `schemas/scene.schema.json`), trasportato dal modello
`StoryScene` fino alla UI:

```json
"visual": { "background": "bg_obitorio", "portrait": "char_mara" }
```

`src/ui/main.gd` traduce i **nomi logici** in percorsi tramite due mappe interne (`BG_MAP`,
`PORTRAIT_MAP`). Regole di risoluzione (in `_apply_visual` / `_apply_portrait`):

- **Il metadata `visual` prevale sempre.**
- `visual.background` sconosciuto/assente → fallback `bg_auto_notte.png`.
- `visual.portrait` `null` / `"none"` / `""` → **ritratto nascosto**.
- `visual.portrait` sconosciuto → fallback `char_daniel_caldo`.
- **Scene senza `visual`** (rete di sicurezza: oggi tutte le scene di Atti 1–3 hanno `visual`) →
  fallback completo: `bg_auto_notte.png` + ritratto di default `char_daniel_caldo`. Nessuna
  regola id-based: il campo `visual` di ogni scena determina sempre la presentazione.

> Tutti gli Atti (1–3) hanno asset dedicati e campo `visual`: tutte le chiavi di
> `BG_MAP`/`PORTRAIT_MAP` puntano a file reali e nessun fallback id-based è più in uso.
> Prima della Nuova Partita il `Background` è visibile ma il `Character` resta nascosto.

## Note

- La ricostruzione delle scelte libera i vecchi pulsanti con `queue_free()` (sicuro durante il
  callback del pulsante premuto).
- `Salva`/`Carica` usano un path interno gestito da `Game`: la UI non conosce percorsi di file.
