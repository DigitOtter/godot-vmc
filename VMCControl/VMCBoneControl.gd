extends Skeleton3D

# VMC Receiver Path
@export var vmc_receiver_path: NodePath = "/root/Main/VMCReceiver"
@onready var vmc_receiver = get_node(self.vmc_receiver_path)

var vmc_to_bone_idx: Dictionary

func __utg_01_convert(u: Vector3) -> Vector3:
	return Vector3(u.x, -u.y, -u.z)

func __utg_02l_convert(u: Vector3) -> Vector3:
	return Vector3(u.z, -u.y, u.x)

func __utg_02r_convert(u: Vector3) -> Vector3:
	return Vector3(-u.z, -u.y, u.x)

var __utg_converters: Dictionary = {
	'hips': self.__utg_01_convert,
	'spine': self.__utg_01_convert,
	'chest': self.__utg_01_convert,
	'upper_chest': self.__utg_01_convert,
	'neck': self.__utg_01_convert,
	'head': self.__utg_01_convert,
	'leftupperarm': self.__utg_02l_convert,
	'rightupperarm': self.__utg_02r_convert,
}

# Called when the node enters the scene tree for the first time.
func _ready():
	# Invert bone mapping
	var bone_mapping: BoneMap = get_parent().vrm_meta.humanoid_bone_mapping
	self.vmc_to_bone_idx.clear()
	for i in range(0, bone_mapping.profile.bone_size):
		var profile_bone_name: String = bone_mapping.profile.get_bone_name(i)
		var skel_bone_name: String = bone_mapping.get_skeleton_bone_name(profile_bone_name)
		if skel_bone_name:
			var bone_data = [self.find_bone(profile_bone_name),
				self.__utg_converters.get(profile_bone_name.to_lower(), self.__utg_01_convert)
			]
			self.vmc_to_bone_idx[profile_bone_name] = bone_data

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# TODO: Add bone stiffness and/or compare to vmc_receiver.t?
	self.reset_bone_poses()
	self.clear_bones_global_pose_override()
	self.clear_bones_local_pose_override()
	var bone_poses: Dictionary = self.vmc_receiver.bone_poses
	for bone_name in bone_poses:
		var bone_data = self.vmc_to_bone_idx.get(bone_name, null)
		#if bone_name.to_lower() != 'head' and \
		#		bone_name.to_lower() != 'neck':
		#	continue
		if bone_data:
			var bone_idx = bone_data[0]
			var converter = bone_data[1]
			var bone_pose = bone_poses[bone_name]
			var rest_pose = self.get_bone_rest(bone_idx).basis.get_euler()
			
			# Convert from Unity to Godot coordinate system
			# At the moment, we're only changing rotation and ignoring translation
			var euler = bone_pose.basis.get_euler()
			euler = converter.call(euler)
			
			self.set_bone_pose_rotation(bone_idx, Quaternion(rest_pose)*Quaternion(euler))
