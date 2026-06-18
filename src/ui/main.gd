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
@onready var _menu_button: Button = $TopBar/TopBarMargin/Controls/MenuButton
@onready var _dossier_button: Button = $TopBar/TopBarMargin/Controls/DossierButton
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
@onready var _load_panel: PanelContainer = $LoadPanel
@onready var _load_list: VBoxContainer = $LoadPanel/LoadMargin/LoadVBox/LoadScroll/LoadList
@onready var _load_cancel_button: Button = $LoadPanel/LoadMargin/LoadVBox/LoadCancelButton
@onready var _save_panel: PanelContainer = $SavePanel
@onready var _save_list: VBoxContainer = $SavePanel/SaveMargin/SaveVBox/SaveScroll/SaveList
@onready var _save_new_button: Button = $SavePanel/SaveMargin/SaveVBox/SaveNewButton
@onready var _save_cancel_button: Button = $SavePanel/SaveMargin/SaveVBox/SaveCancelButton
@onready var _save_confirm: PanelContainer = $SaveConfirm
@onready var _save_confirm_label: Label = $SaveConfirm/SaveConfirmMargin/SaveConfirmVBox/SaveConfirmLabel
@onready var _save_confirm_yes_button: Button = $SaveConfirm/SaveConfirmMargin/SaveConfirmVBox/SaveConfirmButtons/SaveConfirmYesButton
@onready var _save_confirm_no_button: Button = $SaveConfirm/SaveConfirmMargin/SaveConfirmVBox/SaveConfirmButtons/SaveConfirmNoButton
@onready var _dossier_panel: PanelContainer = $DossierPanel
@onready var _dossier_list: VBoxContainer = $DossierPanel/DossierMargin/DossierVBox/DossierBody/DossierListScroll/DossierList
@onready var _dossier_details: VBoxContainer = $DossierPanel/DossierMargin/DossierVBox/DossierBody/DossierDetails
@onready var _dossier_close_button: Button = $DossierPanel/DossierMargin/DossierVBox/DossierCloseButton
@onready var _changes_overlay: PanelContainer = $ChangesOverlay
@onready var _changes_list: VBoxContainer = $ChangesOverlay/ChangesMargin/ChangesList
@onready var _changes_timer: Timer = $ChangesTimer

var _panel_origin: String = "menu"   ## contesto di apertura di Save/Load: "menu" o "game"
var _pending_save_slot: int = 0       ## slot da confermare nel SaveConfirm

## Traduzione dei codici neutri del Core in etichette leggibili (le etichette UI vivono qui).
const RELAZIONE_BAND_LABEL := {
	"diffidente": "Diffidente",
	"neutrale": "Neutrale",
	"fiducia": "Fiducia",
	"alleato": "Alleato",
}
const STATO_LABEL := {
	"normale": "Normale",
	"ferito": "Ferito",
	"morto": "Morto",
}
const SUPPORTO_LABEL := {
	"pieno": "Pieno",
	"limitato": "Limitato",
	"nessuno": "Nessuno",
}
## Etichette della riga "Ferite" (derivata dallo stato; copre anche "morto").
const FERITE_LABEL := {
	"normale": "Nessuna",
	"ferito": "Ferito",
	"morto": "Morto",
}
## Valori (0-100) delle barre di presentazione. Mappature UI, non contenuto narrativo.
const SUPPORTO_BAR := {
	"pieno": 100,
	"limitato": 50,
	"nessuno": 0,
}
const FERITE_BAR := {
	"normale": 100,
	"ferito": 50,
	"morto": 0,
}

func _ready() -> void:
	EventBus.scene_changed.connect(_on_scene_changed)
	EventBus.game_ended.connect(_on_game_ended)
	EventBus.choice_effects_applied.connect(_on_choice_effects)
	_changes_timer.timeout.connect(_on_changes_timer_timeout)
	_start_new_game_button.pressed.connect(_on_new_game)
	_start_save_button.pressed.connect(_on_open_save.bind("menu"))
	_start_load_button.pressed.connect(_on_open_load.bind("menu"))
	_start_resume_button.pressed.connect(_on_resume)
	_start_exit_button.pressed.connect(_on_exit)
	_menu_button.pressed.connect(_on_menu)
	_dossier_button.pressed.connect(_on_open_dossier)
	_dossier_close_button.pressed.connect(_on_dossier_close)
	# La sidebar Dossier deve terminare sul bordo superiore di BottomArea, la cui altezza è
	# dinamica (testo + scelte): la ri-allineiamo a ogni resize di BottomArea (e della finestra).
	_bottom_area.resized.connect(_sync_dossier_height)
	_exit_confirm_button.pressed.connect(_on_exit_confirm)
	_exit_cancel_button.pressed.connect(_on_exit_cancel)
	_load_cancel_button.pressed.connect(_on_panel_cancel)
	_save_cancel_button.pressed.connect(_on_panel_cancel)
	_save_new_button.pressed.connect(_on_save_new)
	_save_confirm_yes_button.pressed.connect(_on_save_confirm_yes)
	_save_confirm_no_button.pressed.connect(_on_save_confirm_no)
	_ending_new_game_button.pressed.connect(_on_new_game)
	# Stato iniziale: schermata di menu (Riprendi/Salva restano disabilitati finché non si gioca).
	_enter_menu()
	if not Game.is_ready():
		_start_new_game_button.disabled = true
		_start_load_button.disabled = true
		_start_resume_button.disabled = true
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

