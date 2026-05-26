extends Node

func start_event(script_name: String, payload: Variant) -> void:
	# 1. Lookup the registry entry
	script_name = script_name + ".gd"
	var entry = InitSubDict.script_registry.get(script_name)
	
	if not entry:
		push_error("EventBus: No registry entry for " + script_name)
		#push_error("Registry ", InitSubDict.script_registry)
		return
		
	# 2. Extract the lane and directory
	var target_lane = entry.get("Pipeline", "DEFAULT")
	var script_path = entry.get("Directory") + script_name
	
	# 3. Package the work and enqueue it
	var event_package: Dictionary = {
		"Script": script_path,
		"data": payload
	}
		
	# Assuming TaskLaneManager is the name of your auto-loaded node
	TaskLaneManager.enqueue_task(target_lane, event_package)
