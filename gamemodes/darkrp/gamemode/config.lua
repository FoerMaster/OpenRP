GM.Config = {
    Defaults = {
        Job = 'citizen',
        Money = 50000,
        DoorCost = 1200,
        DoorSellPercent = 0.66,
        MaxDoors = 5,
        MaxDoorNameLength = 16,
        SalaryEverySeconds = 60 * 10,
        MaxDropMoney = 10000,
        RespawnDelay = 10,
        DeathMoneyPercent = 0.3,
        DeathMoneyMax = 10000,
        NextJobChange = 60 * 2,
        NextCommand = 2,
        JobVoteSeconds = 20,
        DemoteVoteSeconds = 30,
        MinPlayersToDemote = 4,
    },
    Limits = {
        ['props'] = 100,
    },
    AllowedProps = {
        [''] = true,
    }
}
