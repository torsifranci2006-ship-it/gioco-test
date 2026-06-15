extends Node

## Bus di segnali globale (autoload "EventBus").
## Il Core emette; la UI si connette. Disaccoppia presentazione e logica.

## Emesso quando la scena attiva cambia (id della nuova scena).
signal scene_changed(scene_id: String)

## Emesso quando un attributo cambia valore.
signal attribute_changed(attribute_id: String, value: int)

## Emesso quando lo stato di un personaggio cambia ("normale" | "ferito" | "morto").
signal character_state_changed(character_id: String, state: String)

## Emesso a fine partita con il ramo finale risolto.
signal game_ended(ending_id: String)
