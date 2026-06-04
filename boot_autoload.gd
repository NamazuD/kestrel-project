##==========
## Path: /boot_autoload.gd
## Project: Project Kestral
##
## GD Auto loaded Singleton - Initializes on engine start (_ready)
## Boot system orchestrator responsible for initializing and managing boot modules.
## Acts as the parent node for all backend system modules.
## Provides centralized access to boot modules through dynamic properties.
##==========
extends Node

var modules = {
	"InitData": {"node": null, "path": "res://project/boot/_init_data.gd"},
	"InitSubDict": {"node": null, "path": "res://project/boot/_init_sub_dict.gd"},
	"InitTaskLanes": {"node": null, "path": "res://project/boot/_init_task_lanes.gd"},
	"TaskLaneRunner": {"node": null, "path": "res://project/boot/_task_lane_runner.gd"},
	"EventBus": {"node": null, "path": "res://project/boot/_event_bus.gd"}
}

## --- GD Singleton Autostart  ---
## Used from: Godot Autostart Settings
## Effects:
##  - Initializes backend system modules
##  - Instantiates modules, binds scripts, and adds them as child nodes under the boot parent
##  - Ensures deterministic initialization order via ready signal synchronization
##  - Registers module instances in the internal registry
##  - Exposes each module as a property on the boot node
## Node Structure:
##  /Root
##   ├── Boot (system root / autoload)
##   │   ├── InitData        (data initialization)
##   │   ├── InitSubDict     (derived registry mapping)
##   │   ├── InitTaskLanes   (lane system creation)
##   │   ├── TaskLaneRunner  (frame execution driver)
##   │   └── EventBus        (developer interface)
##   └── World.tscn          (game world scene)
##       └── ...
##
func _ready() -> void:
	print("In Ready - Synchronous Bootstrapping")
	
	for key in modules:
		
		# 1. Resolve script resource from path and create node instance
		var path = modules[key].path
		var script = load(path)
		if script == null:
			push_error("Failed to load: " + path)	
			assert(false, "Critical boot failure: missing module script")
		
		# 2. Bind script resource to node, assign name, and add it to the scene tree
		var instance = Node.new()
		instance.set_script(script)
		instance.name = path.get_file().get_basename()
		add_child(instance)
		
		# 3. Register node in module registry
		modules[key].node = instance
		
		# 4. Wait for node 'ready' signal (emitted after _ready() completes)
		if not instance.is_node_ready():
			print("Awaiting signal for: " + key)
			await instance.ready
		else:
			print("Node " + key + " was already ready; skipping await.")
			
		print("GameBootstrapper: Successfully initialized " + key)
		

## --- _get Helper Function ---
## Dynamically intercepts property access requests to provide seamless shorthand access to backend modules
## Used to access nodes associated with the given key name and their associated properties.
## Inputs: Stringname property representing requested key
## Outputs: Associated node reference
##
func _get(property: StringName):
	var p = str(property)
	if modules.has(p):
			#print("Module requested via _get: ", p)
			return modules[p].node
	return null
	
