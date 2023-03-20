extends CharacterBody2D


const SPEED: int = 60
const JUMP_VELOCITY: int = -70
const LADDER_SPEED: int = 20
var connected_to_ladder: bool = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	
	# check if player is dead, and play dead animation as well as restart
	# the level in case of death
	if check_dead():
		if not $Audio/SfxDeath.is_playing(): $Audio/SfxDeath.play()
		get_parent().hide_all_game_objects()
		set_process(false)
		set_process(true)
		GlobalData.lives -= 1
		get_parent().get_tree().reload_current_scene()
	
	# Add the gravity.
	floor_snap_length = 2.0
	if not is_on_floor() and not connected_to_ladder:
		velocity.y += gravity * delta
	elif connected_to_ladder:
		velocity = Vector2.ZERO 
	movement()
	


func handle_climb_platform() -> void:
	# handle ascending platform climbing
	
	var raycast: RayCast2D = null
	if velocity.x > 0:
		raycast = $RayCastRight
	elif velocity.x < 0:
		raycast = $RayCastLeft
	else:
		return
	
	raycast.force_raycast_update()
	var collider: Object = raycast.get_collider()
	if collider != null and collider.name.begins_with("Platform"):
		position.y -= 1
		
func handle_climb_ladder() -> void:
	# handle climbing up and down a ladder
	
	var raycast: RayCast2D = null

	# if Input.is_action_pressed("jump"):
	raycast = $RayCastUp
	#elif Input.is_action_pressed("down"):
	#	raycast = $RayCastDown
	#else:
	#	return
	
	raycast.force_raycast_update()
	var collider: Object = raycast.get_collider()
	if collider == null:
		return
	$test.text = collider.name

	# action, when already conntected to a ladder
	if connected_to_ladder:		
		
#		# stop climbing ladder (down) and go to ground
		if velocity.y > 0 and collider.name.begins_with("Platform"):
			connected_to_ladder = false 
			raycast.collide_with_bodies = false
			return
		
		# fall if climbing down edge of broken ladder
		if velocity.y > 0 and collider.name.begins_with("LadderGap"):
			connected_to_ladder = false 
			raycast.collide_with_bodies = false
			return
		
#		# stop climbing ladder (up) and go to next level platform
		if velocity.y < 0:
			while collider != null:
				# multiple raycast checks
				if collider.name.begins_with("Platform"):
					$RayCastDown.collide_with_bodies = false
				if collider.name.begins_with("LadderGap"):
					velocity.y = 0
					
				raycast.add_exception(collider)
				raycast.force_raycast_update()
				collider = raycast.get_collider()
			
			raycast.clear_exceptions()
			return

	# actions, when not conntected to a ladder	
	else:
		# check if Player can be connected to a ladder	
		if not is_on_floor():
			return
			
		if Input.is_action_pressed("jump") and collider.name.begins_with("Ladder"):
			connected_to_ladder = true
			$RayCastDown.collide_with_bodies = true
			return

		if Input.is_action_pressed("down") and collider.name.begins_with("Ladder"):
			position.y += 9
			$Sprite2D.frame = 6
			connected_to_ladder = true
			$RayCastDown.collide_with_bodies = true

func movement():
		
	if connected_to_ladder:
		if Input.is_action_pressed("jump"):
			velocity.y = -1 * LADDER_SPEED
		if Input.is_action_pressed("down"):
			velocity.y = 1 * LADDER_SPEED
	else:
		# Handle Jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
		var direction = Input.get_axis("left", "right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	handle_climb_platform()
	handle_climb_ladder()
	move_and_slide()

func check_dead() -> bool:
	# check if the player hit a fatal game object
	
	for body in $PlayerHitBox.get_overlapping_bodies():
		if "FireElemental" in body.name or "Barrel" in body.name:
			return true
	return false
