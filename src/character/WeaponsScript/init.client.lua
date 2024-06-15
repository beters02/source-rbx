local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Types = require(ReplicatedStorage:WaitForChild("Types"))
local Weapons = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Weapon")
local Karambit = require(Weapons:WaitForChild("Karambit"))

local player = Players.LocalPlayer
local _ = player.Character or player.CharacterAdded:Wait()

local inputs = {
    shoot = false,
}

local inventory = {
    equipped_slot = "ternary",
    primary = false,
    secondary = false,
    ternary = Karambit.new()
}

local slot_to_keycode = {
    primary = "1",
    secondary = "2",
    ternary = "3"
}

local numbers = {
    ["One"] = 1,
    ["Two"] = 2,
    ["Three"] = 3,
}

local function WeaponAction(slot: Types.InventorySlot, action: string)
    if inventory[slot] then
        inventory[slot][action](inventory[slot])
    end
end

local function ProcessShoot(self: Types.Weapon)
    if self.equipped and (not self.shooting or tick() - self.last_shoot_time < self.config.fire_rate) then
        self:Shoot()
    end
end

local function ProcessEquip(slot)
    WeaponAction(inventory.equipped_slot, "Unequip")

    local wep = inventory[slot]
    if not wep then return end
    
    inventory.equipped_slot = wep.config.slot
    task.wait()
    if inventory[inventory.equipped_slot] then
        WeaponAction(slot, "Equip")
    end
end

local function InputBegan(input: InputObject)
    if input.KeyCode.Name ~= "Unknown" then
        local inputStr = input.KeyCode.Name
        for slot, numstr in pairs(slot_to_keycode) do
            local equipstr = numbers[inputStr]
            if not equipstr then return end
            if equipstr == tonumber(numstr) then
                ProcessEquip(slot)
                break
            end
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        inputs.shoot = true
    end
end

local function InputEnded(input: InputObject)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        inputs.shoot = false
    end
end

local function Update(_dt)
    local wep = inventory[inventory.equipped_slot]
    if wep.equipping and tick() - wep.last_equip_time >= wep.config.equip_length then
        WeaponAction(wep.config.slot, "FinishEquip")
    end
    if inputs.shoot then
        ProcessShoot(wep)
    end
end

UserInputService.InputBegan:Connect(InputBegan)
UserInputService.InputEnded:Connect(InputEnded)
RunService.RenderStepped:Connect(Update)

ProcessEquip("ternary")