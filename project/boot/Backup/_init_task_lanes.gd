extends Node

# Master registry for our dynamic lanes
var lanes: Dictionary = {}

# The defined order of execution
var lane_order: Array = []

# Safety thresholds for monitoring system health
const WARNING_THRESHOLD: int = 100
const EXTREME_THRESHOLD: int = 500

# Initialization scans the filesystem to populate the dictionary
func _ready() -> void:
	_initialize_lanes_from_registry()

func _initialize_lanes_from_registry() -> void:
	# Pull the top-level pipeline dictionary keys directly from our shared memory truth
	var master_registry = InitSubs.routing_table
	
	for pipeline_name in master_registry:
		# Enforce our upper-case lane keys to guarantee naming conventions remain strict
		var lane_name = pipeline_name.to_upper()
		
		lanes[lane_name] = {
			"queue": []
		}
		
		# Seamlessly maintain discovery order for the processor drain loop
		if not lane_order.has(lane_name):
			lane_order.append(lane_name)
			
	print("Initialized lanes from registry in order: ", lane_order)
	print("[InitTaskLanes] Current lanes structure:\n", JSON.stringify(lanes, "\t"))

# Allows developer to re-sequence execution order at runtime
func set_lane_order(new_order: Array) -> void:
	# Basic validation to ensure all lanes are accounted for
	for lane in new_order:
		if not lanes.has(lane):
			push_error("Cannot set order, lane missing: " + lane)
			return
	lane_order = new_order
	
func _process(_delta: float) -> void:
	_drain_all_lanes()

func _drain_all_lanes() -> void:
	for lane_name in lane_order:
		# Safety check in case a lane in LANE_ORDER wasn't found in the filesystem
		if not lanes.has(lane_name):
			continue
			
		var lane_data = lanes[lane_name]
		var queue = lane_data["queue"]
		
		# Check queue health
		if queue.size() > WARNING_THRESHOLD:
			push_warning("Large number of events in lane: " + lane_name)
		if queue.size() > EXTREME_THRESHOLD:
			push_warning("Possible runaway event loop in lane: " + lane_name)
		
		# Process the pipe
		while not queue.is_empty():
			var task = queue.pop_front()
			if task is Callable:
				task.call()

func enqueue_task(lane_name: String, task: Callable) -> void:
	# Convert input to upper case to match filesystem convention
	var upper_lane = lane_name.to_upper()
	if lanes.has(upper_lane):
		lanes[upper_lane]["queue"].append(task)
	else:
		push_error("Attempted to add task to non-existent lane: " + lane_name)
