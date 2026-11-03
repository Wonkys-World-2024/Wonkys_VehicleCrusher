local panel, zone, cycle, cycleStart, lastDamage, lastFx
local function say(ok,msg) lib.notify({title='Wonky Vehicle Recycling',description=msg,type=ok and 'success' or 'error'}) end
local function occupied(v)
 for seat=-1,GetVehicleMaxNumberOfPassengers(v)-1 do if not IsVehicleSeatFree(v,seat) then return true end end
 return false
end
function CrusherCycleElapsed() return cycle and GetGameTimer()-cycleStart or nil end
local function operate()
 if not CrusherVisualReady or not CrusherVisualReady() then return say(false,'Press models are loading. Wait a moment; use /crusherpressdebug if this persists.') end
 if cycle then return say(false,'The crusher is busy.') end
 if IsPedInAnyVehicle(PlayerPedId(),false) then return say(false,'Exit your vehicle before using the panel.') end
 local found
 for _,v in ipairs(GetGamePool('CVehicle')) do
  if CrusherInside(GetEntityCoords(v)) then
   if found then return say(false,'Only one vehicle can be in the bed.') end
   found=v
  end
 end
 if not found then return say(false,'Place a car inside the crusher bed first.') end
 if IsEntityAttached(found) then return say(false,'Release the vehicle from the forklift first.') end
 if occupied(found) then return say(false,'Everyone must leave the vehicle first.') end
 local mn,mx=GetModelDimensions(GetEntityModel(found))
 if mx.y-mn.y>7.0 or mx.x-mn.x>2.8 then return say(false,'This vehicle is too large for the press.') end
 if not NetworkGetEntityIsNetworked(found) then return say(false,'This vehicle is not networked.') end
 local confirm=lib.alertDialog({header='Crush this vehicle?',content='This permanently removes the vehicle from the world and recycles it into materials. Check the bed is clear.',centered=true,cancel=true,labels={confirm='Start crusher',cancel='Cancel'}})
 if confirm~='confirm' then return end
 local ok,msg=lib.callback.await('wonkycrusher:start',false,NetworkGetNetworkIdFromEntity(found));say(ok,msg)
end
local function sync(state)
 if cycle and NetworkDoesEntityExistWithNetworkId(cycle.net) then
  local v=NetToVeh(cycle.net)
  if v~=0 and DoesEntityExist(v) and NetworkHasControlOfEntity(v) then FreezeEntityPosition(v,false);SetVehicleDoorsLocked(v,1) end
 end
 cycle=state or nil;cycleStart=GetGameTimer()-(state and state.elapsed or 0);lastDamage=0;lastFx=0
 SendNUIMessage({action='stop'})
 if cycle then SendNUIMessage({action='start',elapsed=cycle.elapsed/1000}) end
end
RegisterNetEvent('wonkycrusher:sync',sync)
CreateThread(function()
 local hash=joaat(Config.PanelModel)
 if IsModelInCdimage(hash) and IsModelValid(hash) then
  RequestModel(hash);local deadline=GetGameTimer()+8000
  while not HasModelLoaded(hash) and GetGameTimer()<deadline do Wait(50) end
  if HasModelLoaded(hash) then
   local mn=GetModelDimensions(hash)
   panel=CreateObjectNoOffset(hash,Config.Panel.x,Config.Panel.y,Config.Panel.z+Config.PanelGroundOffset+(Config.PanelMountHeight or 0)-mn.z,false,false,false)
   if panel~=0 then SetEntityHeading(panel,Config.Panel.w);FreezeEntityPosition(panel,true);SetEntityCollision(panel,true,true) end
   SetModelAsNoLongerNeeded(hash)
  end
 end
 zone=exports.ox_target:addBoxZone({coords=vec3(Config.Panel.x,Config.Panel.y,Config.Panel.z),size=vec3(1.8,1.8,2.5),rotation=Config.Panel.w,options={
  {name='wonkycrusher_start',label='Start vehicle crusher',icon='fa-solid fa-gears',distance=2.5,onSelect=operate},
  {name='wonkycrusher_collect',label='Collect recycled materials',icon='fa-solid fa-recycle',distance=2.5,onSelect=function() local ok,msg=lib.callback.await('wonkycrusher:collect',false);say(ok,msg) end}
 }})
 local ok,state=pcall(function() return lib.callback.await('wonkycrusher:state',false) end)
 if ok then sync(state) end
 RequestNamedPtfxAsset('core')
end)
CreateThread(function()
 while true do
  local sleep=750;local distance=#(GetEntityCoords(PlayerPedId())-CrusherCenter())
  if distance<100 then
   sleep=0
   local elapsed=cycle and GetGameTimer()-cycleStart or 0
   if cycle and elapsed>3500 and elapsed<Config.CrushAt then
    local v=NetworkDoesEntityExistWithNetworkId(cycle.net) and NetToVeh(cycle.net) or 0
    if v~=0 and DoesEntityExist(v) and not occupied(v) then
     SetVehicleDoorsLocked(v,2)
     if NetworkHasControlOfEntity(v) then
      FreezeEntityPosition(v,true);SetVehicleEngineOn(v,false,true,true)
      if GetGameTimer()-lastDamage>650 then
       lastDamage=GetGameTimer()
       CrusherApplyDamage(v,elapsed)
      end
     end
    end
    if HasNamedPtfxAssetLoaded('core') and GetGameTimer()-lastFx>500 then
     lastFx=GetGameTimer();UseParticleFxAssetNextCall('core')
     local c=CrusherCenter()
     local a=math.rad(Config.Bed.w)
     local x=math.random()*5-2.5
     local p=vec3(c.x+x*math.cos(a),c.y+x*math.sin(a),c.z+0.4)
     StartParticleFxNonLoopedAtCoord('ent_brk_metal_frag',p.x,p.y,p.z,0.0,0.0,0.0,0.5,false,false,false)
    end
   end
  end
  Wait(sleep)
 end
end)
CreateThread(function()
 while true do
  Wait(200)
  local d=#(GetEntityCoords(PlayerPedId())-CrusherCenter())
  local volume=cycle and math.max(0,1-d/Config.SoundRange)*0.65 or 0
  SendNUIMessage({action='volume',volume=volume})
 end
end)
RegisterCommand('crushercoords',function()
 local p=GetEntityCoords(PlayerPedId());print(('Crusher: vector4(%.2f, %.2f, %.2f, %.2f)'):format(p.x,p.y,p.z,GetEntityHeading(PlayerPedId())))
end,false)
AddEventHandler('onResourceStop',function(r)
 if r~=GetCurrentResourceName() then return end
 if zone then exports.ox_target:removeZone(zone) end
 if panel and DoesEntityExist(panel) then DeleteEntity(panel) end
 SendNUIMessage({action='stop'})
end)
