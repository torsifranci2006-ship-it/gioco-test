class_name ConditionEvaluator
extends RefCounted

## Valuta il DSL Condizione (vedi schemas/condition.schema.json) contro un GameState.
## Motore puramente generico: interpreta la struttura, non conosce alcun contenuto.
## Più chiavi nello stesso oggetto sono in AND. Condizione vuota/null = sempre vera.

static func evaluate(condition, state: GameState) -> bool:
	if condition == null or not (condition is Dictionary) or condition.is_empty():
		return true
	for key in condition.keys():
		if String(key).begins_with("_"):
			continue   # chiave-commento per gli autori
		var val = condition[key]
		var ok := true
		match key:
			"attributo":
				ok = _compare(state.get_attribute(val["id"]), val["op"], int(val["valore"]))
			"flag":
				var presente: bool = val.get("presente", true)
				ok = state.has_flag(val["id"]) == presente
			"personaggio":
				var c := state.get_character(val["id"])
				ok = c != null and c.stato == val["stato"]
			"relazione":
				var cr := state.get_character(val["id"])
				ok = cr != null and _compare(cr.relazione, val["op"], int(val["valore"]))
			"ferita":
				# Confronta un campo del record ferita ("rischio" o "scene").
				# Falsa se il personaggio non è ferito.
				var w := state.get_wound(val["id"])
				if w.is_empty():
					ok = false
				else:
					var campo: String = val.get("campo", "rischio")
					ok = _compare(int(w.get(campo, 0)), val["op"], int(val["valore"]))
			"tutte":
				for sub in val:
					if not evaluate(sub, state):
						ok = false
						break
			"alcune":
				ok = false
				for sub in val:
					if evaluate(sub, state):
						ok = true
						break
			"non":
				ok = not evaluate(val, state)
			_:
				push_error("ConditionEvaluator: chiave sconosciuta: " + String(key))
				ok = false
		if not ok:
			return false
	return true

static func _compare(a: int, op: String, b: int) -> bool:
	match op:
		">=": return a >= b
		"<=": return a <= b
		"==": return a == b
		">": return a > b
		"<": return a < b
		_:
			push_error("ConditionEvaluator: operatore sconosciuto: " + op)
			return false
