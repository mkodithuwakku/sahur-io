extends CharacterBody3D
class_name PlayerController

const ConfigStore = preload("res://scripts/core/config.gd")
const AudioService = preload("res://scripts/core/audio_manager.gd")
const CUSTOM_MODEL_SCENE = preload("res://resources/models/tung_tung_tung_sahur.glb")
const VISUAL_BASE_HEIGHT := 0.18
const CUSTOM_MODEL_TARGET_HEIGHT := 1.75

signal respawn_requested(peer_id: int)

@export var peer_id: int = 0
@export var display_name: String = "Guest"

var stats: PlayerStats
var growth: PlayerGrowth = PlayerGrowth.new()
var combat: PlayerCombat = PlayerCombat.new()
var network_state: PlayerNetwork = PlayerNetwork.new()

var desired_move_input: Vector2 = Vector2.ZERO
var desired_facing: Vector3 = Vector3.FORWARD
var external_impulse: Vector3 = Vector3.ZERO
var move_velocity: Vector3 = Vector3.ZERO
var hit_react_remaining: float = 0.0
var defeat_delay_remaining: float = 0.0
var pending_defeat: bool = false
var world_bounds: Vector2 = Vector2(20.0, 20.0)
var authoritative: bool = false
var is_local_player: bool = false

var body_material: StandardMaterial3D = StandardMaterial3D.new()
var head_material: StandardMaterial3D = StandardMaterial3D.new()
var bat_material: StandardMaterial3D = StandardMaterial3D.new()
var local_indicator_material: StandardMaterial3D = StandardMaterial3D.new()
var custom_model_root: Node3D = null
var custom_animation_player: AnimationPlayer = null
var using_custom_model: bool = false

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_root: Node3D = $MeshRoot
@onready var body_pivot: Node3D = $MeshRoot/BodyPivot
@onready var model_anchor: Node3D = $MeshRoot/BodyPivot/ModelAnchor
@onready var body_mesh: MeshInstance3D = $MeshRoot/BodyPivot/Body
@onready var head_mesh: MeshInstance3D = $MeshRoot/BodyPivot/Head
@onready var bat_pivot: Node3D = $MeshRoot/BodyPivot/BatPivot
@onready var bat_mesh: MeshInstance3D = $MeshRoot/BodyPivot/BatPivot/Bat
@onready var local_indicator: MeshInstance3D = $LocalIndicator
@onready var name_label: Label3D = $NameLabel
@onready var you_label: Label3D = $YouLabel

func setup(new_peer_id: int, new_display_name: String, local_peer_id: int, has_server_authority: bool, bounds: Vector2) -> void:
	peer_id = new_peer_id
	display_name = new_display_name
	stats = PlayerStats.new(peer_id, display_name)
	stats.reset_for_respawn(ConfigStore.player_tuning)
	world_bounds = bounds
	authoritative = has_server_authority
	is_local_player = peer_id == local_peer_id

func _ready() -> void:
	if stats == null:
		stats = PlayerStats.new(peer_id, display_name)
		stats.reset_for_respawn(ConfigStore.player_tuning)
	if body_pivot != null:
		body_pivot.position.y = VISUAL_BASE_HEIGHT
	if model_anchor != null:
		model_anchor.position = Vector3(0.0, -VISUAL_BASE_HEIGHT, 0.0)
	body_mesh.material_override = body_material
	head_mesh.material_override = head_material
	bat_mesh.material_override = bat_material
	local_indicator.material_override = local_indicator_material
	local_indicator_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	local_indicator_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	local_indicator_material.emission_enabled = true
	local_indicator_material.emission = Color(0.24, 0.95, 0.78)
	local_indicator_material.emission_energy_multiplier = 1.1
	_attach_custom_model()
	name_label.text = _get_name_label_text()
	you_label.text = "YOU"
	_sync_visual_state(true)

func _physics_process(delta: float) -> void:
	combat.tick(delta)
	if authoritative:
		_authoritative_tick(delta)
	elif is_local_player:
		_prediction_tick(delta)
	else:
		network_state.interpolate(self, delta)
	_update_visuals(delta)

func set_input_vector(move_input: Vector2) -> void:
	desired_move_input = move_input.limit_length(1.0)

