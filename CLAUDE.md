# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Cos'è questo progetto

Gioco **narrativo interattivo** in **Godot 4.x / GDScript**, fortemente basato sulle scelte.
Un solo protagonista; le scelte modificano **attributi nascosti**; molti percorsi che
**convergono verso 2 finali principali**. Esiste una **verità centrale** rivelata nel finale,
dopo la quale il giocatore compie una **decisione finale**; il risultato dipende da
**decisione finale + attributi accumulati**. Personaggi secondari chiave hanno stato
`normale | ferito | morto` che cambia supporto, scene e informazioni disponibili.

**Stato attuale: prima versione giocabile.** Il core narrativo è implementato e guidato dai dati
JSON; esiste una UI minima in Godot (`scenes/main.tscn` + `src/ui/main.gd`) impostata come
`run/main_scene`. Mancano contenuti narrativi completi e rifinitura grafica.

## Regola architetturale fondamentale (NON violare)

**Nessuna logica narrativa è hardcoded nel codice.** Scene, scelte, condizioni, effetti,
stati dei personaggi, attributi e finali vivono **esclusivamente nei dati JSON** sotto `data/`.
Gli script in `src/` sono un **motore generico**: caricano dati, valutano condizioni, applicano
effetti, gestiscono transizioni. Non devono mai contenere un id di scena/personaggio, un testo
narrativo o una soglia di attributo specifici della storia. Aggiungere contenuto = modificare
JSON, mai GDScript.

## Architettura a 3 livelli (disaccoppiati)

```
Dati (JSON, data/)  →  Core / Engine (GDScript UI-agnostic, src/core)  →  Presentazione (UI Godot, src/ui + scenes/)
```

- **Core** non conosce la UI. Comunica i cambiamenti **solo via segnali** (`EventBus`) ed
  espone lo stato in **sola lettura**.
- **La UI non muta mai lo stato direttamente.** Chiama metodi del motore (es.
  `StoryEngine.choose(choice_id)`) e reagisce ai segnali. Questo mantiene il Core testabile
  headless e la UI sostituibile.
- `Game` (autoload) è la facciata che istanzia e collega il Core; è il punto d'ingresso per la UI.

Flusso runtime: `Game.start()` → `StoryEngine` carica la scena → emette `scene_changed` →
la UI mostra testo e scelte → utente sceglie → `StoryEngine.choose(id)` applica effetti
(`EffectApplier`), filtra le scelte (`ConditionEvaluator`), avanza → all'ultimo nodo
`EndingResolver` calcola il finale → `game_ended`.

## DSL dei dati (riusato ovunque)

Due strutture JSON, valutate/applicate dal Core, ricorrono in scene, scelte, personaggi e finali:

- **Condizione** (valutata da `condition_evaluator.gd`): `attributo {id, op, valore}`,
  `flag {id, presente}`, `personaggio {id, stato}`, `relazione {id, op, valore}`, e i
  combinatori `tutte` (AND), `alcune` (OR), `non` (NOT). `op` ∈ `>= <= == > <`.
- **Effetto** (applicato da `effect_applier.gd`): `attributi [{id, delta}]`, `flag_set [id]`,
  `flag_clear [id]`, `personaggio_stato [{id, stato}]`, `relazione [{id, delta}]`.

Schema completo e autorevole: `schemas/*.schema.json` + `docs/data-schema.md`.

## Principio anti-esplosione combinatoria

Le scene sono un **grafo con convergenze**, non rami separati duplicati. Le differenze tra
percorsi si esprimono con **condizioni** (soglie di attributo, flag, stato personaggi) e
**varianti di testo condizionate dentro la stessa scena** (`testo: [{contenuto, condizione}]`),
non creando nuove scene. I 2 finali principali si arricchiscono con **epiloghi condizionati**
da attributi e sopravvivenza dei personaggi, non moltiplicando i finali.

## Dove vivono le cose

| Cosa | Percorso |
| --- | --- |
| Config attributi nascosti / gioco | `data/config/` |
| Personaggi chiave | `data/characters/characters.json` |
| Scene narrative | `data/story/<atto>/<scena>.json` |
| Finali (2 rami + epiloghi) | `data/endings/endings.json` |
| Schemi di validazione | `schemas/*.schema.json` |
| Motore generico (UI-agnostic) | `src/core/` |
| Modelli dati tipizzati | `src/models/` |
| Singleton globali | `src/autoload/` (`EventBus`, `Game`) |
| UI Godot (minima) | `src/ui/main.gd` + `scenes/main.tscn` (vedi `docs/ui.md`) |
| Test headless (futuri) | `tests/` |
| Documentazione di design | `docs/` |

> Attenzione al naming: contenuti narrativi in `data/story/`; le **scene Godot (.tscn)** in `scenes/`.

## Convenzioni

- Gli `id` (attributi, personaggi, scene, scelte) sono `snake_case` e univoci nel loro dominio.
- Ogni nuovo JSON di contenuto deve **validare contro il suo schema** e mantenere la coerenza
  incrociata: ogni `prossima`/`scene_id` punta a una scena esistente; ogni `id` referenziato in
  una condizione/effetto esiste nel config corrispondente.
- GDScript: tipizzazione statica (`var x: int`), `class_name` per i modelli, segnali per la
  comunicazione verso l'esterno. Mantenere gli script **minimali** — niente over-engineering;
  il progetto deve restare gestibile da un piccolo team o sviluppatore singolo.
- Lingua dei contenuti e dei commenti: italiano.

## Comandi

Il progetto si apre in **Godot 4.x** (editor). Comandi utili da terminale (richiedono Godot nel PATH):

```bash
# Aprire l'editor sul progetto
godot --editor --path .

# Avvio headless (per controllare che gli script compilino senza errori)
godot --headless --path . --quit

# Test/debug del core narrativo (headless, nessuna UI): esce con codice 0 se tutto OK
godot --headless --path . -s res://tests/run_core_test.gd
```

Il runner `tests/run_core_test.gd` istanzia direttamente lo `StoryEngine` (non dipende dagli
autoload) ed esercita: scena iniziale, scelte, gating per attributi, effetti, cambio scena,
risoluzione dei due finali con epiloghi, e salvataggio/caricamento.

La `main_scene` è impostata in `project.godot` su `res://scenes/main.tscn` (UI minima, vedi `docs/ui.md`).
