extends Node

# Master registry for our dynamic lanes
var lanes: Dictionary = {}

# The defined order of execution
var lane_order: Array = []

# Tracks our position in lane_order across frames to prevent lane starvation
var current_lane_index: int = 0

func _ready() -> void:
	_initialize_lanes_from_blueprint()

func _initialize_lanes_from_blueprint() -> void:
	var master_registry = InitData.master_blueprint
	
	for pipeline_name in master_registry:
		var lane_name = pipeline_name.to_upper()
		
		lanes[lane_name] = {
			"queue": []
		}
		
		if not lane_order.has(lane_name):
			lane_order.append(lane_name)
			
	print("[InitTaskLanes] Initialized lanes from master blueprint in order: ", lane_order)
	#print("[InitTaskLanes] Current Lane structure:\n", JSON.stringify(lane_order, "\t"))

#func set_lane_order(new_order: Array) -> void:
	#for lane in new_order:
		#if not lanes.has(lane):
			#push_error("Cannot set order, lane missing: " + lane)
			#return
	#lane_order = new_order
	#current_lane_index = 0 # Reset tracker to match new order layout

func _process(_delta: float) -> void:
	TaskLaneManager.drain_lanes(self, 5000)

#func _drain_all_lanes() -> void:
	#if lane_order.is_empty():
		#return
#
	#var time_budget_us = 5000 
	#var frame_start = Time.get_ticks_usec()
	#var lanes_checked = 0
	#var total_lanes = lane_order.size()
	#
	## Loop through lanes starting exactly where the last frame paused
	#while lanes_checked < total_lanes:
		#var lane_name = lane_order[current_lane_index]
		#
		#if lanes.has(lane_name):
			#var queue = lanes[lane_name]["queue"]
			#var lane_start = Time.get_ticks_usec()
			#var budget_hit = false
			#
			#while not queue.is_empty():
				## Global safety check
				#if (Time.get_ticks_usec() - frame_start) > time_budget_us:
					#print("[InitTaskLanes] Budget exhausted. Pausing at lane: ", lane_name)
					#budget_hit = true
					#break # Break out of the task queue loop gracefully
					#
				#var task = queue.pop_front()
				#if task is Callable:
					#task.call()
			#
			## Telemetry still fires accurately even if we broke out early
			#var lane_duration = Time.get_ticks_usec() - lane_start
			#if lane_duration > 1000:
				#print("[InitTaskLanes] Warning: Lane %s took %d microseconds" % [lane_name, lane_duration])
				#
			#if budget_hit:
				#return # Yield control back to engine until next frame; current_lane_index stays here
		#
		## Move pointer to the next lane layout seamlessly
		#current_lane_index = (current_lane_index + 1) % total_lanes
		#lanes_checked += 1
#
#func enqueue_task(lane_name: String, task: Callable) -> void:
	#var upper_lane = lane_name.to_upper()
	#if lanes.has(upper_lane):
		#lanes[upper_lane]["queue"].append(task)
	#else:
		#push_error("Attempted to add task to non-existent lane: " + lane_name)
