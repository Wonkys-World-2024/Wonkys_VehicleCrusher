local cfg=Config.ForkliftGarage
local issued,busy={},{}
local function authorized(src)
 local p=exports.qbx_core:GetPlayer(src)
 if p and p.PlayerData.job and Config.Jobs[p.PlayerData.job.name]and GetPlayerRoutingBucket(src)==0 then return p.PlayerData.citizenid end
end
local function near(src,p,r)
 local ped=GetPlayerPed(src);return ped~=0 and #(GetEntityCoords(ped)-vec3(p.x,p.y,p.z))<r
end
local function occupied(v)
 for _,p in ipairs(GetAllPeds())do if GetVehiclePedIsIn(p,false)==v then return true end end
 return false
end
lib.callback.register('wonkyyard:forkliftGarage',function(src,action)
 local cid=authorized(src)
 if not cid then return false,'Mechanic or tow access required.'end
 if busy[cid]then return false,'Please wait.'end
 if action=='spawn'then
  if not near(src,cfg.collection,4)then return false,'Use the forklift collection point.'end
  local old=issued[cid]
  if old and DoesEntityExist(old)then return false,'Return your current yard forklift first.'end
  local p=cfg.parking
  for _,v in ipairs(GetAllVehicles())do if #(GetEntityCoords(v)-vec3(p.x,p.y,p.z))<3 then return false,'Clear the forklift parking bay first.'end end
  if GetResourceState('qbx_vehiclekeys')~='started'then return false,'Vehicle keys resource is unavailable.'end
  busy[cid]=true
  local v=CreateVehicleServerSetter(joaat(cfg.model),'automobile',p.x,p.y,p.z,p.w)
  if v==0 then busy[cid]=nil;return false,'Forklift could not spawn.'end
  SetEntityRoutingBucket(v,0);issued[cid]=v
  local ok,err=pcall(function()exports.qbx_vehiclekeys:GiveKeys(src,v,true)end)
  busy[cid]=nil
  if not ok then issued[cid]=nil;DeleteEntity(v);print('[Wonky Forklift] Keys failed: '..tostring(err));return false,'Could not issue forklift keys.'end
  return true,'Forklift ready in the parking bay.',NetworkGetNetworkIdFromEntity(v)
 elseif action=='store'then
  if not near(src,cfg.collection,4)and not near(src,cfg.parking,5)then return false,'Use the forklift return point.'end
  local v=issued[cid]
  if not v or not DoesEntityExist(v)then issued[cid]=nil;return false,'You have no issued yard forklift.'end
  if #(GetEntityCoords(v)-vec3(cfg.parking.x,cfg.parking.y,cfg.parking.z))>4 then return false,'Park your forklift in the return bay first.'end
  if occupied(v)then return false,'Exit the forklift before returning it.'end
  local net=NetworkGetNetworkIdFromEntity(v)
  if Entity(v).state.wonkyForkCargo or (YardForkHasLoad and YardForkHasLoad(net))then return false,'Unload the forks before returning it.'end
  DeleteEntity(v)
  if DoesEntityExist(v)then return false,'Forklift return is pending; try again.'end
  issued[cid]=nil;return true,'Yard forklift returned.'
 end
 return false,'Invalid operation.'
end)
AddEventHandler('onResourceStop',function(r)
 if r~=GetCurrentResourceName()then return end
 for _,v in pairs(issued)do
  if DoesEntityExist(v)and not occupied(v)and not Entity(v).state.wonkyForkCargo and not (YardForkHasLoad and YardForkHasLoad(NetworkGetNetworkIdFromEntity(v)))then DeleteEntity(v)end
 end
end)
