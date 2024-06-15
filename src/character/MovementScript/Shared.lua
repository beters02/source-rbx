local Types = require(script.Parent:WaitForChild("Types"))
local Shared: Types.Movement = {}

local function HandleVisualization(self, cf, size)
    if not self.config.VISUALIZE_FEET_HB then
        return
    end
    if not self.vispart then
        self.vispart = Instance.new("Part", self.character)
        self.vispart.CanCollide = false
        self.vispart.Anchored = true
    end
    
    self.vispart.CFrame = cf
    self.vispart.Size = size
end

function Shared.GetAngle(normal)
    return math.deg(math.acos(normal:Dot(Vector3.yAxis)))
end

function Shared:IsGrounded(dir): (boolean, boolean?, RaycastResult?, number?)
    local params = Shared.GetMovementParams(self)
    local cf = CFrame.new(self.collider.Position) - Vector3.new(0, self.collider.Size.Y/2, 0)
    local size = self.config.FEET_HB_SIZE
    dir = dir or Vector3.new(0,-1 * self.collider.Size.Y-self.config.FOOT_OFFSET_AMOUNT,0)

    local result = workspace:Blockcast(cf, size, dir, params)

    HandleVisualization(self, cf, size)
    
    if not result then
        return false
    end

    local steepness = Shared.GetAngle(result.Normal)
    local isSurfing = steepness >= self.config.MIN_SLOPE_ANGLE and steepness <= self.config.MAX_SLOPE_ANGLE
    if isSurfing then
        return false, true, result, steepness
    end

    return true, false, result
end

function Shared:RotateCharacter()
    local collider = self.collider
	local camera = workspace.CurrentCamera
	local rotationLook = collider.Position + camera.CoordinateFrame.lookVector
	collider.CFrame = CFrame.new(collider.Position, Vector3.new(rotationLook.x, collider.Position.y, rotationLook.z))
	collider.RotVelocity = Vector3.new()
end

function Shared:GetMovementDirection(groundNormal)
    local forward = self.Keys.W + -self.Keys.S
    local side = self.Keys.A + -self.Keys.D
    groundNormal = groundNormal or Vector3.new(0,1,0)

    if forward == 0 and side == 0 then
        self.states.input_vec = Vector3.zero
        return Vector3.zero
    end

    self.states.input_vec = Vector3.new(-side, 0, -forward).Unit

    local forwardMove = groundNormal:Cross(self.collider.CFrame.RightVector)
    local sideMove = groundNormal:Cross(forwardMove)
    return (forwardMove * forward + sideMove * side).Unit
end

function Shared:GetMovementParams()
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {self.character, workspace.CurrentCamera}
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.RespectCanCollide = false
    params.CollisionGroup = "PlayerMovement"
    return params
end

function Shared:VectorMa(start: Vector3, scale: number, direction: Vector3)
    return Vector3.new(
        start.X + direction.X * scale,
        start.Y + direction.Y * scale,
        start.Z + direction.Z * scale
    )
end

return Shared