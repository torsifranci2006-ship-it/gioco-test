# Finali

## Struttura

**Due rami principali**. La storia converge su una scena di **rivelazione della verità centrale**,
seguita da una scena di **decisione finale**. Il risultato dipende da:

1. la **decisione finale** (quale scelta prende il giocatore), e
2. gli **attributi accumulati** (e lo stato dei personaggi) durante il gioco.

La ricchezza percepita non viene da molti finali, ma da **epiloghi condizionati** che variano la
chiusura in base allo stato — senza moltiplicare i rami.

## Configurazione

File: `data/endings/endings.json` (schema: `schemas/ending.schema.json`). Esattamente **2 rami**.

Ogni ramo:

| Campo | Note |
| --- | --- |
| `id`, `titolo`, `testo` | identità e testo principale del finale |
| `requisiti.decisione_finale` | id della scelta finale che indirizza a questo ramo |
| `requisiti.condizione` | condizione aggiuntiva su attributi/stato (null = nessuna) |
| `epiloghi` | array di `{ contenuto, condizione }`: frammenti di chiusura aggiunti se la condizione è vera |

## Risoluzione

`ending_resolver.gd`:

1. riceve l'id della scelta presa nella scena di decisione finale + il `GameState`;
2. seleziona il ramo con `decisione_finale` corrispondente e `condizione` soddisfatta;
3. compone il `testo` del ramo + tutti gli `epiloghi` la cui condizione è vera (es. sorte di Mara,
   soglia di `legame`);
4. l'engine emette `EventBus.game_ended(ending_id)`.

## Come innescare il finale dai dati

La scena di decisione finale usa scelte con `prossima: "finale"` (l'`id_scena_finale` in
`data/config/game.json`). Quando una scelta punta lì, lo `StoryEngine` invoca l'`EndingResolver`
invece di caricare un'altra scena.

## Linee guida di design

- I due rami devono rappresentare una **scelta tematica netta** rispetto alla verità centrale
  (es. accettarla vs rifiutarla).
- Usare gli epiloghi per dare conseguenze tangibili ad attributi e morti/ferite dei personaggi.
- Evitare di aggiungere un terzo ramo: per nuove sfumature, preferire un nuovo epilogo condizionato.
