class_name StoryEngine
extends RefCounted

## API principale del Core, UI-agnostic. Orchestra dati, stato, condizioni ed effetti.
## La UI interagisce SOLO tramite questi metodi e reagisce ai segnali di EventBus.
## Nessun contenuto narrativo qui dentro: tutto arriva dai dati caricati.

const CONFIG_PATH := "res://data/config/game.json"

var state: GameState
var last_error: String = ""        ## descrizione dell'ultimo errore di setup()

var _scenes: Dictionary = {}        ## id -> StoryScene
var _endings: Array[Ending] = []
var _initial_scene_id: String = ""
var _final_scene_id: String = "finale"

var _last_ending: Ending = null            ## ultimo finale risolto (per la UI)
var _last_epilogues: Array[String] = []    ## epiloghi composti dell'ultimo finale

var _attribute_names: Dictionary = {}      ## id attributo -> nome visualizzato (per overlay cambiamenti)

## Carica i dati e inizializza lo stato. Ritorna false (con last_error) in caso di errore.
func setup() -> bool:
	last_error = ""
	var cfg := DataLoader.load_game_config(CONFIG_PATH)
	if cfg.is_empty():
		return _fail("config di gioco non valida: " + CONFIG_PATH)
	_initial_scene_id = cfg.get("scena_iniziale", "")
	_final_scene_id = cfg.get("id_scena_finale", "finale")
	var paths: Dictionary = cfg.get("percorsi", {})

	var attributes_config := DataLoader.load_attributes(paths.get("attributi", ""))
	if attributes_config.is_empty():
		return _fail("nessun attributo caricato")
	var characters := DataLoader.load_characters(paths.get("personaggi", ""))
	if characters.is_empty():
		return _fail("nessun personaggio caricato")
	_scenes = DataLoader.load_scenes(paths.get("scene", ""))
	if _scenes.is_empty():
		return _fail("nessuna scena caricata")
	_endings = DataLoader.load_endings(paths.get("finali", ""))
	if _endings.is_empty():
		return _fail("nessun finale caricato")
	if not _scenes.has(_initial_scene_id):
		return _fail("scena iniziale assente: " + _initial_scene_id)

	_attribute_names.clear()
	for a in attributes_config:
		var aid: String = a.get("id", "")
		if aid != "":
			_attribute_names[aid] = String(a.get("nome", aid))

	state = GameState.new()
	state.setup(attributes_config, characters)
	return true

func _fail(msg: String) -> bool:
	last_error = msg
	push_error("StoryEngine.setup: " + msg)
	return false

## Avvia dalla scena iniziale ed emette scene_changed.
func start() -> void:
	if state == null:
		push_error("StoryEngine.start: setup non eseguito o fallito")
		return
	_last_ending = null
	_last_epilogues = []
	# La scena iniziale non è un avanzamento: nessun tick delle ferite.
	_enter_scene(_initial_scene_id, false)

func current_scene() -> StoryScene:
	if state == null:
		return null
	return _scenes.get(state.current_scene_id)

## Accessor di sola lettura: titolo leggibile di una scena dato il suo id (per la UI dei
## salvataggi). Ritorna "" se l'id non esiste. Non altera lo stato né la logica narrativa.
func scene_title(scene_id: String) -> String:
	var sc: StoryScene = _scenes.get(scene_id)
	return sc.titolo if sc != null else ""

## Accessor di sola lettura per la UI (Dossier): personaggi GIÀ incontrati, con dati privi di
## spoiler. "Incontrato" = comparso come ritratto in una scena visitata (history + visual.portrait).
## NON espone descrizione né attributi nascosti. Espone la relazione come fascia qualitativa
## (relazione_fascia) e come valore reale (relazione_value): il Core non perde informazione, è la UI
## a clampare 0-100 solo per la barra (il numero non è mai mostrato al giocatore). Ogni voce:
## { nome:String, stato:String, supporto:String, ferita:bool, relazione_fascia:String, relazione_value:int }.
func met_characters() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if state == null:
		return out
	var seen: Dictionary = {}   # id -> true: evita duplicati mantenendo l'ordine di primo incontro
	for scene_id in state.history:
		var sc: StoryScene = _scenes.get(scene_id)
		if sc == null:
			continue
		var portrait = sc.visual.get("portrait")
		if not (portrait is String) or portrait == "" or portrait == "none":
			continue
		var cid := _character_id_for_portrait(portrait)
		if cid == "" or seen.has(cid):
			continue
		seen[cid] = true
		var c: GameCharacter = state.get_character(cid)
		if c == null:
			continue
		out.append({
			"nome": c.nome,
			"stato": c.stato,
			"supporto": c.supporto(),
			"ferita": state.is_wounded(cid),
			"relazione_fascia": _relazione_band(c.relazione),
			"relazione_value": c.relazione,
		})
	return out

