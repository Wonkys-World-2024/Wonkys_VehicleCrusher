local attached, busy = {}, false
local function notify(ok,msg) lib.notify({title='Wonky Forklift',description=msg,type=ok and 'success' or 'error'}) end
local function forklift(v)
 if v==0 then return false end
 for model in pairs(Config.Forklift.models) do if GetEntityModel(v)==joaat(model) then return true end end
 return false
end
local function bone(v)
 for _,name in ipairs(Config.Forklift.boneNames) do local b=GetEntityBoneIndexByName(v,name);if b~=-1 then return b end end
 local count=GetEntityBoneCount(v)
 return Config.Forklift.fallbackBone<count and Config.Forklift.fallbackBone or -1
end
local function control(v)
 local limit=GetGameTimer()+2000
 while DoesEntityExist(v) and not NetworkHasControlOfEntity(v) and GetGameTimer()<limit do NetworkRequestControlOfEntity(v);Wait(0) end
 return DoesEntityExist(v) and NetworkHasControlOfEntity(v)
end
local function release(net)
 if NetworkDoesEntityExistWithNetworkId(net) then
  local v=NetToVeh(net)
  if v~=0 and DoesEntityExist(v) and NetworkHasControlOfEntity(v) then DetachEntity(v,true,true);SetEntityCollision(v,true,true);ActivatePhysics(v) end
 end
 attached[net]=nil
end
RegisterNetEvent('wonkycrusher:forkRelease',release)
RegisterCommand('wonkyfork',function()
 if busy then return end
 local ped=PlayerPedId();local fork=GetVehiclePedIsIn(ped,false)
 if not forklift(fork) or GetPedInVehicleSeat(fork,-1)~=ped then return notify(false,'You must be driving a forklift.') end
 if not Entity(fork).state.wonkyForkCargo and YardTryForkBale and YardTryForkBale(fork) then return end
 busy=true
 local cargo
 if not Entity(fork).state.wonkyForkCargo then
  local b=bone(fork)
  if b<0 then busy=false;return notify(false,'Moving fork bone not found. Use /forkdebug and send the F8 result.') end
  local tip=GetWorldPositionOfEntityBone(fork,b);local closest=Config.Forklift.pickupDistance
  for _,v in ipairs(GetGamePool('CVehicle')) do
   if v~=fork and not IsEntityAttached(v) then
    local pos=GetEntityCoords(v);local off=GetOffsetFromEntityGivenWorldCoords(fork,pos.x,pos.y,pos.z);local dist=#(pos-tip)
    if off.y>0.3 and dist<closest then cargo=v;closest=dist end
   end
  end
  if not cargo then busy=false;return notify(false,'Position the forks underneath the vehicle, then press G.') end
  local mn,mx=GetModelDimensions(GetEntityModel(cargo));local f=Config.Forklift
  if mx.y-mn.y>f.maxLength or mx.x-mn.x>f.maxWidth or mx.z-mn.z>f.maxHeight then busy=false;return notify(false,'Vehicle exceeds this forklift’s configured size limits.') end
  if not NetworkGetEntityIsNetworked(cargo) or not control(cargo) then busy=false;return notify(false,'Unable to take control of the load vehicle. Try again nearby.') end
 end
 local success,ok,msg=pcall(function()return lib.callback.await('wonkycrusher:forklift',false,VehToNet(fork),cargo and VehToNet(cargo) or nil)end)
 busy=false
 if success then notify(ok,msg) else notify(false,'Forklift request failed; check F8/server console.') end
end,false)
RegisterKeyMapping('wonkyfork','Wonky forklift: secure / release vehicle','keyboard','G')
CreateThread(function()
 while true do
  Wait(500)
  local seen={}
  for _,fork in ipairs(GetGamePool('CVehicle')) do
   if forklift(fork) then
    local load=Entity(fork).state.wonkyForkCargo
    if load and NetworkDoesEntityExistWithNetworkId(load.net) then
     local cargo=NetToVeh(load.net);seen[load.net]=true
     if cargo~=0 and DoesEntityExist(cargo) and NetworkHasControlOfEntity(cargo) then
      local b=bone(fork)
      if b>=0 and not IsEntityAttachedToEntity(cargo,fork) then
       local mn=GetModelDimensions(GetEntityModel(cargo));local o,r=Config.Forklift.offset,Config.Forklift.rotation
       AttachEntityToEntity(cargo,fork,b,o.x,o.y,o.z-mn.z,r.x,r.y,r.z,false,false,false,false,2,true)
       SetVehicleEngineOn(cargo,false,true,true)
      end
      attached[load.net]=true
     end
    end
   end
  end
  for net in pairs(attached) do if not seen[net] then release(net) end end
 end
end)
RegisterCommand('forkdebug',function()
 local v=GetVehiclePedIsIn(PlayerPedId(),false)
 if not forklift(v) then return end
 print(('Wonky Forklift: boneCount=%d chosenBone=%d cargo=%s'):format(GetEntityBoneCount(v),bone(v),json.encode(Entity(v).state.wonkyForkCargo)))
end,false)
RegisterCommand('crusherscan',function()
 local c=CrusherCenter();local count=0
 for _,obj in ipairs(GetGamePool('CObject')) do
  if #(GetEntityCoords(obj)-c)<18.0 then
   local hash=GetEntityModel(obj)
   if hash==joaat('prop_ind_crusher') then
    count=count+1;local p=GetEntityCoords(obj);local mn,mx=GetModelDimensions(hash)
    print(('CRUSHER model=prop_ind_crusher entity=%d pos=%.3f,%.3f,%.3f heading=%.2f bones=%d size=%.2f,%.2f,%.2f'):format(obj,p.x,p.y,p.z,GetEntityHeading(obj),GetEntityBoneCount(obj),mx.x-mn.x,mx.y-mn.y,mx.z-mn.z))
   end
  end
 end
 print(('Crusher scan: %d matching objects. If zero, the visible press may be embedded in another map drawable.'):format(count))
 notify(true,'Crusher scan printed to F8. Send the CRUSHER lines for the original-head animation.')
end,false)
AddEventHandler('onResourceStop',function(r)if r==GetCurrentResourceName() then for net in pairs(attached) do release(net) end end end)