# --- Menu salvataggi / caricamenti (overlay centrati) ---

## Apre il pannello Carica. origin = "menu" | "game" (per il ritorno con Annulla).
func _on_open_load(origin: String) -> void:
	_panel_origin = origin
	_start_menu.visible = false
	_top_bar.visible = false
	_bottom_area.visible = false
	_populate_load_list()
	_load_panel.visible = true

## Apre il pannello Salva.
func _on_open_save(origin: String) -> void:
	_panel_origin = origin
	_start_menu.visible = false
	_top_bar.visible = false
	_bottom_area.visible = false
	_populate_save_list()
	_save_panel.visible = true

## Annulla da LoadPanel/SavePanel: torna al contesto di provenienza.
func _on_panel_cancel() -> void:
	if _panel_origin == "game":
		_enter_game()
	else:
		_enter_menu()

## Popola la lista Carica: una riga-pulsante per salvataggio (clic = carica subito).
func _populate_load_list() -> void:
	_clear_container(_load_list)
	var saves := Game.list_saves()
	for entry in saves:
		_load_list.add_child(_make_save_row(entry, _on_load_slot.bind(int(entry["slot"]))))
	if saves.is_empty():
		_load_list.add_child(_make_empty_label("Nessun salvataggio disponibile."))

## Popola la lista Salva: righe sovrascrivibili (clic = conferma sovrascrittura).
func _populate_save_list() -> void:
	_clear_container(_save_list)
	for entry in Game.list_saves():
		_save_list.add_child(_make_save_row(entry, _on_overwrite_slot.bind(int(entry["slot"]))))

## Clic su uno slot nel LoadPanel: carica (nessuna conferma). load_slot emette scene_changed.
func _on_load_slot(slot: int) -> void:
	if Game.load_slot(slot):
		_show_status("Partita caricata.")
	else:
		_show_status("Caricamento non riuscito.")

## "Nuovo salvataggio": chiede conferma per creare un nuovo slot.
func _on_save_new() -> void:
	_pending_save_slot = Game.next_free_slot()
	_save_confirm_label.text = "Creare un nuovo salvataggio?"
	_save_panel.visible = false
	_save_confirm.visible = true

## Clic su uno slot esistente nel SavePanel: chiede conferma di sovrascrittura.
func _on_overwrite_slot(slot: int) -> void:
	_pending_save_slot = slot
	_save_confirm_label.text = "Sovrascrivere lo slot %d?" % slot
	_save_panel.visible = false
	_save_confirm.visible = true

## Conferma salvataggio (nuovo o sovrascrittura): salva e torna al SavePanel aggiornato.
func _on_save_confirm_yes() -> void:
	var ok := Game.save_slot(_pending_save_slot)
	_save_confirm.visible = false
	_populate_save_list()
	_save_panel.visible = true
	_show_status("Salvato." if ok else "Salvataggio non riuscito.")

## Annulla la conferma: torna al menu salvataggi senza salvare.
func _on_save_confirm_no() -> void:
	_save_confirm.visible = false
	_save_panel.visible = true

## Riga-salvataggio: Button cliccabile multi-riga (titolo / id · data-ora).
func _make_save_row(entry: Dictionary, on_press: Callable) -> Button:
	var title := String(entry.get("scene_title", ""))
	var scene_id := String(entry.get("scene_id", ""))
	if title == "":
		title = scene_id
	var btn := Button.new()
	btn.text = "%s\n%s · %s" % [title, scene_id, _format_datetime(int(entry.get("mtime", 0)))]
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(360, 0)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(on_press)
	return btn

func _make_empty_label(msg: String) -> Label:
	var l := Label.new()
	l.text = msg
	return l

