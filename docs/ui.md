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
├── TitleOverlay (VBoxContainer, centro-destra, v-centrato; visibile solo a menu/pausa)
│   ├── TitleLine1 (Label, "CIÒ CHE RESTA", font 64, avorio/ottone, ombra+outline)
│   └── TitleLine2 (Label, "NEL BUIO", font 64, avorio/ottone, ombra+outline)
├── TopBar (PanelContainer, in alto; visibile solo in gioco)
│   └── TopBarMargin (MarginContainer)
│       └── Controls (HBoxContainer)
│           ├── MenuButton (Button, "Menu")     # torna al menu/pausa
│           ├── DossierButton (Button, "Dossier")  # apre il Dossier personaggi (overlay)
│           └── Status (Label)                  # messaggi ed errori (allineati a dx)
├── BottomArea (VBoxContainer, in basso, cresce verso l'alto; nascosta a menu)
│   ├── TextPanel (PanelContainer)             # textbox noir, bordo sottile, angoli arrotondati
│   │   └── TextMargin (MarginContainer)
│   │       └── SceneText (RichTextLabel)       # testo della scena
│   └── ChoicesPanel (PanelContainer, nascosto se senza scelte)  # menu scelte a piè di pagina
│       └── ChoicesMargin (MarginContainer)
│           └── Choices (HFlowContainer)        # pulsanti scelta a runtime, affiancati + a-capo
├── EndingPanel (Control, full screen, nascosto)   # schermata finale cinematografica (no box-finestra)
│   ├── EndingScrim (ColorRect, α0.72)             # scurisce il background, che resta visibile dietro
│   └── EndingMargin (MarginContainer) → EndingVBox (VBoxContainer, testo centrato)
│       ├── EndingGameTitle1 (Label, "CIÒ CHE RESTA", font 60, ottone, ombra+outline)
│       ├── EndingGameTitle2 (Label, "NEL BUIO", font 60, ottone, ombra+outline)
│       ├── EndingTitle (Label)                     # sottotitolo = ending.titolo (runtime)
│       ├── EndingHeading (Label, "EPILOGO")
│       ├── EndingText (RichTextLabel, centrato, scrollabile)  # ending.testo + epiloghi (invariati)
│       └── EndingNewGameButton (Button, "Torna al menu" -> _enter_menu)
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
├── SaveConfirm (PanelContainer, centrato, nascosto)  # conferma nuovo/sovrascrittura (sb_ending)
│   └── SaveConfirmMargin → SaveConfirmVBox
│       ├── SaveConfirmLabel (Label, testo dinamico)
│       └── SaveConfirmButtons (HBoxContainer)
│           ├── SaveConfirmYesButton (Button, "Conferma" -> Game.save_slot)
│           └── SaveConfirmNoButton (Button, "Annulla" -> SavePanel)
└── DossierPanel (PanelContainer, sidebar destra ~400px, dalla TopBar al bordo sup. di BottomArea, nascosto)  # "Dossier" personaggi (sb_ending)
    └── DossierMargin → DossierVBox
        ├── DossierTitle (Label, "Dossier")
        ├── DossierBody (VBoxContainer)               # impilato verticalmente nella sidebar stretta
        │   ├── DossierListScroll (ScrollContainer) → DossierList (VBox)  # lista compatta in alto: un Button per personaggio
        │   └── DossierDetails (VBoxContainer)         # dettagli sotto: nome/stato/supporto/ferita/relazione del selezionato
        └── DossierCloseButton (Button, "Chiudi" -> nasconde la sidebar)
```

> Stile gestito **solo** con nodi standard e `StyleBoxFlat`/`Theme` (nessun plugin, nessun asset UI).
> Tutti i pannelli usano `StyleBoxFlat` scuri semi-trasparenti con bordo sottile in tono ottone; gli
> overlay centrati (`ExitConfirm`, `LoadPanel`, `SavePanel`, `SaveConfirm`) riusano `sb_ending`.

### Stati della UI

Gli stati sono gestiti in `src/ui/main.gd` da `_enter_menu()` / `_enter_game()` più gli overlay
(`EndingPanel`, `ExitConfirm`, `LoadPanel`, `SavePanel`, `SaveConfirm`). Nessuno tocca lo stato del
motore narrativo.

Il **titolo del gioco** (`TitleOverlay`, nodo separato a destra del menu) è visibile **esattamente
quando lo è `StartMenu`**: menu iniziale e pausa lo mostrano; gioco e tutti gli overlay (Carica,
Salva, Esci, Dossier) lo nascondono. La sincronizzazione è centralizzata: ogni cambio di visibilità
dello `StartMenu` passa per l'helper `_set_menu_screen_visible(v)`, che imposta insieme
`StartMenu` e `TitleOverlay` (unica fonte di verità, niente disallineamenti).

| Stato | StartMenu | TopBar | BottomArea | Overlay attivo |
| --- | --- | --- | --- | --- |
| **Menu** | visibile | nascosto | nascosto | — |
| **Gioco** | nascosto | visibile | visibile | — |
| **Conferma uscita** | nascosto | nascosto | nascosto | `ExitConfirm` |
| **Carica** | nascosto | nascosto | nascosto | `LoadPanel` |
| **Salva** | nascosto | nascosto | nascosto | `SavePanel` (+ `SaveConfirm`) |
| **Dossier** | nascosto | **visibile** | **visibile** | `DossierPanel` (sidebar destra, la partita resta visibile dietro) |

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

### Dossier personaggi

Il pulsante **Dossier** nella `TopBar` (in gioco) apre una **sidebar a destra** (`DossierPanel`,
larghezza ~400px, stile `sb_ending`) con i personaggi **già incontrati**: lista compatta in alto,
dettagli sotto, pulsante **Chiudi** in basso. La sidebar occupa **solo l'area scena**: parte sotto la
`TopBar` (`offset_top=48`) e termina esattamente sul **bordo superiore di `BottomArea`**, così
`TextPanel` e `ChoicesPanel` restano **sempre completamente visibili** (la sidebar non li copre mai).
La sidebar **non nasconde** `TopBar`/`BottomArea`: la partita (background, ritratto, testo) resta
visibile dietro e ai lati.

- **Allineamento dinamico:** `BottomArea` è ancorata in basso e cresce verso l'alto; la sua altezza
  varia con testo e scelte. La UI tiene il bordo inferiore della sidebar allineato leggendo l'altezza
  reale (`_sync_dossier_height` → `DossierPanel.offset_bottom = -_bottom_area.size.y`), agganciata al
  segnale `BottomArea.resized` (copre cambi di contenuto **e** di risoluzione/finestra) e richiamata
  all'apertura. Il valore `offset_bottom` nel `.tscn` è solo un fallback per editor/primo frame.
- **Apri** = `_on_open_dossier` (allinea, popola, mostra); **Chiudi** = `_on_dossier_close` (nasconde
  il pannello, senza toccare lo stato del motore). La UI ottiene i dati **solo** da
  `Game.met_characters()`; non legge JSON né stato interno.

- **"Incontrato"** è derivato dal Core (`StoryEngine.met_characters`) incrociando `history` (scene
  visitate) con `StoryScene.visual.portrait`, risolto al personaggio con la convenzione generica
  `char_<id>` / `char_<id>_<variante>`. I ritratti senza `GameCharacter` corrispondente (es.
  `char_halloran`, `char_voss`) **non compaiono**, senza liste di esclusione hardcoded.
- **Nessuno spoiler.** Il Core espone per ogni personaggio solo: `nome`, `stato`, `supporto`,
  `ferita` (bool), `relazione_fascia` (codice neutro) e `relazione_value` (valore reale int). **Non**
  escono `descrizione` né attributi nascosti. Il **numero** di relazione non è mai mostrato come testo
  al giocatore: serve solo ad alimentare la barra visiva.
- **Fasce di relazione** (codice neutro dal Core → etichetta tradotta dalla UI): `< 0` →
  `diffidente`, `0..24` → `neutrale`, `25..49` → `fiducia`, `>= 50` → `alleato`. Le etichette
  leggibili (e quelle di `stato`/`supporto`) vivono nella UI (`RELAZIONE_BAND_LABEL`, `STATO_LABEL`,
  `SUPPORTO_LABEL`), coerentemente con la regola di disaccoppiamento.
- **Layout per-statistica con barre.** Il dettaglio mostra `Nome`, poi `Stato:`
  (Normale/Ferito/Morto), quindi tre blocchi **etichetta + barra** (`_make_stat_block`), ognuno con la
  `ProgressBar` noir **subito sotto** la propria etichetta (nessuna barra unica in fondo). Tutte le
  barre: `min_value=0`, `max_value=100`, `show_percentage=false`, stile dal `Theme` radice
  (`ProgressBar/styles/background`+`fill`). Mappe dei valori (0–100):
  - **Supporto** (`SUPPORTO_BAR`, UI): `pieno=100`, `limitato=50`, `nessuno=0`.
  - **Relazione**: valore **reale** dal Core (`relazione_value`, non clampato); è la UI a fare
    `value = clampi(relazione_value, 0, 100)` solo a fini grafici. La fascia testuale
    (Diffidente/Neutrale/Fiducia/Alleato) resta sopra la barra.
  - **Ferite** (`FERITE_BAR`/`FERITE_LABEL`, UI, derivata da `stato`): `normale`→"Nessuna"`=100`,
    `ferito`→"Ferito"`=50`, `morto`→"Morto"`=0`.
  - Nessun numero/percentuale è mai visibile al giocatore.

### Overlay cambiamenti dopo scelta

Dopo ogni scelta che produce effetti **diretti**, un piccolo overlay noir (`ChangesOverlay`) appare
**in alto a destra** (sotto la `TopBar`) per ~2.5s, poi sparisce da solo (`ChangesTimer`, `one_shot`).
Mostra **solo la direzione**, mai numeri.

- **Dato dal Core:** `StoryEngine.choose()` fa uno snapshot **prima** di applicare `chosen.effetti`,
  applica, poi calcola il diff (attributi, relazione, stato personaggi) e — **dopo** `scene_changed`,
  mai sul finale — emette `EventBus.choice_effects_applied(changes)`. Il diff è preso **solo** intorno
  agli effetti diretti della scelta (esclude `on_enter` e morte-da-ferita della scena d'arrivo).
- **Contenuto spoiler-free:** ogni voce è già pronta per la UI con nome visualizzato + direzione/stato.
  Righe rese: `Nome: Ferito/Morto/Normale` (cambi di stato), `Fiducia <Nome> ↑/↓` (relazione),
  `<Attributo> ↑/↓` (attributi nascosti — **solo direzione**, mai il valore). **Nessun flag** è mostrato
  (in v1 non c'è metadata anti-spoiler sui flag). Ordine e taglio a **max 5 righe**: stati → relazioni
  → attributi (deciso nel Core in `_build_changes`). Frecce colorate noir (verde tenue ↑ / ruggine ↓).
- **Disaccoppiamento:** la UI (`_on_choice_effects`/`_make_change_label`) fa **solo** rendering e
  auto-hide; non conosce id interni (i nomi arrivano dal Core; le etichette di stato riusano
  `STATO_LABEL`).

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
- `game_ended(ending_id)` → mostra `EndingPanel`;
- `choice_effects_applied(changes)` → mostra l'overlay cambiamenti in alto a destra (vedi sopra).

I segnali `attribute_changed` e `character_state_changed` non sono usati direttamente dalla UI (i
cambiamenti rilevanti arrivano già aggregati e spoiler-free via `choice_effects_applied`).

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
5. **Finale** → `game_ended` → `_show_ending()` mostra `EndingPanel` (schermata cinematografica):
   nasconde `TopBar`/`BottomArea`, scurisce il background con `EndingScrim`, e impagina titolo-gioco +
   `ending.titolo` + "EPILOGO" + testo (`ending.testo` + epiloghi, **invariati**, centrati via bbcode
   `[center]` e scrollabili se lunghi). "Torna al menu" chiama `_enter_menu()` (non avvia una partita).
   La UI di gioco è ripristinata da `_enter_menu`/`_enter_game`.
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
