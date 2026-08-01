function PLAYER:SetWeaponLicense(state)
    self:SetNetVar('weapon_license', state)
end

function PLAYER:ResetWeaponLicense()
    self:SetWeaponLicense(self:HasJobFlag(JOB_FLAG_WEAPON_LICENSE))
end

roleplay.Chat.AddCommand('giveweplicense', function(sender)
    local target = sender:GetEyeTrace().Entity
    if (!IsValid(target) or !target:IsPlayer() or sender:GetPos():Distance(target:GetPos()) > 200) then
        sender:ChatError('NoPlayerInFront')
        return
    end

    if target:HasWeaponLicense() then
        sender:ChatError('LicenseAlreadyHas')
        return
    end

    if (!hook.Run('OnPlayerGiveWeaponLicense', sender, target)) then
        sender:ChatError('LicenseCantManage')
        return
    end

    target:SetWeaponLicense(true)

    sender:ChatSuccess('LicenseGiven', target:Nick())
    target:ChatSuccess('LicenseReceived')

    hook.Run('PlayerGaveWeaponLicense', sender, target)
end)

roleplay.Chat.AddCommand('stripweplicense', function(sender, arguments)
    local target, ambiguous = roleplay.FindPlayer(arguments[1])

    if ambiguous then
        sender:ChatError('ChatAmbiguousName')
        return
    end

    if !target then
        sender:ChatError('PlayerNotFound')
        return
    end

    if !target:HasWeaponLicense() then
        sender:ChatError('LicenseHasNot')
        return
    end

    if (!hook.Run('OnPlayerStripWeaponLicense', sender, target)) then
        sender:ChatError('LicenseCantManage')
        return
    end

    target:SetWeaponLicense(false)

    sender:ChatSuccess('LicenseStripped', target:Nick())
    target:ChatError('LicenseLost')

    hook.Run('PlayerStrippedWeaponLicense', sender, target)
end)
