extends Node

## Bus di segnali globale (autoload "EventBus").
## Il Core emette; la UI si connette. Disaccoppia presentazione e logica.

## Emesso quando la scena attiva cambia (id della nuova scena).
signal scene_changed(scene_id: String)

## Emesso quando un attributo cambia valore.
signal attribute_changed(attribute_id: String, value: int)

## Emesso quando lo stato di un personaggio cambia ("normale" | "ferito" | "morto").
signal character_state_changed(character_id: String, state: String)

## Emesso dopo una scelta con i cambiamenti DIRETTI e spoiler-free da mostrare nell'overlay.
## changes: Array di Dictionary già pronti per la UI (nomi visualizzati + direzione/stato, niente numeri).
signal choice_effects_applied(changes: Array)

## Emesso a fine partita con il ramo finale risolto.
signal game_ended(ending_id: String)
