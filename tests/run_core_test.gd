extends SceneTree

## Suite di test/debug headless del core narrativo. Nessuna UI, nessun .tscn.
## Esegui con:  godot --headless --path . -s res://tests/run_core_test.gd
##
## Copre (T1..T10): boot/scena iniziale, percorso Giustizia, percorso Vendetta,
## sistema ferite, regole_stato automatiche, salvataggio/caricamento, EndingResolver,
## epiloghi condizionali, soglie attributo, idempotenza degli hub.
##
## Principi: ogni test crea il PROPRIO StoryEngine (nessuna dipendenza tra test);
## le asserzioni usano _check() (non assert hard) così la suite gira fino in fondo
## e ogni test può fallire in modo indipendente, con messaggi leggibili.

const SAVE_PATH := "user://test_save_6b.json"

var _failures := 0
var _ok := 0

func _initialize() -> void:
	print("== Test core narrativo (T1..T10) ==")
	_t1_boot()
	_t2_giustizia()
	_t3_vendetta()
	_t4_ferite()
	_t5_regole_stato()
	_t6_save_load()
	_t7_resolver()
	_t8_epiloghi()
	_t9_soglie()
	_t10_idempotenza_hub()
	_finish()

# ---------------------------------------------------------------------------
# T1 — Boot & scena iniziale
# ---------------------------------------------------------------------------
func _t1_boot() -> void:
	_section("T1 Boot & scena iniziale")
	var e := _engine()
	if e.state == null:
		return
	e.start()
	var sc := e.current_scene()
	_check("scena iniziale = a1_s01", sc != null and sc.id == "a1_s01", _scene_id(e))
	_check("testo iniziale non vuoto", e.current_text().size() >= 1)
	_check("almeno una scelta disponibile", e.available_choices().size() >= 1)

# ---------------------------------------------------------------------------
# T2 — Percorso GIUSTIZIA completo (verità completa, Tobia salvo, Halloran, Ellie)
# ---------------------------------------------------------------------------
func _t2_giustizia() -> void:
	_section("T2 Percorso Giustizia")
	var e := _started()
	if e == null:
		return
	var path := [
		"nota_anomalia",            # a1_s01 -> a1_s02
		"vai_obitorio",             # a1_s02 -> a1_s04
		"rispetta_mara",            # a1_s04 -> a1_s02
		"procedi_empatia",          # a1_s02 -> a1_s03
		"leggi_anomalie",           # a1_s03 -> a1_s06
		"apriti",                   # a1_s06 -> a1_s07  (confidenza_daniel)
		"gesto_ellie",              # a1_s07 -> a1_s08  (ellie_contatto)
		"proteggi_testimone",       # a1_s08 -> a2_s01
		"leggi_firma",              # a2_s01 -> a2_s02
		"vai_laboratorio",          # a2_s02 -> a2_s08
		"analizza_con_mara",        # a2_s08 -> a2_s02  (M3, relazione mara)
		"indaga_halloran",          # a2_s02 -> a2_s04
		"cogli_reazione",           # a2_s04 -> a2_s02  (D4, sospetto_halloran)
		"procedi_lucidita",         # a2_s02 -> a2_s06
		"ascolta_tobia",            # a2_s06 -> a2_s06  (M6)
		"scava_roeder",             # a2_s06 -> a2_s06  (roeder_innocente_scoperto)
		"procedi",                  # a2_s06 -> a2_s07
		"proteggi_tobia",           # a2_s07 -> a2_s09  (tobia_salvo)
		"nota_ritagli",             # a2_s09 -> a2_s10  (D6)
		"vai_halloran_umano",       # a2_s10 -> a2_s11
		"accogli_halloran",         # a2_s11 -> a2_s10  (halloran_pentito)
		"fidati_daniel",            # a2_s10 -> a2_s13
		"guarda_verita",            # a2_s13 -> a3_s01
		"chiudi_logica",            # a3_s01 -> a3_s02
		"assicura_log",             # a3_s02 -> a3_s02  (S1)
		"assicura_tobia",           # a3_s02 -> a3_s02  (S2)
		"assicura_firma",           # a3_s02 -> a3_s02  (S3)
		"assicura_roeder",          # a3_s02 -> a3_s02  (S4)
		"procedi_rivelazione",      # a3_s02 -> a3_s03
		"affronta_daniel",          # a3_s03 -> a3_s04
		"vai_testimonianza",        # a3_s04 -> a3_s05
		"accetta_responsabilita",   # a3_s05 -> a3_s04  (halloran_testimonia)
		"appello_umanita",          # a3_s04 -> a3_s06
		"arresta_daniel",           # a3_s06 -> finale
	]
	_walk(e, path)
	_check("empatia >= 55 (variante umile)", e.state.get_attribute("empatia") >= 55,
		"empatia=%d" % e.state.get_attribute("empatia"))
	_check("lucidita >= 60 (S3 raggiungibile)", e.state.get_attribute("lucidita") >= 60,
		"lucidita=%d" % e.state.get_attribute("lucidita"))
	_check("flag roeder_innocente_scoperto", e.state.has_flag("roeder_innocente_scoperto"))
	_check("prova S3 (firma personale) ottenuta", e.state.has_flag("prova_firma_personale"))
	_check("flag daniel_arrestato", e.state.has_flag("daniel_arrestato"))
	_check("Tobia normale a fine corsa", _char(e, "tobia") == GameCharacter.NORMALE)
	var fine := e.current_ending()
	_check("finale = ramo_giustizia", fine != null and fine.id == "ramo_giustizia",
		(fine.id if fine else "null"))
	var ep := e.current_epilogues()
	_check("epilogo umile presente", _contains(ep, "Non ti sei fatto giudice"))
	_check("epilogo Tobia futuro presente", _contains(ep, "Tobia avrà altri inverni"))
	_check("epilogo Ellie presente", _contains(ep, "Chiami Ellie"))
	_check("epilogo Tobia perduto ASSENTE", not _contains(ep, "banco vuoto"))

