extends Node  

# The global, static data bucket accessible from anywhere
static var subscription_aliases: Dictionary = {}

#Load templates to help create aliases.
# Load the resource, then use get_meta() to grab the specific dictionary inside
const ALIAS_ROOT_PATH: String = "res://project/scripts/"

#---------------------------------------------------

func _ready() -> void:
	var result = {
		"data" : {
			"subscription_aliases" : {}
		},
		"error" : null
	}
	
	var staged_aliases: Dictionary = {}
	
	# Pass the staging dict into the crawler
	var success = _dir_dictionary(staged_aliases, result, ALIAS_ROOT_PATH)
	
	# 1. Error Handling: Intercept failures immediately
	if not success or result.error != null:
		var final_error = result.error if result.error != null else "Unknown initialization error."
		push_error("Alias Registry Failed: " + final_error)
		
		# Clear the global reference to guarantee stale/partial data isn't used
		subscription_aliases = {} 
		return

	# 2. Transaction Commit: Assign the verified block to global memory
	result.data.subscription_aliases = staged_aliases
	subscription_aliases = result.data.subscription_aliases
	
	print("Alias Registry successfully initialized with ", subscription_aliases.size(), " channels.")
	print("[InitTaskLanes] Current Alias structure:\n", JSON.stringify(subscription_aliases, "\t"))


#---------------------------------------------------

# The atomic filesystem crawler
func _dir_dictionary(temp_registry: Dictionary, results: Dictionary, path: String) -> bool:
	var dir = DirAccess.open(path)
	if not dir:
		results.error = "File system error: Unable to open directory path: " + path
		return false

	var has_subdirectories: bool = false
	
	# 1. Recursive Step: Dig down into branches
	for sub_dir in dir.get_directories():
		if not sub_dir.begins_with("."):
			has_subdirectories = true
			var next_path = path.path_join(sub_dir)
			
			# Pass the local temporary storage down through the chain
			if not _dir_dictionary(temp_registry, results, next_path):
				return false
			
	# 2. Base Case: Write strictly to our local staging dictionary, not 'results'
	if not has_subdirectories:
		if _physical_dir_has_scripts(path):
			var leaf_name = path.get_file()
			temp_registry[leaf_name] = path + "/"
			
	return true
	
#---------------------------------------------------

# Helper function to check if a specific physical leaf directory contains any .gd scripts
func _physical_dir_has_scripts(path: String) -> bool:
	var dir = DirAccess.open(path)
	if not dir:
		return false
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var found_script = false
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".gd"):
			found_script = true
			break
		file_name = dir.get_next()
		
	dir.list_dir_end()
	return found_script
