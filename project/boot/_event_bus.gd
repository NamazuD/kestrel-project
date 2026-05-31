##==========
## Path: /project/boot/_event_bus.gd
## Project: Project Kestral
##
## GD Auto loaded Singleton - Initializes on engine start (_ready)
## Routes a front end script level event calls to job based execution lanes.
## Lane queues executed in order once per frame
## Uses: InitSubDict.script_registry
## Consumed by: External developer scripts via EventBus.start_event(script_name, payload)"
## Outputs: TaskLaneManager.enqueue_task(target_lane, event_package)
##==========

extends Node

## --- Start Event ---
## The method is deliberatly called start_event because from
##	a developer perspective this queues a descrite event for execution.
## Used from: Developer Event Calls
## 	Input: (script_name: String, 
##			payload: Dictionary {
##				"payload": Dictionary(payload)
##	})
## Used by: TaskLaneManager.enqueue_task
## 	Output: (target_lane: String,
## 			event_package: Dictionary {
##     			"script": String (script_path),
##     			"data": Variant (payload)
## 	})
func start_event(script_name: String, payload: Dictionary) -> void:

	# 1. 'gd' added to the script name so developers can use just the script name.
	#	# script_name should be provided without ".gd"
	script_name = script_name + ".gd"
	
	# 2. Lookup the registry entry
	var entry = InitSubDict.script_registry.get(script_name)
	if not entry:
		push_error("EventBus: No registry entry for " + script_name + "Note: The file extention 'gd' is not required when doing a script call.")
		#push_error("Registry ", InitSubDict.script_registry)
		return
		
	# 3. Extract the lane and directory
	# Pipeline and Directory are defined in InitSubDict.script_registry (environment)
	var target_lane = entry.get("pipeline", "DEFAULT")
	var script_path = entry.get("directory") + script_name
	
	# 4. Package the work and enqueue it
	var event_package: Dictionary = {
		"script": script_path,
		"data": payload
	}
		
	# 5. Send to assigned execution lane.
	TaskLaneRunner.task_helper.enqueue_task(target_lane, event_package)
