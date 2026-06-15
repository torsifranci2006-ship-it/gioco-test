class_name SaveSystem
extends RefCounted

## Serializza/deserializza il GameState (attributi, stato personaggi, flag, cronologia, scena).
## Salva solo lo STATO, mai i contenuti: i contenuti restano nei dati JSON.
## load() ritorna uno snapshot da reimportare in uno stato già configurato
## (vedi GameState.import_snapshot), così bounds e regole restano quelli dei dati.

static func save(state: GameState, path: String) -> bool:
	var chars := {}
	for id in state.characters.keys():
		var c: GameCharacter = state.characters[id]
		chars[id] = { "stato": c.stato, "relazione": c.relazione }
	var data := {
		"attributes": state.attributes,
		"flags": state.flags,
		"characters": chars,
		"wounds": state.wounds,
		"history": state.history,
		"current_scene_id": state.current_scene_id,
	}
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("SaveSystem: impossibile scrivere: " + path)
		return false
	f.store_string(JSON.stringify(data, "  "))
	return true

static func load(path: String) -> GameState:
	if not FileAccess.file_exists(path):
		push_error("SaveSystem: salvataggio non trovato: " + path)
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("SaveSystem: impossibile leggere: " + path)
		return null
	var data = JSON.parse_string(f.get_as_text())
	if not (data is Dictionary):
		push_error("SaveSystem: salvataggio non valido: " + path)
		return null
	var snap := GameState.new()
	var attrs = data.get("attributes", {})
	snap.attributes = attrs if attrs is Dictionary else {}
	var fl = data.get("flags", {})
	snap.flags = fl if fl is Dictionary else {}
	for id in data.get("characters", {}).keys():
		var cd: Dictionary = data["characters"][id]
		var c := GameCharacter.new()
		c.id = id
		c.stato = cd.get("stato", GameCharacter.NORMALE)
		c.relazione = int(cd.get("relazione", 0))
		snap.characters[id] = c
	var wd = data.get("wounds", {})
	if wd is Dictionary:
		for id in wd.keys():
			snap.wounds[id] = (wd[id] as Dictionary).duplicate()
	var hist: Array[String] = []
	for h in data.get("history", []):
		hist.append(String(h))
	snap.history = hist
	snap.current_scene_id = data.get("current_scene_id", "")
	return snap
