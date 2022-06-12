extends AnimationPlayer

# VMC Receiver Path
export(NodePath) var vmc_receiver_path = "/root/Main/VMCReceiver"
onready var vmc_receiver = get_node(self.vmc_receiver_path)

# Code taken from https://github.com/you-win/openseeface-gd
class ExpressionData:
	var morphs: Array # MorphData

class MorphData:
	var mesh: MeshInstance
	var morph: String
	var values: Array

var expression_data: Dictionary = {}

func __modify_blend_shape(mesh_instance: MeshInstance, blend_shape: String, value: float) -> void:
	mesh_instance.set(blend_shape, value)


# Called when the node enters the scene tree for the first time.
func _ready():
	for animation_name in self.get_animation_list():
		self.current_animation = animation_name
		self.seek(0, true)
	
	for animation_name in self.get_animation_list():
		expression_data[animation_name] = ExpressionData.new()
		var animation: Animation = self.get_animation(animation_name)
		for track_index in animation.get_track_count():
			var track_name: String = animation.track_get_path(track_index)
			var split_name: PoolStringArray = track_name.split(":")
			
			if split_name.size() != 2:
				print("Model has ultra nested meshes: %s" % track_name)
				continue
			
			var mesh = get_node_or_null((split_name[0]))
			if not mesh:
				#print("Unable to find mesh: %s" % split_name[0])
				continue
			
			var md = MorphData.new()
			md.mesh = mesh
			md.morph = split_name[1]
			
			for key_index in animation.track_get_key_count(track_index):
				md.values.append(animation.track_get_key_value(track_index, key_index))
			
			expression_data[animation_name].morphs.append(md)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for name in self.vmc_receiver.blend_shapes:
		if self.get_animation(name.to_upper()) != null:
			var val: float = self.vmc_receiver.blend_shapes[name]
			self.current_animation = name.to_upper()
			self.seek(val, true)
		else:
			#print("Unknown blend shape: '" + name + "'")
			pass
