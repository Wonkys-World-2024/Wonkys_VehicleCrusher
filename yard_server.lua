local cfg=Config.Yard
if not cfg.enabled then return end
local state=json.decode(GetResourceKvpString('yard:state:v1') or '{}') or {}
state.bales=state.bales or {};state.bins=state.bins or {};state.stripRewards=state.stripRewards or {};state.serial=state.serial or 0
local strip,deliveries={},{}
local deliveryNext=0
local function persist() SetResourceKvp('yard:state:v1',json.encode(state)) end
local function player(src)return exports.qbx_core:GetPlayer(src)end
local function allowed(src)
 local p=player(src);return p and p.PlayerData.job and Config.Jobs[p.PlayerData.job.name] and GetPlayerRoutingBucket(src)==0
end
local function near(src,pos,dist)
 local p=GetPlayerPed(src);return p~=0 and #(GetEntityCoords(p)-pos)<dist
end
local function occupied(v)
 for _,p in ipairs(GetAllPeds())do if GetVehiclePedIsIn(p,false)==v then return true end end
 return false
end
local function playerOccupied(v)
 for _,id in ipairs(GetPlayers())do local ped=GetPlayerPed(tonumber(id));if ped~=0 and GetVehiclePedIsIn(ped,false)==v then return true end end
 return false
end
local function owned(v)
 if not Config.BlockOwnedVehicles then return false end
 local plate=(GetVehicleNumberPlateText(v) or ''):upper():gsub('%s','')
 local ok,res=pcall(function()return MySQL.scalar.await("SELECT 1 FROM player_vehicles WHERE REPLACE(UPPER(plate),' ','')=? LIMIT 1",{plate})end)
 return not ok or res~=nil and res~=false
end
local function position(b)
 if b.carrier then
  local e=NetworkGetEntityFromNetworkId(b.carrier)
  if e~=0 and DoesEntityExist(e)then return GetEntityCoords(e)end
 end
 return vec3(b.x,b.y,b.z)
end
local function publish() TriggerClientEvent('wonkyyard:state',-1,state.bales,state.bins) end
-- Loads cannot survive a server/resource restart; recover them at the sorting area.
for _,b in pairs(state.bales)do if b.carrier then b.carrier=nil;b.kind=nil;b.x=cfg.sorting.x;b.y=cfg.sorting.y;b.z=cfg.sorting.z end end
persist()
function YardCanCrushVehicle(v) return not (strip[v] and strip[v].busy) end
function YardForkHasLoad(net) for _,b in pairs(state.bales)do if b.carrier==net and b.kind=='fork'then return true end end;return false end
function YardBedBlocked()
 for _,b in pairs(state.bales)do if not b.carrier and #(position(b)-CrusherCenter())<4 then return true end end
 return false
end
function YardOnCrushed(a)
 state.serial=state.serial+1;local c=CrusherCenter();local id=tostring(state.serial)
 state.bales[id]={id=id,cid=a.cid,rewards=a.rewards,x=c.x,y=c.y,z=cfg.baleGroundZ}
 persist();publish();return true
