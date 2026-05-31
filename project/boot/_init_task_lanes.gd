##==========
## Path: /project/boot/_init_task_lanes.gd
## Project: Project Kestral
##
## GD Auto loaded Singleton - Initializes on engine start (_ready)
## Creates: 
##  - Global lanes Dictionary (execution lanes)
##  - Global lane_order Array (execution order)
## Uses InitData.directory_structure
## Consumed by:
##  - TaskLaneManager.set_lane_order([new_order])
##  - TaskLaneManager.drain_lanes()
##  - TaskLaneManager.enqueue_task(lane_name, task)
##==========

extends Node

# Job base execution lanes
var lanes: Dictionary = {}

# The defined lane order of execution
var lane_order: Array = []

## --- GD Singleton Autostart  ---
## Used from: Godot Autostart Settings
## Inputs: None
## Effects: Initializes event execution lanes (via internal generation)
## Outputs: None
##
func _ready() -> void:
	print("[InitTaskLanes] Initialized lanes from directory_structure")
	_initialize_job_lanes()
	print("[InitTaskLanes] Initialized lanes in order: ", lane_order)

## --- Initialize Job Lanes ---
## Method to initialize task lanes to queue discrete events
## Lanes are executed once per frame
## Default order is alphabetical, 
##	optionally set by TaskLaneManager.set_lane_order([lanes])
## Used from: func _ready()
## Inputs: None
## Effects: 
##  - Builds and populates dictionary of execution lanes
##  - Builds lane order array
## Modifies: 
##  - Persistent global lanes: Dictionary
## 	Structure: lanes format:
##	{ "PIPELINE_NAME": {
##		"queue": [
##          { "script": "...", "data": {} }
##		]  }}
##  - Persistent global lane_order: Array
##	["PIPELINE_NAME_1", "PIPELINE_NAME_2", ....]
##
func _initialize_job_lanes() -> void:

	# 1. Populate lanes and lane_order
	var master_registry = InitData.directory_structure
	for pipeline_name in master_registry:

		# 1.1 For each pipeline name populate a dictionary entry.
		var lane_name = pipeline_name.to_upper()
		lanes[lane_name] = {
			"queue": []
		}
		
		# 1.2 If lane order is not defined use default order
		if not lane_order.has(lane_name):
			lane_order.append(lane_name)


