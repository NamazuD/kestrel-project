##==========
## Recommended Path: /project/boot/_init_threads.gd
## Project: Project Kestral
##
## GD Auto loaded Singleton - Initializes on engine start (_ready)
## Optional, stateless, non-mutating threads used only for isolated heavy computation.
## Example: Heavy computations that would otherwise block the main thread
## Not needed for most applications
## Recommendation: Use as an isolated computation unit; not intended as a core system participant
## Creates: Worker thread domains and execution state
## Uses:
##  - Godot Thread API
##  - Godot Semaphore (thread blocking/wake)
##  - Godot Mutex (shared state protection)
## Consumed by: External systems submitting tasks to worker domains (optional usage)
##==========

extends Node

# Number of worker threads to initialize (0 = disabled)
@export var thread_count: int = 0

# --- Worker Domain Data Structure ---
# Encapsulates all state required for a single worker thread
# Each domain owns its thread lifecycle and task queue
# Thread Safety:
#  - task_queue and should_exit must only be accessed while holding mutex
#  - semaphore coordinates thread wake/sleep behavior
# Ownership:
#  - Created and managed by the thread system
#  - Not intended for direct external mutation
#
class WorkerDomain:
	var thread: Thread = Thread.new()			# Godot thread instance (OS-managed execution)
	var semaphore: Semaphore = Semaphore.new()	# Signals work availability / wake-up
	var mutex: Mutex = Mutex.new()			# Protects shared state access
	var task_queue: Array = []				# Queue of pending tasks (FIFO)
	var should_exit: bool = false				# Shutdown signal flag

# Registry of active worker domains keyed by domain name
# Used internally for thread lifecycle management and task submission
var active_domains: Dictionary = {}

## --- GD Singleton Autostart  ---
## Used from: Godot Autostart Settings
## Inputs: None
## Effects: Initializes optional isolated computational threads (via internal generation)
## Outputs: None
##
func _ready() -> void:
	# 1. 
	if thread_count <= 0:
		print("Thread initialization skipped: thread_count is 0.")
		return

	# 2. 
	print("Thread initialization start for ", thread_count, " threads.")
	for i in range(thread_count):
		# 2.1 Generates generic names like "worker_0", "worker_1", etc.
		var thread_name = "worker_" + str(i)
		_spawn_worker_thread(thread_name)

	print("Threads are initialized and parked on a semaphore, activating only when work is posted.")
	
## --- Spawn Worker Thread (internal)  ---
## Creates a computational worker thread
## Starts thread loop bound to domain_name
## Used from: func _ready()
## Inputs: domain_name: String
## Effects:
##  - Creates and registers a worker domain
##  - Starts thread loop bound to domain_name
##
func _spawn_worker_thread(domain_name: String) -> void:


	# 1. CREATE DOMAIN (application state):
	# Instantiate and register a worker domain for tracking and lifecycle control
	var domain = WorkerDomain.new()
	active_domains[domain_name] = domain
	

	# 2. START THREAD (Godot Thread API):
	# Launch a new OS thread bound to this domain's lifecycle loop
	# Thread immediately enters its loop and blocks until work is posted
	domain.thread.start(_thread_loop.bind(domain))
	print("Domain thread initialized and sleeping: ", domain_name)


## --- Thread Loop Lifecycle (internal)  ---
## Defines the lifecycle of a worker thread:
##  blocking, wake-up, fetch, execution, and shutdown
## Inputs: domain: WorkerDomain
## Effects:
##  - Consumes queued tasks from domain.task_queue
##  - Executes task-defined logic on a background thread
## Invokes: Task-defined callable or execution logic provided by the developer
##
func _thread_loop(domain: WorkerDomain) -> void:

	# 1. This loop runs entirely on its own background OS thread
	while true:

		# 1.1 SLEEP (Godot Semaphore):
		# Blocks this OS thread with 0% CPU until another thread posts work
		domain.semaphore.wait()

		# 1.2 CHECK SHUTDOWN (Godot Mutex):
		# Lock shared state to safely check exit condition
		domain.mutex.lock()
		if domain.should_exit:
			# Unlock after safe read and/or modification
			domain.mutex.unlock()
			break
		
		# 1.3 FETCH WORK (protected shared queue):
		# Safely retrieve next task from thread-owned queue
		var current_task = null
		if not domain.task_queue.is_empty():
			current_task = domain.task_queue.pop_front()
		domain.mutex.unlock()

		# 1.4 EXECUTE (task-defined behavior):
		# Execute payload-defined logic.
		# Tasks are expected to carry their own callable or execution definition.
		#
		# Example task structure (see README for full details):
		# {
		#     "callable": Callable(target, "method_name"),
		#     "data": payload
		# }
		#
		# Triggered when a task is posted via:
		# domain.task_queue.push_back(task)
		# domain.semaphore.post()
		#
		if current_task:
			current_task.callable.call(current_task.data)


## --- Godot Lifecycle Callback ---
## Called automatically by the engine when this node exits the scene tree
## Used for cleanup of thread resources
#
func _exit_tree() -> void:
	_cleanup_threads()


## --- Godot Lifecycle Callback ---
## Called automatically by the engine for system and OS-level notifications
## Uses notification code to detect specific events (e.g., window close request)
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_cleanup_threads()


## --- Cleanup Threads (internal) ---
## Signals all worker threads to terminate and waits for clean shutdown
## Releases blocked threads so they can observe exit conditions
## Clears all registered thread domains after termination
## Used from:
##  - _exit_tree()
##  - _notification(what)
## Inputs: None
##
func _cleanup_threads() -> void:
	# 1. Avoid running cleanup multiple times if both events fire sequentially
	if active_domains.is_empty():
		return
		
	# 2. Begin process of shutting down threads.
	print("Shutting down worker threads safely...")
	for domain_name in active_domains:
	
		# 2.1 SIGNAL SHUTDOWN (Godot Mutex):
		# Set exit flag so thread can terminate safely
		var domain = active_domains[domain_name]
		domain.mutex.lock()
		domain.should_exit = true
		domain.mutex.unlock()
		
		# 2.2 WAKE THREAD (Godot Semaphore):
		# Signal the semaphore to release a blocked thread from wait()
		# Allows the thread to resume and evaluate the exit condition
		domain.semaphore.post()
		
		# 2.3 JOIN THREAD (Godot Thread API):
		# Wait for OS thread to finish cleanly before detaching
		domain.thread.wait_to_finish()

	 # 3. Clear domain registry after all threads have terminated
	active_domains.clear()
	print("All worker threads safely detached.")
