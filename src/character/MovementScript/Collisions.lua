local Types = require(script.Parent:WaitForChild("Types"))
local Shared = require(script.Parent:WaitForChild("Shared"))
local Collisions = {} :: Types.Movement

local function visualizeRayResult(result: RaycastResult, origin: Vector3, direction: Vector3)
	local position = result and result.Position or (origin + direction)
	local distance = (origin - position).Magnitude
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Size = Vector3.new(0.1, 0.1, distance)
	p.CFrame = CFrame.lookAt(origin, position)*CFrame.new(0, 0, -distance/2)
	p.Parent = workspace.Temp
	return p
end

local function flattenVectorAgainstWall(moveVector: Vector3, normal: Vector3)
	-- if magnitudes are 0 then just nevermind
	if moveVector.Magnitude == 0 and normal.Magnitude == 0 then
		return Vector3.zero
	end
	
	-- unit the normal (i its already normalized idk)
	normal = normal.Unit
	
	-- reflect the vector
	local reflected = moveVector - 2 * moveVector:Dot(normal) * normal
	-- add the reflection to the move vector = vector parallel to wall
	local parallel = moveVector + reflected
	
	-- if magnitude 0 NEVERMIND!!!
	if parallel.Magnitude == 0 then
		return Vector3.zero
	end
	
	-- reduce the parallel vector to make sense idk HorseNuggetsXD did all this thank u
	local cropped = parallel.Unit:Dot(moveVector.Unit) * parallel.Unit * moveVector.Magnitude
	return cropped
end

function Collisions:CollideAndSlide(wishedSpeed: Vector3)
	local mod = 1

	if wishedSpeed.Magnitude == 0 then
		return wishedSpeed
	end

	-- get input vector
	local inputVec = self.states.input_vec
	local newSpeed = wishedSpeed
	local hrp = self.player.Character.HumanoidRootPart

	-- raycast var
	local params = Shared.GetMovementParams(self)

	-- wished speed modifier
	wishedSpeed *= 2

	-- direction amount var
	local dirAmnt = 1.375 * (mod or 1)
	local mainDirAmnt = 1.55 * (mod or 1)

	-- stick var
	local isSticking = false
	local normals = {}
	local stickingDirections = {}
	local ldd = {dir = false, dist = false} -- lowest distance direction
	local partsAlreadyHit = {}

	-- destroy sticking visualizations
	if self.config.VISUALIZE_COLLIDE_AND_SLIDE then
		for _, v in pairs(self.vis_coll_parts) do
			v:Destroy()
		end
	end

	local lookVecs = {
		Vector3.new(0, (-self.config.TORSO_TO_FEET) + self.config.STEP_OFFSET, 0),
		Vector3.new(0, 0, 0),
		Vector3.new(0, 2, 0)
	}

	for _, v in pairs(lookVecs) do
		local values = {}
		local hval = {}
		local currForDir
		local currSideDir
		local rayPos

		if typeof(v) == "Vector3" then
			rayPos = hrp.Position + v
		else
			rayPos = Vector3.new(hrp.Position.X, hrp.Parent[v].CFrame.Position, hrp.Position.Z)
		end

		-- right, front, back
		if inputVec.X > 0 then
			currForDir = hrp.CFrame.RightVector
			table.insert(values, currForDir)
			table.insert(hval, hrp.CFrame.LookVector * dirAmnt)
			table.insert(hval, -hrp.CFrame.LookVector * dirAmnt)
		-- left, front, back
		elseif inputVec.X < 0 then
			currForDir = -hrp.CFrame.RightVector
			table.insert(values, currForDir)
			table.insert(hval, hrp.CFrame.LookVector * dirAmnt)
			table.insert(hval, -hrp.CFrame.LookVector * dirAmnt)
		end
		
		-- back, left, right
		if inputVec.Z > 0 then
			currSideDir = -hrp.CFrame.LookVector
			table.insert(values, currSideDir)
			table.insert(hval, hrp.CFrame.RightVector * dirAmnt)
			table.insert(hval, -hrp.CFrame.RightVector * dirAmnt)
		-- front, left, right
		elseif inputVec.Z < 0 then
			currSideDir = hrp.CFrame.LookVector
			table.insert(values, currSideDir)
			table.insert(hval, hrp.CFrame.RightVector * dirAmnt)
			table.insert(hval, -hrp.CFrame.RightVector * dirAmnt)
		end


		if inputVec.Z == 0 and inputVec.X == 0 then
			values[1] = wishedSpeed.Unit
			table.insert(hval, CFrame.new(wishedSpeed.Unit).RightVector * dirAmnt)
			table.insert(hval, -CFrame.new(wishedSpeed.Unit).RightVector * dirAmnt)
		else
			table.insert(values, wishedSpeed.Unit * dirAmnt)
		end
		
		-- middle directions
		if currForDir and currSideDir then
			for a, b in pairs(values) do
				values[a] = b * mainDirAmnt
			end
			table.insert(values, (currForDir+currSideDir) * mainDirAmnt)
		else
			values[1] *= mainDirAmnt
			table.insert(values, (values[1] + hval[1]).Unit * mainDirAmnt)
			table.insert(values, (values[1] + hval[2]).Unit * mainDirAmnt)
			table.insert(values, hval[1])
			table.insert(values, hval[2])
		end

		for _, b in pairs(values) do
			if not b then continue end

			-- visualize ray using pos and direction
			if self.config.VISUALIZE_COLLIDE_AND_SLIDE then
                table.insert(self.vis_coll_parts, visualizeRayResult(false, rayPos, b))
            end
			
			local result = workspace:Raycast(rayPos, b, params)
			if not result then continue end

			if (not ldd.dir or not ldd.dist) or (ldd.dist and ldd.dist < result.Distance) then
				ldd.dir = b
				ldd.dist = result.Distance
			end

			-- don't collide with the same part twice
			if table.find(partsAlreadyHit, result.Instance) then continue end
			table.insert(partsAlreadyHit, result.Instance)

			-- get the movement direction compared to the wall
			local _v =  newSpeed.Unit * result.Normal
			
			-- find active coordinate of comparison
			for _, c in pairs({_v.X, _v.Y, _v.Z}) do
				if math.abs(c) > 0 then
					_v = c
					break
				end
			end

			-- if we are moving AWAY from the normal, (positive)
			-- then do not flatten the vector.

			-- it's not necessary.
			-- you will stick.
			-- stick.

			if type(_v) == "number" and _v > 0 then
				continue
			end

			if not isSticking then isSticking = true end
			newSpeed = flattenVectorAgainstWall(newSpeed, result.Normal)
			newSpeed -= result.Instance.Velocity

            self.mover.PlaneVelocity = Vector2.new(newSpeed.X, newSpeed.Z)
			self.collider.Velocity = Vector3.new(newSpeed.X, (self.collider.Velocity.Y), newSpeed.Z) -- anti sticking has to be applied on collider velocity as well (resolves head & in air collision)
		end
	end

	return newSpeed, isSticking and normals, isSticking and stickingDirections, isSticking and ldd.dir
end

return Collisions