function PLAYER:HasWeaponLicense()
    return self:GetNetVar('weapon_license', false)
end
