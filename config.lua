Config = {}

Config.Init = {
    pedModel = "IG_Req_Officer",
    pedPosition = vector4(-253.71, -971.08, 31.22, 163.49), --vector4(-636.2, -1779.0, 24.13, 332.58),
    pedScenario = "WORLD_HUMAN_CLIPBOARD",
    targetLabel = "Начать работу",
    targetLabelDone = "Завершить работу",
    targetIcon = "fa fa-align-justify",
    blip = {
        name = "Работа грузчика",
        srpite = 615,
        color = 3,
        scale = 0.6
    },
    inCome = 50,
    timeStart = 8,
    timeEnd = 15

}

Config.Marker = {
    type = 1,
    scale = vector3(1, 1, 0.2),
    r = 255,
    g = 255,
    b = 255,
    dist = 25
}

Config.Anim = {
    animDict = "anim@heists@box_carry@",
    anim = "idle",
    prop = "hei_prop_heist_box",
    propPosition = vector3(0,0,0),
    bone = 28422
}

Config.Points = {
    {
        positionTake = vector4(-444.03, -1666.7, 19.03, 340.34),
        positionPut = vector4(-531.76, -1616.41, 17.8, 339.2),
        count = 3,  --15
    },
    {
        positionTake = vector4(-579.44, -1788.84, 22.7, 308.49),
        positionPut = vector4(-640.24, -1779.26, 24.27, 52.75)
        count = 3,  --20
    },
    {
        positionTake = vector4(-640.24, -1779.26, 24.27, 52.75) ,
        positionPut = vector4(-631.6, -1779.63, 23.97, 293.64),
        count = 3,  --25
    },
}
