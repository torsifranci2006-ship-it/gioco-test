class_name GameState
extends RefCounted

## Stato di gioco runtime. Contenitore generico: nessun id/valore narrativo hardcoded.
## La UI legge questo stato ma NON lo muta direttamente (lo fa solo il Core).
## I setter emettono i segnali su EventBus, se presente (vedi _bus).

var attributes: Dictionary = {}    ## id -> int
var characters: Dictionary = {}    ## id -> GameCharacter
var flags: Dictionary = {}         ## id -> true
var history: Array[String] = []    ## id delle scene visitate, in ordine
var current_scene_id: String = ""
## Stato runtime delle ferite: id -> { scene, rischio, rischio_per_scena, soglia_critica, soglia_cura }.
## Contiene una voce solo per i personaggi attualmente "ferito".
var wounds: Dictionary = {}

var _bounds: Dictionary = {}       ## id -> { "min": int, "max": int }

## Inizializza attributi (ai default) e personaggi dai dati caricati.
func setup(attributes_config: Array, character_list: Array) -> void:
	attributes.clear()
	_bounds.clear()
	characters.clear()
	flags.clear()
	history.clear()
	wounds.clear()
	current_scene_id = ""
	for a in attributes_config:
		var aid: String = a.get("id", "")
		if aid == "":
			continue
		attributes[aid] = int(a.get("default", 0))
		_bounds[aid] = { "min": int(a.get("min", 0)), "max": int(a.get("max", 0)) }
	for c in character_list:
		characters[c.id] = c

# --- Attributi ---

func get_attribute(id: String) -> int:
	return int(attributes.get(id, 0))

func set_attribute(id: String, value: int) -> void:
	if not attributes.has(id):
		push_error("GameState: attributo sconosciuto: " + id)
		return
	var b: Dictionary = _bounds.get(id, { "min": value, "max": value })
	var clamped := clampi(value, b["min"], b["max"])
	if clamped != int(attributes[id]):
		attributes[id] = clamped
		_emit("attribute_changed", id, clamped)

func add_attribute(id: String, delta: int) -> void:
	set_attribute(id, get_attribute(id) + delta)

# --- Flag ---

func has_flag(id: String) -> bool:
	return flags.get(id, false)

func set_flag(id: String) -> void:
	flags[id] = true

func clear_flag(id: String) -> void:
	flags.erase(id)

# --- Personaggi ---

func get_character(id: String) -> GameCharacter:
	return characters.get(id)

func set_character_state(id: String, stato: String) -> void:
	var c: GameCharacter = characters.get(id)
	if c == null:
		push_error("GameState: personaggio sconosciuto: " + id)
		return
	if c.stato == stato:
		return
	var old := c.stato
	c.stato = stato
	# Ciclo di vita della ferita: si apre entrando in "ferito", si chiude uscendone.
	if stato == GameCharacter.FERITO and old != GameCharacter.FERITO:
		_start_wound(c)
	elif stato != GameCharacter.FERITO:
		wounds.erase(id)
	_emit("character_state_changed", id, stato)

func _start_wound(c: GameCharacter) -> void:
	var cfg: Dictionary = c.ferita_config
	wounds[c.id] = {
		"scene": 0,
		"rischio": int(cfg.get("rischio_iniziale", 0)),
		"rischio_per_scena": int(cfg.get("rischio_per_scena", 10)),
		"soglia_critica": int(cfg.get("soglia_critica", 100)),
		"soglia_cura": int(cfg.get("soglia_cura", 50)),
	}

func is_wounded(id: String) -> bool:
	return wounds.has(id)

## Copia di sola lettura del record ferita (vuota se il personaggio non è ferito).
func get_wound(id: String) -> Dictionary:
	return wounds.get(id, {})

## Avanzamento del tempo per i feriti: chiamato SOLO al cambio di scena (vedi StoryEngine).
## La morte automatica avviene esclusivamente qui, mai mentre si resta nella stessa scena.
func advance_wounds() -> void:
	for id in wounds.keys().duplicate():   # copia: set_character_state può rimuovere voci
		if not wounds.has(id):
			continue
		var w: Dictionary = wounds[id]
		w["scene"] += 1
		w["rischio"] += w["rischio_per_scena"]
		if w["rischio"] >= w["soglia_critica"]:
			set_character_state(id, GameCharacter.MORTO)   # rimuove il record ferita

## Tentativo di cura (innescato da un effetto "cura" nei JSON).
func try_cure(id: String) -> void:
	var c: GameCharacter = characters.get(id)
	if c == null or c.stato != GameCharacter.FERITO:
		return
	var w: Dictionary = wounds.get(id, {})
	if w.is_empty():
		return
	if int(w["rischio"]) <= int(w["soglia_cura"]):
		set_character_state(id, GameCharacter.NORMALE)   # cura riuscita
	else:
		set_character_state(id, GameCharacter.MORTO)     # troppo tardi

func add_relazione(id: String, delta: int) -> void:
	var c: GameCharacter = characters.get(id)
	if c == null:
		push_error("GameState: personaggio sconosciuto: " + id)
		return
	c.relazione += delta

# --- Salvataggio ---

## Reimporta uno snapshot (da SaveSystem) preservando i bounds e i dati base dei personaggi.
func import_snapshot(snap: GameState) -> void:
	for id in snap.attributes.keys():
		if attributes.has(id):
			set_attribute(id, int(snap.attributes[id]))
	flags = snap.flags.duplicate()
	for id in snap.characters.keys():
		var c: GameCharacter = characters.get(id)
		var sc: GameCharacter = snap.characters[id]
		if c != null and sc != null:
			set_character_state(id, sc.stato)
			c.relazione = sc.relazione
	# Ripristina il progresso esatto delle ferite (dopo gli stati, che lo avrebbero re-inizializzato).
	wounds = snap.wounds.duplicate(true)
	history = snap.history.duplicate()
	current_scene_id = snap.current_scene_id

# --- Segnali (disaccoppiati, sicuri in headless senza autoload) ---

func _emit(signal_name: String, a, b) -> void:
	var loop := Engine.get_main_loop()
	if loop is SceneTree and loop.root != null and loop.root.has_node("EventBus"):
		loop.root.get_node("EventBus").emit_signal(signal_name, a, b)
