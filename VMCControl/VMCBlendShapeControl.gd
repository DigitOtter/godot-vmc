extends AnimationPlayer

# VMC Receiver Path
@export var vmc_receiver_path: NodePath = "/root/Main/VmcReceiver"
@onready var vmc_receiver = get_node(self.vmc_receiver_path)

# Code taken from https://github.com/you-win/openseeface-gd
class ExpressionData:
	var morphs: Array # MorphData

class MorphData:
	var mesh: MeshInstance3D
	var blend_idx: int
	var values: PackedFloat32Array
	var base_value_mod: float = 0

var expression_data: Dictionary = {}

func __modify_blend_shape(mesh_instance: MeshInstance3D, blend_shape: String, value: float) -> void:
	mesh_instance.set(blend_shape, value)

# Called when the node enters the scene tree for the first time.
func _ready():
	self.speed_scale = 0.0
	
	if !self.get_animation_list().has("RESET"):
		print("Missing RESET animation")

	##### Load base blendshape values from RESET Animation
	var base_values: Dictionary = {}
	var reset_animation = self.get_animation("RESET")
	for track_index in reset_animation.get_track_count():
		var track_name: String = reset_animation.track_get_path(track_index)
		var split_name: PackedStringArray = track_name.split(":")
		var mesh = get_node_or_null('../' + split_name[0])
		if not mesh or not mesh is MeshInstance3D:
			continue
		
		var blend_idx = mesh.find_blend_shape_by_name(split_name[1])
		if blend_idx == null:
			# Only save blend shape animation tracks
			continue
		
		var mesh_vals: Dictionary = base_values.get(mesh, {})
		mesh_vals[blend_idx] = reset_animation.track_get_key_value(track_index, 0)
		base_values[mesh] = mesh_vals

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

			# Add blend shape weights for this given animation
			# The weight at animation time 0 is taken from RESET
			# The weight at animation time 1 is taken from the current animation track
			md.values.append(base_values[md.mesh][md.blend_idx])
			md.values.append(animation.track_get_key_value(track_index, 0))

			expression.morphs.append(md)
			var split_anim_name = animation_name.split('/', true, 1)
			var vrm_blend_name: String = split_anim_name[split_anim_name.size()-1] if split_anim_name.size() > 0 else animation_name
			#var vrm_blend_name: String = animation_name.split('/', true, 1)[1]
			self.expression_data[vrm_blend_name.to_upper()] = expression
	
	# Manual fixes. Should be removed with new avatar
	print("Warning: Applying manual fixes for current avatar blendshapes. Should be removed with next VRM model")
	if self.expression_data.has("MOUTHSMILELEFT"):
		for morph in self.expression_data["MOUTHSMILELEFT"].morphs:
			morph.base_value_mod = 0.45
	if self.expression_data.has("MOUTHSMILERIGHT"):
		for morph in self.expression_data["MOUTHSMILERIGHT"].morphs:
			morph.base_value_mod = 0.45
	if self.expression_data.has("AA"):
		self.expression_data["A"] = self.expression_data["AA"]
	if self.expression_data.has("EE"):
		self.expression_data["E"] = self.expression_data["EE"]
	if self.expression_data.has("IH"):
		self.expression_data["I"] = self.expression_data["IH"]
	if self.expression_data.has("OH"):
		self.expression_data["O"] = self.expression_data["OH"]
	if self.expression_data.has("OU"):
		self.expression_data["U"] = self.expression_data["OU"]
	if self.expression_data.has("BLINKLEFT"):
		self.expression_data["BLINK_L"] = self.expression_data["BLINKLEFT"]
	if self.expression_data.has("BLINKRIGHT"):
		self.expression_data["BLINK_R"] = self.expression_data["BLINKRIGHT"]
	#self.expression_data["JOY"] = self.expression_data["HAPPY"]
	#self.expression_data["SORROW"] = self.expression_data["SAD"]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Reset all animations
	self.current_animation = "RESET"
	self.seek(0, true)
	
	for blend_shape_name in self.vmc_receiver.blend_shapes:
		var expressions: ExpressionData = self.expression_data.get(blend_shape_name.to_upper(), null)
		if not expressions:
			continue
		
		for morph in expressions.morphs:
			var anim_val: float = self.vmc_receiver.blend_shapes[blend_shape_name]
			var track_count: int = morph.values.size()-1
			var key_idx: int = ceil(anim_val*track_count)
			var blend_val: float = morph.mesh.get_blend_shape_value(morph.blend_idx) + morph.base_value_mod
			if key_idx != 0:
				#var weight: float = 1 - (key_idx/track_count - anim_val)
				blend_val += float(lerpf(morph.values[key_idx-1], morph.values[key_idx], anim_val))
				#blend_val += anim_val
			
			morph.mesh.set_blend_shape_value(morph.blend_idx, blend_val)
