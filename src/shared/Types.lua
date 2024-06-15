local Types = {}

export type InventorySlot = "primary" | "secondary" | "ternary"

export type Weapon = {
    equipped: boolean,
    equipping: boolean,
    shooting: boolean,
    slot: InventorySlot,
    config: WeaponConfiguration,
    last_shoot_time: number,
    last_equip_time: number,
    Init: (self: Weapon) -> (),
    Equip: (self: Weapon) -> (),
    Unequip: (self: Weapon) -> (),
    Shoot: (self: Weapon) -> (),
}

export type WeaponConfiguration = {
    fire_rate: number,
    equip_length: number,
}

export type SkinObject = {
    weapon: string,
    model: string,
    skin: string,
    seed: number
}

-- weapon_model_skin_seed
export type SkinString = string

export type AssetId = string

export type SeedMap = {
    metallic: AssetId,
    smoothness: AssetId,
    diffuseOriginal: AssetId
}

-- Gets
function Types.newWeaponConfiguration(options)
    local self = {
        fire_rate = 0.2,
        equip_length = 0.5,
    } :: WeaponConfiguration
    if not options then
        return self
    end
    for i, v in pairs(options) do
        self[i] = v
    end
    return self
end

function Types.toSkinObject(weapon: string, model: string, skin: string, seed: number): SkinObject
    return {weapon = weapon, model = model, skin = skin, seed = seed} :: SkinObject
end

function Types.toSkinString(skinObject: SkinObject): SkinString
    local s = skinObject
    return s.weapon .. "_" .. s.model .. "_" .. s.skin .. "_" .. tostring(s.seed) :: SkinString
end

function Types.fromSkinString(skinStr: SkinString): SkinObject
    local s = skinStr:split("_")
    return {weapon = s[1], model = s[2], skin = s[3], seed = s[4]} :: SkinObject
end

Types.SeedMapToPBR = {
    diffuseOriginal = "ColorMap",
    metallic = "MetalnessMap",
    smoothness = "RoughnessMap"
}

return Types