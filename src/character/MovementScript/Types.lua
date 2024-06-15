export type Movement = {
    Keys: {W: number, A: number, S: number, D: number, Space: number},

    player: Player,
    character: Model,
    collider: Part,
    vispart: Part?,
    vis_coll_parts: {Part},
    config: MovementConfig,
    mover: LinearVelocity,
    up_mover: LinearVelocity,
    dt: number,
    states: MovementStates,
}

export type MovementConfig = {
    VISUALIZE_FEET_HB: boolean,
    VISUALIZE_COLLIDE_AND_SLIDE: boolean,
    LEG_HEIGHT: number,
    FEET_HB_SIZE: Vector3,
    TORSO_HB_SIZE: Vector3,

    MASS: number,
    GRAVITY: number,
    FRICTION: number,

    GROUND_ACCEL: number,
    GROUND_DECCEL: number,
    AIR_ACCEL: number,

    RUN_SPEED: number,
    WALK_SPEED: number,
    CROUCH_SPEED: number,
    AIR_SPEED: number,

    AIR_MAX_SPEED: number,
	AIR_MAX_SPEED_FRIC: number,
	AIR_MAX_SPEED_FRIC_DEC: number,

    JUMP_VELOCITY: number,

    STEP_OFFSET: number,
    TORSO_TO_FEET: number,

    MAX_SLOPE_ANGLE: number,
}

export type MovementStates = {
    grounded: boolean,
    air_friction: number,
    input_vec: number,
    surfing: boolean
}

return nil