local Config = {

    --[[General]]
    VISUALIZE_FEET_HB = false, -- Visualize Feet Hitbox
    VISUALIZE_COLLIDE_AND_SLIDE = false,
    STEP_OFFSET = 1.2,
    MASS = 16,
    AIR_FRICTION = 0.4,
    FRICTION = 6,
    GRAVITY = 20,
    JUMP_VELOCITY = 50,

    --[[Accel/Deccel]]
    GROUND_ACCEL = 14,
    GROUND_DECCEL = 10,
    AIR_ACCEL = 52,

    --[[General Speed]]
    AIR_SPEED = 6,
    RUN_SPEED = 22,
    WALK_SPEED = 12,
    CROUCH_SPEED = 12,

    --[[Advanced Speed]]
    AIR_MAX_SPEED = 36.5,        -- The speed at which AIR_MAX_SPEED_FRIC is applied.
	AIR_MAX_SPEED_FRIC = 3,      -- The initial friction applied at max speed
	AIR_MAX_SPEED_FRIC_DEC = .5, -- Amount multiplied to current max speed friction per 1/60sec
    MIN_SLOPE_ANGLE = 40,
    MAX_SLOPE_ANGLE = 75,

    --[[Misc (Don't worry about these)]]
    LEG_HEIGHT = 1.9+.3,
    TORSO_TO_FEET = 3.1+1.9,
    FEET_HB_SIZE = Vector3.new(1,0.1,1),
    TORSO_HB_SIZE = Vector3.new(3,1,3),
    FOOT_OFFSET_AMOUNT = 1.2
}

return Config