class_name GameCharacter
extends RefCounted

## Modello di un personaggio chiave. Solo dati + derivazione del supporto.
## Lo stato è una String allineata ai dati JSON e alle condizioni (niente conversioni enum).
## Vedi schemas/character.schema.json.

const NORMALE := "normale"
const FERITO := "ferito"
const MORTO := "morto"

## Severità per le transizioni di stato monotone (solo peggioramento).
const _SEVERITA := { "normale": 0, "ferito": 1, "morto": 2 }

## Parametri di default della ferita, usati se il JSON non li specifica.
## Tutto configurabile per-personaggio nel blocco "ferita" di characters.json.
const DEFAULT_FERITA := {
	"rischio_iniziale": 0,    # rischio al momento del ferimento
	"rischio_per_scena": 10,  # incremento del rischio a ogni avanzamento scena
	"soglia_critica": 100,    # rischio >= soglia_critica -> morte automatica (solo in avanzamento)
	"soglia_cura": 50,        # la cura riesce solo se rischio <= soglia_cura, altrimenti morte
}

var id: String = ""
var nome: String = ""
var descrizione: String = ""
var stato: String = NORMALE
var relazione: int = 0
var regole_stato: Array = []   ## Array di { quando: <condizione>, diventa: "ferito"|"morto" }
var ferita_config: Dictionary = {}   ## parametri ferita (default + override dal JSON)

## Supporto derivato dallo stato (regola generica, non narrativa).
func supporto() -> String:
	match stato:
		NORMALE: return "pieno"
		FERITO: return "limitato"
		_: return "nessuno"

static func severita(s: String) -> int:
	return _SEVERITA.get(s, 0)

## Costruisce dal dizionario JSON grezzo.
static func from_dict(data: Dictionary) -> GameCharacter:
	var c := GameCharacter.new()
	c.id = data.get("id", "")
	c.nome = data.get("nome", "")
	c.descrizione = data.get("descrizione", "")
	c.stato = data.get("stato_iniziale", NORMALE)
	c.relazione = int(data.get("relazione_iniziale", 0))
	var regole = data.get("regole_stato")
	c.regole_stato = regole if regole is Array else []
	# Config ferita: default sovrascritti dai valori presenti nel JSON.
	c.ferita_config = DEFAULT_FERITA.duplicate()
	var fer = data.get("ferita")
	if fer is Dictionary:
		for k in fer.keys():
			c.ferita_config[k] = int(fer[k])
	return c
