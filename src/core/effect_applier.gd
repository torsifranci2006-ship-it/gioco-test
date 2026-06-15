class_name EffectApplier
extends RefCounted

## Applica il DSL Effetto (vedi schemas/effect.schema.json) a un GameState.
## Motore generico: applica delta/flag/stati senza conoscere contenuti specifici.
## Dopo l'applicazione rivaluta le regole_stato dei personaggi (transizioni automatiche).
## I segnali vengono emessi dai setter di GameState.

static func apply(effect, state: GameState) -> void:
	if effect == null or not (effect is Dictionary) or effect.is_empty():
		return
	for a in effect.get("attributi", []):
		state.add_attribute(a["id"], int(a["delta"]))
	for fid in effect.get("flag_set", []):
		state.set_flag(fid)
	for fid in effect.get("flag_clear", []):
		state.clear_flag(fid)
	for cs in effect.get("personaggio_stato", []):
		state.set_character_state(cs["id"], cs["stato"])
	for cid in effect.get("cura", []):
		state.try_cure(cid)
	for r in effect.get("relazione", []):
		state.add_relazione(r["id"], int(r["delta"]))
	_apply_state_rules(state)

## Valuta le regole_stato di ogni personaggio; applica solo transizioni di peggioramento.
static func _apply_state_rules(state: GameState) -> void:
	for id in state.characters.keys():
		var c: GameCharacter = state.characters[id]
		for rule in c.regole_stato:
			var target: String = rule.get("diventa", "")
			if target == "":
				continue
			if GameCharacter.severita(target) <= GameCharacter.severita(c.stato):
				continue
			if ConditionEvaluator.evaluate(rule.get("quando", {}), state):
				state.set_character_state(id, target)
