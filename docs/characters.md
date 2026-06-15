# Personaggi chiave

## Obiettivo

Pochi **personaggi secondari chiave** (template: 3) il cui **stato** evolve con le scelte e i
valori accumulati, modificando ciò che il giocatore può fare e sapere. Pochi personaggi =
sistema gestibile e impatto narrativo leggibile.

## Stati e supporto

| Stato | Supporto | Effetto sul gioco |
| --- | --- | --- |
| `normale` | pieno | fornisce tutto il proprio aiuto/scene/informazioni |
| `ferito` | limitato | aiuto ridotto; **blocca alcune opportunità** |
| `morto` | nessuno | **rimuove definitivamente** scene, informazioni o aiuti |

Lo `stato` è un dato runtime; il `supporto` è **derivato** dallo stato nel modello
`GameCharacter` (non si scrive nei dati).

## Configurazione

File: `data/characters/characters.json` (schema: `schemas/character.schema.json`).

| Campo | Tipo | Note |
| --- | --- | --- |
| `id` | string | univoco, `snake_case` |
| `nome`, `descrizione` | string | |
| `stato_iniziale` | enum | `normale` \| `ferito` \| `morto` |
| `relazione_iniziale` | int | valore nascosto opzionale |
| `regole_stato` | array | transizioni automatiche `{ quando: <condizione>, diventa: ferito\|morto }` |
| `ferita` | object | parametri della dinamica di ferimento (opzionale; default nel codice) |

## Come cambia lo stato

Due meccanismi, entrambi guidati dai dati:

1. **Esplicito** — un Effetto (`personaggio_stato: [{id, stato}]`) negli `effetti` di una scelta o
   nell'`on_enter` di una scena.
2. **Automatico** — le `regole_stato` del personaggio: dopo ogni applicazione di effetto, l'engine
   valuta le condizioni e applica la transizione (es. relazione sotto soglia → `ferito`). Le
   transizioni sono **monotone** verso il peggioramento (normale → ferito → morto); non si torna
   indietro per design.

## Dinamica della ferita (stato `ferito`)

Lo stato `ferito` non è statico: è una **condizione che peggiora nel tempo** finché non viene
curata o porta alla morte. Tutto è configurabile per-personaggio nel blocco `ferita`:

| Parametro | Significato | Default |
| --- | --- | --- |
| `rischio_iniziale` | rischio di morte all'istante del ferimento | `0` |
| `rischio_per_scena` | quanto aumenta il rischio a **ogni avanzamento di scena** | `10` |
| `soglia_critica` | se `rischio >= soglia_critica` → **morte automatica** | `100` |
| `soglia_cura` | la cura riesce solo se `rischio <= soglia_cura`, altrimenti è troppo tardi | `50` |

### Stato runtime (in `GameState.wounds`)

Quando un personaggio diventa `ferito`, `GameState` apre un record `{ scene, rischio,
rischio_per_scena, soglia_critica, soglia_cura }` (le soglie sono copiate dalla config al momento
del ferimento). Il record viene rimosso quando il personaggio esce da `ferito` (guarisce o muore).
È incluso nel salvataggio.

### Progressione e morte automatica — solo all'avanzamento di scena

**IMPORTANTE:** rischio e morte avanzano **esclusivamente al cambio di scena**, mai mentre il
giocatore resta fermo nella stessa scena (es. rivalutando le scelte). A ogni avanzamento, per ogni
ferito: `scene += 1`, `rischio += rischio_per_scena`; se `rischio >= soglia_critica` il personaggio
muore automaticamente. La morte è **deterministica** (nessun fattore casuale), così il gioco resta
riproducibile e testabile.

### Cura (effetto `cura` nei JSON)

La cura avviene solo tramite un effetto `cura: [<id>...]` definito nei dati (scelta o `on_enter`):

- se il personaggio è `ferito` e `rischio <= soglia_cura` → torna `normale` (record rimosso);
- se `rischio > soglia_cura` → è troppo tardi: il personaggio **muore**;
- se non è ferito → nessun effetto.

### Gating narrativo (condizione `ferita`)

La condizione `ferita: { id, campo: "rischio"|"scene", op, valore }` permette ai JSON di reagire
allo stato della ferita (es. mostrare un testo d'allarme o abilitare una scelta di cura solo quando
il rischio è alto). È falsa se il personaggio non è ferito.

## Come lo stato influenza il gioco

Lo stato è referenziato nelle **condizioni** di scene e scelte:

- `personaggio: {id, stato: "normale"}` per mostrare scene/scelte che richiedono pieno supporto;
- `non: { personaggio: {id, stato: "normale"} }` per varianti quando il personaggio è ferito/morto;
- gli epiloghi dei finali usano lo stato per riflettere la sorte di ciascun personaggio.

## Linee guida di design

- Assegnare a ogni personaggio un ruolo chiaro rispetto alla **verità centrale** e ai finali.
- Le morti devono **chiudere** percorsi in modo riconoscibile (scene/informazioni assenti), non
  solo cambiare testo.
- Mantenere il numero basso: ogni personaggio in più moltiplica le combinazioni da curare.
