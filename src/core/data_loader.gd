class_name DataLoader
extends RefCounted

## Carica i contenuti JSON da data/ e li trasforma in modelli tipizzati.
## Validazione LEGGERA (file leggibile, JSON valido, chiavi obbligatorie presenti):
## la validazione formale completa resta affidata agli schemi in schemas/ (authoring/CI).

## Legge e parsa un file JSON. Ritorna il Variant parsato o null in caso di errore.
static func read_json(path: String):
	if not FileAccess.file_exists(path):
		push_error("DataLoader: file non trovato: " + path)
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("DataLoader: impossibile aprire: " + path)
		return null
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed == null:
		push_error("DataLoader: JSON non valido in: " + path)
		return null
	return parsed

## Config di gioco: percorsi e id chiave.
static func load_game_config(path: String) -> Dictionary:
	var d = read_json(path)
	if not (d is Dictionary):
		return {}
	for k in ["scena_iniziale", "id_scena_finale", "percorsi"]:
		if not d.has(k):
			push_error("DataLoader: game config manca la chiave '%s'" % k)
			return {}
	return d

## Lista grezza dei config attributo.
static func load_attributes(path: String) -> Array:
	var d = read_json(path)
	if not (d is Dictionary) or not d.has("attributi"):
		push_error("DataLoader: 'attributi' mancante in " + path)
		return []
	return d["attributi"]

static func load_characters(path: String) -> Array[GameCharacter]:
	var out: Array[GameCharacter] = []
	var d = read_json(path)
	if not (d is Dictionary) or not d.has("personaggi"):
		push_error("DataLoader: 'personaggi' mancante in " + path)
		return out
	for cd in d["personaggi"]:
		out.append(GameCharacter.from_dict(cd))
	return out

## Scansione ricorsiva di una cartella; ritorna id -> StoryScene.
static func load_scenes(dir_path: String) -> Dictionary:
	var scenes := {}
	_scan_dir(dir_path, scenes)
	return scenes

static func _scan_dir(dir_path: String, scenes: Dictionary) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("DataLoader: cartella scene non accessibile: " + dir_path)
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full := dir_path.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with("."):
				_scan_dir(full, scenes)
		elif entry.ends_with(".json"):
			var data = read_json(full)
			if data is Dictionary and data.has("id"):
				var sc := StoryScene.from_dict(data)
				if scenes.has(sc.id):
					push_error("DataLoader: id scena duplicato: " + sc.id)
				scenes[sc.id] = sc
		entry = dir.get_next()
	dir.list_dir_end()

static func load_endings(path: String) -> Array[Ending]:
	var out: Array[Ending] = []
	var d = read_json(path)
	if not (d is Dictionary) or not d.has("rami"):
		push_error("DataLoader: 'rami' mancante in " + path)
		return out
	for rd in d["rami"]:
		out.append(Ending.from_dict(rd))
	return out
