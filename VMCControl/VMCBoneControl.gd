extends Skeleton3D

# VMC Receiver Path
@export var vmc_receiver_path: NodePath = "/root/Main/VMCReceiver"
@onready var vmc_receiver = get_node(self.vmc_receiver_path)

var to_vmc_bone_mapping: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	# Invert bone mapping
	var bone_mapping: Dictionary = get_parent().vrm_meta.humanoid_bone_mapping
	self.to_vmc_bone_mapping.clear()
	for key in bone_mapping:
		var vrm_name: String = key
		self.to_vmc_bone_mapping[bone_mapping[key]] = vrm_name.substr(0,1).capitalize() + vrm_name.substr(1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# TODO: Add bone stiffness and/or compare to vmc_receiver.t?
	var bone_poses: Dictionary = self.vmc_receiver.bone_poses
	for idx in range(0, self.get_bone_count()):
		var bone_name: String = self.get_bone_name(idx)
		var vrm_bone_name = self.to_vmc_bone_mapping.get(bone_name, null)
		if vrm_bone_name:
			var bone_pose = bone_poses.get(vrm_bone_name, null)
			if bone_pose: # and bone_name == 'hips':
				bone_pose.origin = Vector3.ZERO
				# Convert from Unity to Godot coordinate system
				# At the moment, we're only changing rotation and ignoring translation
				var euler = bone_pose.basis.get_euler()
				euler.x = -euler.x
				euler.y = -euler.y
				bone_pose.basis = Basis(euler)
				self.set_bone_pose(idx, bone_pose)
	
