local Config = {

    --[[General]]
    VISUALIZE_FEET_HB = false, -- Visualize Feet Hitbox
    VISUALIZE_COLLIDE_AND_SLIDE = false,
    STEP_OFFSET = 1.3,
    MASS = 16,
    FRICTION = 6,
    GRAVITY = 0.6,
    JUMP_VELOCITY = 25,

    --[[Accel/Deccel]]
    GROUND_ACCEL = 12,
    GROUND_DECCEL = 10,
    AIR_ACCEL = 52,

    --[[General Speed]]
    AIR_SPEED = 6,
    RUN_SPEED = 24,
    WALK_SPEED = 12,
    CROUCH_SPEED = 12,

    --[[Advanced Speed]]
    AIR_MAX_SPEED = 36.5,        -- The speed at which AIR_MAX_SPEED_FRIC is applied.
	AIR_MAX_SPEED_FRIC = 3,      -- The initial friction applied at max speed
	AIR_MAX_SPEED_FRIC_DEC = .5, -- Amount multiplied to current max speed friction per 1/60sec

    --[[Misc (Don't worry about these)]]
    LEG_HEIGHT = 1.9,
    TORSO_TO_FEET = 3.1,
    FEET_HB_SIZE = Vector3.new(2,2,2),
    TORSO_HB_SIZE = Vector3.new(3,1,3),
    
}

return Config