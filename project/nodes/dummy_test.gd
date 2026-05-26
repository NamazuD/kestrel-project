extends Node
#
func _unhandled_input(event: InputEvent) -> void:
	# Check if the Spacebar was just pressed down
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			print("[TestTrigger] Spacebar pressed! Pushing dummy event to EventBus...")
			
			# Define a mock alias and payload to simulate a gameplay trigger
			var test_alias: String = "actor_movement"
			var test_payload: Dictionary = {
				"target_node": "Player",
				"vector": Vector2(1, 0),
				"speed": 150
			}
			
			##Checking what threads are currently active.
			#print(InitThreads.active_domains.keys()) 
			#
			## Drop it off at the public gateway
			EventBus.start_event("actor_movement", test_payload)
			EventBus.start_event("event_handler", test_payload)
			EventBus.start_event("calc_movement", test_payload)
			
			
