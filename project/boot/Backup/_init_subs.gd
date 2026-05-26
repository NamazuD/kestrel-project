extends Node

# Persistent global memory for the event system.
# Accessible anywhere via SubscriberBinder.routing_table
static var routing_table: Dictionary = {}

func _ready() -> void:
	# Wait for the boot queue to ensure paths are fully finalized
	await get_tree().process_frame
	print("[SubscriberBinder] Tied to registry memory. Binding scripts...")
	_bind_scripts_to_leaves()

func _bind_scripts_to_leaves() -> void:
	var binding_registry: Dictionary = {}
	var source_paths: Dictionary = InitAliases.subscription_aliases
	
	# Loop through each explicit domain entry
	for domain_name in source_paths:
		var dir_path: String = source_paths[domain_name]
		
		# Derive the pipeline name from the path structure
		# E.g., "res://project/scripts/PIPELINE_1/DOMAIN_NAME/" -> "PIPELINE_1"
		var pipeline_name: String = _extract_pipeline_from_path(dir_path)
		
		# Ensure the nested dictionary structure exists
		if not binding_registry.has(pipeline_name):
			binding_registry[pipeline_name] = {}
		if not binding_registry[pipeline_name].has(domain_name):
			binding_registry[pipeline_name][domain_name] = []
			
		# Recursively scan the directory and its sub-folders for scripts
		_scan_directory_recursive(dir_path, binding_registry[pipeline_name][domain_name], domain_name)
					
	# Commit the cleanly mapped scripts to your memory object
	# (e.g., GlobalRegistry.memory_object = binding_registry)
	routing_table = binding_registry
	
	print("[SubscriberBinder] All scripts registered cleanly to their pipelines and domains.")
	print("[InitTaskLanes] Current registry structure:\n", JSON.stringify(routing_table, "\t"))

# Helper function to recursively find scripts across deep directory levels
func _scan_directory_recursive(dir_path: String, target_array: Array, domain_name: String) -> void:
	# Open a brand new, isolated DirAccess instance for THIS specific folder layer
	var dir = DirAccess.open(dir_path)
	if not dir:
		print("[SubscriberBinder] Error opening directory: ", dir_path)
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		# Ignore hidden system files and folders
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
			
		var full_path = dir_path.path_join(file_name)
		if dir.current_is_dir():
			# Crucial: This calls the function again, which creates its OWN 'dir' object 
			# on the call stack, preserving this current loop's state.
			_scan_directory_recursive(full_path, target_array, domain_name)
		elif file_name.ends_with(".gd"):
			var script_resource = load(full_path)
			if script_resource:
				target_array.append(script_resource)
				print("[SubscriberBinder] Registered: ", file_name, " -> [", domain_name, "]")

		file_name = dir.get_next()

# Helper to pull the pipeline folder name safely out of the path string
func _extract_pipeline_from_path(path: String) -> String:
	# Standardize path separators and split
	var clean_path = path.replace("\\", "/")
	var segments = clean_path.split("/", false)
	
	# If the path ends in a domain directory (e.g., /scripts/PIPELINE/DOMAIN/), 
	# the pipeline is the second to last element.
	if segments.size() >= 2:
		return segments[segments.size() - 2].to_upper()
		
	return "UNKNOWN_PIPELINE"
