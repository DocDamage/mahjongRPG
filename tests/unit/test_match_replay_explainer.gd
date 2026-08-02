extends RefCounted

const MatchFlow = preload("res://src/mahjong/domain/match_flow.gd")
const MatchReplayExplainer = preload("res://src/mahjong/presentation/match_replay_explainer.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var first = MatchFlow.new(902)
	var second = MatchFlow.new(902)
	first.start_match(); second.start_match()
	first.discard_at(0); second.discard_at(0)
	var first_replay: Dictionary = first.replay.snapshot()
	var second_replay: Dictionary = second.replay.snapshot()
	if String(first_replay.get("hash", "")).length() != 64 or first_replay["hash"] != second_replay["hash"]:
		failures.append("identical deterministic histories must produce stable replay hashes")
	var explanation := MatchReplayExplainer.explain(first_replay)
	if explanation.is_empty() or not MatchReplayExplainer.summary(first_replay).contains("deterministic replay events"):
		failures.append("replay history should expose player-readable explanations")
	var rebuilt = MatchFlow.rebuild_from_replay(first_replay)
	if rebuilt == null or rebuilt.replay.snapshot().get("hash", "") != first_replay["hash"]:
		failures.append("replay reconstruction must preserve the deterministic event hash")
	return failures
