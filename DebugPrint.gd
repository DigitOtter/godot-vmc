extends Node


export(NodePath) var vmc_receiver_path = null

onready var vmc_receiver: Node = get_node(self.vmc_receiver_path)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	print(self.vmc_receiver.root_poses)
	print(self.vmc_receiver.bone_poses)
	print(self.vmc_receiver.other_data)