## Risolve una chiave ritratto (es. "char_mara", "char_daniel_caldo") a un id di personaggio
## ESISTENTE, con convenzione generica "char_<id>" / "char_<id>_<variante>". Ritorna "" se nessun
## match: così i ritratti privi di GameCharacter (es. char_halloran, char_voss) restano esclusi.
func _character_id_for_portrait(portrait: String) -> String:
	for cid in state.characters.keys():
		if portrait == "char_" + cid or portrait.begins_with("char_" + cid + "_"):
			return cid
	return ""

## Codice neutro della fascia di relazione (la UI lo traduce in etichetta leggibile). Mai il numero.
## Soglie qualitative generiche, non contenuto narrativo specifico della storia.
func _relazione_band(value: int) -> String:
	if value < 0:
		return "diffidente"
	elif value < 25:
		return "neutrale"
	elif value < 50:
		return "fiducia"
	return "alleato"

## Frammenti di testo della scena corrente la cui condizione è soddisfatta.
func current_text() -> Array[String]:
	var out: Array[String] = []
	var sc := current_scene()
	if sc == null:
		return out
	for frag in sc.testo:
		if ConditionEvaluator.evaluate(frag.get("condizione"), state):
			out.append(frag.get("contenuto", ""))
	return out

## Scelte visibili nella scena corrente; ognuna con il flag runtime `abilitata`.
func available_choices() -> Array[Choice]:
	var out: Array[Choice] = []
	var sc := current_scene()
	if sc == null:
		return out
	for ch in sc.scelte:
		if not ConditionEvaluator.evaluate(ch.visibile_se, state):
			continue
		ch.abilitata = ConditionEvaluator.evaluate(ch.abilitata_se, state)
		out.append(ch)
	return out

## Applica la scelta: effetti, poi avanzamento di scena o risoluzione del finale.
func choose(choice_id: String) -> void:
	var sc := current_scene()
	if sc == null:
		push_error("StoryEngine.choose: nessuna scena corrente")
		return
	var chosen: Choice = null
	for ch in sc.scelte:
		if ch.id == choice_id:
			chosen = ch
			break
	if chosen == null:
		push_error("StoryEngine.choose: scelta inesistente: " + choice_id)
		return
	if not ConditionEvaluator.evaluate(chosen.visibile_se, state) \
			or not ConditionEvaluator.evaluate(chosen.abilitata_se, state):
		push_error("StoryEngine.choose: scelta non disponibile: " + choice_id)
		return
	# Snapshot PRIMA degli effetti diretti della scelta, per il diff dell'overlay cambiamenti.
	var _pre_choice := _snapshot_for_changes()
	EffectApplier.apply(chosen.effetti, state)
	# Diff calcolato qui: cattura SOLO gli effetti diretti della scelta (incl. regole_stato
	# innescate dagli stessi), prima di _enter_scene (esclude on_enter e morte-da-ferita).
	var changes := _build_changes(_pre_choice)
	if chosen.prossima == _final_scene_id:
		_trigger_ending(choice_id)
	else:
		# Passare a una nuova scena è un avanzamento: le ferite progrediscono.
		_enter_scene(chosen.prossima, true)
		# Emesso DOPO scene_changed (overlay sopra la nuova scena); mai sul finale.
		_emit_choice_effects(changes)

# --- Overlay cambiamenti dopo scelta (diff spoiler-free, niente numeri) ---

## Cattura attributi, relazione e stato di ogni personaggio, per confronto post-scelta.
func _snapshot_for_changes() -> Dictionary:
	var attr: Dictionary = {}
	for id in state.attributes.keys():
		attr[id] = int(state.attributes[id])
	var chars: Dictionary = {}
	for cid in state.characters.keys():
		var c: GameCharacter = state.characters[cid]
		chars[cid] = { "relazione": c.relazione, "stato": c.stato }
	return { "attr": attr, "chars": chars }

