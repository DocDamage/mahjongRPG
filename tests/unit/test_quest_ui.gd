extends RefCounted

const HallForeman = preload("res://src/story/hall_foreman.gd")
const QuestTracker = preload("res://src/ui/quest_tracker.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	GameSession.start_new_game(500)
	var tree := Engine.get_main_loop() as SceneTree
	var hall = HallForeman.new()
	tree.root.add_child(hall)
	hall._on_interacted(null)
	var tracker = QuestTracker.new()
	tree.root.add_child(tracker)
	var label := tracker.get_node("Panel/Objective") as Label
	if not tracker.get_node("Panel").visible or not label.text.contains("Select and deliver") or label.focus_mode != Control.FOCUS_NONE:
		failures.append("the read-only tracker should show the active intentional step without stealing focus")
	GameSession.inventory.add_item(&"crop_beans")
	GameSession.inventory.add_item(&"fish_anchovy")
	if not label.text.contains("[READY] Beans: 1/1") or not label.text.contains("[READY] Fish: 1/1"):
		failures.append("tracker counts should refresh after inventory changes without progressing the quest")
	hall._on_interacted(null)
	var dialog: CanvasLayer = hall._dialog
	if dialog == null:
		failures.append("the migrated Hall coordinator should open explicit provision selection when ready")
		tracker.free()
		hall.free()
		return failures
	var choices := dialog.get_node("Root/Center/Panel/Content/FishChoices") as VBoxContainer
	var confirm := dialog.get_node("Root/Center/Panel/Content/Actions/Confirm") as Button
	if choices.get_child_count() != 1 or not confirm.disabled:
		failures.append("delivery UI should require an explicit eligible-fish selection before confirmation")
	dialog._select_fish(&"fish_anchovy", choices.get_child(0))
	if confirm.disabled or not SaveService.can_save():
		if confirm.disabled:
			failures.append("keyboard/controller-focusable selection should enable explicit confirmation")
	# The persistence guard must remain active until cancel/confirm.
	if SaveService.can_save():
		failures.append("delivery modal should restrict save/load while a transaction choice is open")
	if SaveService.load_current_session(&"autosave") != ERR_BUSY:
		failures.append("load should fail busy before touching save data while delivery confirmation is open")
	GameSession.start_new_game(501)
	if not dialog.is_queued_for_deletion() or not SaveService.can_save() or GameSession.is_paused():
		failures.append("new-game replacement should cancel stale delivery UI and release every guard")
	dialog.free()
	tracker.free()
	hall.free()
	return failures
