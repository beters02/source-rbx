local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Types = require(script:WaitForChild("Types"))

local Movement: Types.Movement = {}
local Physics = require(script:WaitForChild("Physics"))
local Shared = require(script:WaitForChild("Shared"))
local Trace = require(script:WaitForChild("Trace"))

local function Init()
    Movement.Keys = {W = 0, S = 0, D = 0, A = 0, Space = 0}
    Movement.player = game.Players.LocalPlayer
    Movement.character = Movement.player.Character or Movement.player.CharacterAdded:Wait()
    Movement.collider = Movement.character:WaitForChild("HumanoidRootPart")
    Movement.vispart = false
    Movement.vis_coll_parts = {}
    Movement.config = require(script:WaitForChild("Config"))

    local mover = Instance.new("LinearVelocity", Movement.collider)
    local a0 = Instance.new("Attachment", Movement.collider)
    a0.Name = "MovementAttachment"
    mover.Attachment0 = a0
    mover.MaxForce = 10000000
    mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
    mover.PrimaryTangentAxis = Vector3.new(1,0,0)
    mover.SecondaryTangentAxis = Vector3.new(0,0,1)
    Movement.mover = mover

    -- Will figure this out soon.
    --[[local upMover = Instance.new("LinearVelocity", Movement.collider)
    upMover.Attachment0 = Movement.collider:WaitForChild("MovementAttachment")
    upMover.ForceLimitMode = Enum.ForceLimitMode.PerAxis
    upMover.ForceLimitsEnabled = true
    upMover.MaxAxesForce = Vector3.new(0, 100000, 0)
    upMover.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    Movement.up_mover = upMover]]

    Movement.states = {grounded = false, air_friction = 0, input_vec = Vector3.zero, surfing = false}
end

--

local function Gravity()
    local mod = Movement.config.GRAVITY * Movement.dt
    Movement.collider.Velocity = Vector3.new(
        Movement.collider.Velocity.X,
        Movement.collider.Velocity.Y - mod,
        Movement.collider.Velocity.Z
    )
end

local function Air()
    Physics.ApplyAirVelocity(Movement)
    local vel = Vector3.new(Movement.mover.PlaneVelocity.X, Movement.collider.Velocity.Y, Movement.mover.PlaneVelocity.Y)
    vel = Trace.Reflect(Movement, vel, Movement.collider.CFrame.Position)
    Movement.mover.PlaneVelocity = Vector2.new(vel.X, vel.Z)
    Movement.collider.Velocity = vel
end

local function Ground(groundNormal: Vector3)
    Physics.ApplyGroundVelocity(Movement, groundNormal)
end

local function Jump()
    Movement.temp_jump_last = tick()
    Movement.states.jumping = true
	Movement.collider.Velocity = Vector3.new(
        Movement.collider.Velocity.X,
        Movement.config.JUMP_VELOCITY,
        Movement.collider.Velocity.Z
    )
end

local function ProcessMovement()
    local isGrounded, isSurfing, result = Shared.IsGrounded(Movement)
    Movement.states.grounded = isGrounded or false
    Movement.states.surfing = isSurfing or false

    if Movement.collider.Velocity.Y < 0 then
        Movement.states.jumping = false
    end

    Shared.RotateCharacter(Movement)

    if Movement.states.jumping or not Movement.states.grounded then
        local groundNormal = false
        if isSurfing then
            groundNormal = result.Normal
            if Movement.collider.Velocity.Y > 0 then
                --Physics.ApplyFriction(Movement, false, true)
            end
        end

        Air(groundNormal)
        Gravity()
    elseif Movement.Keys.Space > 0 then
        Jump()
        Air()
    else
        Ground(result.Normal)
    end
end

--

local function InputBegan(input: InputObject, gp: boolean)
    if input.KeyCode and Movement.Keys[input.KeyCode.Name] then
        Movement.Keys[input.KeyCode.Name] = 1
    end
end

local function InputEnded(input: InputObject, gp: boolean)
    if input.KeyCode and Movement.Keys[input.KeyCode.Name] then
        Movement.Keys[input.KeyCode.Name] = 0
    end
end

local function Update(dt)
    Movement.dt = dt
    ProcessMovement()
end

Init()
UserInputService.InputBegan:Connect(InputBegan)
UserInputService.InputEnded:Connect(InputEnded)
RunService.RenderStepped:Connect(Update)