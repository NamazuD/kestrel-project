##==========
## Path: /project/boot/_init_data.gd
## Project: Project Kestral
##
## GD Auto loaded Singleton - Initializes on engine start (_ready)
## Creates global dictionary directory_structure
## Structure defined in: _generate_directory()
## Consumed by:
##  - InitTaskLanes._initialize_job_lanes() → builds execution queue lanes
##  - _InitSubDict._derive_script_registry() → builds reverse script lookup dictionary
##==========

extends Node

var directory_structure: Dictionary = {}
# Read-only for external consumers; populated internally only

const ROOT_PATH: String = "res://project/scripts/"

## --- GD Singleton Autostart  ---
## Used from: Godot Autostart Settings
## Inputs: ROOT_PATH (const): root directory used for discovery
## Effects: Initializes directory_structure (via internal generation)
## Outputs: None
##
func _ready() -> void:
	print("[InitData] Starting system discovery walk...")
	_generate_directory(ROOT_PATH)
	print("[InitData] Directory structure fully constructed.")
	# print("[InitData] Directory Alias structure:\n", JSON.stringify(directory_structure, "\t"))

## --- Generate Directory Structure ---
## Method to build the nested directory from a single filesystem walk
## Validity is defined by the presence of scripts in the end leaves. 
## If there are no scripts present then there is no need to create a pipeline or preserve the branch. 
## This allows for a trimmed structure that preserves only what is needed.
## Used from: func _ready()
## Inputs:
##  - root_path: String
## Effects:
##  - Builds and populates directory_structure
## Modifies: Persistent global directory_structure: Dictionary
##	Structure: directory_structure format:
## 		{ PIPELINE_NAME: {
##       	DOMAIN_NAME: {
##           	"path": String,
##           	"scripts": Array[String]
##	}}}
## Calls: _gather_scripts(current_path: String, pipeline_name: String)
##
func _generate_directory(root_path: String) -> void:

	# 1. Check if directory is accessable
	var dir = DirAccess.open(root_path)
	if not dir:
		print("[InitData] Error: Could not open root scripts directory at ", root_path)
		return
		
	# 2. Step through the directory
	dir.list_dir_begin()
	var pipeline_dir = dir.get_next()
	
	# 3. Construct Directory Dictionary - Ignore branches that contain no scripts. 
	while pipeline_dir != "":
		if dir.current_is_dir() and not pipeline_dir.begins_with("."):
			# 3.1 Temporary entries to hold pipeline and path values.
			var pipeline_name = pipeline_dir.to_upper()
			var pipeline_path = root_path.path_join(pipeline_dir) + "/"
			
			# 3.2 Temporary entry to hold potential pipelines
			directory_structure[pipeline_name] = {}
				
			# 3.3 Recursive search inside this pipeline folder
			_gather_scripts(pipeline_path, pipeline_name)
			
			# 3.4 Clean-up Step: If no scripts/domains were found down this branch, erase the pipeline
			if directory_structure[pipeline_name].is_empty():
				directory_structure.erase(pipeline_name)
				print("[InitData] Cleaned up empty pipeline directory: ", pipeline_name)
			
		pipeline_dir = dir.get_next()
	dir.list_dir_end()

## --- Gather Scripts ---
## Recursively walks through any depth
## Establishes the leaf domain when scripts are found
## Used from: func _generate_directory(root_path)
##	Inputs: 
##	- current_path: String
##	- pipeline_name: String
## Modifies: Persistent global directory_structure: Dictionary
## Populates:
##  directory_structure[pipeline_name][DOMAIN_NAME] = {
##      "path": String,
##      "scripts": Array[String]
##  }
## Validity: DOMAIN_NAME is created only when at least one script is found
 
func _gather_scripts(current_path: String, pipeline_name: String) -> void:
	# 1. Recursion break: If directory is not found, return.
	var dir = DirAccess.open(current_path)
	if not dir:
		return
		
	# 2. List subdirectories
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	# 3. Iterate through the list of directories
	while file_name != "":
		if not file_name.begins_with("."):

			# 3.1 Use DirAccess directly to check if the path is a directory
			var full_path = current_path.path_join(file_name)
			var sub_dir_check = DirAccess.open(full_path)
			if sub_dir_check:

				# 3.1.1 Search sub-directories, carrying the pipeline context along
				_gather_scripts(full_path + "/", pipeline_name)

			# 3.2 If a script is found ....
			elif file_name.ends_with(".gd"):

				# 3.2.1 Save the folder holding it as the domain name.
				var domain_folder = current_path.get_base_dir().get_file()
				var domain_name = domain_folder.to_upper()
				
				# 3.2.2 Initialize the domain structure only when a script has been discovered
				if not directory_structure[pipeline_name].has(domain_name):
					directory_structure[pipeline_name][domain_name] = {
						"path": current_path,
						"scripts": []
					}
				
				# 3.2.3 Append the script name to this domain's collection
				directory_structure[pipeline_name][domain_name]["scripts"].append(file_name)
				print("[InitData] Mapped Script: ", file_name, " inside domain: ", domain_name)
				
		file_name = dir.get_next()
	dir.list_dir_end()
