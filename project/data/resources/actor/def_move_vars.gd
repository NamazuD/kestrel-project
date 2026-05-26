## [TEMPLATE] MoveResource
## This script serves as a data schema for actor movement variables.
## DO NOT attach this script to nodes. Use it to create .tres resources.

extends Resource
class_name MoveResource

@export_group("Base Physics")
## The maximum velocity the actor can reach. (Default: 200.0)
@export var max_speed: float = 200.0

@export_group("Forces")
## How quickly the actor reaches max_speed. (Default: 1000.0)
@export var acceleration: float = 1000.0
## How quickly the actor comes to a stop. (Default: 800.0)
@export var friction: float = 800.0
