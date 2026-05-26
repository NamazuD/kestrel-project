# event_handler.gd
# No 'extends' needed. This is a pure logic module.

## Executes the movement logic.
## This is called directly by the TaskLaneManager.
static func _on_event(payload: Dictionary) -> void:
	print("event_handler.gd called.")
