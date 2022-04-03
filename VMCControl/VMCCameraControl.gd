extends Camera

export(NodePath) var vmc_receiver_path = "/root/Main/VMCReceiver"
onready var vmc_receiver = get_node(self.vmc_receiver_path)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if vmc_receiver.camera_pose == Transform.IDENTITY:
		return
	
	self.transform = vmc_receiver.camera_pose
