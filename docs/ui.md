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

Layout in stile visual novel/noir: sfondo e ritratto a tutto schermo, testo sopra e scelte a piè
di pagina in pannelli ancorati in basso. Una **schermata iniziale** (`StartMenu`, menu verticale a
sinistra) appare prima della partita; in gioco la sostituisce una **barra comandi discreta**
(`TopBar`) in alto. Il nodo radice `Main` porta un `Theme` (sub-resource) che stila i pulsanti —
inclusi quelli **generati a runtime** — con `StyleBoxFlat` (normale/hover/pressed/disabled).

```
Main (Control)                         [script: src/ui/main.gd; theme: noir]
├── Background (TextureRect)            # sfondo a tutto schermo (dietro a tutto)
├── Character (TextureRect)             # ritratto sopra il background
├── Scrim (ColorRect, α0.40)           # velo scuro leggero per la leggibilità
├── StartMenu (PanelContainer, sinistra, v-centrato)  # menu iniziale (pre-partita e su "Menu")
│   └── StartMenuMargin (MarginContainer)
│       └── StartMenuVBox (VBoxContainer)
│           ├── StartResumeButton                      # "Riprendi" (disabilitato finché non si gioca)
│           ├── StartNewGameButton / StartLoadButton   # pulsanti grandi 260×56
│           ├── StartSaveButton                        # disabilitato finché non si gioca
│           ├── StartExitButton                        # "Esci" -> conferma
│           └── StartStatus (Label)                    # feedback pre-partita
├── TopBar (PanelContainer, in alto; visibile solo in gioco)
│   └── TopBarMargin (MarginContainer)
│       └── Controls (HBoxContainer)
│           ├── NewGameButton / SaveButton / LoadButton / MenuButton  # controlli discreti
│           └── Status (Label)                  # messaggi ed errori (allineati a dx)
├── BottomArea (VBoxContainer, in basso, cresce verso l'alto; nascosta a menu)
│   ├── TextPanel (PanelContainer)             # textbox noir, bordo sottile, angoli arrotondati
│   │   └── TextMargin (MarginContainer)
│   │       └── SceneText (RichTextLabel)       # testo della scena
│   └── ChoicesPanel (PanelContainer, nascosto se senza scelte)  # menu scelte a piè di pagina
│       └── ChoicesMargin (MarginContainer)
│           └── Choices (HFlowContainer)        # pulsanti scelta a runtime, affiancati + a-capo
├── EndingPanel (PanelContainer, nascosto)         # schermata finale (overlay, StyleBoxFlat)
│   └── EndingMargin (MarginContainer)
│       └── EndingVBox (VBoxContainer)
│           ├── EndingTitle (Label)
│           ├── EndingText (RichTextLabel)          # testo finale + epiloghi
│           └── EndingNewGameButton (Button)
├── ExitConfirm (PanelContainer, centrato, nascosto)  # conferma uscita (overlay, sb_ending)
│   └── ExitMargin (MarginContainer)
│       └── ExitVBox (VBoxContainer)
│           ├── ExitLabel (Label, "Vuoi davvero uscire?")
│           └── ExitButtons (HBoxContainer)
│               ├── ExitConfirmButton (Button, "Conferma" -> get_tree().quit())
│               └── ExitCancelButton (Button, "Annulla" -> torna al menu)
├── LoadPanel (PanelContainer, centrato, nascosto)   # "Carica partita" (overlay, sb_ending)
│   └── LoadMargin → LoadVBox
│       ├── LoadTitle (Label, "Carica partita")
│       ├── LoadScroll (ScrollContainer) → LoadList (VBoxContainer)  # righe a runtime, clic = carica
│       └── LoadCancelButton (Button, "Annulla" -> origine)
├── SavePanel (PanelContainer, centrato, nascosto)   # "Salva partita" (overlay, sb_ending)
│   └── SaveMargin → SaveVBox
│       ├── SaveTitle (Label, "Salva partita")
│       ├── SaveNewButton (Button, "Nuovo salvataggio")
│       ├── SaveScroll (ScrollContainer) → SaveList (VBoxContainer)  # slot sovrascrivibili a runtime
│       └── SaveCancelButton (Button, "Annulla" -> origine)
└── SaveConfirm (PanelContainer, centrato, nascosto)  # conferma nuovo/sovrascrittura (sb_ending)
    └── SaveConfirmMargin → SaveConfirmVBox
        ├── SaveConfirmLabel (Label, testo dinamico)
        └── SaveConfirmButtons (HBoxContainer)
            ├── SaveConfirmYesButton (Button, "Conferma" -> Game.save_slot)
            └── SaveConfirmNoButton (Button, "Annulla" -> SavePanel)
```

