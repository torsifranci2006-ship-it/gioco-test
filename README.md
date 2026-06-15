# Gioco Narrativo Interattivo (working title)

Gioco narrativo interattivo data-driven realizzato in **Godot 4.x / GDScript**.
Storia fortemente basata sulle scelte, con attributi nascosti, personaggi che possono
ferirsi o morire, e due finali principali arricchiti da epiloghi condizionati.

## Concept

- Un solo protagonista giocabile.
- Le scelte modificano **attributi nascosti** (non mostrati al giocatore).
- Molti percorsi narrativi che **convergono verso 2 finali principali**.
- Una **verità centrale** ribalta il significato della storia; dopo la rivelazione il
  giocatore compie una **decisione finale**.
- Il risultato finale dipende da **decisione finale + attributi accumulati**.
- **Personaggi secondari chiave** con stato `normale | ferito | morto`:
  - *normale* → supporto pieno; *ferito* → supporto limitato, blocca alcune opportunità;
    *morto* → rimuove definitivamente scene, informazioni o aiuti.

## Stack

- **Engine:** Godot 4.x
- **Logica:** GDScript (motore generico, UI-agnostic)
- **Contenuti:** JSON data-driven, validati da JSON Schema

## Principio di design

Architettura **a stati + attributi**, non a rami separati: si evita l'esplosione
combinatoria usando condizioni e varianti di testo condizionate. **Nessuna logica
narrativa è hardcoded**: tutto il contenuto vive in `data/*.json`; il codice è solo motore.

## Struttura

```
data/      contenuti narrativi (JSON): config, personaggi, scene, finali
schemas/   JSON Schema di validazione dei contenuti
src/       GDScript: core (motore), models, autoload, ui
scenes/    scene Godot (.tscn) — UI futura
tests/     test headless — futuri
docs/      documentazione di design dei sistemi
```

## Stato del progetto

**Prima versione giocabile.** Sono implementati: il core narrativo data-driven (caricamento,
attributi, condizioni, effetti, personaggi, ferite, finali, salvataggi) e una UI minima in
Godot (`scenes/main.tscn`). Mancano contenuti narrativi completi e rifinitura grafica.

## Documentazione

Vedi `docs/` per il design di ogni sistema e `CLAUDE.md` per le regole architetturali.

| Documento | Contenuto |
| --- | --- |
| `docs/architecture.md` | Architettura a 3 livelli, flusso runtime, segnali |
| `docs/attributes.md` | Sistema degli attributi nascosti |
| `docs/characters.md` | Modello e stati dei personaggi |
| `docs/scenes.md` | Modello delle scene, scelte, condizioni, effetti |
| `docs/endings.md` | Modello dei finali e degli epiloghi |
| `docs/data-schema.md` | Riferimento completo del formato dati JSON |
| `docs/ui.md` | UI minima Godot: nodi, segnali, flusso |