func set_attack_facing(facing: Vector3) -> void:
	var planar: Vector3 = Vector3(facing.x, 0.0, facing.z)
	if planar.length_squared() > 0.0001:
		desired_facing = planar.normalized()

func get_attack_facing() -> Vector3:
	return desired_facing

func can_start_attack() -> bool:
	return stats.alive and not pending_defeat and combat.can_attack()

func is_targetable() -> bool:
	return stats.alive and not pending_defeat

func begin_attack_preview() -> bool:
	if not can_start_attack():
		return false
	combat.begin_attack()
	_apply_attack_lunge()
	_play_attack_feedback()
	return true

func server_process_attack(candidates: Array) -> Array:
	if not begin_attack_preview():
		return []
	var hits: Array = []
	var half_arc: float = ConfigStore.combat_tuning.attack_arc_degrees * 0.5
	var range_value: float = ConfigStore.combat_tuning.get_attack_range(stats.growth_level)
	for candidate in candidates:
		if candidate == null or candidate == self:
			continue
		if not candidate.is_targetable():
			continue
		if combat.has_hit_target(candidate.peer_id):
			continue
		if MathUtils.is_in_attack_arc(global_position, desired_facing, candidate.global_position, range_value, half_arc):
			combat.mark_target_hit(candidate.peer_id)
			var knockback_direction: Vector3 = MathUtils.planar_direction(global_position, candidate.global_position)
			var knockback_force: float = ConfigStore.combat_tuning.get_knockback(stats.growth_level)
			var defeated: bool = candidate.server_receive_hit(ConfigStore.combat_tuning.damage, peer_id, knockback_direction * knockback_force)
			hits.append({
				"target_peer_id": candidate.peer_id,
				"defeated": defeated
			})
	return hits

func server_receive_hit(damage: float, attacker_peer_id: int, knockback_vector: Vector3) -> bool:
	if not stats.alive or pending_defeat:
		return false
	var resistance: float = 1.0 + ConfigStore.player_tuning.knockback_resistance_per_growth * float(maxi(stats.growth_level - 1, 0))
	external_impulse = (external_impulse + (knockback_vector / resistance)).limit_length(ConfigStore.combat_tuning.max_received_knockback_speed)
	hit_react_remaining = ConfigStore.combat_tuning.hit_react_duration
	var defeated: bool = stats.take_damage(damage, attacker_peer_id)
	if defeated:
		pending_defeat = true
		defeat_delay_remaining = ConfigStore.combat_tuning.defeat_delay
		desired_move_input = Vector2.ZERO
	else:
		AudioService.play_hit()
	_sync_visual_state(true)
	return defeated

func server_register_kill() -> void:
	stats.kills += 1
	growth.apply_kill_growth(stats, ConfigStore.player_tuning)
	AudioService.play_growth()
	_sync_visual_state(true)

func server_respawn(spawn_position: Vector3) -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
	move_velocity = Vector3.ZERO
	external_impulse = Vector3.ZERO
	hit_react_remaining = 0.0
	defeat_delay_remaining = 0.0
	pending_defeat = false
	desired_move_input = Vector2.ZERO
	desired_facing = Vector3.FORWARD
	stats.reset_for_respawn(ConfigStore.player_tuning)
	_sync_visual_state(true)

func build_state_snapshot() -> Dictionary:
	return {
		"peer_id": peer_id,
		"name": display_name,
		"position": global_position,
		"velocity": velocity,
		"yaw": rotation.y,
		"health": stats.current_health,
		"max_health": stats.max_health,
		"alive": stats.alive,
		"growth": stats.growth_level,
		"kills": stats.kills,
		"deaths": stats.deaths,
		"respawn": stats.respawn_remaining,
		"cooldown": combat.cooldown_remaining,
		"swing_elapsed": combat.swing_elapsed,
		"swinging": combat.swinging,
		"hit_react": hit_react_remaining,
		"defeat_delay": defeat_delay_remaining,
		"pending_defeat": pending_defeat,
		"killer_id": stats.last_attacker_id
	}

