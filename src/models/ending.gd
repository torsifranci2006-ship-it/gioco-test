class_name Ending
extends RefCounted

## Modello di un ramo finale. Solo dati: nessuna logica narrativa.
## Vedi schemas/ending.schema.json.

var id: String = ""
var titolo: String = ""
var testo: String = ""
var decisione_finale: String = ""   ## id della scelta finale richiesta
var condizione: Dictionary = {}      ## condizione aggiuntiva per selezionare il ramo
var epiloghi: Array = []             ## Array di { contenuto, condizione }

## Costruisce dal dizionario JSON grezzo.
static func from_dict(data: Dictionary) -> Ending:
	var e := Ending.new()
	e.id = data.get("id", "")
	e.titolo = data.get("titolo", "")
	e.testo = data.get("testo", "")
	var req = data.get("requisiti", {})
	if req is Dictionary:
		e.decisione_finale = req.get("decisione_finale", "")
		var cond = req.get("condizione")
		e.condizione = cond if cond is Dictionary else {}
	var ep = data.get("epiloghi")
	e.epiloghi = ep if ep is Array else []
	return e
