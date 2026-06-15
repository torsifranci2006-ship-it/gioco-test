extends Control

## UI minima del gioco narrativo.
## Nessun contenuto né logica narrativa qui: la UI parla SOLO con Game e con i segnali di EventBus.
## Non legge i JSON e non conosce i sistemi interni.

@onready var _scene_text: RichTextLabel = $Margin/Root/SceneText
@onready var _choices: VBoxContainer = $Margin/Root/ChoicesScroll/Choices
@onready var _new_game_button: Button = $Margin/Root/Controls/NewGameButton
@onready var _save_button: Button = $Margin/Root/Controls/SaveButton
@onready var _load_button: Button = $Margin/Root/Controls/LoadButton
@onready var _status: Label = $Margin/Root/Status
@onready var _ending_panel: PanelContainer = $EndingPanel
@onready var _ending_title: Label = $EndingPanel/EndingVBox/EndingTitle
@onready var _ending_text: RichTextLabel = $EndingPanel/EndingVBox/EndingText
@onready var _ending_new_game_button: Button = $EndingPanel/EndingVBox/EndingNewGameButton

func _ready() -> void:
	EventBus.scene_changed.connect(_on_scene_changed)
	EventBus.game_ended.connect(_on_game_ended)
	_new_game_button.pressed.connect(_on_new_game)
	_save_button.pressed.connect(_on_save)
	_load_button.pressed.connect(_on_load)
	_ending_new_game_button.pressed.connect(_on_new_game)
	_ending_panel.visible = false
	if not Game.is_ready():
		_new_game_button.disabled = true
		_save_button.disabled = true
		_load_button.disabled = true
		_status.text = "Errore di inizializzazione: " + Game.last_error()
	else:
		_status.text = "Premi Nuova Partita per iniziare."

# --- Pulsanti principali ---

func _on_new_game() -> void:
	if not Game.is_ready():
		return
	_ending_panel.visible = false
	Game.new_game()
	_status.text = "Nuova partita avviata."

func _on_save() -> void:
	if Game.save_game():
		_status.text = "Partita salvata."
	else:
		_status.text = "Impossibile salvare la partita."

func _on_load() -> void:
	if Game.load_game():
		_status.text = "Partita caricata."
	else:
		_status.text = "Nessun salvataggio valido da caricare."

# --- Reazione ai segnali del Core ---

func _on_scene_changed(_scene_id: String) -> void:
	_ending_panel.visible = false
	_render_current()

func _on_game_ended(_ending_id: String) -> void:
	_show_ending()

# --- Rendering ---

func _render_current() -> void:
	var scene := Game.current_scene()
	if scene == null:
		_scene_text.text = ""
		_clear_choices()
		_status.text = "Scena non disponibile (dati incoerenti?)."
		return
	_scene_text.text = _join(Game.current_text())
	_build_choices()

func _build_choices() -> void:
	_clear_choices()
	var choices := Game.available_choices()
	for choice in choices:
		var button := Button.new()
		button.text = choice.testo
		button.disabled = not choice.abilitata
		if not choice.abilitata and choice.motivo_blocco != "":
			button.tooltip_text = choice.motivo_blocco
		button.pressed.connect(_on_choice.bind(choice.id))
		_choices.add_child(button)
	if choices.is_empty():
		_status.text = "Nessuna scelta disponibile in questa scena."

func _clear_choices() -> void:
	for child in _choices.get_children():
		child.queue_free()

func _on_choice(choice_id: String) -> void:
	Game.choose(choice_id)

func _show_ending() -> void:
	var ending := Game.current_ending()
	if ending == null:
		_status.text = "Finale non disponibile."
		return
	_ending_title.text = ending.titolo
	var parts: Array[String] = [ending.testo]
	for ep in Game.current_epilogues():
		parts.append(ep)
	_ending_text.text = _join(parts)
	_ending_panel.visible = true

# Unisce le righe con una riga vuota di separazione (evita dipendenze da String.join/PackedStringArray).
func _join(lines: Array[String]) -> String:
	var out := ""
	for i in lines.size():
		if i > 0:
			out += "\n\n"
		out += lines[i]
	return out
