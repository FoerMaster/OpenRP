GM.Config = {
    Defaults = {
        Job = 'citizen',
        Money = 50000,
        DoorCost = 1200,
        DoorSellPercent = 0.66,
        MaxDoors = 5,
        SalaryEverySeconds = 60 * 10,
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
