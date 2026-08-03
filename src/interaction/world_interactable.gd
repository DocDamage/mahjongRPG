extends Area2D
class_name WorldInteractable

signal interacted(actor: Node2D)

@export_multiline var prompt_text := "Interact"
@export var interaction_id: StringName


func interact(actor: Node2D) -> void:
	interacted.emit(actor)
