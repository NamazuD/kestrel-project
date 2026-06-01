##==========
## Path: /project/boot/helpers/task_helper.gd
## Project: Project Kestral
##
## Stateful manager for interacting with task execution lanes.
## Provides controlled access to enqueue, reorder, and drain lane workloads.
## Maintains minimal execution state (current_lane_index)
## Operates on structures defined in InitTaskLanes.
## Uses:
##  - InitTaskLanes (lane structure and ordering)
##  - Godot Time API (frame budget enforcement)
## Consumed by:
##  - EventBus (task submission via enqueue_task)
##  - TaskLaneRunner (frame-based execution via drain_lanes)
## Constraints:
##  - Assumes lanes are pre-initialized and immutable
##  - Does not perform initialization or cleanup
##  - Execution is driven externally by engine signals
##==========

class_name TASKHELPER extends RefCounted

# Tracks current position in lane_order across frames to prevent lane starvation
# Used to distribute large workloads across frames
var current_lane_index: int = 0

# Frame time budget (microseconds) to distribute work across frames
static var time_budget_us: int = 5000

## --- Set Lane Order ---
## Replaces lane_order after validation and resets traversal state
## Inputs: new_order: Array
## Effects:
##  - Validates input against existing lanes
##  - Replaces lane_order with validated order
##  - Resets traversal state
## Modifies:
##  - Persistent global lane_order: Array
##	["PIPELINE_NAME_1", "PIPELINE_NAME_2", ....]
##  - current_lane_index: int
##
func set_lane_order(new_order: Array) -> void:

	# 1. Reference owning system
	var lane_system = BootAutoload.modules.InitTaskLanes.node
	var validated_order: Array = []

	# 2. Validate and build new lane order
	for lane in new_order:

		# 2.1 Fail quickly if lane is not found
		if not lane_system.lanes.has(lane):
			push_error("Cannot set order, lane missing: " + lane)
			return

		validated_order.append(lane)

	# 3. Commit new lane order atomically
	lane_system.lane_order = validated_order

	# 4. Reset traversal state
	current_lane_index = 0

## --- Drain Lanes ---
## Executes queued tasks across lanes within a time budget
## Triggered once per frame by engine (_process or equivalent)
## Inputs: None
## Effects:
##  - Processes queued tasks across execution lanes
##  - Enforces per-frame time budget
##  - Advances traversal state
## Modifies:
##  - InitTaskLanes.lanes[*]["queue"]
##  - current_lane_index: int
##
func drain_lanes() -> void:
	
	# 1. Reference lane system
	var lane_system = BootAutoload.modules.InitTaskLanes.node
	if lane_system.lane_order.is_empty():
		return


	# 2.  Start timing
	var frame_start: int = Time.get_ticks_usec()
	var lanes_checked: int = 0
	var total_lanes: int = lane_system.lane_order.size()
	
	# 3.  Round-robin processing
	while lanes_checked < total_lanes:
		# 3.1.
		var lane_name = lane_system.lane_order[current_lane_index]
		var lane_data = lane_system.lanes.get(lane_name)
		
		# 3.2. 
		if lane_data:

			# 3.2.1.
			var queue: Array = lane_data["queue"]

			# 3.2.2.			
			while not queue.is_empty():
				# --- TIME BUDGET ENFORCEMENT ---
				var elapsed: int = Time.get_ticks_usec() - frame_start
				if elapsed > time_budget_us:
					return
					
				# --- TASK EXECUTION ---
				var task: Dictionary = queue.pop_front()
				var script_resource = load(task["script"])
				
				
				if script_resource:
					# Instantiate script and verify required method
					var instance = script_resource.new()
					if not script_resource:
						push_error("[TaskLaneManager] Failed to load script: " + task["script"])
						continue
					if instance.has_method("_on_event"):
						instance._on_event(task.get("data", {}))
					else:
						push_error("[TaskLaneManager] Missing '_on_event(data)' in: " + task["script"])

		
		# 3.3. Advance lane index
		current_lane_index = (current_lane_index + 1) % total_lanes
		lanes_checked += 1

## --- Enqueue Task ---
## Adds a task to the specified lane queue
## Inputs:
##  - lane_name: String
##  - task: Dictionary { "script": String, "data": Dictionary }
## Effects:
##  - Validates lane existence
##  - Appends task to target lane queue
## Modifies:
##  - InitTaskLanes.lanes[upper_lane]["queue"]
##
func enqueue_task(lane_name: String, task: Dictionary) -> void:

	# 1. Normalize lane name
	var upper_lane = lane_name.to_upper()

	# 2. Validate lane exists
	if not BootAutoload.modules.InitTaskLanes.node.lanes.has(upper_lane):
		push_error("[TaskLaneManager] Invalid lane: " + upper_lane)
		return

	# 3. Validate task structure (minimal)
	if not task.has("script"):
		push_error("[TaskLaneManager] Task missing 'script' field")
		return
	if typeof(task["script"]) != TYPE_STRING:
		push_error("[TaskLaneManager] 'script' must be a String path")
		return

	# 4. Normalize data field (safe default)
	if not task.has("data"):
		task["data"] = {}
	elif typeof(task["data"]) != TYPE_DICTIONARY:
		push_error("[TaskLaneManager] 'data' must be a Dictionary")
		return

	# 5. Append task to queue
	BootAutoload.modules.InitTaskLanes.node.lanes[upper_lane]["queue"].append(task)
