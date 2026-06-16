class_name StoryScene
extends RefCounted

## Modello di una scena narrativa. Solo dati: nessuna logica narrativa.
## Vedi schemas/scene.schema.json.

var id: String = ""
var titolo: String = ""
var atto: String = ""
var precondizioni: Dictionary = {}   ## condizione di ingresso; vuota = sempre accessibile
var testo: Array = []                ## Array di { contenuto, personaggio?, condizione }
var on_enter: Dictionary = {}        ## DSL Effetto applicato all'ingresso
var scelte: Array[Choice] = []
var prossima_default: String = ""
var visual: Dictionary = {}          ## metadati di presentazione UI (background/portrait); vuoto = nessuno

## Costruisce dal dizionario JSON grezzo.
static func from_dict(data: Dictionary) -> StoryScene:
	var s := StoryScene.new()
	s.id = data.get("id", "")
	s.titolo = data.get("titolo", "")
	s.atto = data.get("atto", "")
	var pre = data.get("precondizioni")
	s.precondizioni = pre if pre is Dictionary else {}
	var txt = data.get("testo")
	s.testo = txt if txt is Array else []
	var oe = data.get("on_enter")
	s.on_enter = oe if oe is Dictionary else {}
	s.scelte = []
	for cd in data.get("scelte", []):
		s.scelte.append(Choice.from_dict(cd))
	var pd = data.get("prossima_default")
	s.prossima_default = pd if pd is String else ""
	var v = data.get("visual")
	s.visual = v if v is Dictionary else {}
	return s
