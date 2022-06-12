# GodotVMC Example Project

An example project containing [godot-vmc](https://github.com/DigitOtter/godot-vmc-lib)

## Installation

Download the repository, then unzip the library archive from [here](https://github.com/DigitOtter/godot-vmc-lib/releases) in the `addons` subdirectory.

## Example scripts

### VMCBlendShapeControl.gd

`VMCBlendShapeControl.gd` reads the received blendshapes out of the `VMCReceiver.blend_shapes` dictionary and applies them to the corresponding animation frames of the parent `AnimationPlayer`.
To use `VMCBlendShapeControl.gd`, add this script to the `AnimationPlayer` of the model that should be controlled (see image).

![VMCBlendShapeControl script](images/blend_shape_control_script.png?raw=true)

### VMCBoneControl.gd

`VMCBoneControl.gd` reads the received bone poses out of the `VMCReceiver.bone_poses` dictionary and applies them to the corresponding bones of the parent `Skeleton`.
To use `VMCBoneControl.gd`, add this script to the `Skeleton` of the model that should be controlled (see image).

NOTE: I've added a conversion from the Unity to the Godot coordinate frame. It should work out-of-the-box with vmc data intended for VSeeFace.

![VMCBoneControl script](images/bone_control_script.png?raw=true)
