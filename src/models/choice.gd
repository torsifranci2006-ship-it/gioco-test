class_name Choice
extends RefCounted

## Modello di una scelta dentro una scena. Solo dati: nessuna logica narrativa.
## Vedi schemas/scene.schema.json (proprietà "scelte").

var id: String = ""
var testo: String = ""
var visibile_se: Dictionary = {}   ## condizione; vuota = sempre visibile
var abilitata_se: Dictionary = {}  ## condizione; vuota = sempre abilitata
var motivo_blocco: String = ""
var effetti: Dictionary = {}       ## DSL Effetto
var prossima: String = ""          ## id scena successiva, oppure l'id della scena finale

## Stato runtime, calcolato da StoryEngine.available_choices(): non proviene dai dati.
var abilitata: bool = true

## Costruisce dal dizionario JSON grezzo.
static func from_dict(data: Dictionary) -> Choice:
	var c := Choice.new()
	c.id = data.get("id", "")
	c.testo = data.get("testo", "")
	var vis = data.get("visibile_se")
	c.visibile_se = vis if vis is Dictionary else {}
	var ena = data.get("abilitata_se")
	c.abilitata_se = ena if ena is Dictionary else {}
	var mot = data.get("motivo_blocco")
	c.motivo_blocco = mot if mot is String else ""
	var eff = data.get("effetti")
	c.effetti = eff if eff is Dictionary else {}
	c.prossima = data.get("prossima", "")
	return c
