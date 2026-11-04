# Wonky Vehicle Crusher / Full Yard 2.0.8
Preview https://www.youtube.com/watch?v=8btIEaW6a2w&t=4s
## Install / upgrade

1. Stop Wonkys_VehicleCrusher with no forklift load or active cycle.
2. Replace its resource folder with the folder in this ZIP, including stream and web. Do not run an older copy alongside it.
3. Start after qbx_core, ox_lib, ox_target, ox_inventory and oxmysql:
   `ensure Wonkys_VehicleCrusher`
4. OneSync is required. Reconnect if new models do not stream immediately.

No SQL migration or new inventory items are required. Default jobs are mechanic and tow. Preserve resource KVP storage: it holds bales, shared bin stock, stripping bonuses and legacy unclaimed rewards. Keep the resource folder name unchanged.
## Gameplay demos

1. [Vehicle crusher in action](./part1.mp4)
2. [Moving scrap with the forklift](./part2.mp4)
3. [Scrap sorting and material bins](./part3.mp4)
## Full recycling workflow

1. Bring an empty NPC/admin-spawned road vehicle, or request an NPC delivery through ox_target at the crusher control panel. Deliveries have a five-minute cooldown and require a clear bay.
2. Optionally place it on the blue weighbridge marker and target the area for its handling mass and configurable material yield ranges.
3. With a repairkit in inventory, target the vehicle to strip its battery, catalytic converter, wheel materials and interior trim. Each task takes eight seconds and pays once per part for that vehicle during the resource session. The repairkit is not consumed. Collect these separate bonuses at the control panel; anything that does not fit stays available.
4. Drive the configured forklift under the empty vehicle. Press G or /wonkyfork to secure/release it; use normal fork controls to raise/lower. Release it onto the crusher bed and reverse clear.
5. Target the control panel to start the 22-second cycle. The amber warning light and alarm activate, the textured head lowers and the vehicle progressively loses windows, tyres, doors, bonnet and boot before removal.
6. A scrap load remains on the bed after confirmed vehicle removal. Move it with the forklift using G. Clear it before starting another crush.
7. Release the load at BALE SORTING, target the sorting area and complete the sorting task. Its materials enter the labelled shared bins. Target each bin to deposit or withdraw a quantity.
8. Alternatively release the load beside a trailer and target the trailer to load it. Up to four loads fit; target it again to unload. Trailer attachment offsets are generic and may need adapting to your trailer model.

Emergency stop is available at the control panel. It aborts the cycle and returns the head smoothly. Existing damage remains. A vehicle already removed is not restored; its scrap load remains available.

Crush materials: metalscrap, steel, iron, aluminum, copper, plastic, rubber and glass. New crush rewards are carried in the scrap load and must be sorted, rather than collected directly at the panel. The older panel collection option remains for legacy unclaimed rewards.

## Yard positions (2.0.3)

Updated to your supplied locations. Target boxes use each supplied heading; sorting and weighbridge cabinets use their configured headings. Sorting coordinates are the forklift drop-off point (the small cabinet is offset 2m to its side).

| Area | X | Y | Z | Heading |
| --- | --- | --- | --- | --- |
| Bale sorting | -541.5 | -1709.38 | 19.26 | 15.96 |
| Weighbridge | -459.14 | -1714.78 | 18.64 | 147.35 |
| Delivery spawn | -468.13 | -1721.47 | 18.66 | 284.72 |
| Delivery bay | -441.87 | -1696.75 | 18.94 | 157.14 |
| metalscrap bin | -547.16 | -1703.96 | 19.38 | 299.23 |
| steel bin | -548.52 | -1701.39 | 19.31 | 297.67 |
| iron bin | -550.12 | -1698.98 | 19.31 | 290.4 |
| aluminum bin | -551.39 | -1696.57 | 19.35 | 299.96 |
| copper bin | -553.56 | -1692.9 | 19.42 | 300.03 |
| plastic bin | -555.06 | -1690.42 | 19.47 | 300.03 |
| rubber bin | -556.43 | -1688.2 | 19.47 | 299.96 |
| glass bin | -557.86 | -1685.61 | 19.47 | 300.03 |

NPC navigation still needs an in-game route check. Bin bases use the supplied Z values; if those were player standing coordinates rather than ground coordinates, they may need lowering after a screenshot check.

/crushercoords prints player coordinates. /crusherpressdebug reports press models. /forkdebug reports the fork bone. Config.Yard controls the new yard placements and Config.Jobs controls access. Existing crusher pivot, bed and control panel are retained.

## Models and gameplay limits

The working original crusher is split into wonky_crusher_frame and wonky_crusher_head, preserving texture/UV data. The upper assembly travels 2.35m. Only the scanned original crusher is hidden while replacements are active; it is restored on resource stop/stream-out. The head has no collision; the frame retains the original static collider. Compression and damage are scripted, not a physically flattened vehicle mesh.