## Costruisce la lista di cambiamenti spoiler-free, ordinata stati -> relazioni -> attributi e
## limitata a 5 righe. Solo direzione (±1) e nomi visualizzati: nessun valore numerico, nessun flag.
func _build_changes(before: Dictionary) -> Array:
	var stati: Array = []
	var relazioni: Array = []
	var attributi: Array = []
	var before_chars: Dictionary = before.get("chars", {})
	var before_attr: Dictionary = before.get("attr", {})
	for cid in state.characters.keys():
		var c: GameCharacter = state.characters[cid]
		var b: Dictionary = before_chars.get(cid, {})
		if String(b.get("stato", c.stato)) != c.stato:
			stati.append({ "tipo": "stato", "nome": c.nome, "stato": c.stato })
		var prev_rel: int = int(b.get("relazione", c.relazione))
		if c.relazione != prev_rel:
			relazioni.append({ "tipo": "relazione", "nome": c.nome, "direzione": signi(c.relazione - prev_rel) })
	for id in state.attributes.keys():
		var prev_val: int = int(before_attr.get(id, state.attributes[id]))
		var now_val: int = int(state.attributes[id])
		if now_val != prev_val:
			attributi.append({ "tipo": "attributo", "nome": String(_attribute_names.get(id, id)), "direzione": signi(now_val - prev_val) })
	var ordered: Array = []
	ordered.append_array(stati)
	ordered.append_array(relazioni)
	ordered.append_array(attributi)
	if ordered.size() > 5:
		ordered = ordered.slice(0, 5)
	return ordered

## Emette il segnale solo se c'è qualcosa da mostrare.
func _emit_choice_effects(changes: Array) -> void:
	if changes.is_empty():
		return
	var bus := _bus()
	if bus != null:
		bus.emit_signal("choice_effects_applied", changes)

## Risolve il finale senza modificare lo stato (utile alla UI per anteprime/debug).
func resolve_ending(final_choice_id: String) -> Ending:
	return EndingResolver.resolve(_endings, final_choice_id, state)

func epilogues_for(ending: Ending) -> Array[String]:
	return EndingResolver.epilogues_for(ending, state)

# --- Salvataggio ---

func save_game(path: String) -> bool:
	if state == null:
		return false
	return SaveSystem.save(state, path)

func load_game(path: String) -> bool:
	if state == null:
		push_error("StoryEngine.load_game: setup non eseguito")
		return false
	var snap := SaveSystem.load(path)
	if snap == null:
		return false
	state.import_snapshot(snap)
	_emit_scene_changed(state.current_scene_id)
	return true

# --- Interni ---

func _enter_scene(scene_id: String, advance: bool) -> void:
	if not _scenes.has(scene_id):
		push_error("StoryEngine: scena inesistente: " + scene_id)
		return
	var sc: StoryScene = _scenes[scene_id]
	state.current_scene_id = scene_id
	state.history.append(scene_id)
	# 1) Il tempo passa sui feriti già esistenti (qui, ed eventuale morte automatica)...
	if advance:
		state.advance_wounds()
	# 2) ...poi gli eventi della nuova scena (che possono ferire qualcuno ex novo).
	EffectApplier.apply(sc.on_enter, state)
	_emit_scene_changed(scene_id)

func _trigger_ending(final_choice_id: String) -> void:
	var ending := EndingResolver.resolve(_endings, final_choice_id, state)
	if ending == null:
		push_error("StoryEngine: nessun finale risolto per la decisione: " + final_choice_id)
		return
	_last_ending = ending
	_last_epilogues = EndingResolver.epilogues_for(ending, state)
	_emit_game_ended(ending.id)

## Ultimo finale risolto (null se la partita non è terminata).
func current_ending() -> Ending:
	return _last_ending

## Epiloghi composti dell'ultimo finale.
func current_epilogues() -> Array[String]:
	return _last_epilogues

# --- Segnali (disaccoppiati, sicuri in headless senza autoload) ---

func _emit_scene_changed(scene_id: String) -> void:
	var bus := _bus()
	if bus != null:
		bus.emit_signal("scene_changed", scene_id)

func _emit_game_ended(ending_id: String) -> void:
	var bus := _bus()
	if bus != null:
		bus.emit_signal("game_ended", ending_id)

func _bus() -> Node:
	var loop := Engine.get_main_loop()
	if loop is SceneTree and loop.root != null and loop.root.has_node("EventBus"):
		return loop.root.get_node("EventBus")
	return null
