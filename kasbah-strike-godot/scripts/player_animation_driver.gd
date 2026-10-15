extends Node
class_name PlayerAnimationDriver
## Pilote les animations d'un personnage Mixamo sans imposer des noms précis.
## Ajoute ce noeud sous le personnage, puis appelle setup() avec son AnimationPlayer
## et update_locomotion() depuis le script du joueur.

@export var animation_player_path: NodePath
@export var animation_tree_path: NodePath
@export var locomotion_blend_path: String = "parameters/Locomotion/blend_position"

var animation_player: AnimationPlayer
var animation_tree: AnimationTree
var playback: AnimationNodeStateMachinePlayback

var _animation_names: Dictionary = {}
var _current_animation: StringName = &""

func _ready() -> void:
	if not animation_player_path.is_empty():
		animation_player = get_node_or_null(animation_player_path) as AnimationPlayer
	if not animation_tree_path.is_empty():
		animation_tree = get_node_or_null(animation_tree_path) as AnimationTree
		if animation_tree:
			playback = animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	_cache_animation_names()

func setup(player: AnimationPlayer = null, tree: AnimationTree = null) -> void:
	if player:
		animation_player = player
	if tree:
		animation_tree = tree
		playback = animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	_cache_animation_names()

func update_locomotion(horizontal_speed: float, grounded: bool, sprinting: bool = false) -> void:
	if not grounded:
		_play_first([&"Jump", &"Falling", &"InAir", &"jump", &"fall"])
	elif horizontal_speed < 0.15:
		_play_first([&"Idle", &"idle", &"Breathing Idle", &"mixamo.com"])
	elif sprinting:
		_play_first([&"Run", &"Running", &"Sprint", &"run"])
	else:
		_play_first([&"Walk", &"Walking", &"walk", &"Run", &"Running"])

func play_action(action: StringName) -> void:
	match String(action).to_lower():
		"reload":
			_play_first([&"Reload", &"Reloading", &"reload"])
		"shoot", "fire":
			_play_first([&"Shoot", &"Fire", &"Firing", &"shoot"])
		"death", "die":
			_play_first([&"Death", &"Dying", &"die"])
		"hit":
			_play_first([&"Hit", &"HitReaction", &"hit"])

func _play_first(candidates: Array[StringName]) -> void:
	if animation_tree and playback:
		var states := _get_tree_state_names()
		for candidate in candidates:
			if states.has(String(candidate)):
				playback.travel(String(candidate))
				return
	if not animation_player:
		return
	for candidate in candidates:
		var actual := _find_animation(candidate)
		if actual != &"" and actual != _current_animation:
			_current_animation = actual
			animation_player.play(actual)
			return

func _find_animation(candidate: StringName) -> StringName:
	var wanted := String(candidate).to_lower()
	for key in _animation_names.keys():
		var lower := String(key).to_lower()
		if lower == wanted or lower.contains(wanted):
			return StringName(key)
	return &""

func _cache_animation_names() -> void:
	_animation_names.clear()
	if animation_player:
		for animation_name in animation_player.get_animation_list():
			_animation_names[animation_name] = true

func _get_tree_state_names() -> Array[String]:
	var result: Array[String] = []
	if not animation_tree or not animation_tree.tree_root is AnimationNodeStateMachine:
		return result
	var machine := animation_tree.tree_root as AnimationNodeStateMachine
	for state_name in machine.get_node_list():
		result.append(String(state_name))
	return result
