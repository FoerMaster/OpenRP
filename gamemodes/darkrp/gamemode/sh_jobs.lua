local DEF_PLY = {}

DEF_PLY.DisplayName			= "DEFAULT"
DEF_PLY.Team = TEAM_CITIZEN
DEF_PLY.SlowWalkSpeed		= 200
DEF_PLY.WalkSpeed			= 400
DEF_PLY.RunSpeed				= 600
DEF_PLY.CrouchedWalkSpeed	= 0.3
DEF_PLY.DuckSpeed			= 0.3
DEF_PLY.UnDuckSpeed			= 0.3
DEF_PLY.JumpPower			= 200
DEF_PLY.CanUseFlashlight		= true
DEF_PLY.MaxHealth			= 100
DEF_PLY.MaxArmor				= 100
DEF_PLY.StartHealth			= 100
DEF_PLY.StartArmor			= 0
DEF_PLY.DropWeaponOnDie		= false
DEF_PLY.TeammateNoCollide	= true
DEF_PLY.AvoidPlayers			= true
DEF_PLY.UseVMHands			= true

DEF_PLY.SWEPs               = {}
DEF_PLY.Default_SWEPs       = {"weapon_physgun", "hands", "gmod_tool"}
DEF_PLY.MaxPlayers = -1
DEF_PLY.Model = {"models/player/odessa.mdl"}

function DEF_PLY:SetupDataTables()
	-- self.Player:NetworkVar( "Bool", 0, "Escaping" )
end

function DEF_PLY:Init()
    if SERVER then
        self.Player:SetTeam(self.Team)
    end
end

function DEF_PLY:Spawn()
end

function DEF_PLY:SetModel()
    self.Player:SetModel(table.Random(self.Model))
end

function DEF_PLY:Loadout()
    for k,v in ipairs(self.Default_SWEPs) do
        self.Player:Give(v)
    end
    for k,v in ipairs(self.SWEPs) do
        self.Player:Give(v)
    end
end

function DEF_PLY:Death( inflictor, attacker )
end

function DEF_PLY:CalcView( view ) end
function DEF_PLY:CreateMove( cmd ) end
function DEF_PLY:ShouldDrawLocal() end

function DEF_PLY:StartMove( mv, cmd ) end
function DEF_PLY:Move( mv ) end
function DEF_PLY:FinishMove( mv ) end

function DEF_PLY:ViewModelChanged( vm, old, new )
end

function DEF_PLY:PreDrawViewModel( vm, weapon )
end

function DEF_PLY:PostDrawViewModel( vm, weapon )
end

function DEF_PLY:GetHandsModel()
	local playermodel = player_manager.TranslateToPlayerModelName( self.Player:GetModel() )
	return player_manager.TranslatePlayerHands( playermodel )

end

function DEF_PLY:CanDropMoney( amount )
end

function DEF_PLY:OnDroppedMoney( amount, ent )
end

function DEF_PLY:CanTransferMoney( target, amount )
end

function DEF_PLY:OnTransferedMoney( target, amount )
end

function DEF_PLY:CanBuyDoor( door )
end

function DEF_PLY:OnBoughtDoor( door, cost )
end

function DEF_PLY:CanSellDoor( door )
end

function DEF_PLY:OnSoldDoor( door, refund )
end

function DEF_PLY:CanOpenDoor( door )
end

function DEF_PLY:OnLeftDoor( door )
end

function DEF_PLY:CheckBuildLimit( class, count, limit )
end

function DEF_PLY:OnSpawnedProp( model, ent )
end

player_manager.RegisterClass( "rp_player", DEF_PLY, nil )

-- Флаги:
JOB_FLAG_UNDISMISSABLE = 1
JOB_FLAG_NEED_VOTE = 2
JOB_FLAG_NONRP = 3
JOB_FLAG_CANT_BUY_DOOR = 4