extends Node

## Facciata di gioco (autoload "Game"). Punto d'ingresso unico per la UI.
## _ready() inizializza solo le dipendenze (setup del Core). NON avvia una partita:
## new_game() va chiamato esplicitamente. Gli errori di setup sono propagati con messaggi chiari.
## La UI usa SOLO questi metodi: non legge i JSON né conosce i sistemi interni.

const SAVE_PATH := "user://savegame.json"   ## legacy slot singolo (non più usato dalla UI)
const SAVE_DIR := "user://saves/"           ## directory degli slot multipli

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

# --- Salvataggi multi-slot (user://saves/save_<N>.json) ---

func _slot_path(slot: int) -> String:
	return SAVE_DIR + "save_%d.json" % slot

## Salva la partita corrente nello slot indicato. Crea la directory se manca.
func save_slot(slot: int) -> bool:
	if not ready_ok:
		return false
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	return engine.save_game(_slot_path(slot))

## Carica la partita dallo slot indicato (emette scene_changed tramite il motore).
func load_slot(slot: int) -> bool:
	if not ready_ok:
		return false
	return engine.load_game(_slot_path(slot))

## Titolo leggibile di una scena dato il suo id (pass-through al motore). "" se sconosciuto.
func scene_title(scene_id: String) -> String:
	return engine.scene_title(scene_id) if ready_ok else ""

## Primo slot libero (max esistente + 1, a partire da 1) per "Nuovo salvataggio".
func next_free_slot() -> int:
	var max_slot := 0
	for entry in list_saves():
		max_slot = max(max_slot, int(entry.get("slot", 0)))
	return max_slot + 1

## Elenco dei salvataggi esistenti, ordinati per data/ora decrescente (più recente in cima).
## Ogni voce: { slot:int, scene_id:String, scene_title:String, mtime:int }.
func list_saves() -> Array:
	var out: Array = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return out
	for fname in dir.get_files():
		if not (fname.begins_with("save_") and fname.ends_with(".json")):
			continue
		var slot := int(fname.trim_prefix("save_").trim_suffix(".json"))
		var path := _slot_path(slot)
		var scene_id := _peek_scene_id(path)
		out.append({
			"slot": slot,
			"scene_id": scene_id,
			"scene_title": scene_title(scene_id),
			"mtime": int(FileAccess.get_modified_time(path)),
		})
	out.sort_custom(func(a, b): return a["mtime"] > b["mtime"])
	return out

## Parse leggero: estrae solo current_scene_id da un file di salvataggio (non ricostruisce lo stato).
func _peek_scene_id(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var data = JSON.parse_string(f.get_as_text())
	if data is Dictionary:
		return String(data.get("current_scene_id", ""))
	return ""
