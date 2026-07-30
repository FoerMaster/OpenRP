nw.Register 'owner'
    :Write(net.WriteEntity)
    :Read(net.ReadEntity)

nw.Register 'money'
    :Write(net.WriteUInt, 32)
    :Read(net.ReadUInt, 32)
    :SetLocalPlayer()

nw.Register 'respawn_at'
    :Write(net.WriteFloat)
    :Read(net.ReadFloat)
    :SetLocalPlayer()

nw.Register 'door_data'
    :Write(net.WriteTable)
    :Read(net.ReadTable)