# ---------------------------------------------------------------------------
# T3 — Percorso VENDETTA completo (variante vendetta; Tobia sacrificato)
# ---------------------------------------------------------------------------
func _t3_vendetta() -> void:
	_section("T3 Percorso Vendetta")
	var e := _started()
	if e == null:
		return
	var path := [
		"concentrati_risultato",    # a1_s01 -> a1_s02
		"procedi_pragmatismo",      # a1_s02 -> a1_s03
		"batti_pista_affari",       # a1_s03 -> a1_s06
		"resta_distante",           # a1_s06 -> a1_s07
		"rimanda",                  # a1_s07 -> a1_s08
		"sfrutta_testimone",        # a1_s08 -> a2_s01
		"imposta_caccia",           # a2_s01 -> a2_s02
		"procedi_pragmatismo",      # a2_s02 -> a2_s06
		"procedi",                  # a2_s06 -> a2_s07
		"usa_tobia_esca",           # a2_s07 -> a2_s09  (tobia ferito)
		"resta_professionale",      # a2_s09 -> a2_s10  (tick: rischio 40)
		"pista_fredda",             # a2_s10 -> a2_s13  (tick: rischio 80)
		"guarda_verita",            # a2_s13 -> a3_s01  (tick: rischio 120 -> morto a a2_s13)
		"procedi_senza_esitare",    # a3_s01 -> a3_s02
		"procedi_rivelazione",      # a3_s02 -> a3_s03
		"affronta_daniel",          # a3_s03 -> a3_s04
		"chiudi_freddo",            # a3_s04 -> a3_s06
		"uccidi_daniel",            # a3_s06 -> finale
	]
	_walk(e, path)
	_check("pragmatismo >= 55 (variante vendetta)", e.state.get_attribute("pragmatismo") >= 55,
		"pragmatismo=%d" % e.state.get_attribute("pragmatismo"))
	_check("flag verita_sepolta", e.state.has_flag("verita_sepolta"))
	_check("Daniel morto", _char(e, "daniel") == GameCharacter.MORTO)
	_check("Tobia morto (timer ferite)", _char(e, "tobia") == GameCharacter.MORTO)
	var fine := e.current_ending()
	_check("finale = ramo_vendetta", fine != null and fine.id == "ramo_vendetta",
		(fine.id if fine else "null"))
	var ep := e.current_epilogues()
	_check("epilogo vendetta presente", _contains(ep, "Hai smesso di dubitare"))
	_check("epilogo orfano perduto presente", _contains(ep, "L'orfano non c'è più"))
	_check("epilogo Città (pace sepolta) presente", _contains(ep, "La città ringrazia un uomo giusto"))
	_check("epilogo misericordia ASSENTE", not _contains(ep, "Lo hai fatto per lui"))

