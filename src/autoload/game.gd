extends Node

## Facciata di gioco (autoload "Game"). Punto d'ingresso unico per la UI.
## _ready() inizializza solo le dipendenze (setup del Core). NON avvia una partita:
## new_game() va chiamato esplicitamente. Gli errori di setup sono propagati con messaggi chiari.
## La UI usa SOLO questi metodi: non legge i JSON né conosce i sistemi interni.

const SAVE_PATH := "user://savegame.json"

var engine: StoryEngine
var ready_ok: bool = false        ## true se il setup del motore è riuscito

func _ready() -> void:
	engine = StoryEngine.new()
	ready_ok = engine.setup()
	if not ready_ok:
		push_error("Game: inizializzazione del motore fallita — " + engine.last_error)

# --- Controllo partita ---

## Avvia esplicitamente una nuova partita. Ritorna false se il motore non è pronto.
func new_game() -> bool:
	if not ready_ok:
		push_error("Game.new_game: motore non inizializzato (" + engine.last_error + ")")
		return false
	engine.start()
	return true

## Inoltra la scelta del giocatore al motore.
func choose(choice_id: String) -> void:
	if not ready_ok:
		push_error("Game.choose: motore non inizializzato")
		return
	engine.choose(choice_id)

# --- Stato per la UI (sola lettura, pass-through) ---

func is_ready() -> bool:
	return ready_ok

func last_error() -> String:
	return engine.last_error if engine != null else "motore non disponibile"

func current_text() -> Array[String]:
	if not ready_ok:
		return []
	return engine.current_text()

func available_choices() -> Array[Choice]:
	if not ready_ok:
		return []
	return engine.available_choices()

func current_scene() -> StoryScene:
	return engine.current_scene() if ready_ok else null

func current_ending() -> Ending:
	return engine.current_ending() if ready_ok else null

func current_epilogues() -> Array[String]:
	if not ready_ok:
		return []
	return engine.current_epilogues()

# --- Salvataggio / caricamento (path interno, nessun path nella UI) ---

func save_game() -> bool:
	if not ready_ok:
		return false
	return engine.save_game(SAVE_PATH)

func load_game() -> bool:
	if not ready_ok:
		return false
	return engine.load_game(SAVE_PATH)