func _clear_container(c: Node) -> void:
	for child in c.get_children():
		child.queue_free()

## Formatta un timestamp Unix come "gg/mm/aaaa hh:mm".
func _format_datetime(unix_time: int) -> String:
	if unix_time <= 0:
		return "—"
	var d := Time.get_datetime_dict_from_unix_time(unix_time)
	return "%02d/%02d/%04d %02d:%02d" % [d.day, d.month, d.year, d.hour, d.minute]

## Mostra un messaggio di stato sia nella TopBar (in gioco) sia nel menu iniziale (pre-partita).
func _show_status(msg: String) -> void:
	_status.text = msg
	_start_status.text = msg

# --- Navigazione UI (stati: menu iniziale / gioco / conferma uscita) ---

## Stato MENU: schermata iniziale visibile, UI di gioco e overlay nascosti.
func _enter_menu() -> void:
	_exit_confirm.visible = false
	_ending_panel.visible = false
	_load_panel.visible = false
	_save_panel.visible = false
	_save_confirm.visible = false
	_dossier_panel.visible = false
	_changes_overlay.visible = false
	_changes_timer.stop()
	_top_bar.visible = false
	_bottom_area.visible = false
	_character.visible = false
	_start_menu.visible = true
	# "Riprendi" dipende esclusivamente dall'esistenza dell'autosave su disco.
	_start_resume_button.disabled = not Game.has_autosave()

## Stato GIOCO: UI di gioco visibile, menu/overlay nascosti. Abilita Riprendi e Salva
## (da qui una partita esiste in memoria). Il ritratto è gestito da _apply_visual.
func _enter_game() -> void:
	_exit_confirm.visible = false
	_ending_panel.visible = false
	_load_panel.visible = false
	_save_panel.visible = false
	_save_confirm.visible = false
	_dossier_panel.visible = false
	_start_menu.visible = false
	_top_bar.visible = true
	_bottom_area.visible = true
	_start_save_button.disabled = false

## "Menu" (in gioco): torna alla schermata iniziale senza toccare lo stato del motore.
func _on_menu() -> void:
	Game.autosave()   # così "Riprendi" punta sempre all'ultimo stato giocato
	_enter_menu()
	_show_status("Partita in pausa. Autosave aggiornato.")

## "Riprendi" (menu): carica l'autosave da disco ed entra direttamente in gioco.
## Non apre il menu Carica e non mostra liste.
func _on_resume() -> void:
	if not Game.has_autosave():
		return
	if Game.load_autosave():
		# load_autosave emette scene_changed -> _on_scene_changed -> _enter_game
		_show_status("Partita ripresa.")
	else:
		_show_status("Autosave non valido.")
		_start_resume_button.disabled = true

## "Esci" (menu): mostra la conferma centrale, non chiude subito.
func _on_exit() -> void:
	_start_menu.visible = false
	_exit_confirm.visible = true

## "Conferma" (dialog uscita): autosalva e chiude l'applicazione.
func _on_exit_confirm() -> void:
	Game.quit_with_autosave()

## "Annulla" (dialog uscita): chiude la conferma e torna al menu iniziale.
func _on_exit_cancel() -> void:
	_enter_menu()

# --- Dossier personaggi (overlay in gioco, sola lettura) ---

## "Dossier" (in gioco): apre la sidebar con i personaggi incontrati. Non tocca il motore e
## NON nasconde TopBar/BottomArea: la partita resta visibile dietro la sidebar.
func _on_open_dossier() -> void:
	_sync_dossier_height()   # allinea il fondo della sidebar a BottomArea già prima di mostrarla
	_populate_dossier()
	_dossier_panel.visible = true

## "Chiudi": nasconde la sidebar lasciando la partita esattamente com'è.
func _on_dossier_close() -> void:
	_dossier_panel.visible = false

## Allinea il bordo INFERIORE della sidebar Dossier al bordo SUPERIORE di BottomArea (zona scena).
## BottomArea è ancorata in basso e cresce verso l'alto: la sua altezza renderizzata (size.y) varia
## con testo e scelte, quindi un offset fisso sarebbe fragile. Leggiamo l'altezza reale a runtime.
func _sync_dossier_height() -> void:
	_dossier_panel.offset_bottom = -_bottom_area.size.y

