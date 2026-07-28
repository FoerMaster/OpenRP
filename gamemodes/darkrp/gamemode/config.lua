GM.Config = {
    Defaults = {
        Job = 'citizen',
        Money = 50000,
        DoorCost = 1200,
        DoorSellPercent = 0.66,
        SalaryEverySeconds = 60 * 10,
        NextJobChange = 60 * 2,
        NextCommand = 2,
    },
    Limits = {
        ['props'] = 100,
    },
    AllowedProps = {
        [''] = true,
    }
}
