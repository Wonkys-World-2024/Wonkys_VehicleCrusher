Config = {}
Config.Jobs = { mechanic = true, tow = true }
Config.Bed = vec4(-526.76, -1725.81, 20.01, 318.88)
-- The supplied centre is a player position: adjust these after the first placement test.
Config.BedOffset = vec3(0.0, 0.0, 0.0) -- world axes, metres
Config.BedHalfWidth = 3.8
Config.BedHalfLength = 2.0
Config.BedHeightTolerance = 2.0
Config.Panel = vec4(-532.21, -1720.74, 19.55, 143.53)
Config.PanelModel = 'm23_1_prop_m31_controlpanel_02a'
Config.PanelMountHeight = 0.95 -- panel bottom above the configured ground reference
Config.PanelGroundOffset = -1.0 -- player position to ground
Config.ControlDistance = 3.0
Config.Duration = 22000
Config.CrushAt = 17000
Config.Press = { width = 7.6, depth = 2.6, thickness = 0.35, raisedZ = 3.3, loweredZ = 0.15 }
Config.SoundRange = 45.0
Config.BlockOwnedVehicles = true -- reads player_vehicles; never deletes database ownership records
Config.Rewards = {
 { name = 'metalscrap', min = 8, max = 16 },
 { name = 'steel', min = 5, max = 10 },
 { name = 'iron', min = 3, max = 7 },
 { name = 'aluminum', min = 2, max = 6 },
 { name = 'copper', min = 1, max = 4 },
 { name = 'plastic', min = 3, max = 8 },
 { name = 'rubber', min = 2, max = 5 },
 { name = 'glass', min = 2, max = 6 },
}

Config.Forklift = {
 models = { dibzer_forklift = true },
 maxLength = 12.0, maxWidth = 4.0, maxHeight = 4.5,
 pickupDistance = 4.5,
 boneNames = { 'forks', 'forks_attach', 'fork', 'fork_l' },
 fallbackBone = 3,
 offset = vec3(0.0, 1.25, -0.52), -- vehicle: forward along forks, lowered toward tines
 scrapOffset = vec3(0.0, 1.25, -0.50), -- scrap attachment root, independent of vehicle bounds
 rotation = vec3(0.0, 0.0, 90.0),
}

Config.OriginalPress = {
 position = vec4(-522.747, -1728.968, 18.214, 55.0),
 travel = 2.35,
 hideRadius = 2.0,
 streamDistance = 180.0,
}

Config.Yard = {
 enabled = true,
 center = vec3(-478.0, -1715.0, 19.0), radius = 100.0,
 toolItem = 'repairkit', stripDuration = 8000,
 sorting = vec3(-542.14, -1706.00, 19.32),
 sortingHeading = 15.96,
 sortingPanel = vec4(-542.14, -1706.00, 19.32, 123.76),
 -- Every listed model is rendered as one grouped forklift/trailer load.
 baleModel = 'bzzz_scrap_box_a', -- invisible attachment root
 scrapModels = {
  'bzzz_scrap_beam_a',
  'bzzz_scrap_beam_b',
  'bzzz_scrap_box_a',
  'bzzz_scrap_cogwheel_a',
  'bzzz_scrap_gear_a',
  'bzzz_scrap_nail_a',
  'bzzz_scrap_nail_b',
  'bzzz_scrap_nut_a',
  'bzzz_scrap_nut_b',
  'bzzz_scrap_nut_c',
  'bzzz_scrap_plate_a',
  'bzzz_scrap_plate_b',
  'bzzz_scrap_samwheel_a',
  'bzzz_scrap_samwheel_b',
  'bzzz_scrap_screw_a',
  'bzzz_scrap_something_a',
  'bzzz_scrap_something_b',
  'bzzz_scrap_spring_a',
  'bzzz_scrap_spring_b',
  'bzzz_scrap_tube_a',
  'bzzz_scrap_tube_b',
  'bzzz_scrap_tube_c',
 },
 baleGroundZ = 19.1,
 weighbridge = vec4(-421.18, -1713.04, 19.45, 69.05),
 weighbridgePanel = vec4(-418.2, -1723.20, 19.6, 250.48),
 weighbridgeSize = vec3(3.5, 8.0, 0.15),
 deliverySpawn = vec4(-468.13, -1721.47, 18.66, 284.72),
 deliveryBay = vec4(-441.87, -1696.75, 18.94, 157.14),
 deliveryCooldown = 300000,
 deliveryModels = { 'asea', 'emperor', 'ingot', 'premier', 'regina' },
 bins = {
  {item='metalscrap',label='Metal Scrap',pos=vec3(-547.16,-1703.96,19.38),heading=299.23},
  {item='steel',label='Steel',pos=vec3(-548.52,-1701.39,19.31),heading=297.67},
  {item='iron',label='Iron',pos=vec3(-550.12,-1698.98,19.31),heading=290.4},
  {item='aluminum',label='Aluminium',pos=vec3(-551.39,-1696.57,19.35),heading=299.96},
  {item='copper',label='Copper',pos=vec3(-553.56,-1692.9,19.42),heading=300.03},
  {item='plastic',label='Plastic',pos=vec3(-555.06,-1690.42,19.47),heading=300.03},
  {item='rubber',label='Rubber',pos=vec3(-556.43,-1688.2,19.47),heading=299.96},
  {item='glass',label='Glass',pos=vec3(-557.86,-1685.61,19.47),heading=300.03},
 },
 parts = {
  battery={label='Remove battery',bone='bonnet',rewards={{name='copper',count=2},{name='plastic',count=2}}},
  catalyst={label='Remove catalytic converter',bone='exhaust',rewards={{name='metalscrap',count=3},{name='steel',count=2}}},
  wheels={label='Remove wheel materials',bone='wheel_lf',rewards={{name='rubber',count=4},{name='aluminum',count=3}}},
  trim={label='Strip interior trim',bone='door_dside_f',rewards={{name='plastic',count=4},{name='glass',count=2}}},
 },
}

Config.ForkliftGarage = {
 model = 'dibzer_forklift', -- actual vehicle spawn name (not resource folder name)
 collection = vec4(-512.19, -1747.59, 19.23, 50.7),
 parking = vec4(-511.59, -1736.8, 19.22, 324.61),
}

Config.CrusherAlert = {
 model = 'hei_prop_wall_alarm_on',
 position = vec4(-531.68, -1721.25, 19.64, 151.35),
 flashInterval = 450,
}
