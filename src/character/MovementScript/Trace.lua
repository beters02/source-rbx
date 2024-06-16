export type Trace = {
    startPos: Vector3,
    endPos: Vector3,


    fraction: number,
    startSolid: boolean,
    hitPart: Instance,
    hitPoint: Vector3,
    planeNormal: Vector3,
    distance: number
}

local Types = require(script.Parent:WaitForChild("Types"))
local Shared = require(script.Parent:WaitForChild("Shared"))
local Trace: Types.Movement = {}

local numBumps = 1
local maxClipPlanes = 5
local _planes = {}

local numToCoord = {"X", "Y", "Z"}

local function ClipVelocity(self, input, normal, output, overbounce)
    local newVelMod = Types.Vec3Mod.new(output)
    Trace.ClipVelocity(self, input, normal, newVelMod, overbounce)
    return newVelMod:ToVector3()
end

function Trace:TraceBox(start: Vector3, destination: Vector3)
    local contactOffset = 0.1 -- idk what this is

    local longSide = math.sqrt(contactOffset * contactOffset + contactOffset * contactOffset)
    local direction = (destination - start).Unit
    local maxDistance = (start - destination).Magnitude + longSide

    local result: Trace = {
        startPos = start,
        endPos = destination
    }

    local _, _, hit = Shared.IsGrounded(self, direction*maxDistance)
    if hit then
        result.fraction = hit.Distance / maxDistance
        result.hitPart = hit.Instance
        result.hitPoint = hit.Position
        result.planeNormal = hit.Normal
        result.distance = hit.Distance
    else
        result.fraction = 1
    end

    return result
end

function Trace:ClipVelocity(input: Vector3, normal: Vector3, output: Types.Vec3Mod, overbounce: number)
    local angle = normal.Y
    local blocked = 0x00     -- // Assume unblocked.

    if angle > 0 then -- // If the plane that is blocking us has a positive z component, then assume it's a floor.
        blocked = blocked or 0x01
    end

    if angle == 0 then -- // If the plane has no Z, it is vertical (wall/step)
        blocked = blocked or 0x02
    end

    -- // Determine how far along plane to slide based on incoming direction.
    local backoff = input:Dot(normal) * overbounce

    --// iterate once to make sure we aren't still moving through the plane
    for i = 1, 3, 1 do
        local ci = numToCoord[i]
        local change = normal[ci] * backoff
        output[ci] = input[ci] - change
    end

    local adjust = output:ToVector3():Dot(normal)
    if adjust < 0 then
        output = output:ToVector3()-(normal * adjust)
    end

    -- Return blocking flags.
    return blocked
end

function Trace:Reflect(velocity: Vector3, origin: Vector3)

    self = self :: Types.Movement

    local d
    local newVelocity = Vector3.zero
    local blocked = 0
    local numplanes = 1
    local originalVelocity = velocity
    local primalVelocity = velocity

    local allFraction = 0
    local timeLeft = self.dt

    for bumpcount = 1, numBumps, 1 do

        if velocity.Magnitude == 0 then
            break
        end

        -- Assume we can move all the way from the current origin to the
        --  end point.
        local endp = Shared.VectorMa(self, origin, timeLeft, velocity)
        local trace = Trace.TraceBox(self, origin, endp)
        allFraction += trace.fraction

        if trace.fraction > 0 then
            -- actually covered some distance
            originalVelocity = velocity
            numplanes = 0
        end

        -- If we covered the entire distance, we are done
                --  and can return.
        if trace.fraction == 1 then
            break
        end -- moved the entire distance

        -- If the plane we hit has a high z component in the normal, then
        --  it's probably a floor
        if trace.planeNormal.Y > self.config.MAX_SLOPE_ANGLE then
            blocked = blocked or 1
        end

        -- If the plane has a zero z component in the normal, then it's a
        --  step or wall
        if trace.planeNormal.Y == 0 then
            blocked = blocked or 2 -- step/wall
        end

        -- Reduce amount of m_flFrameTime left by total time left * fraction
        --  that we covered.
        timeLeft -= timeLeft * trace.fraction

    
        -- Did we run out of planes to clip against?
        if numplanes >= maxClipPlanes then
            -- this shouldn't really happen
            --  Stop our movement if so.
            velocity = Vector3.zero
            break
        end

        -- Set up next clipping plane
        _planes[numplanes] = trace.planeNormal
        numplanes+=1

        -- modify original_velocity so it parallels all of the clip planes
        --

        -- reflect player velocity
        -- Only give this a try for first impact plane because you can get yourself stuck in an acute corner by jumping in place
        --  and pressing forward and nobody was really using this bounce/reflection feature anyway...
        if numplanes == 2 then
            if _planes[1].Y > self.config.MAX_SLOPE_ANGLE then
                return blocked
            else
                newVelocity = ClipVelocity(self, originalVelocity, _planes[1], newVelocity, 1)
            end
            velocity = newVelocity
            originalVelocity = newVelocity
        else
            local _i = 0
            for i = 1, numplanes-1, 1 do
                _i = i

                newVelocity = ClipVelocity(self, originalVelocity, _planes[i], newVelocity, 1)

                local _j = 0
                for j = 1, numplanes-1, 1 do
                    _j = j
                    if j ~= i and velocity:Dot(_planes[j]) < 0 then
                        break
                    end
                end

                if _j == numplanes then
                    break
                end
            end

            if _i ~= numplanes then
                
            else
                if numplanes ~= 3 then
                    velocity = Vector3.zero
                    break
                end
    
                local dir = _planes[1]:Cross(_planes[2]).Unit
                d = dir:Dot(velocity)
                velocity = dir * d
            end
        end

        d = velocity:Dot(primalVelocity)
        if d <= 0 then
            velocity = Vector3.zero
            break
        end

    end

    if allFraction == 0 then
        velocity = Vector3.zero
    end

    return velocity, blocked
end

return Trace