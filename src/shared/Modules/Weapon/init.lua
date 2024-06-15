local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage:WaitForChild("Types"))
local SharedEvents = ReplicatedStorage:WaitForChild("Events")

local Weapon: Types.Weapon = {}
Weapon.__index = Weapon

local function initModel(self)
    self.model = self.assets_folder.Models.default:Clone()
    self.model.Parent = game.Players.LocalPlayer.Backpack
end

local function initAnimations(self)
    self.animations = {}
    local animator: Animator = workspace.CurrentCamera:WaitForChild("Viewmodel"):WaitForChild("AnimationController"):WaitForChild("Animator")
    for _, v in pairs(self.assets_folder.Animations:GetChildren()) do
        self.animations[v.Name] = animator:LoadAnimation(v)
    end
    self.animations.Hold.Looped = true
end

function Weapon.new(weapon: string, config: Types.WeaponConfiguration)
    local self: Types.Weapon = {}
    self.equipped = false
    self.equipping = false
    self.shooting = false
    self.name = weapon
    self.client_model = ""
    self.config = Types.newWeaponConfiguration(config)
    self.last_shoot_time = 0
    self.last_equip_time = 0
    self.assets_folder = ReplicatedStorage.Assets.Weapons[weapon]
    self.vm = workspace.CurrentCamera:WaitForChild("Viewmodel")
    
    initModel(self)
    initAnimations(self)
    return setmetatable(self, Weapon) :: Types.Weapon
end

function Weapon:PlayAnimation(animation: AnimationTrack)
    if animation.IsPlaying then
        return
    end
    animation:Play()
end

function Weapon:Equip()
    self.model.Parent = workspace.CurrentCamera
    self.vm.RightHand.RightGrip.Part1 = self.model.GunComponents.WeaponHandle
    SharedEvents.Equip:Fire()
    self.last_equip_time = tick()
    self.equipping = true
    self.animations.Pullout:Play()
    self.animations.Pullout.Stopped:Wait()
    if not self.equipping and not self.equipped then return end
    self.animations.Hold:Play()
end

function Weapon:FinishEquip()
    self.equipping = false
    self.equipped = true
end

function Weapon:Unequip()
    self.model.Parent = game.Players.LocalPlayer.Backpack
    self.vm.RightHand.RightGrip.Part1 = nil
    SharedEvents.Unequip:Fire()
    self.equipping = false
    self.equipped = false
    self.shooting = false
    self.animations.Hold:Stop()
    self.animations.Pullout:Stop()
    self.animations.Shoot:Stop()
end

function Weapon:Shoot()
    SharedEvents.Shoot:Fire()
    self.last_shoot_time = tick()
    if self.animations.Pullout.IsPlaying then
        self.animations.Pullout:Stop()
        task.wait()
    end
    self:PlayAnimation(self.animations.Shoot)
end

return Weapon :: Types.Weapon