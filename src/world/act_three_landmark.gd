extends "res://src/interaction/world_interactable.gd"

signal feedback(message: String)

enum Action { VALIDATE_CHAIN, DISCOVER_BARGAIN, CHOOSE_CONSEQUENCE, EXPLAIN_RULE, PROVE_SILAS_ALIVE, EXPLORE_REACH, FINAL_WARNING, REVIEW_INHERITANCE }

@export var action: Action
@export var target_id: StringName


func _ready() -> void:
	interacted.connect(_on_interacted)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-27, -23, 54, 46), Color("452f3c"))
	draw_rect(Rect2(-27, -23, 54, 46), Color("ffd78c"), false, 2.0)
	draw_circle(Vector2(0, -30), 8.0, Color("dca2e8") if action == Action.FINAL_WARNING else Color("ee7561"))


func _on_interacted(_actor: Node2D) -> void:
	match action:
		Action.VALIDATE_CHAIN:
			if GameSession.story.validate_clue_chain(GameSession.evidence) == OK:
				feedback.emit("Every regional clue now forms one continuous investigation chain. %s" % GameSession.story.journal_status())
			else:
				var missing: Array[StringName] = GameSession.story.missing_clues(GameSession.evidence)
				feedback.emit("The evidence chain is incomplete. Missing: %s." % ", ".join(missing.map(func(clue_id): return String(clue_id).replace("_", " "))))
		Action.DISCOVER_BARGAIN:
			feedback.emit("Bargain record discovered: King bound the Hall's stakes to a bloodline and a truthful table." if GameSession.story.discover_bargain(GameSession.evidence) == OK else "First validate the full clue chain; the record will not yield its meaning out of order.")
		Action.CHOOSE_CONSEQUENCE:
			feedback.emit("Your promise to %s is recorded and will carry into the final confrontation." % String(target_id).replace("_", " ") if GameSession.story.choose_consequence(target_id) == OK else "This consequence is unavailable or already chosen.")
		Action.EXPLAIN_RULE:
			feedback.emit("Altered rule explained: %s. The journal now states both the threat and its fair counter." % String(target_id).replace("_", " ") if GameSession.story.explain_rule(target_id, GameSession.evidence) == OK else "The needed evidence has not yet established this altered rule.")
		Action.PROVE_SILAS_ALIVE:
			feedback.emit("Silas is alive. His signal comes from beyond the King's Reach gate." if GameSession.story.prove_silas_alive(GameSession.evidence) == OK else "Explain every altered rule before trusting the signal.")
		Action.EXPLORE_REACH:
			feedback.emit("King's Reach explored: %s." % String(target_id).replace("_", " ") if GameSession.story.explore_kings_reach(target_id) == OK else "The approach remains sealed until the investigation proves Silas is alive, or this site is already charted.")
		Action.FINAL_WARNING:
			feedback.emit("FINAL WARNING RECORDED: the championship is separately gated and will begin only when you explicitly continue in Phase 15. %s" % GameSession.story.journal_status() if GameSession.story.accept_final_warning(GameSession.public_life, GameSession.community) == OK else "Before the warning: schedule the final championship, unite community support, and chart every King's Reach site. %s" % GameSession.story.journal_status())
		Action.REVIEW_INHERITANCE:
			feedback.emit("Silas's inheritance deed joins your evidence journal." if GameSession.evidence.discover(&"inheritance_deed") == OK else "You already carry Silas's inheritance deed.")
