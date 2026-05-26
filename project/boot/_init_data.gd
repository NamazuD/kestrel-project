extends Node

# 1. The Master Hierarchy (The Blueprint)
var master_blueprint: Dictionary = {}

# 2. The Inverted Script Registry (The Lookup)
var script_registry: Dictionary = {}

const ROOT_PATH: String = "res://project/scripts/"

func _ready() -> void:
	print("[InitData] Starting system discovery walk...")
	_generate_master_blueprint(ROOT_PATH)
	print("[InitData] Master blueprint fully constructed.")
	print("[InitData] Current Alias structure:\n", JSON.stringify(master_blueprint, "\t"))

# Standalone function to build the nested blueprint from a single filesystem walk
func _generate_master_blueprint(root_path: String) -> void:
	var dir = DirAccess.open(root_path)
	if not dir:
		print("[InitData] Error: Could not open root scripts directory at ", root_path)
		return
		
	dir.list_dir_begin()
	var pipeline_dir = dir.get_next()
	
	while pipeline_dir != "":
		if dir.current_is_dir() and not pipeline_dir.begins_with("."):
			var pipeline_name = pipeline_dir.to_upper()
			var pipeline_path = root_path.path_join(pipeline_dir) + "/"
			
			# Temporary entry to hold potential domains
			master_blueprint[pipeline_name] = {}
				
			# Kick off the recursive search inside this pipeline folder
			_gather_scripts_from_leaf(pipeline_path, pipeline_name)
			
			# Clean-up Step: If no scripts/domains were found down this branch, erase the pipeline
			if master_blueprint[pipeline_name].is_empty():
				master_blueprint.erase(pipeline_name)
				print("[InitData] Cleaned up empty pipeline directory: ", pipeline_name)
			
		pipeline_dir = dir.get_next()
	dir.list_dir_end()


# Recursively walks through any depth and dynamically establishes the leaf domain when scripts are found
func _gather_scripts_from_leaf(current_path: String, pipeline_name: String) -> void:
	var dir = DirAccess.open(current_path)
	if not dir:
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not file_name.begins_with("."):
			var full_path = current_path.path_join(file_name)
			
			# Use DirAccess directly to check if the path is a directory
			var sub_dir_check = DirAccess.open(full_path)
			if sub_dir_check and sub_dir_check.dir_exists(full_path):
				# Dive deeper into sub-directories, carrying the pipeline context along
				_gather_scripts_from_leaf(full_path + "/", pipeline_name)
			elif file_name.ends_with(".gd"):
				# We found a script! The folder holding it is the domain name.
				var domain_folder = current_path.get_base_dir().get_file()
				var domain_name = domain_folder.to_upper()
				
				# Initialize the domain structure only when a script is actively discovered
				if not master_blueprint[pipeline_name].has(domain_name):
					master_blueprint[pipeline_name][domain_name] = {
						"Path": current_path,
						"Scripts": []
					}
				
				# Append the script name to this domain's collection
				master_blueprint[pipeline_name][domain_name]["Scripts"].append(file_name)
				print("[InitData] Mapped Script: ", file_name, " inside dynamically discovered domain: ", domain_name)
				
		file_name = dir.get_next()
	dir.list_dir_end()
