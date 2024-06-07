local Types = require(script.Parent:WaitForChild("Types"))
local Shared = require(script.Parent:WaitForChild("Shared"))
local Collisions = require(script.Parent:WaitForChild("Collisions"))
local Physics = {} :: Types.Movement

function Physics:ApplyGroundVelocity(groundNormal: Vector3)
    local wishDir = Shared.GetMovementDirection(self, groundNormal)
    local wishSpeed = wishDir.Magnitude * self.config.RUN_SPEED

    -- normal friction
    if self.states.air_friction <= 0 then
        Physics.ApplyFriction(self)
    else
		-- friction that is applied due to the player reaching max speed while bhopping
        local sub = self.config.AIR_MAX_SPEED_FRIC_DEC * self.dt * 60
		local curr = self.states.air_friction
		local fric = curr - sub
		if fric < 0 then
			fric = curr + fric
		end

		Physics.ApplyFriction(self, math.max(1, fric/self.config.FRICTION))
		self.states.air_friction = math.max(0, curr - sub)
    end

    Physics.ApplyGroundAcceleration(self, wishDir, wishSpeed)
	Collisions.CollideAndSlide(self, Vector3.new(self.mover.PlaneVelocity.X, 0, self.mover.PlaneVelocity.Y))
end

function Physics:ApplyGroundAcceleration(wishDir: Vector3, wishSpeed: number)
    local addSpeed
	local accelerationSpeed
	local currentSpeed
	local currentVelocity = Vector3.new(self.mover.PlaneVelocity.X, 0, self.mover.PlaneVelocity.Y)
	local newVelocity = currentVelocity
	
	-- get current/add speed
	currentSpeed = currentVelocity:Dot(wishDir)
	addSpeed = wishSpeed - currentSpeed

	-- if we're not adding speed, dont do anything
	if addSpeed <= 0 then return end
	
	-- get accelSpeed, cap at addSpeed
	accelerationSpeed = math.min(self.config.GROUND_ACCEL * self.dt * wishSpeed, addSpeed)
	
	-- you can't change the properties of a Vector3, so we do x, y, z
	newVelocity += (accelerationSpeed * wishDir)
	--newVelocity = Vector3.new(newVelocity.X, self.sliding and newVelocity.Y or 0, newVelocity.Z)
    newVelocity = Vector3.new(newVelocity.X,  0, newVelocity.Z)

	-- clamp magnitude (max speed)
	if newVelocity.Magnitude > (self.config.RUN_SPEED --[[self.equippedWeaponPenalty]]) then
		newVelocity = newVelocity.Unit * math.min(newVelocity.Magnitude, (self.config.RUN_SPEED))
	end

	-- apply acceleration
    self.mover.PlaneVelocity = Vector2.new(newVelocity.X, newVelocity.Z)
end

function Physics:ApplyAirVelocity()
	local vel = Vector3.new(self.mover.PlaneVelocity.X, 0, self.mover.PlaneVelocity.Y)
    local wishDir = Shared.GetMovementDirection(self, Vector3.new(0,1,0))
    local wishSpeed = wishDir.Magnitude * self.config.AIR_SPEED
    local currSpeed = vel.Magnitude

	-- initiate extra friction for max speed
	if currSpeed > self.config.AIR_MAX_SPEED then
		self.states.air_friction = self.config.AIR_MAX_SPEED_FRIC
	end

	-- apply extra friction if necessary
    if self.states.air_friction > 0 then
		Physics.ApplyFriction(self, 0.01 * self.states.air_friction)
	end
	
	Physics.ApplyAirAcceleration(self, wishDir, wishSpeed)
	Collisions.CollideAndSlide(self, Vector3.new(self.mover.PlaneVelocity.X, self.collider.Velocity.Y, self.mover.PlaneVelocity.Y))
end

function Physics:ApplyAirAcceleration(wishDir: Vector3, wishSpeed: number)
    local currentSpeed
	local addSpeed
	local accelerationSpeed
    local currentVelocity = Vector3.new(self.mover.PlaneVelocity.X, 0, self.mover.PlaneVelocity.Y)

	-- get current/add speed
	currentSpeed = currentVelocity:Dot(wishDir)
	addSpeed = wishSpeed - currentSpeed

	-- if we're not adding speed, dont do anything
	if addSpeed <= 0 then return end

	-- get accelSpeed, cap at addSpeed
	accelerationSpeed = math.min(self.config.AIR_ACCEL * self.dt * wishSpeed, addSpeed)

	-- get new velocity
	local newVelocity = currentVelocity + accelerationSpeed * wishDir

	-- apply acceleration
	self.mover.PlaneVelocity = Vector2.new(newVelocity.X, newVelocity.Z)
end

function Physics:ApplyFriction(modifier: number?)
    local vel = Vector3.new(self.mover.PlaneVelocity.X, 0, self.mover.PlaneVelocity.Y)
	local speed = vel.Magnitude
    modifier = modifier or 1
	
	-- if we're not moving, don't apply friction
	if speed <= 0 then
		return vel
	end

	local drop = 0
	local fric = self.config.FRICTION
    local decel = self.config.GROUND_DECCEL
	local newSpeed
	local control
	
	-- ???
	control = speed < decel and decel or speed
	drop = control * fric * self.dt * modifier
	if type(drop) ~= "number" then drop = drop.Magnitude end

	-- ????????????
	newSpeed = math.max(speed - drop, 0)
	if speed > 0 and newSpeed > 0 then
		newSpeed /= speed
	end

    vel *= newSpeed
    self.mover.PlaneVelocity = Vector2.new(vel.X, vel.Z)
end

return Physics