# ---------------------------------------------------------------------------
# T4 — Sistema ferite (timer, morte automatica, cura). Test diretto su GameState.
# ---------------------------------------------------------------------------
func _t4_ferite() -> void:
	_section("T4 Sistema ferite")
	var e := _engine()
	if e.state == null:
		return
	e.state.set_character_state("tobia", GameCharacter.FERITO)
	var w := e.state.get_wound("tobia")
	_check("ferita aperta: rischio iniziale 0", int(w.get("rischio", -1)) == 0)
	e.state.advance_wounds()
	_check("rischio = 40 dopo 1 avanzamento", int(e.state.get_wound("tobia").get("rischio", -1)) == 40)
	# restando fermi (nessun avanzamento) il rischio non cambia
	_check("nessuna progressione restando fermi", int(e.state.get_wound("tobia").get("rischio", -1)) == 40)
	e.state.advance_wounds()
	_check("rischio = 80 dopo 2 avanzamenti", int(e.state.get_wound("tobia").get("rischio", -1)) == 80)
	e.state.advance_wounds()
	_check("morte automatica oltre soglia (3 avanzamenti)", _char(e, "tobia") == GameCharacter.MORTO)
	_check("record ferita rimosso alla morte", not e.state.is_wounded("tobia"))

	var e2 := _engine()
	e2.state.set_character_state("tobia", GameCharacter.FERITO)   # rischio 0 <= soglia_cura 50
	e2.state.try_cure("tobia")
	_check("cura in tempo: tobia torna normale", _char(e2, "tobia") == GameCharacter.NORMALE)
	_check("cura riuscita: record rimosso", not e2.state.is_wounded("tobia"))

	var e3 := _engine()
	e3.state.set_character_state("tobia", GameCharacter.FERITO)
	e3.state.advance_wounds()
	e3.state.advance_wounds()                                     # rischio 80 > soglia_cura 50
	e3.state.try_cure("tobia")
	_check("cura tardiva: tobia muore", _char(e3, "tobia") == GameCharacter.MORTO)

# ---------------------------------------------------------------------------
# T5 — Regole di stato automatiche (mara: relazione < 0 -> ferito)
# ---------------------------------------------------------------------------
func _t5_regole_stato() -> void:
	_section("T5 Regole di stato automatiche")
	var e := _engine()
	if e.state == null:
		return
	_check("mara parte normale", _char(e, "mara") == GameCharacter.NORMALE)
	EffectApplier.apply({ "relazione": [ { "id": "mara", "delta": -50 } ] }, e.state)
	_check("relazione(mara) < 0 -> mara ferita (regola automatica)",
		_char(e, "mara") == GameCharacter.FERITO,
		"relazione=%d" % e.state.get_character("mara").relazione)

# ---------------------------------------------------------------------------
# T6 — Salvataggio / Caricamento (round-trip dello stato, incluse le ferite)
# ---------------------------------------------------------------------------
func _t6_save_load() -> void:
	_section("T6 Salvataggio / Caricamento")
	var e := _started()
	if e == null:
		return
	e.state.add_attribute("empatia", 7)
	e.state.set_flag("flag_di_prova")
	e.state.set_character_state("tobia", GameCharacter.FERITO)
	e.state.advance_wounds()                                      # rischio 40
	var emp_pre := e.state.get_attribute("empatia")
	var rischio_pre := int(e.state.get_wound("tobia").get("rischio", -1))
	var scene_pre := e.state.current_scene_id
	_check("save_game() riuscito", e.save_game(SAVE_PATH))
	# sporca lo stato
	e.state.add_attribute("empatia", 13)
	e.state.clear_flag("flag_di_prova")
	e.state.set_character_state("tobia", GameCharacter.NORMALE)   # rimuove la ferita
	_check("load_game() riuscito", e.load_game(SAVE_PATH))
	_check("attributo ripristinato", e.state.get_attribute("empatia") == emp_pre,
		"empatia=%d atteso=%d" % [e.state.get_attribute("empatia"), emp_pre])
	_check("flag ripristinato", e.state.has_flag("flag_di_prova"))
	_check("stato personaggio ripristinato (tobia ferito)", _char(e, "tobia") == GameCharacter.FERITO)
	_check("record ferita ripristinato (rischio)",
		int(e.state.get_wound("tobia").get("rischio", -1)) == rischio_pre)
	_check("scena corrente ripristinata", e.state.current_scene_id == scene_pre)

