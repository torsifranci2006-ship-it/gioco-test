# Scene, scelte, condizioni ed effetti

## Modello mentale

Le scene formano un **grafo orientato con convergenze**, non alberi di rami separati. La varietà
nasce da:

1. **Condizioni** che mostrano/nascondono/abilitano scelte e gating delle scene.
2. **Varianti di testo condizionate** dentro la stessa scena (niente scene duplicate).
3. **Effetti** che modificano attributi/flag/stato personaggi e quindi i percorsi futuri.

Questo è il cuore della strategia **anti-esplosione combinatoria**: molti stati, poche scene.

## Scena

File: `data/story/<atto>/<scena>.json` (schema: `schemas/scene.schema.json`).

| Campo | Note |
| --- | --- |
| `id` | univoco tra tutte le scene |
| `titolo`, `atto` | metadati |
| `precondizioni` | condizione di ingresso (null = sempre) |
| `testo` | array di `{ contenuto, personaggio?, condizione }`; i frammenti appaiono in ordine se la condizione è vera |
| `on_enter` | Effetto applicato all'ingresso (null = nessuno) |
| `scelte` | array di Choice |
| `prossima_default` | per scene senza scelte: avanzamento automatico |

## Scelta (Choice)

| Campo | Note |
| --- | --- |
| `id` | univoco nella scena |
| `testo` | etichetta mostrata |
| `visibile_se` | se falsa → **nascosta** |
| `abilitata_se` | se falsa → **mostrata disabilitata** + `motivo_blocco` |
| `motivo_blocco` | testo del perché è bloccata |
| `effetti` | Effetto applicato alla selezione |
| `prossima` | id scena successiva, oppure `"finale"` per innescare la risoluzione del finale |

> Distinzione importante: *nascosta* (il giocatore non la vede) vs *disabilitata* (la vede, capisce
> che le manca qualcosa). Usare il blocco per comunicare l'effetto degli attributi/stati senza
> svelarli.

## DSL Condizione

Schema: `schemas/condition.schema.json`. Valutata da `condition_evaluator.gd`. Una condizione
vuota/null è **sempre vera**.

| Chiave | Significato |
| --- | --- |
| `attributo {id, op, valore}` | confronto su un attributo (`op` ∈ `>= <= == > <`) |
| `flag {id, presente}` | presenza/assenza di un flag |
| `personaggio {id, stato}` | stato di un personaggio |
| `relazione {id, op, valore}` | confronto sul valore di relazione |
| `ferita {id, campo, op, valore}` | confronto su `rischio`/`scene` di un ferito (falsa se non ferito) |
| `tutte [...]` | AND |
| `alcune [...]` | OR |
| `non {...}` | NOT |

## DSL Effetto

Schema: `schemas/effect.schema.json`. Applicato da `effect_applier.gd`.

| Chiave | Significato |
| --- | --- |
| `attributi [{id, delta}]` | somma `delta` (con clamp `min/max`) |
| `flag_set [id]` / `flag_clear [id]` | imposta/rimuove flag |
| `personaggio_stato [{id, stato}]` | forza lo stato di un personaggio |
| `cura [id]` | tenta la cura dei feriti indicati (riesce se `rischio <= soglia_cura`, altrimenti morte) |
| `relazione [{id, delta}]` | modifica la relazione |

Dopo ogni effetto l'engine rivaluta le `regole_stato` dei personaggi. La progressione del rischio
delle ferite (e l'eventuale morte automatica) avviene invece solo al **cambio di scena**, non
all'applicazione di un effetto: vedi `characters.md`.

## Flag = informazioni/conoscenza

I flag rappresentano soprattutto **informazioni scoperte** ("indizio_verita_1") e snodi di trama.
Sono il modo principale per ricordare cosa il giocatore sa, e per condizionare la rivelazione della
verità centrale.

## Linee guida di design

- Preferire **convergenze**: dopo un bivio, far rientrare i percorsi in una scena comune con testo
  variante, invece di mantenere due catene parallele.
- Coerenza incrociata: ogni `prossima`/`scene_id` deve puntare a una scena esistente; ogni `id`
  citato in condizioni/effetti deve esistere nei rispettivi config.
