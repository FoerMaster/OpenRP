JOB.DisplayName = "Полицейский"
JOB.Description = "Следит за порядком в городе, задерживает нарушителей"
JOB.Color = Color(23, 55, 181)
JOB.Team = TEAM_GOVERNMENT
JOB.MaxPlayers = 6
JOB.MaxHealth = 100
JOB.StartHealth = 100
JOB.StartArmor = 50
JOB.Salary = 750
JOB.Flags = { JOB_FLAG_CANT_BUY_DOOR, JOB_FLAG_NEED_VOTE }
JOB.SWEPs = { "weapon_stunstick", "weapon_pistol" }
JOB.Model = {
    "models/player/police.mdl",
    "models/player/police_fem.mdl"
}

function JOB:OnJoined(oldJob)
    self.Player:SellAllDoors()
    self.Player:LeaveAllDoors()
end
