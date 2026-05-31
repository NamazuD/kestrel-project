##==========
## Path: /project/boot/_init_sub_dict.gd
## Project: Project Kestral
##
## GD Auto loaded Singleton - Initializes on engine start (_ready)
## Creates global dictionary script_registry
## Structure defined in: _derive_script_registry()
## Consumed by:
##  - InitTaskLanes._initialize_job_lanes() → builds execution queue lanes
##  - EventBus.start_event(script_name, payload) → routes events to execution lanes
##==========

extends Node

# Globally accessable reverse lookup script-based dictionary
var script_registry: Dictionary = {}

## --- GD Singleton Autostart  ---
## Used from: Godot Autostart Settings
## Inputs: None
## Effects: Initializes script_registry (via internal generation)
## Outputs: None
##
func _ready() -> void:
	print("[InitSubDict] Inverting directory_structure into flat script registry...")
	_derive_script_registry()
	print("[InitSubDict] Flat script registry ready. Total unique scripts: ", script_registry.size())
	#print("[InitSubDict] Current Alias structure:\n", JSON.stringify(script_registry, "\t"))

## --- Derive Script Registry ---
## Method to derive reverse lookup dictionary from previous directory structure
## New dictionary will allow path and pipeline lookup based on script name.
## Used from: func _ready()
## Inputs: None
## Effects: 
##  - Builds and populates script_registry
## Modifies: Persistent global script_registry: Dictionary
## 	Structure: script_registry format:
##	{ "script_name": {
##        	"Directory": "directory_path",
##        	"Pipeline": "pipeline_name"
##	}}
##
func _derive_script_registry() -> void:
	# 1.  Fetch the master directory_structure created by _init_data.gd singleton
	var directory_structure = InitData.directory_structure
	for pipeline_name in directory_structure:

		# 1.1. Create an initial Dictionary to populate
		var domains_dict = directory_structure[pipeline_name]
		for domain_name in domains_dict:

			# 1.1.1. Create temporary variables to populate lookup dictionary
			var domain_data = domains_dict[domain_name]
			var directory_path = domain_data["path"]
			var scripts_list = domain_data["scripts"]
			
			# 1.1.2. Map each individual script name to its pipeline execution details
			for script_name in scripts_list:
				
				# 1.1.2.a. Duplicate filename warning
				if script_registry.has(script_name):
					push_error("[InitSubDict] Duplicate script filename detected: " + script_name) 
					return

				# 1.1.2.b. Populate dictionary with new data.	
				script_registry[script_name] = {
					"directory": directory_path,
					"pipeline": pipeline_name
				}
