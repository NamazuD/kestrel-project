extends Node

# The new flat script-based dictionary accessible to the rest of the game
var script_registry: Dictionary = {}

func _ready() -> void:
	# Wait for the next frame or a tiny break if needed, 
	# but as long as AutoLoad order is correct, InitData will be ready.
	print("[InitSubDict] Inverting master blueprint into flat script registry...")
	_derive_script_registry()
	print("[InitSubDict] Flat script registry ready. Total unique scripts: ", script_registry.size())
	#print("[InitSubDict] Current Alias structure:\n", JSON.stringify(script_registry, "\t"))

func _derive_script_registry() -> void:
	# Fetch the master blueprint directly from your first singleton
	var blueprint = InitData.master_blueprint
	
	for pipeline_name in blueprint:
		var domains_dict = blueprint[pipeline_name]
		
		for domain_name in domains_dict:
			var domain_data = domains_dict[domain_name]
			var directory_path = domain_data["Path"]
			var scripts_list = domain_data["Scripts"]
			
			# Map each individual script name to its pipeline execution details
			for script_name in scripts_list:
				
				# If a duplicate filename happens to exist across different domains, 
				# this will warn you so it doesn't quietly overwrite your data.
				if script_registry.has(script_name):
					push_warning("[InitSubDict] Duplicate script filename detected: " + script_name + 
						". Overwriting old path: " + script_registry[script_name]["Directory"] + 
						" with new path: " + directory_path)
				
				script_registry[script_name] = {
					"Directory": directory_path,
					"Pipeline": pipeline_name
				}
