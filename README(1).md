# Wonky Vehicle Crusher

A vehicle recycling yard for FiveM and Qbox. Strip parts, lift empty vehicles onto an animated crusher, then move the scrap to sorting or load it onto a trailer. Version documented: **2.0.8**.

## Requirements

| Dependency | Used for |
| --- | --- |
| [FiveM with OneSync](https://docs.fivem.net/docs/scripting-reference/onesync/) | Networked vehicles, forklift cargo and server-side entity checks |
| [qbx_core](https://github.com/Qbox-project/qbx_core) | Player and job access |
| [ox_lib](https://github.com/CommunityOx/ox_lib) | Callbacks, notifications and progress interactions |
| [ox_target](https://github.com/CommunityOx/ox_target) | Crusher, vehicle, sorting and bin interactions |
| [ox_inventory](https://github.com/CommunityOx/ox_inventory) | Tool checks and material inventory |
| [oxmysql](https://github.com/CommunityOx/oxmysql) | Vehicle ownership lookup against Qbox's `player_vehicles` table |
| [qbx_vehiclekeys](https://github.com/Qbox-project/qbx_vehiclekeys) | Required for the yard forklift collection feature |
| GTA V game build containing San Andreas Mercenaries props | Supplies the default control panel, `m23_1_prop_m31_controlpanel_02a` |

## Props and vehicle assets

- **BZZZ / BzZzi — Iron Scrap.** The scrap load uses 22 models from this free pack, including beams, gears, fasteners and tubes. The private development ZIP bundles the models, texture dictionary and `bzzz_scrap_items.ytyp`. Use a single streamed copy. If you install the props as a separate resource, start it before the crusher and remove both BZZZ YTYP declarations from the crusher manifest along with its bundled BZZZ files. [Creator's download and credits](https://forum.cfx.re/t/props-iron-scrap/5281969)
- **Dibzer forklift.** The default spawn model is `dibzer_forklift`. Install your copy of the vehicle separately and start its resource first. To use another model, set both `Config.ForkliftGarage.model` and the allowlist in `Config.Forklift.models`. Check the fork bone and cargo offsets in-game.
- **Crusher and audio.** The resource uses the streamed `wonky_crusher_frame` and `wonky_crusher_head` models, their archetype and crusher texture data. The NUI plays `web/crusher.wav` and `web/warning.wav`. The default yard uses existing map machinery and skip locations. The bin interactions are zones, so the script does not spawn the skips.

## Installation

1. Place the resource in your server's resources directory as `Wonkys_VehicleCrusher`. Keep the folder name stable because saved yard data uses resource KVP storage.
2. Enable OneSync and make sure the dependencies above start before the crusher. Start the forklift addon and the separate BZZZ prop resource here too if your installation uses them.
3. Verify these exact item IDs in your ox_inventory setup: `repairkit`, `metalscrap`, `steel`, `iron`, `aluminum`, `copper`, `plastic`, `rubber`, and `glass`. The repair kit is needed for stripping and is retained after use. No crusher-specific SQL migration is required.
4. Review `config.lua` for your yard layout. Access defaults to `mechanic` and `tow`. Test in the main world routing bucket.
5. Add this below the dependencies in `server.cfg`:

   ```cfg
   ensure Wonkys_VehicleCrusher
   ```

## Using the yard

1. Bring an empty eligible road vehicle, or request an NPC delivery at the crusher panel. The default delivery cooldown is five minutes.
2. Optionally use the weighbridge panel to see handling mass and estimated yields. Target the vehicle with a repair kit to strip battery, catalyst, wheel or trim materials. Claim stripping bonuses separately at the control panel.
3. Collect a forklift at the yard collection point. Use **G** or `/wonkyfork` to secure or release cargo. Lower the vehicle onto the bed and reverse clear.
4. Start the 22-second cycle at the crusher panel. The warning light and sound run while the press lowers and vehicle damage progresses. Emergency stop returns the head but leaves damage already applied.
5. Move the resulting scrap load to sorting and target the sorting area to send materials to the shared bins. Alternatively, release it next to a trailer and target the trailer to load it. The default limit is four loads per trailer.

With the default ownership guard enabled, the crusher rejects registered vehicles and blocks processing if the ownership lookup fails. Empty trunks and gloveboxes before recycling. Their contents are not transferred.

## Configuration and troubleshooting

| Setting or command | Purpose |
| --- | --- |
| `Config.Jobs` | Jobs authorized to operate the yard |
| `Config.Bed`, `Config.Panel`, `Config.OriginalPress` | Crusher pickup area, control panel and press placement |
| `Config.Yard` | Sorting, weighbridge, deliveries, shared bins and scrap models |
| `Config.Rewards` | Material yields |
| `Config.ForkliftGarage`, `Config.Forklift` | Collection, return, allowed models and cargo alignment |
| `/crushercoords`, `/crusherpressdebug`, `/crusherscan` | Placement and press diagnostics |
| `/forkdebug` | Report the selected fork bone |

Test delivery routing, fork and trailer alignment, sorting and shared bins in-game after changing models or map resources. Finish active cycles and return or unload forklifts before restarting. Back up resource KVP data before upgrades. It stores scrap loads, bin stock and pending rewards.

## Credits and release packaging

- **Wonky's World** — crusher scripting and yard integration.
- **BzZzi / BZZZ** — Iron Scrap props.
- **Dibzer** — forklift credited by the development build. Obtain the vehicle from its original distribution.
- **Rockstar Games** — GTA V world assets and base-game props used by the yard.
- **Qbox, Overextended and CommunityOx contributors** — framework and supporting resources.

The development ZIP is a private server build. Prepare a separate public package and verify redistribution terms for all bundled models, textures and audio before uploading them. Link to the original downloads for assets you distribute separately. Publish a license covering only the code and assets you have rights to license.