func apply_state_snapshot(snapshot: Dictionary) -> void:
	display_name = snapshot.get("name", display_name)
	name_label.text = display_name
	stats.display_name = display_name
	stats.current_health = snapshot.get("health", stats.current_health)
	stats.max_health = snapshot.get("max_health", stats.max_health)
	stats.alive = snapshot.get("alive", stats.alive)
	stats.growth_level = snapshot.get("growth", stats.growth_level)
	stats.kills = snapshot.get("kills", stats.kills)
	stats.deaths = snapshot.get("deaths", stats.deaths)
	stats.respawn_remaining = snapshot.get("respawn", stats.respawn_remaining)
	stats.last_attacker_id = snapshot.get("killer_id", stats.last_attacker_id)
	combat.cooldown_remaining = snapshot.get("cooldown", combat.cooldown_remaining)
	combat.swing_elapsed = snapshot.get("swing_elapsed", combat.swing_elapsed)
	combat.swinging = snapshot.get("swinging", combat.swinging)
	hit_react_remaining = snapshot.get("hit_react", hit_react_remaining)
	defeat_delay_remaining = snapshot.get("defeat_delay", defeat_delay_remaining)
	pending_defeat = snapshot.get("pending_defeat", pending_defeat)
	var snapshot_yaw: float = snapshot.get("yaw", rotation.y)
	var direction: Vector3 = Vector3(sin(snapshot_yaw), 0.0, cos(snapshot_yaw))
	if direction.length_squared() > 0.0001:
		desired_facing = direction.normalized()
	network_state.apply_server_state(
		self,
		snapshot.get("position", global_position),
		snapshot_yaw,
		snapshot.get("velocity", velocity),
		is_local_player,
		ConfigStore.match_tuning.desync_snap_distance
	)
	_sync_visual_state(false)

func build_ui_state(killer_name: String = "") -> Dictionary:
	return {
		"name": display_name,
		"health": stats.current_health,
		"max_health": stats.max_health,
		"alive": stats.alive,
		"pending_defeat": pending_defeat,
		"kills": stats.kills,
		"deaths": stats.deaths,
		"growth": stats.growth_level,
		"respawn": stats.respawn_remaining,
		"killer_name": killer_name,
		"cooldown": combat.cooldown_remaining
	}

func _authoritative_tick(delta: float) -> void:
	if stats.alive:
		_simulate_movement(delta)
		_tick_hit_reaction(delta)
		return
	velocity = Vector3.ZERO
	if stats.tick_respawn(delta):
		respawn_requested.emit(peer_id)

func _prediction_tick(delta: float) -> void:
	if stats.alive:
		_simulate_movement(delta)
		_tick_hit_reaction(delta)
	else:
		velocity = Vector3.ZERO

func _simulate_movement(delta: float) -> void:
	var target_speed: float = growth.get_move_speed(stats, ConfigStore.player_tuning)
	var desired_velocity: Vector3 = MathUtils.planar_velocity_from_input(Vector2.ZERO if pending_defeat else desired_move_input, target_speed)
	move_velocity.x = move_toward(move_velocity.x, desired_velocity.x, ConfigStore.player_tuning.acceleration * delta)
	move_velocity.z = move_toward(move_velocity.z, desired_velocity.z, ConfigStore.player_tuning.acceleration * delta)
	external_impulse = external_impulse.move_toward(Vector3.ZERO, delta * ConfigStore.combat_tuning.knockback_decay)
	velocity = move_velocity + external_impulse
	move_and_slide()
	global_position = Vector3(
		clamp(global_position.x, -world_bounds.x, world_bounds.x),
		global_position.y,
		clamp(global_position.z, -world_bounds.y, world_bounds.y)
	)
	if desired_move_input.length_squared() > 0.0001:
		desired_facing = Vector3(desired_move_input.x, 0.0, desired_move_input.y).normalized()
	elif Vector2(move_velocity.x, move_velocity.z).length_squared() > 0.0001:
		desired_facing = Vector3(move_velocity.x, 0.0, move_velocity.z).normalized()
	rotation.y = lerp_angle(rotation.y, MathUtils.yaw_from_direction(desired_facing), clamp(delta * 12.0, 0.0, 1.0))

