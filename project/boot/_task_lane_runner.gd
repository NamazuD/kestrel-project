##==========
## Path: /project/boot/_task_lane_runner.gd
## Dynamic Boot Module - Initialized by BootAutoload
##
## Triggers TaskLaneManager lane execution each frame
## No initialization logic required
## Uses: Maintains an internal instance of TASKHELPER to handle the workload state.
## Consumed by: Godot engine frame loop (automatic)
##==========

extends Node

# Instantiate the helper once when the runner starts
var task_helper = TASKHELPER.new()

func _process(_delta: float) -> void:
	# Safety Guard: If the bootstrapper hasn't initialized the lane system yet,
	# skip this frame's execution entirely.
	if not BootAutoload.modules.InitTaskLanes:
		return
		
	# Use the instance to drain lanes safely once the data is present
	task_helper.drain_lanes()