end
lib.callback.register('wonkyyard:state',function() return state.bales,state.bins end)
lib.callback.register('wonkyyard:stripStart',function(src,net,part)
 if not allowed(src) or not near(src,cfg.center,cfg.radius) or not cfg.parts[part]then return false,'Not available here.'end
 local v=type(net)=='number' and NetworkGetEntityFromNetworkId(net) or 0
 if v==0 or not DoesEntityExist(v) or not near(src,GetEntityCoords(v),5) or occupied(v) or Entity(v).state.wonkyCrushing then return false,'Use an empty vehicle nearby.'end
 local typ=GetVehicleType(v);if typ~='automobile' and typ~='bike' and typ~='quadbike'then return false,'Road vehicles only.'end
 if cfg.toolItem and exports.ox_inventory:GetItemCount(src,cfg.toolItem)<1 then return false,'You need a repair kit (not consumed).'end
 if owned(v)then return false,'Registered vehicle or ownership check failed.'end
 if not DoesEntityExist(v)or occupied(v)or Entity(v).state.wonkyCrushing then return false,'Vehicle is no longer available.'end
 local rec=strip[v]
 if not rec or rec.model~=GetEntityModel(v)or rec.plate~=GetVehicleNumberPlateText(v)then rec={model=GetEntityModel(v),plate=GetVehicleNumberPlateText(v),parts={}};strip[v]=rec end
 if rec.parts[part] or rec.busy then return false,'Already stripped or someone is working on it.'end
 rec.busy={src=src,part=part,start=GetGameTimer()};return true
end)
lib.callback.register('wonkyyard:stripFinish',function(src,net,part,cancel)
 local v=type(net)=='number' and NetworkGetEntityFromNetworkId(net)or 0;local rec=strip[v]
 if not rec or not rec.busy or rec.busy.src~=src or rec.busy.part~=part then return false,'No active stripping task.'end
 local ticket=rec.busy;rec.busy=nil
 if cancel then return false,'Cancelled.'end
 if GetGameTimer()-ticket.start<cfg.stripDuration-250 or not allowed(src)or not DoesEntityExist(v)or not near(src,GetEntityCoords(v),5)or occupied(v)or Entity(v).state.wonkyCrushing then return false,'Task interrupted.'end
 if rec.model~=GetEntityModel(v)or rec.plate~=GetVehicleNumberPlateText(v)or owned(v)then return false,'Vehicle changed or ownership check failed.'end
 if rec.parts[part]then return false,'Already stripped.'end
 rec.parts[part]=true
 local cid=player(src).PlayerData.citizenid;state.stripRewards[cid]=state.stripRewards[cid]or{}
 for _,r in ipairs(cfg.parts[part].rewards)do state.stripRewards[cid][#state.stripRewards[cid]+1]={name=r.name,count=r.count}end
 persist();TriggerClientEvent('wonkyyard:stripped',-1,net,part)
 return true,'Part stripped. Collect bonus materials at the control panel.'
end)
lib.callback.register('wonkyyard:stripCollect',function(src)
 if not allowed(src)or not near(src,vec3(Config.Panel.x,Config.Panel.y,Config.Panel.z),4)then return false,'Use the control panel.'end
 local cid=player(src).PlayerData.citizenid;local left={};local total=0
 for _,r in ipairs(state.stripRewards[cid]or{})do
  if exports.ox_inventory:CanCarryItem(src,r.name,r.count)and exports.ox_inventory:AddItem(src,r.name,r.count)then total=total+r.count else left[#left+1]=r end
 end
 state.stripRewards[cid]=left;persist();return total>0,('Collected %d stripping materials; any remainder stays available.'):format(total)
end)
lib.callback.register('wonkyyard:baleFork',function(src,forkNet,id)
 local f=type(forkNet)=='number'and NetworkGetEntityFromNetworkId(forkNet)or 0
 if not allowed(src)or f==0 or not DoesEntityExist(f)or GetPedInVehicleSeat(f,-1)~=GetPlayerPed(src)then return false,'Drive the forklift.'end
 local valid=false;for model in pairs(Config.Forklift.models)do if GetEntityModel(f)==joaat(model)then valid=true end end
 if not valid or Entity(f).state.wonkyForkCargo then return false,'Forklift is not available.'end
 for _,b in pairs(state.bales)do
  if b.carrier==forkNet and b.kind=='fork'then
   local p=GetEntityCoords(f);local h=math.rad(GetEntityHeading(f));b.x=p.x-math.sin(h)*2;b.y=p.y+math.cos(h)*2;b.z=p.z-0.5;b.carrier=nil;b.kind=nil
   persist();publish();return true,'Bale released.'
  end
 end
 local b=state.bales[tostring(id)]
 if not b or b.carrier or #(position(b)-GetEntityCoords(f))>6 then return false,'Move the forks closer to a loose bale.'end
 b.carrier=forkNet;b.kind='fork';persist();publish();return true,'Scrap bale secured to the forks.'
end)
lib.callback.register('wonkyyard:baleSort',function(src,id)
 local b=state.bales[tostring(id)]
 if not allowed(src)or not b or b.carrier or not near(src,cfg.sorting,5)or #(position(b)-cfg.sorting)>5 then return false,'Release the bale in the sorting area first.'end
 for _,r in ipairs(b.rewards)do state.bins[r.name]=(state.bins[r.name]or 0)+r.count end
 state.bales[tostring(id)]=nil;persist();publish();return true,'Bale sorted. Withdraw materials from the labelled bins.'
end)
lib.callback.register('wonkyyard:bin',function(src,index,action,count)
 local bin=cfg.bins[index]
 if not allowed(src)or not bin or not near(src,bin.pos,4)or type(count)~='number'or count%1~=0 or count<1 or count>1000 then return false,'Invalid bin request.'end
 local item=bin.item;local stock=state.bins[item]or 0
 if action=='deposit'then
  if not exports.ox_inventory:RemoveItem(src,item,count)then return false,'You do not have enough material.'end
  state.bins[item]=stock+count
 elseif action=='withdraw'then
  if stock<count then return false,'Not enough material in this bin.'end
  if not exports.ox_inventory:CanCarryItem(src,item,count)then return false,'Make inventory space first.'end
  if not exports.ox_inventory:AddItem(src,item,count)then return false,'Could not add material.'end
  state.bins[item]=stock-count
 else return false,'Unknown operation.'end
 persist();publish();return true,('Bin now contains %d %s.'):format(state.bins[item],bin.label)
end)
lib.callback.register('wonkyyard:baleTrailer',function(src,id,trailerNet,unload)
 local b=state.bales[tostring(id)];local tr=type(trailerNet)=='number'and NetworkGetEntityFromNetworkId(trailerNet)or 0
 if not allowed(src)or not b or tr==0 or not DoesEntityExist(tr)or GetEntityType(tr)~=2 or GetVehicleType(tr)~='trailer'or not near(src,GetEntityCoords(tr),8)then return false,'Use a nearby trailer.'end
 if unload then
  if b.carrier~=trailerNet or b.kind~='trailer'then return false,'Not loaded on this trailer.'end
  local p=GetEntityCoords(tr);b.x=p.x+3;b.y=p.y;b.z=p.z;b.carrier=nil;b.kind=nil
 else
  if b.carrier or #(position(b)-GetEntityCoords(tr))>7 then return false,'Release the bale beside the trailer first.'end
  local count=0;for _,other in pairs(state.bales)do if other.carrier==trailerNet then count=count+1 end end
  if count>=4 then return false,'Four-bale limit reached.'end
  local slots={};for _,other in pairs(state.bales)do if other.carrier==trailerNet then slots[other.slot or 0]=true end end
  local slot=0;while slots[slot]do slot=slot+1 end
  b.carrier=trailerNet;b.kind='trailer';b.slot=slot
 end
 persist();publish();return true,unload and 'Bale unloaded beside trailer.'or'Bale secured on trailer.'
end)
lib.callback.register('wonkyyard:delivery',function(src)
 if not allowed(src)or not near(src,vec3(Config.Panel.x,Config.Panel.y,Config.Panel.z),4)then return false,'Use the control panel.'end
 if next(deliveries)or GetGameTimer()<deliveryNext then return false,'A delivery is active or the supplier is on cooldown.'end
 for _,v in ipairs(GetAllVehicles())do if #(GetEntityCoords(v)-vec3(cfg.deliveryBay.x,cfg.deliveryBay.y,cfg.deliveryBay.z))<6 then return false,'Clear the delivery bay first.'end end
 deliveryNext=GetGameTimer()+cfg.deliveryCooldown
 local s=cfg.deliverySpawn;local model=cfg.deliveryModels[math.random(#cfg.deliveryModels)]
 local v=CreateVehicleServerSetter(joaat(model),'automobile',s.x,s.y,s.z,s.w)
 if v==0 then return false,'Delivery vehicle could not spawn.'end
 local ped=CreatePed(4,joaat('a_m_m_business_01'),s.x,s.y,s.z,s.w,true,true)
 if ped==0 then DeleteEntity(v);return false,'Customer could not spawn.'end
 SetEntityRoutingBucket(v,0);SetEntityRoutingBucket(ped,0)
 deliveries[v]={ped=ped,src=src,start=GetGameTimer()}
 TriggerClientEvent('wonkyyard:driveDelivery',src,NetworkGetNetworkIdFromEntity(v),NetworkGetNetworkIdFromEntity(ped))
 return true,'Customer is bringing a scrap vehicle to the delivery bay.'
end)
lib.callback.register('wonkyyard:deliveryArrived',function(src,net)
 local v=type(net)=='number'and NetworkGetEntityFromNetworkId(net)or 0;local d=deliveries[v]
 if not d or d.src~=src or not allowed(src)or not DoesEntityExist(v)or #(GetEntityCoords(v)-vec3(cfg.deliveryBay.x,cfg.deliveryBay.y,cfg.deliveryBay.z))>8 then return false end
 d.arrived=true;d.arrivalTime=GetGameTimer();return true
end)
CreateThread(function()
 while true do
  Wait(1000)
  for v,d in pairs(deliveries)do
   if d.arrived and DoesEntityExist(v)and not occupied(v)then
    deliveries[v]=nil
    if DoesEntityExist(d.ped)then DeleteEntity(d.ped)end
    local p=player(d.src);if p and GetResourceState('qbx_vehiclekeys')=='started'then pcall(function()exports.qbx_vehiclekeys:GiveKeys(d.src,v,true)end)end
   elseif not DoesEntityExist(v)or GetGameTimer()-d.start>180000 then
    if DoesEntityExist(v)and not playerOccupied(v)then DeleteEntity(v)end;if DoesEntityExist(d.ped)then DeleteEntity(d.ped)end;deliveries[v]=nil
   end
  end
  for v,r in pairs(strip)do if not DoesEntityExist(v)then strip[v]=nil elseif r.busy and GetGameTimer()-r.busy.start>cfg.stripDuration+15000 then r.busy=nil end end
  local dirty=false
  for _,b in pairs(state.bales)do
   if b.carrier then local e=NetworkGetEntityFromNetworkId(b.carrier)
    if e==0 or not DoesEntityExist(e)then b.carrier=nil;b.kind=nil;b.x=cfg.sorting.x;b.y=cfg.sorting.y;b.z=cfg.sorting.z;dirty=true
    else local p=GetEntityCoords(e);b.x=p.x;b.y=p.y;b.z=p.z end
   end
  end
  if dirty then persist();publish()end
 end
end)
AddEventHandler('onResourceStop',function(r)
 if r~=GetCurrentResourceName()then return end
 for v,d in pairs(deliveries)do if DoesEntityExist(v)and not playerOccupied(v)then DeleteEntity(v)end;if DoesEntityExist(d.ped)then DeleteEntity(d.ped)end end
 persist()
end)
