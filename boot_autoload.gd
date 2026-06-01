# boot_autoload.gd
extends Node

# Your new registry
var modules = {
	"InitData": {"node": null, "path": "res://project/boot/_init_data.gd"},
	"InitSubDict": {"node": null, "path": "res://project/boot/_init_sub_dict.gd"},
	"InitTaskLanes": {"node": null, "path": "res://project/boot/_init_task_lanes.gd"},
	"TaskLaneRunner": {"node": null, "path": "res://project/boot/_task_lane_runner.gd"},
	"EventBus": {"node": null, "path": "res://project/boot/_event_bus.gd"}
}

func _ready() -> void:
	print("In Ready - Synchronous Bootstrapping")
	
	for key in modules:
		var path = modules[key].path
		var script = load(path)
		
		var instance = Node.new()
		instance.set_script(script)
		instance.name = path.get_file().get_basename()
		
		add_child(instance)
		
		# Assign directly to the dictionary
		modules[key].node = instance
		
		if not instance.is_node_ready():
			instance.request_ready()
			instance.notification(NOTIFICATION_READY)
			
		print("GameBootstrapper: Successfully initialized " + key)
