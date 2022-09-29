extends AnimationPlayer

# VMC Receiver Path
@export var vmc_receiver_path: NodePath = "/root/Main/VMCReceiver"
@onready var vmc_receiver = get_node(self.vmc_receiver_path)

# Code taken from https://github.com/you-win/openseeface-gd
class ExpressionData:
	var morphs: Array # MorphData

class MorphData:
	var mesh: MeshInstance3D
	var blend_idx: int
	var values: PackedFloat32Array

var expression_data: Dictionary = {}

func __modify_blend_shape(mesh_instance: MeshInstance3D, blend_shape: String, value: float) -> void:
	mesh_instance.set(blend_shape, value)


# Called when the node enters the scene tree for the first time.
func _ready():
	for animation_name in self.get_animation_list():
		var expression: ExpressionData = ExpressionData.new()
		var animation: Animation = self.get_animation(animation_name)
		for track_index in animation.get_track_count():
			var track_name: String = animation.track_get_path(track_index)
			var split_name: PackedStringArray = track_name.split(":")
			
			if split_name.size() != 2:
				print("Model has ultra nested meshes: %s" % track_name)
				continue
			
			var mesh = get_node_or_null('../' + split_name[0])
			if not mesh or not mesh is MeshInstance3D:
				#print("Unable to find mesh: %s" % split_name[0])
				continue
			
			var md = MorphData.new()
			md.mesh = mesh
			var blend_idx = mesh.find_blend_shape_by_name(split_name[1])
			if blend_idx == null:
				# Only save blend shape animation tracks
				continue
			
			md.blend_idx = blend_idx
			
			for key_index in animation.track_get_key_count(track_index):
				md.values.append(animation.track_get_key_value(track_index, key_index))
			
			expression.morphs.append(md)
			var vrm_blend_name: String = animation_name.split('/', true, 1)[1]
			self.expression_data[vrm_blend_name] = expression

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Reset all animations
	for animation_name in self.get_animation_list():
		self.current_animation = animation_name
		self.seek(0, true)
	
	for name in self.vmc_receiver.blend_shapes:
		var expressions: ExpressionData = self.expression_data.get(name.to_upper(), null)
		if not expressions:
			continue
		
		for morph in expressions.morphs:
			var anim_val: float = self.vmc_receiver.blend_shapes[name]
			var track_count: int = morph.values.size()-1
			var key_idx: int = ceil(anim_val*track_count)
			var blend_val: float = morph.mesh.get_blend_shape_value(morph.blend_idx)
			if key_idx != 0:
				var weight: float = 1 - (key_idx/track_count - anim_val)
				blend_val += float(lerpf(morph.values[key_idx-1], morph.values[key_idx], weight))
				#blend_val += anim_val
			
			morph.mesh.set_blend_shape_value(morph.blend_idx, blend_val)