func _tick_hit_reaction(delta: float) -> void:
	hit_react_remaining = max(hit_react_remaining - delta, 0.0)
	if not pending_defeat:
		return
	defeat_delay_remaining = max(defeat_delay_remaining - delta, 0.0)
	if defeat_delay_remaining > 0.0:
		return
	pending_defeat = false
	stats.begin_respawn(ConfigStore.match_tuning.respawn_delay)
	velocity = Vector3.ZERO
	move_velocity = Vector3.ZERO
	external_impulse = Vector3.ZERO
	AudioService.play_elimination()
	_sync_visual_state(true)

func _sync_visual_state(_instant: bool) -> void:
	if name_label != null:
		name_label.text = _get_name_label_text()
	var growth_scale: float = growth.get_scale(stats, ConfigStore.player_tuning)
	if mesh_root != null:
		mesh_root.scale = Vector3.ONE * growth_scale
	if collision_shape != null:
		collision_shape.scale = Vector3.ONE * clamp(0.92 + (growth_scale - 1.0) * 0.65, 0.92, 1.6)
	if using_custom_model:
		body_mesh.visible = false
		head_mesh.visible = false
		bat_mesh.visible = false
	else:
		body_material.albedo_color = _get_body_color()
		head_material.albedo_color = _get_head_color()
		bat_material.albedo_color = _get_bat_color()
		body_mesh.visible = true
		head_mesh.visible = true
		bat_mesh.visible = true
	local_indicator_material.albedo_color = Color(0.24, 0.95, 0.78, 0.52)
	if mesh_root != null:
		mesh_root.visible = stats.alive
	if collision_shape != null:
		collision_shape.disabled = not stats.alive
	if name_label != null:
		name_label.modulate = Color(0.88, 1.0, 0.95) if is_local_player and stats.alive else (Color.WHITE if stats.alive else Color(1.0, 0.8, 0.8, 0.8))
	if local_indicator != null:
		local_indicator.visible = is_local_player and stats.alive
		local_indicator.scale = Vector3.ONE * _get_local_indicator_base_scale(growth_scale)
	if you_label != null:
		you_label.visible = is_local_player and stats.alive
		you_label.modulate = Color(0.5, 1.0, 0.88, 0.96)

func _update_visuals(delta: float) -> void:
	var attack_swing: float = sin(combat.get_animation_weight() * PI)
	var hit_react_weight: float = sin((1.0 - clampf(hit_react_remaining / maxf(ConfigStore.combat_tuning.hit_react_duration, 0.001), 0.0, 1.0)) * PI)
	if bat_pivot != null and not using_custom_model:
		bat_pivot.rotation.x = 0.35 + attack_swing * 0.55
		bat_pivot.rotation.y = -0.18 - attack_swing * 0.3
		bat_pivot.rotation.z = 0.85 - attack_swing * 1.45 + hit_react_weight * 0.16
	if body_pivot != null and stats.alive:
		var move_amount: float = clampf(Vector2(velocity.x, velocity.z).length() / maxf(ConfigStore.player_tuning.base_move_speed, 0.01), 0.0, 1.0)
		body_pivot.position.y = VISUAL_BASE_HEIGHT + sin(Time.get_ticks_msec() * 0.015) * 0.04 * move_amount + attack_swing * 0.03
		body_pivot.rotation.x = hit_react_weight * 0.24
		body_pivot.rotation.z = 0.0 if using_custom_model else (-attack_swing * 0.12 + hit_react_weight * 0.08)
	if model_anchor != null and not using_custom_model:
		model_anchor.rotation.y = attack_swing * 0.28
		model_anchor.rotation.x = hit_react_weight * 0.32
		model_anchor.rotation.z = -attack_swing * 0.1 + hit_react_weight * 0.05
	elif model_anchor != null:
		model_anchor.rotation.x = hit_react_weight * 0.32
		model_anchor.rotation.z = hit_react_weight * 0.05
	if local_indicator != null and local_indicator.visible:
		var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.01) * 0.06
		var target_scale := _get_local_indicator_base_scale(growth.get_scale(stats, ConfigStore.player_tuning)) * pulse
		local_indicator.scale = local_indicator.scale.lerp(Vector3.ONE * target_scale, clamp(delta * 8.0, 0.0, 1.0))
	rotation.y = lerp_angle(rotation.y, MathUtils.yaw_from_direction(desired_facing), clamp(delta * 10.0, 0.0, 1.0))

