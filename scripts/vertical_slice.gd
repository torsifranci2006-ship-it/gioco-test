extends Control

## Vertical slice VISIVO — scena di prova isolata dal gioco principale.
## NON usa il motore narrativo (StoryEngine/Game/EventBus) né i dati JSON:
## carica direttamente i 3 asset e mostra un brevissimo estratto statico di a1_s01.
## Scopo: validare leggibilità UI + lettura caldo/freddo di Daniel.

const BG_PATH := "res://assets/backgrounds/bg_auto_notte.png"
const DANIEL_CALDO := "res://assets/characters/daniel/char_daniel_caldo.png"
const DANIEL_FREDDO := "res://assets/characters/daniel/char_daniel_freddo.png"

# Estratto statico di a1_s01 (copia di prova; i dati JSON non vengono toccati).
const LINEA_1 := "Pioggia sottile, di quelle che non lavano via niente. Il corpo è contro la saracinesca, le luci blu che battono sull'asfalto."
const LINEA_2 := "Daniel è già accovacciato accanto: «Faceva i turni di notte, scommetto. Mani come queste non dormono.»"

@onready var _background: TextureRect = $Background
@onready var _character: TextureRect = $Character
@onready var _text: RichTextLabel = $Textbox/Margin/VBox/DialogueText
@onready var _continua: Button = $Textbox/Margin/VBox/Buttons/ContinuaButton
@onready var _toggle: Button = $Textbox/Margin/VBox/Buttons/ToggleDanielButton

var _daniel_caldo: bool = true
var _battuta: int = 0

func _ready() -> void:
	_background.texture = _try_load(BG_PATH)
	_set_daniel(true)
	_battuta = 0
	_text.text = LINEA_1
	_continua.pressed.connect(_on_continua)
	_toggle.pressed.connect(_on_toggle)

## Carica una texture solo se esiste (la scena resta apribile anche senza i PNG).
func _try_load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	push_warning("Vertical slice: asset mancante: " + path)
	return null

func _set_daniel(caldo: bool) -> void:
	_daniel_caldo = caldo
	var path := DANIEL_CALDO if caldo else DANIEL_FREDDO
	_character.texture = _try_load(path)
	_toggle.text = "Daniel: %s (debug)" % ("caldo" if caldo else "freddo")

func _on_toggle() -> void:
	_set_daniel(not _daniel_caldo)

func _on_continua() -> void:
	if _battuta == 0:
		_battuta = 1
		_text.text = LINEA_2
	else:
		_continua.disabled = true
