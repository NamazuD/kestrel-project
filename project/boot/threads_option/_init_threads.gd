extends Node

# An inner class to cleanly bundle each domain's execution state
class WorkerDomain:
	var thread: Thread = Thread.new()
	var semaphore: Semaphore = Semaphore.new()
	var mutex: Mutex = Mutex.new()
	var task_queue: Array = []
	var should_exit: bool = false

const THREAD_DOMAINS_RES = preload("res://project/boot/thread_domains.tres")

# Globally accessible registry of active thread states for your event managers
var active_domains: Dictionary = {}

# New exported variable for flexibility
@export var thread_count: int = 0

func _ready() -> void:
	if thread_count <= 0:
		print("Thread initialization skipped: thread_count is 0.")
		return

	print("Thread initialization start for ", thread_count, " threads.")
	
	for i in range(thread_count):
		# Generates generic names like "worker_0", "worker_1", etc.
		var thread_name = "worker_" + str(i)
		_spawn_worker_thread(thread_name)

	print("All worker threads suspended and registered. Handing off to world.")

	get_tree().change_scene_to_file.call_deferred("res://project/nodes/core/map/default/default_world.tscn")
	

func _spawn_worker_thread(domain_name: String) -> void:
	var domain = WorkerDomain.new()
	active_domains[domain_name] = domain
	
	# Start the background loop, passing the specific domain object as context
	domain.thread.start(_thread_loop.bind(domain))
	print("Domain thread initialized and sleeping: ", domain_name)

# This loop runs entirely on its own background OS thread
func _thread_loop(domain: WorkerDomain) -> void:
	while true:
		# SLEEP: Instantly goes to 0% CPU until a task is posted to the semaphore
		domain.semaphore.wait()
		
		# CHECK SHUTDOWN: Safely check if the thread needs to close down
		domain.mutex.lock()
		if domain.should_exit:
			domain.mutex.unlock()
			break
		
		# FETCH WORK: Pull the next payload out of the queue securely
		var current_task = null
		if not domain.task_queue.is_empty():
			current_task = domain.task_queue.pop_front()
		domain.mutex.unlock()
		
		# EXECUTE: Pass the payload to your processing logic
		if current_task:
			_process_thread_work(current_task)

func _process_thread_work(_task: Variant) -> void:
	# This is where the background thread executes the passed payload.
	# Your static event managers will pass the handling logic here.
	pass

# Automated cleanup when Godot removes the node from the tree (e.g., manual reload)
func _exit_tree() -> void:
	_cleanup_threads()

# Intercept low-level OS notifications (e.g., clicking X on the window)
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_cleanup_threads()

# The single, unified source of truth for halting the hardware loops
func _cleanup_threads() -> void:
	# Avoid running cleanup multiple times if both events fire sequentially
	if active_domains.is_empty():
		return
		
	print("Shutting down worker threads safely...")
	for domain_name in active_domains:
		var domain = active_domains[domain_name]
		
		domain.mutex.lock()
		domain.should_exit = true
		domain.mutex.unlock()
		
		# Wake up the thread from its wait() state so it can see the exit flag
		domain.semaphore.post()
		
		# Wait for the OS thread to cleanly finish its loop and detach safely
		domain.thread.wait_to_finish()
		
	active_domains.clear()
	print("All worker threads safely detached.")
