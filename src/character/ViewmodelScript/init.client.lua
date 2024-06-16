local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedEvents = ReplicatedStorage:WaitForChild("Events")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local camera = workspace.CurrentCamera
local vm = ReplicatedStorage:WaitForChild("Viewmodel")
local viewmodelc = vm:Clone()
viewmodelc.Parent = camera

local function Update(_dt)
    viewmodelc.PrimaryPart.CFrame = camera.CFrame
end

for _, v in pairs({"Equip", "Shoot", "Unequip"}) do
    SharedEvents[v].Event:Connect(function()
    end)
end

RunService.RenderStepped:Connect(Update)