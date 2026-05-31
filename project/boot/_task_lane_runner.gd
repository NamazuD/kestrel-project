##==========
## Path: /project/boot/_task_lane_runner.gd
## GD Auto loaded Singleton - Frame execution driver
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
	# Use the instance to drain lanes
	task_helper.drain_lanes()