## Popola la lista a sinistra dai dati (già privi di spoiler) forniti da Game; mostra il primo.
func _populate_dossier() -> void:
	_clear_container(_dossier_list)
	_clear_container(_dossier_details)
	var chars := Game.met_characters()
	if chars.is_empty():
		_dossier_list.add_child(_make_empty_label("Nessun personaggio nel dossier."))
		return
	for entry in chars:
		var btn := Button.new()
		btn.text = String(entry.get("nome", ""))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_show_dossier_details.bind(entry))
		_dossier_list.add_child(btn)
	_show_dossier_details(chars[0])

## Mostra i dettagli del personaggio selezionato. Nome + Stato, poi un blocco etichetta+barra per
## Supporto, Relazione e Ferite. Nessuna descrizione, nessun numero, nessun attributo nascosto.
func _show_dossier_details(entry: Dictionary) -> void:
	_clear_container(_dossier_details)
	_dossier_details.add_child(_make_detail_label(String(entry.get("nome", "")), 20, Color(0.9, 0.85, 0.7)))
	var stato_code := String(entry.get("stato", ""))
	_dossier_details.add_child(_make_detail_label("Stato: " + STATO_LABEL.get(stato_code, stato_code)))
	# Supporto (pieno/limitato/nessuno -> 100/50/0)
	var supp_code := String(entry.get("supporto", ""))
	_dossier_details.add_child(_make_stat_block(
		"Supporto: " + SUPPORTO_LABEL.get(supp_code, supp_code),
		SUPPORTO_BAR.get(supp_code, 0)))
	# Relazione (valore reale dal Core, clampato 0-100 solo per la barra); fascia testuale mantenuta
	var band := String(entry.get("relazione_fascia", ""))
	_dossier_details.add_child(_make_stat_block(
		"Relazione: " + RELAZIONE_BAND_LABEL.get(band, band),
		int(entry.get("relazione_value", 0))))
	# Ferite (derivata dallo stato: normale/ferito/morto -> 100/50/0)
	_dossier_details.add_child(_make_stat_block(
		"Ferite: " + FERITE_LABEL.get(stato_code, stato_code),
		FERITE_BAR.get(stato_code, 0)))

## Blocco di una statistica: etichetta con, subito sotto, la sua barra (raggruppate strette).
func _make_stat_block(label_text: String, bar_value: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	box.add_child(_make_detail_label(label_text))
	box.add_child(_make_stat_bar(bar_value))
	return box

## Barra visiva di una statistica (stile noir dal Theme). Il value è clampato 0-100 SOLO a fini
## grafici e non è mai mostrato come testo (show_percentage = false).
func _make_stat_bar(value: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = clampi(value, 0, 100)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 14)
	return bar

## Riga di dettaglio del Dossier (Label con font/colore opzionali).
func _make_detail_label(text: String, font_size: int = 0, color: Color = Color(0, 0, 0, 0)) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font_size > 0:
		l.add_theme_font_size_override("font_size", font_size)
	if color.a > 0.0:
		l.add_theme_color_override("font_color", color)
	return l

# --- Overlay cambiamenti dopo scelta (alto a destra, transitorio) ---

## Mostra l'overlay con i cambiamenti (già spoiler-free) ricevuti dal Core; auto-nascosto dal Timer.
func _on_choice_effects(changes: Array) -> void:
	_clear_container(_changes_list)
	for change in changes:
		_changes_list.add_child(_make_change_label(change))
	if _changes_list.get_child_count() == 0:
		return
	_changes_overlay.visible = true
	_changes_timer.start()   # one_shot: riparte da capo a ogni scelta

func _on_changes_timer_timeout() -> void:
	_changes_overlay.visible = false

## Riga dell'overlay: "Nome ↑/↓" per attributi/relazioni, "Nome: Stato" per i cambi di stato.
## Solo direzione e nome: nessun valore numerico mostrato.
func _make_change_label(change: Dictionary) -> Label:
	var l := Label.new()
	var nome := String(change.get("nome", ""))
	var tipo := String(change.get("tipo", ""))
	var direction := int(change.get("direzione", 0))
	var up := Color(0.62, 0.78, 0.58)
	var down := Color(0.85, 0.6, 0.52)
	var text := ""
	var color := Color(0.9, 0.85, 0.7)
	if tipo == "stato":
		var stato_code := String(change.get("stato", ""))
		text = nome + ": " + STATO_LABEL.get(stato_code, stato_code)
		color = up if stato_code == "normale" else down
	elif tipo == "relazione":
		text = "Fiducia " + nome + " " + ("↑" if direction > 0 else "↓")
		color = up if direction > 0 else down
	elif tipo == "attributo":
		text = nome + " " + ("↑" if direction > 0 else "↓")
		color = up if direction > 0 else down
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", 15)
	return l

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

