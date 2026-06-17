extends Control

## UI minima del gioco narrativo.
## Nessun contenuto né logica narrativa qui: la UI parla SOLO con Game e con i segnali di EventBus.
## Non legge i JSON e non conosce i sistemi interni.

const BG_PATH := "res://assets/backgrounds/bg_auto_notte.png"
const DANIEL_CALDO := "res://assets/characters/daniel/char_daniel_caldo.png"
const DANIEL_FREDDO := "res://assets/characters/daniel/char_daniel_freddo.png"

## Mappe asset visuali: nome logico (dal campo "visual" delle scene) -> percorso res://.
## NB: molti valori sono FALLBACK temporanei agli unici asset finora prodotti.
const BG_MAP := {
	"bg_esterno_crimine_notte": "res://assets/backgrounds/bg_esterno_crimine_notte.png",
	"bg_commissariato": "res://assets/backgrounds/bg_commissariato.png",
	"bg_obitorio": "res://assets/backgrounds/bg_obitorio.png",
	"bg_incontro_veil": "res://assets/backgrounds/bg_incontro_veil.png",
	"bg_bar_privato": "res://assets/backgrounds/bg_bar_privato.png",
	"bg_tobia_rifugio": "res://assets/backgrounds/bg_tobia_rifugio.png",
}
const PORTRAIT_MAP := {
	"char_daniel_caldo": "res://assets/characters/daniel/char_daniel_caldo.png",
	"char_daniel_freddo": "res://assets/characters/daniel/char_daniel_freddo.png",
	"char_mara": "res://assets/characters/mara/char_mara.png",
	"char_veil": "res://assets/characters/veil/char_veil.png",
	"char_tobia": "res://assets/characters/tobia/char_tobia.png",
}

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
@onready var _background: TextureRect = $Background
@onready var _character: TextureRect = $Character

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
	# --- Livelli visivi (vertical slice integrato) ---
	_background.texture = _try_load(BG_PATH)
	_set_portrait_freddo(false)   # pre-carica il ritratto caldo...
	_character.visible = false    # ...ma Daniel non appare prima della Nuova Partita

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
	_apply_visual(Game.current_scene())
	_render_current()

func _on_game_ended(_ending_id: String) -> void:
	_set_portrait_freddo(true)   # finale attivo -> Daniel freddo (regola temporanea slice)
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

# --- Livelli visivi (vertical slice integrato) ---

## Carica una texture solo se presente (la UI resta funzionante anche senza asset).
func _try_load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	push_warning("UI: asset visivo mancante: " + path)
	return null

func _set_portrait_freddo(freddo: bool) -> void:
	var tex := _try_load(DANIEL_FREDDO if freddo else DANIEL_CALDO)
	if tex != null:
		_character.texture = tex

## Applica i metadati visuali della scena (campo "visual"). Il metadata PREVALE sempre;
## in sua assenza si usa il fallback (bg_auto_notte + ritratto secondo la regola Atto 3).
func _apply_visual(scene: StoryScene) -> void:
	if scene == null:
		_character.visible = false
		return
	var visual: Dictionary = scene.visual
	if visual.is_empty():
		# Scene senza metadata (per ora Atti 2-3): fallback completo.
		var bg := _try_load(BG_PATH)
		if bg != null:
			_background.texture = bg
		_set_portrait_fallback(scene.id)
		return
	# Background: il metadata prevale; chiave assente/sconosciuta -> fallback bg_auto_notte.
	var bg_tex := _try_load(BG_MAP.get(visual.get("background"), BG_PATH))
	if bg_tex != null:
		_background.texture = bg_tex
	_apply_portrait(visual, scene.id)

func _apply_portrait(visual: Dictionary, scene_id: String) -> void:
	if not visual.has("portrait"):
		_set_portrait_fallback(scene_id)   # scena con visual ma senza chiave portrait
		return
	var key = visual.get("portrait")
	if key == null or key == "none" or key == "":
		_character.visible = false          # nessun ritratto in questa scena
		return
	var tex := _try_load(PORTRAIT_MAP.get(key, DANIEL_CALDO))   # chiave sconosciuta -> caldo
	if tex != null:
		_character.texture = tex
	_character.visible = true

## Fallback ritratto per scene SENZA campo "visual".
## REGOLA TEMPORANEA: Daniel "freddo" dalla rivelazione (a3_s03) in poi, altrimenti caldo.
## Si applica SOLO in assenza di metadata; da rimuovere quando anche gli Atti 2-3
## avranno il campo "visual". Il metadata, se presente, prevale sempre su questa regola.
func _set_portrait_fallback(scene_id: String) -> void:
	_set_portrait_freddo(_is_act3_reveal(scene_id))
	_character.visible = true

func _is_act3_reveal(scene_id: String) -> bool:
	var parts := scene_id.split("_")
	if parts.size() != 2:
		return false
	var atto: String = parts[0]
	var scena: String = parts[1]
	if not atto.begins_with("a") or not scena.begins_with("s"):
		return false
	return int(atto.substr(1)) == 3 and int(scena.substr(1)) >= 3

