class_name EndingResolver
extends RefCounted

## Sceglie il ramo finale e compone gli epiloghi in base allo stato.
## Generico: usa ConditionEvaluator, non conosce i contenuti dei finali.

## Seleziona il ramo: prima quello con decisione corrispondente e condizione soddisfatta;
## in mancanza, quello con condizione vuota (default per quella decisione). Null se nessuno.
static func resolve(endings: Array, final_choice_id: String, state: GameState) -> Ending:
	var fallback: Ending = null
	for e in endings:
		if e.decisione_finale != final_choice_id:
			continue
		if e.condizione.is_empty():
			if fallback == null:
				fallback = e
			continue
		if ConditionEvaluator.evaluate(e.condizione, state):
			return e
	return fallback

## Frammenti di epilogo applicabili (condizione vera) per il ramo dato.
static func epilogues_for(ending: Ending, state: GameState) -> Array[String]:
	var out: Array[String] = []
	if ending == null:
		return out
	for ep in ending.epiloghi:
		if ConditionEvaluator.evaluate(ep.get("condizione"), state):
			out.append(ep.get("contenuto", ""))
	return out
