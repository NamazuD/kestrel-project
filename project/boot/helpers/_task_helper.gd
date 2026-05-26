class_name TaskLaneManager extends RefCounted

# We pass the data node into these functions to keep them decoupled
static func set_lane_order(lane_node: Node, new_order: Array) -> void:
	for lane in new_order:
		if not lane_node.lanes.has(lane):
			push_error("Cannot set order, lane missing: " + lane)
			return
	lane_node.lane_order = new_order
	lane_node.current_lane_index = 0

static func drain_lanes(lane_node: Node, time_budget_us: int) -> void:
	if lane_node.lane_order.is_empty():
		return

	var frame_start: int = Time.get_ticks_usec()
	var lanes_checked: int = 0
	var total_lanes: int = lane_node.lane_order.size()
	
	while lanes_checked < total_lanes:
		var lane_name = lane_node.lane_order[lane_node.current_lane_index]
		var lane_data = lane_node.lanes.get(lane_name)
		
		if lane_data:
			var queue: Array = lane_data["queue"]
			var budget_hit: bool = false
			
			while not queue.is_empty():
				# 1. Budget enforcement
				if (Time.get_ticks_usec() - frame_start) > time_budget_us:
					budget_hit = true
					break
					
				# 2. Extract and run task
				var task: Dictionary = queue.pop_front()
				var script_resource = load(task["Script"])
				
				if script_resource:
					# Check if the static method exists on the script resource itself
					if script_resource.has_method("_on_event"):
						script_resource._on_event(task.get("data", {}))
					else:
						push_error("[TaskLaneManager] Script lacks expected receiving method '_on_event(package)': ", task["Script"])
			
			if budget_hit:
				return 
		
		# Move to next lane in round-robin sequence
		lane_node.current_lane_index = (lane_node.current_lane_index + 1) % total_lanes
		lanes_checked += 1

#The manager now expects a generic dictionary or structure 
# rather than being tied to a specific scene node
static func enqueue_task(lane_name: String, task: Dictionary) -> void:
	# Access the global registry directly, no need to pass it in
	var upper_lane = lane_name.to_upper()
	
	# Simple, direct append to the queue
	InitTaskLanes.lanes[upper_lane]["queue"].append(task)
	print("InitTaskLanes: ", JSON.stringify(InitTaskLanes.lanes, "\t"))
