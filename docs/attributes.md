# Sistema degli attributi nascosti

## Obiettivo

Gli attributi sono assi numerici **nascosti** al giocatore. Le scelte li modificano nel tempo;
il loro valore accumulato influenza la disponibilità di scelte/scene e, soprattutto, il **ramo
finale e gli epiloghi**. Sono il meccanismo che permette di avere molti percorsi che convergono,
senza duplicare la narrazione.

## Configurazione

File: `data/config/attributes.json` (schema: `schemas/attributes.schema.json`).

Ogni attributo:

| Campo | Tipo | Note |
| --- | --- | --- |
| `id` | string | univoco, `snake_case` |
| `nome` | string | etichetta leggibile |
| `descrizione` | string | nota di design |
| `min` / `max` | int | i valori vengono mantenuti (clamp) in `[min, max]` |
| `default` | int | valore iniziale |
| `nascosto` | bool | sempre `true` per design |

## Template iniziale (4 assi, modificabili)

- **empatia** — guida verso la cura degli altri.
- **pragmatismo** — efficacia e calcolo rispetto al sentimento.
- **determinazione** — spinta a perseguire l'obiettivo nonostante rischi/ostacoli.
- **legame** — vicinanza complessiva ai personaggi chiave.

> Tenere il set **ristretto** (≈3-5 assi). Pochi assi ben scelti danno molta varietà di
> combinazioni rimanendo gestibili per un team piccolo.

## Come vengono modificati e letti

- **Modifica**: tramite il DSL Effetto (`attributi: [{id, delta}]`) negli `effetti` di una scelta o
  nell'`on_enter` di una scena. L'engine applica il delta e fa il clamp in `[min, max]`.
- **Lettura**: tramite il DSL Condizione (`attributo: {id, op, valore}`) per gating di
  scelte/scene e per la selezione del ramo finale.

## Linee guida di design

- Evitare attributi ridondanti (se due assi si muovono sempre insieme, sono uno solo).
- Usare soglie chiare (es. `>= 50`) per i punti di svolta; documentarle vicino al contenuto.
- Gli attributi non vanno mai mostrati direttamente; al massimo se ne riflette l'effetto nel testo
  tramite varianti condizionate.
