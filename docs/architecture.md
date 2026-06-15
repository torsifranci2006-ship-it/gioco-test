# Architettura

## Tre livelli disaccoppiati

```
┌─────────────┐     ┌──────────────────────────┐     ┌────────────────────┐
│   Dati      │ --> │   Core / Engine          │ --> │   Presentazione    │
│  (JSON)     │     │   (GDScript, UI-agnostic)│     │   (UI Godot)       │
│  data/      │     │   src/core, src/models   │     │   src/ui, scenes/  │
└─────────────┘     └──────────────────────────┘     └────────────────────┘
                          │  emette segnali  ▲ chiama metodi
                          ▼ (EventBus)       │ (StoryEngine.choose)
```

- **Dati**: tutto il contenuto narrativo in JSON (`data/`). Vedi `data-schema.md`.
- **Core**: motore generico che carica i dati, valuta condizioni, applica effetti, gestisce le
  transizioni di scena e risolve i finali. **Non conosce la UI** e **non contiene contenuti
  narrativi**.
- **Presentazione**: scene/script Godot che mostrano testo e scelte. Implementazione futura.

### Regola di disaccoppiamento

- Il Core comunica i cambiamenti **solo via segnali** (`EventBus`) ed espone lo stato in
  **sola lettura**.
- La UI **non muta mai** lo stato: chiama `StoryEngine.choose(choice_id)` (tramite la facciata
  `Game`) e reagisce ai segnali.
- Conseguenza: il Core è testabile in headless senza alcuna UI; la UI è sostituibile.

## Componenti del Core (`src/core/`)

| File | Ruolo |
| --- | --- |
| `data_loader.gd` | Carica/parsa i JSON in modelli tipizzati |
| `game_state.gd` | Stato runtime: attributi, personaggi, flag, cronologia |
| `condition_evaluator.gd` | Valuta il DSL Condizione contro lo stato |
| `effect_applier.gd` | Applica il DSL Effetto allo stato |
| `story_engine.gd` | API principale: `setup/start/current_scene/available_choices/choose` |
| `ending_resolver.gd` | Sceglie il ramo finale e compone gli epiloghi |
| `save_system.gd` | Serializza/deserializza solo lo stato |

Modelli tipizzati in `src/models/`: `StoryScene`, `Choice`, `GameCharacter`, `Ending`.

## Autoload (`src/autoload/`)

- `EventBus` — segnali globali: `scene_changed`, `attribute_changed`, `character_state_changed`,
  `game_ended`.
- `Game` — facciata: istanzia il Core, espone `new_game()` e `choose()`. Punto d'ingresso per la UI.

## Flusso runtime

1. `Game._ready()` crea lo `StoryEngine` e chiama `setup()` (carica dati + inizializza stato).
2. `Game.new_game()` → `StoryEngine.start()` → carica la `scena_iniziale` → emette `scene_changed`.
3. La UI mostra il testo (frammenti filtrati per condizione) e le `available_choices()`.
4. L'utente sceglie → `Game.choose(id)` → `StoryEngine.choose(id)`:
   - `EffectApplier.apply()` muta lo stato (attributi, flag, stati personaggi) ed emette i segnali;
   - rivaluta le `regole_stato` dei personaggi (transizioni automatiche);
   - se `prossima == id_scena_finale` → `EndingResolver` calcola il ramo + epiloghi → `game_ended`;
   - altrimenti carica la scena successiva → `scene_changed`.

## Perché questa architettura

- **Anti-esplosione combinatoria**: grafo di scene con convergenze + condizioni/varianti, invece
  di rami duplicati. Vedi `scenes.md`.
- **Manutenibilità per team piccolo**: aggiungere contenuto = editare JSON; il codice resta stabile
  e minimale.
- **Testabilità**: il Core gira headless; i contenuti si validano contro `schemas/`.