func _get_body_color() -> Color:
	var bonus := float(max(stats.growth_level - 1, 0)) * 0.04
	if not stats.alive:
		return Color(0.35, 0.35, 0.4)
	if is_local_player:
		return Color(0.19 + bonus, 0.78, 0.68)
	return Color(0.85, 0.49 + bonus, 0.28)

func _get_head_color() -> Color:
	if not stats.alive:
		return Color(0.45, 0.45, 0.5)
	return Color(0.97, 0.9, 0.75)

func _get_bat_color() -> Color:
	if not stats.alive:
		return Color(0.3, 0.28, 0.25)
	return Color(0.44, 0.27, 0.15)

func _get_name_label_text() -> String:
	return "%s  [YOU]" % display_name if is_local_player else display_name

func _get_local_indicator_base_scale(growth_scale: float) -> float:
	return clamp(0.95 + (growth_scale - 1.0) * 0.3, 0.95, 1.35)

func _attach_custom_model() -> void:
	if model_anchor == null or custom_model_root != null:
		return
	if CUSTOM_MODEL_SCENE == null:
		return
	var instance := CUSTOM_MODEL_SCENE.instantiate() as Node3D
	if instance == null:
		return
	instance.name = "ImportedModel"
	model_anchor.add_child(instance)
	_fit_custom_model(instance)
	custom_model_root = instance
	custom_animation_player = instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if custom_animation_player != null and custom_animation_player.has_animation("idle"):
		custom_animation_player.play("idle")
	using_custom_model = true

func _play_attack_feedback(play_audio: bool = true) -> void:
	if play_audio:
		AudioService.play_swing()
	if custom_animation_player != null and custom_animation_player.has_animation("attack"):
		custom_animation_player.play("attack")

func _apply_attack_lunge() -> void:
	var lunge_direction := desired_facing
	if lunge_direction.length_squared() <= 0.0001:
		lunge_direction = Vector3.FORWARD
	external_impulse = (external_impulse + lunge_direction.normalized() * ConfigStore.combat_tuning.get_lunge(stats.growth_level)).limit_length(ConfigStore.combat_tuning.max_received_knockback_speed)

func _fit_custom_model(instance: Node3D) -> void:
	var bounds := _get_custom_model_bounds(instance)
	if bounds.size.y <= 0.001:
		return
	var scale_factor := CUSTOM_MODEL_TARGET_HEIGHT / bounds.size.y
	instance.scale = Vector3.ONE * scale_factor
	bounds = _get_custom_model_bounds(instance)
	var center_x := bounds.position.x + bounds.size.x * 0.5
	var center_z := bounds.position.z + bounds.size.z * 0.5
	instance.position = Vector3(-center_x, -bounds.position.y, -center_z)

func _get_custom_model_bounds(root: Node3D) -> AABB:
	var mesh_instances: Array[MeshInstance3D] = []
	_collect_model_meshes(root, mesh_instances)
	var has_bounds := false
	var combined := AABB()
	var root_inverse := root.global_transform.affine_inverse()
	for mesh_instance in mesh_instances:
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var relative_transform := root_inverse * mesh_instance.global_transform
		for corner in _get_aabb_corners(mesh_instance.get_aabb()):
			var point := relative_transform * corner
			if not has_bounds:
				combined = AABB(point, Vector3.ZERO)
				has_bounds = true
			else:
				combined = combined.expand(point)
	return combined if has_bounds else AABB(Vector3.ZERO, Vector3.ZERO)

func _collect_model_meshes(node: Node, mesh_instances: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		mesh_instances.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_model_meshes(child, mesh_instances)

func _get_aabb_corners(bounds: AABB) -> PackedVector3Array:
	var min_point := bounds.position
	var max_point := bounds.position + bounds.size
	return PackedVector3Array([
		Vector3(min_point.x, min_point.y, min_point.z),
		Vector3(max_point.x, min_point.y, min_point.z),
		Vector3(min_point.x, max_point.y, min_point.z),
		Vector3(max_point.x, max_point.y, min_point.z),
		Vector3(min_point.x, min_point.y, max_point.z),
		Vector3(max_point.x, min_point.y, max_point.z),
		Vector3(min_point.x, max_point.y, max_point.z),
		Vector3(max_point.x, max_point.y, max_point.z)
	])