Scrap loads now combine ALL 22 supplied BZZZ iron scrap props (beams, box, gears, nails, nuts, plates, wheels, screw, springs and tubes). Their YDR/YTD/YTYP assets are bundled and registered in this resource. Do not stream a second copy of the same BZZZ assets in another resource. Config.Yard.scrapModels controls the pieces. The arrangement preserves original model sizes and needs an in-game visual check; it is a mixed parts pile, not a compressed vehicle mesh. Their server records and contents are synchronized; clients render local non-colliding replicas attached to forks/trailers. Loads recover at sorting after resource restart or carrier deletion. Any authorized yard worker can move/sort a load and use the shared bins.

Stripping uses a tool animation and material bonuses, with tyre/glass effects where applicable. It does not create individually modelled removable batteries/catalysts or loose wheel inventory items. The weighbridge is a marker and interaction area displaying handling-file mass; it is not a physical scale and does not change base rewards by weight. NPC deliveries are requested at the panel rather than spawned automatically in the background.

Forklift road-vehicle limit: 12m long, 4m wide, 4.5m high. Crusher limit: 7m long, 2.8m wide. Aircraft, boats and trains are excluded. Attachments are scripted; carryable does not mean crushable. Collect a yard forklift at the configured collection target, or use your existing garage/admin menu. G is remappable in FiveM key bindings.

Registered player-owned vehicles are blocked through the player_vehicles plate check; database failure blocks processing. Ownership records are never deleted. Inventory contents in vehicle trunks/gloveboxes are not transferred. Vehicles must be empty. Emergency stop does not undo prior damage. GTA controls detached debris lifetime; addon models need breakable geometry.

## Validation

Lua 5.4 syntax checks and mocked tests cover authorization, occupied/owned vehicle rejection, DB failure, cycle locking, deletion before reward, inventory capacity, repeated collection, forklift secure/release, staged damage, bale transfer/single sorting, bin stock changes and timed single-part stripping payouts.

The existing press/damage was previously confirmed working in-game. This v2 yard expansion was checked offline; rendering, new placements, trailer offsets, NPC pathfinding and multiplayer ownership require an in-game test. Bin inventory operations and resource KVP writes are not a cross-resource database transaction: avoid force-stopping the server during transfers. Stop cleanly and back up resource KVP storage.

## 2.0.1 BZZZ scrap loads
Replaces the former single GTA scrap prop for both new and already-saved loads. All pieces move together on forks/trailers and are removed together on sorting, stream-out and resource stop. Rewards, gates, crusher motion and stripping workflow are unchanged. These supplied BZZZ assets are included for your server; this ZIP is not intended for public redistribution.

## 2.0.2 forklift alignment
Vehicle loads move 0.90m forward and 0.60m down from v2.0.1. Scrap loads move 0.90m forward and 0.65m down. Config.Forklift.offset controls vehicles; Config.Forklift.scrapOffset controls scrap. Positive Y moves toward fork tips; negative Z lowers the load. Vehicle height still compensates for model bounding-box minimum Z. These are screenshot-based adjustments and need an in-game alignment check. Release cargo before restarting the resource.

## 2.0.4 existing skip targets
Removed all spawned prop_bin_07a dustbins. Material interactions remain as ox_target zones at the eight configured skip positions, with existing labels, deposit/withdraw and shared stock preserved. Your mapped skip props are not spawned, moved or deleted by this resource. Restart removes the old resource-spawned dustbins automatically.

## 2.0.5 forklift collection / return
Target the collection point at -512.19, -1747.59, 19.23 (heading 50.7) to collect your yard forklift. It spawns at -511.59, -1736.8, 19.22 (heading 324.61), with qbx_vehiclekeys keys. Mechanic/tow only, one issued forklift per character, with a clear-bay check. Return it to that same parking point, release all cargo and exit, then target the return bay or collection point. Only your issued forklift can be stored; unrelated vehicles are never accepted. qbx_vehiclekeys must be started. No NPC or extra collection prop is spawned. Empty unloaded issued forklifts are cleaned up on resource stop; return forklifts before restarting.

## 2.0.6 Dibzer forklift
Collection now spawns dibzer_forklift, and vehicle/scrap loading accepts that model. Start your installed vehicle resource before Wonkys_VehicleCrusher. The vehicle files are not bundled. This assumes dibzer_forklift is the actual spawn name; if that is only the resource folder name, set Config.ForkliftGarage.model and Config.Forklift.models to the actual modelName in vehicles.meta. The existing moving fork bone search, fallback index and load offsets are retained; this addon model needs an in-game alignment/bone check. /forkdebug reports the chosen fork bone.

## 2.0.7 button control panels
Replaces the three added electrical cabinets (crusher, sorting, weighbridge) with m23_1_prop_m31_controlpanel_02a. Config.PanelMountHeight defaults to 0.95m above each ground reference so this small wall-style panel is accessible around waist height. The model has no integral pedestal; adjust mounting height/position to align with a suitable surface if desired. Existing map machinery is retained. Targets remain in their existing areas. Requires a server game build containing the San Andreas Mercenaries prop; the model is not bundled. In-game placement needs checking.

## 2.0.8 weighbridge panel target
Weighbridge button box ground reference is -452.99, -1714.46, 18.64, heading 153.56 (Config.Yard.weighbridgePanel). It keeps the configured mounting height. ox_target is now attached directly to the spawned box, at 2.5m interaction distance. Removed the old large weigh-area target; the vehicle weighing area remains at -459.14, -1714.78, 18.64.
