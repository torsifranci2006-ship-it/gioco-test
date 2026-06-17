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
	"bg_casa_daniel": "res://assets/backgrounds/bg_casa_daniel.png",
	"bg_laboratorio": "res://assets/backgrounds/bg_laboratorio.png",
	"bg_voss_archivio": "res://assets/backgrounds/bg_voss_archivio.png",
}
const PORTRAIT_MAP := {
	"char_daniel_caldo": "res://assets/characters/daniel/char_daniel_caldo.png",
	"char_daniel_freddo": "res://assets/characters/daniel/char_daniel_freddo.png",
	"char_mara": "res://assets/characters/mara/char_mara.png",
	"char_veil": "res://assets/characters/veil/char_veil.png",
	"char_tobia": "res://assets/characters/tobia/char_tobia.png",
	"char_halloran": "res://assets/characters/halloran/char_halloran.png",
	"char_voss": "res://assets/characters/voss/char_voss.png",
}

@onready var _scene_text: RichTextLabel = $BottomArea/TextPanel/TextMargin/SceneText
@onready var _choices_panel: PanelContainer = $BottomArea/ChoicesPanel
@onready var _choices: HFlowContainer = $BottomArea/ChoicesPanel/ChoicesMargin/Choices
@onready var _bottom_area: VBoxContainer = $BottomArea
@onready var _top_bar: PanelContainer = $TopBar
@onready var _new_game_button: Button = $TopBar/TopBarMargin/Controls/NewGameButton
@onready var _save_button: Button = $TopBar/TopBarMargin/Controls/SaveButton
@onready var _load_button: Button = $TopBar/TopBarMargin/Controls/LoadButton
@onready var _menu_button: Button = $TopBar/TopBarMargin/Controls/MenuButton
@onready var _status: Label = $TopBar/TopBarMargin/Controls/Status
@onready var _start_menu: PanelContainer = $StartMenu
@onready var _start_resume_button: Button = $StartMenu/StartMenuMargin/StartMenuVBox/StartResumeButton
@onready var _start_new_game_button: Button = $StartMenu/StartMenuMargin/StartMenuVBox/StartNewGameButton
@onready var _start_load_button: Button = $StartMenu/StartMenuMargin/StartMenuVBox/StartLoadButton
@onready var _start_save_button: Button = $StartMenu/StartMenuMargin/StartMenuVBox/StartSaveButton
@onready var _start_exit_button: Button = $StartMenu/StartMenuMargin/StartMenuVBox/StartExitButton
@onready var _start_status: Label = $StartMenu/StartMenuMargin/StartMenuVBox/StartStatus
@onready var _exit_confirm: PanelContainer = $ExitConfirm
@onready var _exit_confirm_button: Button = $ExitConfirm/ExitMargin/ExitVBox/ExitButtons/ExitConfirmButton
@onready var _exit_cancel_button: Button = $ExitConfirm/ExitMargin/ExitVBox/ExitButtons/ExitCancelButton
@onready var _ending_panel: PanelContainer = $EndingPanel
@onready var _ending_title: Label = $EndingPanel/EndingMargin/EndingVBox/EndingTitle
@onready var _ending_text: RichTextLabel = $EndingPanel/EndingMargin/EndingVBox/EndingText
@onready var _ending_new_game_button: Button = $EndingPanel/EndingMargin/EndingVBox/EndingNewGameButton
@onready var _background: TextureRect = $Background
@onready var _character: TextureRect = $Character

func _ready() -> void:
	EventBus.scene_changed.connect(_on_scene_changed)
	EventBus.game_ended.connect(_on_game_ended)
	_new_game_button.pressed.connect(_on_new_game)
	_save_button.pressed.connect(_on_save)
	_load_button.pressed.connect(_on_load)
	_start_new_game_button.pressed.connect(_on_new_game)
	_start_save_button.pressed.connect(_on_save)
	_start_load_button.pressed.connect(_on_load)
	_start_resume_button.pressed.connect(_on_resume)
	_start_exit_button.pressed.connect(_on_exit)
	_menu_button.pressed.connect(_on_menu)
	_exit_confirm_button.pressed.connect(_on_exit_confirm)
	_exit_cancel_button.pressed.connect(_on_exit_cancel)
	_ending_new_game_button.pressed.connect(_on_new_game)
	# Stato iniziale: schermata di menu (Riprendi/Salva restano disabilitati finché non si gioca).
	_enter_menu()
	if not Game.is_ready():
		_new_game_button.disabled = true
		_save_button.disabled = true
		_load_button.disabled = true
		_start_new_game_button.disabled = true
		_start_load_button.disabled = true
		# _start_save_button resta disabilitato (nessuna partita da salvare)
		_show_status("Errore di inizializzazione: " + Game.last_error())
	else:
		_show_status("Premi Nuova Partita per iniziare.")
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
	_show_status("Nuova partita avviata.")

