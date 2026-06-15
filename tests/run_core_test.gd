extends SceneTree

## Runner di test/debug headless del core narrativo. Nessuna UI, nessun .tscn.
## Esegui con:  godot --headless -s res://tests/run_core_test.gd
## Verifica: caricamento scena iniziale, scelte disponibili, selezione, effetti,
## cambio scena, gating per attributi, risoluzione finali, salvataggio/caricamento.

var _failures := 0

func _initialize() -> void:
	print("== Test core narrativo ==")

	var engine := StoryEngine.new()
	_check("setup() riuscito", engine.setup(), engine.last_error)
	if engine.state == null:
		_finish()
		return

	# 1. Scena iniziale
	engine.start()
	_check("scena iniziale = prologo", engine.current_scene() != null and engine.current_scene().id == "prologo")
	print("   testo:")
	for t in engine.current_text():
		print("     - " + t)

	# 2. Scelte disponibili (gating): 'indaga_verita' parte disabilitata (determinazione 50 < 55)
	var choices := engine.available_choices()
	print("   scelte visibili: " + str(choices.size()))
	var indaga := _find_choice(choices, "indaga_verita")
	_check("'indaga_verita' visibile ma disabilitata", indaga != null and not indaga.abilitata)

	# 3. Effetti di una scelta: 'raggiungi_mara' -> +empatia, +relazione mara
	var empatia0 := engine.state.get_attribute("empatia")
	var mara0 := engine.state.get_character("mara").relazione
	engine.choose("raggiungi_mara")
	_check("empatia aumentata", engine.state.get_attribute("empatia") == empatia0 + 5)
	_check("relazione mara aumentata", engine.state.get_character("mara").relazione == mara0 + 10)

	# 4. Accumulo attributi -> sblocca scelta. 'procedi_solo' dà +3 determinazione.
	engine.choose("procedi_solo")
	engine.choose("procedi_solo")
	_check("determinazione >= 55 dopo accumulo", engine.state.get_attribute("determinazione") >= 55)
	indaga = _find_choice(engine.available_choices(), "indaga_verita")
	_check("'indaga_verita' ora abilitata", indaga != null and indaga.abilitata)

	# 5. Flag impostato da una scelta
	engine.choose("indaga_verita")
	_check("flag 'indizio_verita_1' impostato", engine.state.has_flag("indizio_verita_1"))

	# 6. Risoluzione finali (decisione + attributi). empatia >= 50 -> ramo_sacrificio
	var fine := engine.resolve_ending("accetta_verita")
	_check("decisione 'accetta_verita' -> ramo_sacrificio", fine != null and fine.id == "ramo_sacrificio")

	# 7. Epiloghi condizionati: con tobia morto compare il suo epilogo
	engine.state.set_character_state("tobia", GameCharacter.MORTO)
	var epiloghi := engine.epilogues_for(fine)
	_check("epilogo per tobia morto presente", _contains(epiloghi, "Tobia"))
	print("   epiloghi: " + str(epiloghi))

	# 8. Altro ramo: 'rifiuta_verita' (condizione nulla) -> ramo_rifiuto
	_check("decisione 'rifiuta_verita' -> ramo_rifiuto",
		engine.resolve_ending("rifiuta_verita") != null and engine.resolve_ending("rifiuta_verita").id == "ramo_rifiuto")

	# 9. Salvataggio / caricamento
	var save_path := "user://test_save.json"
	_check("save_game() riuscito", engine.save_game(save_path))
	var empatia_pre := engine.state.get_attribute("empatia")
	engine.state.add_attribute("empatia", 7)   # sporca lo stato
	_check("load_game() riuscito", engine.load_game(save_path))
	_check("stato ripristinato dal salvataggio", engine.state.get_attribute("empatia") == empatia_pre)

	# 10. Ferite: progressione del rischio e morte automatica SOLO in avanzamento
	print("-- ferite: progressione e morte automatica --")
	var e1 := _fresh()
	e1.choose("affronta_pericolo")             # ferisce tobia; l'avanzamento ticka: rischio 0 -> 40
	var w := e1.state.get_wound("tobia")
	_check("tobia ferito dopo l'evento", e1.state.get_character("tobia").stato == GameCharacter.FERITO)
	_check("rischio=40 e scene=1 dopo 1 avanzamento", int(w.get("rischio", -1)) == 40 and int(w.get("scene", -1)) == 1)
	# Restare fermi (rivalutare le scelte) NON deve uccidere né far progredire il rischio.
	var _ignored := e1.available_choices()
	_check("nessuna morte/progressione restando fermi",
		e1.state.get_character("tobia").stato == GameCharacter.FERITO
		and int(e1.state.get_wound("tobia").get("rischio")) == 40)
	e1.choose("procedi_solo")                  # avanzamento: rischio -> 80
	_check("rischio=80 dopo 2 avanzamenti", int(e1.state.get_wound("tobia").get("rischio", -1)) == 80)
	e1.choose("procedi_solo")                  # avanzamento: rischio -> 120 >= 100 -> morte
	_check("morte automatica oltre soglia (3 avanzamenti)", e1.state.get_character("tobia").stato == GameCharacter.MORTO)
	_check("record ferita rimosso alla morte", not e1.state.is_wounded("tobia"))

	# 11. Cura in tempo -> normale
	print("-- ferite: cura in tempo --")
	var e2 := _fresh()
	e2.choose("affronta_pericolo")             # rischio 40 (<= soglia_cura 50)
	e2.choose("medica_tobia")
	_check("cura in tempo: tobia torna normale", e2.state.get_character("tobia").stato == GameCharacter.NORMALE)
	_check("cura riuscita: record ferita rimosso", not e2.state.is_wounded("tobia"))

	# 12. Cura troppo tardi -> morte
	print("-- ferite: cura troppo tardi --")
	var e3 := _fresh()
	e3.choose("affronta_pericolo")             # rischio 40
	e3.choose("procedi_solo")                  # rischio 80 (> soglia_cura 50)
	e3.choose("medica_tobia")
	_check("cura tardiva: tobia muore", e3.state.get_character("tobia").stato == GameCharacter.MORTO)

	# 13. La condizione 'ferita' guida il testo della scena
	print("-- ferite: condizione di testo --")
	var e4 := _fresh()
	e4.choose("affronta_pericolo")             # rischio 40 -> sotto la soglia 50
	_check("testo d'allarme assente sotto soglia", not _contains(e4.current_text(), "peggiorano"))
	e4.choose("procedi_solo")                  # rischio 80 -> >= 50
	_check("testo d'allarme presente sopra soglia", _contains(e4.current_text(), "peggiorano"))

	_finish()

func _fresh() -> StoryEngine:
	var e := StoryEngine.new()
	e.setup()
	e.start()
	return e

func _finish() -> void:
	if _failures == 0:
		print("== TUTTI I TEST OK ==")
		quit(0)
	else:
		printerr("== %d TEST FALLITI ==" % _failures)
		quit(1)

func _check(label: String, cond: bool, detail: String = "") -> void:
	if cond:
		print("  [OK] " + label)
	else:
		_failures += 1
		printerr("  [FAIL] " + label + ("  -> " + detail if detail != "" else ""))

func _find_choice(choices: Array, id: String) -> Choice:
	for c in choices:
		if c.id == id:
			return c
	return null

func _contains(items: Array, needle: String) -> bool:
	for s in items:
		if String(s).find(needle) != -1:
			return true
	return false