> Stile gestito **solo** con nodi standard e `StyleBoxFlat`/`Theme` (nessun plugin, nessun asset UI).
> Tutti i pannelli usano `StyleBoxFlat` scuri semi-trasparenti con bordo sottile in tono ottone; gli
> overlay centrati (`ExitConfirm`, `LoadPanel`, `SavePanel`, `SaveConfirm`) riusano `sb_ending`.

### Stati della UI

Gli stati sono gestiti in `src/ui/main.gd` da `_enter_menu()` / `_enter_game()` più gli overlay
(`EndingPanel`, `ExitConfirm`, `LoadPanel`, `SavePanel`, `SaveConfirm`). Nessuno tocca lo stato del
motore narrativo.

| Stato | StartMenu | TopBar | BottomArea | Overlay attivo |
| --- | --- | --- | --- | --- |
| **Menu** | visibile | nascosto | nascosto | — |
| **Gioco** | nascosto | visibile | visibile | — |
| **Conferma uscita** | nascosto | nascosto | nascosto | `ExitConfirm` |
| **Carica** | nascosto | nascosto | nascosto | `LoadPanel` |
| **Salva** | nascosto | nascosto | nascosto | `SavePanel` (+ `SaveConfirm`) |

- **Avvio** → stato Menu; `Salva` disabilitato (nessuna partita); `Riprendi` abilitato **sse esiste
  l'autosave** su disco, altrimenti disabilitato.
- **Nuova Partita / Carica** → `scene_changed` → stato Gioco; `Salva` si abilita.
- **Menu** (in gioco) → **autosalva** e torna allo stato Menu **senza** resettare il motore; così
  `Riprendi` punta sempre all'ultimo stato giocato.
- **Riprendi** (a menu) → **carica l'autosave da disco** ed entra in gioco; non apre liste/pannelli.
- **Esci** → conferma centrale; **Conferma** = `Game.quit_with_autosave()` (autosalva poi esce),
  **Annulla** = torna al menu.
- **Salva / Carica** (da StartMenu *o* TopBar) → aprono `SavePanel`/`LoadPanel`; una variabile
  `_panel_origin` ricorda il contesto, così **Annulla** torna a Menu o a Gioco. I salvataggi **manuali**
  sono slot multipli in `user://saves/save_<N>.json`, elencati per data/ora decrescente; ogni voce mostra
  **titolo scena**, **id scena** e **data/ora**. Creare un nuovo slot o sovrascriverne uno passa da
  `SaveConfirm`.

### Autosave

Esiste **un solo autosave** in `user://autosave.json`, separato dagli slot manuali (`user://saves/`)
e **mai elencato** in `LoadPanel`/`SavePanel` (i pannelli mostrano una nota che lo ricorda). Viene
sovrascritto a ogni uscita: nessuna cronologia.

- **Quando si autosalva** (gestito in `Game`, autoload): premendo **Menu**, su **Esci** confermato
  (`quit_with_autosave`), e alla **chiusura finestra/sessione** via `NOTIFICATION_WM_CLOSE_REQUEST`
  (con `set_auto_accept_quit(false)` in `Game._ready`), più `_exit_tree()` come rete di sicurezza. Un
  flag `_autosave_done_on_exit` evita doppi salvataggi in chiusura.
- `Game.autosave()` non crea nulla se non c'è partita in corso (motore con `state == null`).
- **Riprendi** usa esclusivamente l'autosave: abilitato sse `Game.has_autosave()`; se il file è
  presente ma non valido, il caricamento fallisce con un messaggio e il pulsante viene disabilitato.
- `Carica`/`Salva` lavorano **solo** sugli slot manuali e non toccano mai l'autosave.

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
