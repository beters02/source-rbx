local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

PhysicsService:RegisterCollisionGroup("PlayerMovement")
PhysicsService:RegisterCollisionGroup("Players")
PhysicsService:CollisionGroupSetCollidable("Players", "PlayerMovement", false)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("Part") or v:IsA("MeshPart") then
                v.CollisionGroup = "Players"
            end
        end
    end)
end)