# ---------------------------------------------------------------------------
# T7 — EndingResolver (selezione ramo, fallback con condizione nulla, decisione ignota)
# ---------------------------------------------------------------------------
func _t7_resolver() -> void:
	_section("T7 EndingResolver")
	var e := _engine()
	if e.state == null:
		return
	var g := e.resolve_ending("arresta_daniel")
	_check("decisione 'arresta_daniel' -> ramo_giustizia", g != null and g.id == "ramo_giustizia",
		(g.id if g else "null"))
	var v := e.resolve_ending("uccidi_daniel")
	_check("decisione 'uccidi_daniel' -> ramo_vendetta", v != null and v.id == "ramo_vendetta",
		(v.id if v else "null"))
	_check("decisione ignota -> null (nessun crash)", e.resolve_ending("decisione_inesistente") == null)

# ---------------------------------------------------------------------------
# T8 — Epiloghi condizionali (composizione per stato; test unit-style)
# ---------------------------------------------------------------------------
func _t8_epiloghi() -> void:
	_section("T8 Epiloghi condizionali")
	# Stato A: Giustizia, Tobia morto, empatia alta
	var a := _engine()
	if a.state == null:
		return
	a.state.set_character_state("tobia", GameCharacter.MORTO)
	a.state.set_attribute("empatia", 60)
	var fa := a.resolve_ending("arresta_daniel")
	var epa := a.epilogues_for(fa)
	_check("A: epilogo Tobia perduto presente", _contains(epa, "banco vuoto"))
	_check("A: epilogo umile presente (empatia 60)", _contains(epa, "Non ti sei fatto giudice"))
	_check("A: epilogo Tobia futuro ASSENTE", not _contains(epa, "Tobia avrà altri inverni"))
	# Stato B: Vendetta, empatia + legame alti -> misericordia
	var b := _engine()
	b.state.set_attribute("empatia", 60)
	b.state.set_attribute("legame", 60)
	var fb := b.resolve_ending("uccidi_daniel")
	var epb := b.epilogues_for(fb)
	_check("B: epilogo misericordia presente (empatia>=55 & legame>=50)",
		_contains(epb, "Lo hai fatto per lui"))

# ---------------------------------------------------------------------------
# T9 — Soglie attributo (gating per soglia; current_scene_id impostato per isolamento)
# ---------------------------------------------------------------------------
func _t9_soglie() -> void:
	_section("T9 Soglie attributo")
	# D6 a a2_s09: visibile con legame>=45 (senza confidenza_daniel)
	var e1 := _engine()
	if e1.state == null:
		return
	e1.state.current_scene_id = "a2_s09"
	e1.state.set_attribute("legame", 44)
	_check("D6 (nota_ritagli) NON visibile a legame=44", _find(e1, "nota_ritagli") == null)
	e1.state.set_attribute("legame", 45)
	_check("D6 (nota_ritagli) visibile a legame=45", _find(e1, "nota_ritagli") != null)

	# verifica_daniel a a2_s10: abilitata con lucidita>=60 E legame<50
	var e2 := _engine()
	e2.state.current_scene_id = "a2_s10"
	e2.state.set_attribute("lucidita", 60)
	e2.state.set_attribute("legame", 49)
	_check("verifica_daniel abilitata a lucidita=60, legame=49", _can(e2, "verifica_daniel"))
	e2.state.set_attribute("legame", 50)
	_check("verifica_daniel disabilitata a legame=50 (attrito emotivo)", not _can(e2, "verifica_daniel"))

	# S3 a a3_s02: visibile con lucidita>=60 e un segnale (indizio_ritagli)
	var e3 := _engine()
	e3.state.current_scene_id = "a3_s02"
	e3.state.set_flag("indizio_ritagli")
	e3.state.set_attribute("lucidita", 59)
	_check("S3 (assicura_firma) NON visibile a lucidita=59", _find(e3, "assicura_firma") == null)
	e3.state.set_attribute("lucidita", 60)
	_check("S3 (assicura_firma) visibile a lucidita=60 + segnale", _find(e3, "assicura_firma") != null)

