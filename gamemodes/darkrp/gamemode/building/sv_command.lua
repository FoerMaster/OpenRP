concommand.Add( "gm_spawn", function(ply, command, arguments)
    if (ply._SpawnCooldown > CurTime()) then return end
    ply._SpawnCooldown = CurTime() + 0.3

    local model = arguments[ 1 ]

    if ( model == nil ) then return end

	if (!GAMEMODE.Config.AllowedProps[model]) then return end

    if (!util.IsValidProp(model)) then return end

    if (!hook.Run("PlayerSpawnProp", ply, model)) then return end

    local vStart = ply:GetShootPos()
    local vForward = ply:GetAimVector()

    local trace = {}
	trace.start = vStart
	trace.endpos = vStart + (vForward * 2048)
	trace.filter = ply

	local tr = util.TraceLine( trace )
	
	local ent = ents.Create( "prop_physics" )
	if ( !IsValid( ent ) ) then return end

	local ang = ply:EyeAngles()
	ang.yaw = ang.yaw + 180
	ang.roll = 0
	ang.pitch = 0
	
	ent:SetModel( model )
	ent:SetSkin( 0 )
	ent:SetAngles( ang )
	ent:SetPos( tr.HitPos )
	ent:Spawn()
	ent:Activate()
	local vFlushPoint = tr.HitPos - ( tr.HitNormal * 512 )	
	vFlushPoint = ent:NearestPoint( vFlushPoint )
	vFlushPoint = ent:GetPos() - vFlushPoint
	vFlushPoint = tr.HitPos + vFlushPoint

	local VecOffset = vFlushPoint - ent:GetPos()
    for i = 0, ent:GetPhysicsObjectCount() - 1 do
        local phys = ent:GetPhysicsObjectNum( i )
        phys:SetPos( phys:GetPos() + VecOffset )
    end

    hook.Run("PlayerSpawnedProp", ply, model, ent)

    local PhysObj = ent:GetPhysicsObject()
	if ( IsValid( PhysObj ) ) then
		local pmin, pmax = PhysObj:GetAABB()
		local omin, omax = ent:OBBMins(), ent:OBBMaxs()

		if ( pmin && pmax && omin && omax ) then
			local PhysSize = ( pmin - pmax ):Length()
			local ModelSize = ( omin - omax ):Length()

			if ( PhysSize <= 5 && math.abs( ModelSize - PhysSize ) >= 10 ) then
				ent:PhysicsInitBox( omin, omax )
				ent:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
			end
		end
	end

    undo.Create( "Prop" )
		undo.SetPlayer( ply )
		undo.AddEntity( ent )
	undo.Finish( "Prop (" .. tostring( model ) .. ")" )

    ply:AddCleanup( "props", ent )
    ply:AddCount( "props", ent )

    local phys = ent:GetPhysicsObject()
	if (IsValid(phys)) then
		phys:EnableMotion(false)
        phys:SetDragCoefficient(0)
        phys:SetMass(0)
	end
    ent:StopParticles()

    if (not util.IsInWorld(ent:GetPos())) then
        ent:Remove()
        return
    end

end, nil, "Спавн пропов без ебанных регдоллов" )