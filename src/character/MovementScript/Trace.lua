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

function Trace:TraceBox(start: Vector3, destination: Vector3)
    local contactOffset = 1.1 -- idk what this is

    local longSide = math.sqrt(contactOffset * contactOffset + contactOffset * contactOffset)
    local direction = (destination - start).normalized
    local maxDistance = Vector3.new(start+longSide, destination).Magnitude+longSide

    local result: Trace = {
        startPos = start,
        endPos = destination
    }

    local hit = Shared:FootCast(direction*maxDistance)
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

function Trace:ClipVelocity(input: Vector3, normal: Vector3, output: Vector3, overbounce: number)
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

    local adjust = output:Dot(normal)
    if adjust < 0 then
        output -= (normal * adjust)
    end

    -- Return blocking flags.
    return blocked;
end

function Trace:Reflect(velocity: Vector3, origin: Vector3)

    self = self :: Types.Movement

    local d
    local newVelocity = Vector3.zero
    local blocked = 0
    local numplanes = 0
    local originalVelocity = velocity
    local primalVelocity = velocity

    local allFraction = 0
    local timeLeft = self.dt

    for bumpcount = 1, numBumps+1, 1 do

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
        timeLeft -= timeLeft * trace.fraction;

    
        -- Did we run out of planes to clip against?
        if numplanes >= maxClipPlanes then
            -- this shouldn't really happen
            --  Stop our movement if so.
            velocity = Vector3.zero;
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
        if numplanes == 1 then
            for i = 1, numplanes + 1, 1 do
                if _planes[i].Y > self.config.MAX_SLOPE_ANGLE then
                    return blocked
                else
                    Trace.ClipVelocity(self, originalVelocity, _planes[i], newVelocity, 1)
                end
            end
            velocity = newVelocity;
            originalVelocity = newVelocity;
        else
            for i = 1, numplanes + 1, 1 do
                Trace.ClipVelocity(self, originalVelocity, _planes[i], newVelocity, 1)
                for j = 1, numplanes + 1, 1 do
                    if j ~= 1 and velocity:Dot(_planes[j]) < 0 then
                        break
                    end
                    if j == numplanes then
                        break
                    end
                end

                -- Did we go all the way through plane set
                if i ~= numplanes then
                    
                else
                    if numplanes ~= 2 then
                        -- velocity = vector3.zero
                        break
                    end

                    local dir = _planes[1]:Cross(_planes[2].Unit)
                    d = dir:Dot(velocity)
                    
                end

            end

            d = velocity:Dot(primalVelocity)
            if d < 0 then
                -- velocity = zero
                break
            end

            if allFraction == 0 then
                velocity = Vector3.zero;
            end
        end
    end
end

