extends Node

## Facciata di gioco (autoload "Game"). Punto d'ingresso unico per la UI.
## _ready() inizializza solo le dipendenze (setup del Core). NON avvia una partita:
## new_game() va chiamato esplicitamente. Gli errori di setup sono propagati con messaggi chiari.

var engine: StoryEngine
var ready_ok: bool = false        ## true se il setup del motore è riuscito

func _ready() -> void:
	engine = StoryEngine.new()
	ready_ok = engine.setup()
	if not ready_ok:
		push_error("Game: inizializzazione del motore fallita — " + engine.last_error)

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
