local teamCounter = 1
local function makeTeam(name, color)
    teamCounter = teamCounter + 1
    team.SetUp(teamCounter, name, color or Color(25, 128, 61))
    return teamCounter
end

TEAM_CITIZEN = makeTeam('Гражданские', Color(25, 128, 61))
TEAM_GOVERNMENT = makeTeam('Правительство', Color(23, 55, 181))