--[[
--/ <summary>
        public static int Reflect (ref Vector3 velocity, Collider collider, Vector3 origin, float deltaTime) {

            float d;
            var newVelocity = Vector3.zero;
            var blocked = 0;           -- Assume not blocked
            var numplanes = 0;           --  and not sliding along any planes
            var originalVelocity = velocity;  -- Store original velocity
            var primalVelocity = velocity;

            var allFraction = 0f;
            var timeLeft = deltaTime;   -- Total time for this movement operation.

            for (int bumpcount = 0; bumpcount < numBumps; bumpcount++) {

                if (velocity.magnitude == 0f)
                    break;

                -- Assume we can move all the way from the current origin to the
                --  end point.
                var end = VectorExtensions.VectorMa (origin, timeLeft, velocity);
                var trace = Tracer.TraceCollider (collider, origin, end, groundLayerMask);

                allFraction += trace.fraction;

                if (trace.fraction > 0) {

                    -- actually covered some distance
                    originalVelocity = velocity;
                    numplanes = 0;

                }

                -- If we covered the entire distance, we are done
                --  and can return.
                if (trace.fraction == 1)
                    break;      -- moved the entire distance

                -- If the plane we hit has a high z component in the normal, then
                --  it's probably a floor
                if (trace.planeNormal.y > SurfSlope)
                    blocked |= 1;       -- floor

                -- If the plane has a zero z component in the normal, then it's a 
                --  step or wall
                if (trace.planeNormal.y == 0)
                    blocked |= 2;       -- step / wall

                -- Reduce amount of m_flFrameTime left by total time left * fraction
                --  that we covered.
                timeLeft -= timeLeft * trace.fraction;

                -- Did we run out of planes to clip against?
                if (numplanes >= maxClipPlanes) {

                    -- this shouldn't really happen
                    --  Stop our movement if so.
                    velocity = Vector3.zero;
                    --Con_DPrintf("Too many planes 4\n");
                    break;

                }

                -- Set up next clipping plane
                _planes [numplanes] = trace.planeNormal;
                numplanes++;

                -- modify original_velocity so it parallels all of the clip planes
                --

                -- reflect player velocity 
                -- Only give this a try for first impact plane because you can get yourself stuck in an acute corner by jumping in place
                --  and pressing forward and nobody was really using this bounce/reflection feature anyway...
                if (numplanes == 1) {

                    for (int i = 0; i < numplanes; i++) {

                        if (_planes [i] [1] > SurfSlope) {

                            -- floor or slope
                            return blocked;
                            --ClipVelocity(originalVelocity, _planes[i], ref newVelocity, 1f);
                            --originalVelocity = newVelocity;

                        } else
                            ClipVelocity (originalVelocity, _planes [i], ref newVelocity, 1f);

                    }

                    velocity = newVelocity;
                    originalVelocity = newVelocity;

                } else {

                    int i = 0;
                    for (i = 0; i < numplanes; i++) {

                        ClipVelocity (originalVelocity, _planes [i], ref velocity, 1);

                        int j = 0;

                        for (j = 0; j < numplanes; j++) {
                            if (j != i) {

                                -- Are we now moving against this plane?
                                if (Vector3.Dot (velocity, _planes [j]) < 0)
                                    break;

                            }
                        }

                        if (j == numplanes)  -- Didn't have to clip, so we're ok
                            break;

                    }

                    -- Did we go all the way through plane set
                    if (i != numplanes) {   -- go along this plane
                        -- pmove.velocity is set in clipping call, no need to set again.
                        ;
                    } else {   -- go along the crease

                        if (numplanes != 2) {

                            velocity = Vector3.zero;
                            break;

                        }

                        var dir = Vector3.Cross (_planes [0], _planes [1]).normalized;
                        d = Vector3.Dot (dir, velocity);
                        velocity = dir * d;

                    }

                    --
                    -- if original velocity is against the original velocity, stop dead
                    -- to avoid tiny occilations in sloping corners
                    --
                    d = Vector3.Dot (velocity, primalVelocity);
                    if (d <= 0f) {

                        --Con_DPrintf("Back\n");
                        velocity = Vector3.zero;
                        break;

                    }

                }

            }

            if (allFraction == 0f)
                velocity = Vector3.zero;

            -- Check if they slammed into a wall
            --float fSlamVol = 0.0f;

            --var primal2dLen = new Vector2(primal_velocity.x, primal_velocity.z).magnitude;
            --var vel2dLen = new Vector2(_moveData.Velocity.x, _moveData.Velocity.z).magnitude;
            --float fLateralStoppingAmount = primal2dLen - vel2dLen;
            --if (fLateralStoppingAmount > PLAYER_MAX_SAFE_FALL_SPEED * 2.0f)
            --{
            --    fSlamVol = 1.0f;
            --}
            --else if (fLateralStoppingAmount > PLAYER_MAX_SAFE_FALL_SPEED)
            --{
            --    fSlamVol = 0.85f;
            --}

            --PlayerRoughLandingEffects(fSlamVol);

            return blocked;
        }]]

return Trace