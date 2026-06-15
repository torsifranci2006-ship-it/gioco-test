# Riferimento del formato dati

Tutti i contenuti vivono in `data/` come JSON e sono validati dagli schemi in `schemas/`.
Questo documento è la guida di lettura; gli schemi sono la fonte autorevole.

## File e schemi

| Contenuto | File dati | Schema |
| --- | --- | --- |
| Config attributi | `data/config/attributes.json` | `schemas/attributes.schema.json` |
| Config gioco | `data/config/game.json` | — (riferimenti/percorsi) |
| Personaggi | `data/characters/characters.json` | `schemas/character.schema.json` |
| Scene | `data/story/<atto>/<scena>.json` | `schemas/scene.schema.json` |
| Finali | `data/endings/endings.json` | `schemas/ending.schema.json` |
| Condizione (riusata) | embedded | `schemas/condition.schema.json` |
| Effetto (riusato) | embedded | `schemas/effect.schema.json` |

> A livello radice di ogni file dati le chiavi che iniziano con `_` (es. `_commento`) sono note
> per gli autori: ammesse dagli schemi e ignorate dall'engine.

## Condizione (DSL riusato)

```json
{ "tutte": [
    { "attributo": { "id": "determinazione", "op": ">=", "valore": 55 } },
    { "non": { "personaggio": { "id": "veil", "stato": "morto" } } }
] }
```

Operatori `op`: `>= <= == > <`. Combinatori: `tutte` (AND), `alcune` (OR), `non` (NOT).
Condizione vuota/null = sempre vera.

## Effetto (DSL riusato)

```json
{ "attributi": [ { "id": "empatia", "delta": 5 } ],
  "flag_set": [ "indizio_verita_1" ],
  "personaggio_stato": [ { "id": "tobia", "stato": "ferito" } ],
  "cura": [ "tobia" ],
  "relazione": [ { "id": "mara", "delta": 10 } ] }
```

> Sistema ferite: lo stato `ferito` peggiora nel tempo (rischio crescente) e può portare a morte
> automatica **solo al cambio di scena**. Parametri per-personaggio nel blocco `ferita` di
> `characters.json`; cura tramite l'effetto `cura`; lettura via la condizione `ferita`.
> Dettagli in `characters.md`.

## Convenzioni

- `id` in `snake_case`, univoci nel proprio dominio (attributi, personaggi, scene; scelte univoche
  nella scena).
- Coerenza incrociata obbligatoria:
  - ogni `prossima`/`scene_id` punta a una scena esistente (o all'`id_scena_finale`);
  - ogni `id` di attributo/personaggio citato in condizioni/effetti esiste nel relativo config.
- Lingua dei contenuti: italiano.

## Validazione

Gli schemi sono JSON Schema draft-07. Validazione possibile con qualsiasi validatore standard
(es. in CI o con uno script di lint futuro). La validazione **non** è parte del runtime di gioco:
serve in fase di authoring per evitare dati incoerenti.