# ---------------------------------------------------------------------------
# T10 — Idempotenza hub (a2_s06: on_enter nullo, scelte-guardia, loop con uscita)
# ---------------------------------------------------------------------------
func _t10_idempotenza_hub() -> void:
	_section("T10 Idempotenza hub")
	var e := _started()
	if e == null:
		return
	e.state.current_scene_id = "a2_s06"
	var emp0 := e.state.get_attribute("empatia")
	_check("ascolta_tobia disponibile all'ingresso", _find(e, "ascolta_tobia") != null)
	e.choose("ascolta_tobia")                                    # empatia +4, set M6, torna a a2_s06
	_check("resta in a2_s06 dopo la scelta-guardia", _scene_id(e) == "a2_s06")
	_check("empatia aumentata una sola volta (+4)", e.state.get_attribute("empatia") == emp0 + 4,
		"empatia=%d atteso=%d" % [e.state.get_attribute("empatia"), emp0 + 4])
	_check("ascolta_tobia non più disponibile (guardia)", _find(e, "ascolta_tobia") == null)
	_check("procedi sempre disponibile (uscita garantita)", _find(e, "procedi") != null)
	# secondo ingresso allo stesso hub: on_enter nullo -> nessuna inflazione di attributi
	var emp1 := e.state.get_attribute("empatia")
	e.choose("momento_daniel")                                   # legame +5, torna a a2_s06
	_check("re-ingresso hub non altera empatia (on_enter nullo)",
		e.state.get_attribute("empatia") == emp1)
	_check("uscita 'procedi' ancora disponibile", _find(e, "procedi") != null)

# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------
func _engine() -> StoryEngine:
	var e := StoryEngine.new()
	if not e.setup():
		_check("setup() del Core riuscito", false, e.last_error)
	return e

func _started() -> StoryEngine:
	var e := _engine()
	if e.state == null:
		return null
	e.start()
	return e

func _find(e: StoryEngine, id: String) -> Choice:
	for c in e.available_choices():
		if c.id == id:
			return c
	return null

func _can(e: StoryEngine, id: String) -> bool:
	var c := _find(e, id)
	return c != null and c.abilitata

func _walk(e: StoryEngine, path: Array) -> void:
	for id in path:
		var sc := e.current_scene()
		var c := _find(e, id)
		if c == null:
			_check("[%s] scelta '%s' disponibile" % [_scene_id(e), id], false, "non trovata tra le scelte visibili")
			return
		if not c.abilitata:
			_check("[%s] scelta '%s' abilitata" % [_scene_id(e), id], false, "trovata ma disabilitata")
			return
		e.choose(id)

func _scene_id(e: StoryEngine) -> String:
	var sc := e.current_scene()
	return sc.id if sc != null else "<nessuna>"

func _char(e: StoryEngine, id: String) -> String:
	var c := e.state.get_character(id)
	return c.stato if c != null else "<assente>"

func _contains(items: Array, needle: String) -> bool:
	for s in items:
		if String(s).find(needle) != -1:
			return true
	return false

func _section(title: String) -> void:
	print("-- " + title + " --")

func _check(label: String, cond: bool, detail: String = "") -> void:
	if cond:
		_ok += 1
		print("  [OK] " + label)
	else:
		_failures += 1
		printerr("  [FAIL] " + label + ("  -> " + detail if detail != "" else ""))

func _finish() -> void:
	print("== Risultato: %d OK, %d FAIL ==" % [_ok, _failures])
	if _failures == 0:
		print("== TUTTI I TEST OK ==")
		quit(0)
	else:
		printerr("== %d TEST FALLITI ==" % _failures)
		quit(1)
