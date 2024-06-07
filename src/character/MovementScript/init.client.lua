local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Types = require(script:WaitForChild("Types"))

local Movement: Types.Movement = {}
local Physics = require(script:WaitForChild("Physics"))
local Shared = require(script:WaitForChild("Shared"))

local function Init()
    Movement.Keys = {W = 0, S = 0, D = 0, A = 0, Space = 0}
    Movement.player = game.Players.LocalPlayer
    Movement.character = Movement.player.Character or Movement.player.CharacterAdded:Wait()
    Movement.collider = Movement.character:WaitForChild("HumanoidRootPart")
    Movement.vispart = false
    Movement.vis_coll_parts = {}
    Movement.config = require(script:WaitForChild("Config"))

    local mover = Instance.new("LinearVelocity", Movement.collider)
    mover.Attachment0 = Instance.new("Attachment", Movement.collider)
    mover.MaxForce = 10000000
    mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
    mover.PrimaryTangentAxis = Vector3.new(1,0,0)
    mover.SecondaryTangentAxis = Vector3.new(0,0,1)
    Movement.mover = mover

    Movement.gravity_mover = Instance.new("BodyForce", Movement.collider)
    Movement.gravity_mover.Force = Vector3.new(0, (1-Movement.config.GRAVITY)*196.2, 0) * Movement.config.MASS

    Movement.states = {grounded = false, air_friction = 0, input_vec = Vector3.zero}
end

--

local function Air()
    Physics.ApplyAirVelocity(Movement)
end

local function Ground(groundNormal: Vector3)
    Physics.ApplyGroundVelocity(Movement, groundNormal)
end

local function Jump()
	Movement.collider.Velocity = Vector3.new(
        Movement.collider.Velocity.X,
        Movement.config.JUMP_VELOCITY,
        Movement.collider.Velocity.Z
    )
end

local function ProcessMovement()
    local res = Shared.IsGrounded(Movement)
    local norm = res and res.Normal
    Movement.states.grounded = norm and true

    Shared.RotateCharacter(Movement)

    if not Movement.states.grounded then
        Air()
    elseif Movement.Keys.Space > 0 then
        Jump()
        Air()
    else
        Ground(norm)
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