func _on_save() -> void:
	if Game.save_game():
		_show_status("Partita salvata.")
	else:
		_show_status("Impossibile salvare la partita.")

func _on_load() -> void:
	if Game.load_game():
		_show_status("Partita caricata.")
	else:
		_show_status("Nessun salvataggio valido da caricare.")

## Mostra un messaggio di stato sia nella TopBar (in gioco) sia nel menu iniziale (pre-partita).
func _show_status(msg: String) -> void:
	_status.text = msg
	_start_status.text = msg

# --- Navigazione UI (stati: menu iniziale / gioco / conferma uscita) ---

## Stato MENU: schermata iniziale visibile, UI di gioco e overlay nascosti.
func _enter_menu() -> void:
	_exit_confirm.visible = false
	_ending_panel.visible = false
	_top_bar.visible = false
	_bottom_area.visible = false
	_character.visible = false
	_start_menu.visible = true

## Stato GIOCO: UI di gioco visibile, menu/overlay nascosti. Abilita Riprendi e Salva
## (da qui una partita esiste in memoria). Il ritratto è gestito da _apply_visual.
func _enter_game() -> void:
	_exit_confirm.visible = false
	_ending_panel.visible = false
	_start_menu.visible = false
	_top_bar.visible = true
	_bottom_area.visible = true
	_start_resume_button.disabled = false
	_start_save_button.disabled = false

## "Menu" (in gioco): torna alla schermata iniziale senza toccare lo stato del motore.
func _on_menu() -> void:
	_enter_menu()
	_show_status("Partita in pausa.")

## "Riprendi" (menu): torna alla partita corrente senza ricaricare né resettare.
func _on_resume() -> void:
	if Game.current_scene() == null:
		return
	_enter_game()
	_apply_visual(Game.current_scene())
	_render_current()

## "Esci" (menu): mostra la conferma centrale, non chiude subito.
func _on_exit() -> void:
	_start_menu.visible = false
	_exit_confirm.visible = true

## "Conferma" (dialog uscita): chiude l'applicazione.
func _on_exit_confirm() -> void:
	get_tree().quit()

## "Annulla" (dialog uscita): chiude la conferma e torna al menu iniziale.
func _on_exit_cancel() -> void:
	_enter_menu()

# --- Reazione ai segnali del Core ---

func _on_scene_changed(_scene_id: String) -> void:
	_enter_game()
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
		_show_status("Scena non disponibile (dati incoerenti?).")
		return
	_scene_text.text = _join(Game.current_text())
	_build_choices()

func _build_choices() -> void:
	_clear_choices()
	var choices := Game.available_choices()
	for choice in choices:
		var button := Button.new()
		button.text = choice.testo
		button.custom_minimum_size = Vector2(180, 44)
		button.disabled = not choice.abilitata
		if not choice.abilitata and choice.motivo_blocco != "":
			button.tooltip_text = choice.motivo_blocco
		button.pressed.connect(_on_choice.bind(choice.id))
		_choices.add_child(button)
	_choices_panel.visible = _choices.get_child_count() > 0
	if choices.is_empty():
		_show_status("Nessuna scelta disponibile in questa scena.")

func _clear_choices() -> void:
	for child in _choices.get_children():
		child.queue_free()

func _on_choice(choice_id: String) -> void:
	Game.choose(choice_id)

func _show_ending() -> void:
	var ending := Game.current_ending()
	if ending == null:
		_show_status("Finale non disponibile.")
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
## in sua assenza si usa il fallback (bg_auto_notte + ritratto di default).
func _apply_visual(scene: StoryScene) -> void:
	if scene == null:
		_character.visible = false
		return
	var visual: Dictionary = scene.visual
	if visual.is_empty():
		# Scene senza metadata (rete di sicurezza): fallback completo.
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

## Fallback ritratto per scene SENZA campo "visual" (rete di sicurezza: oggi tutte le scene
## di Atti 1-3 hanno "visual"). Default neutro "caldo", senza logica id-based.
func _set_portrait_fallback(_scene_id: String) -> void:
	_set_portrait_freddo(false)
	_character.visible = true

