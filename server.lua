local active, locked = nil, false
local claimLocks, rate = {}, {}
local function player(src) return exports.qbx_core:GetPlayer(src) end
local function allowed(src)
 local p = player(src)
 return p and p.PlayerData and p.PlayerData.job and Config.Jobs[p.PlayerData.job.name] == true
end
local function atPanel(src)
 local ped = GetPlayerPed(src)
 return ped ~= 0 and GetPlayerRoutingBucket(src) == 0 and #(GetEntityCoords(ped) - vec3(Config.Panel.x,Config.Panel.y,Config.Panel.z)) <= Config.ControlDistance + 1.0
end
local function notify(src, text, kind)
 TriggerClientEvent('ox_lib:notify',src,{title='Wonky Vehicle Recycling',description=text,type=kind or 'inform'})
end
local function occupied(veh)
 for _,ped in ipairs(GetAllPeds()) do if GetVehiclePedIsIn(ped,false) == veh then return true end end
 return false
end
local function snapshot()
 if not active then return false end
 return {net=active.net,elapsed=GetGameTimer()-active.start}
end
local function stopCycle(text)
 if active and DoesEntityExist(active.entity) then
  FreezeEntityPosition(active.entity,false)
  Entity(active.entity).state:set('wonkyCrushing',false,true)
 end
 if active and text then notify(active.src,text,'error') end
 active=nil;locked=false
 TriggerClientEvent('wonkycrusher:sync',-1,false)
end
local function key(cid) return 'materials:'..cid end
local function pending(cid) return json.decode(GetResourceKvpString(key(cid)) or '[]') or {} end
local function store(cid,items) SetResourceKvp(key(cid),json.encode(items)) end
lib.callback.register('wonkycrusher:state',function() return snapshot() end)
lib.callback.register('wonkycrusher:start',function(src,net)
 if not allowed(src) or not atPanel(src) then return false,'Use the control panel as a mechanic or tow operator.' end
 if rate[src] and GetGameTimer()-rate[src]<2000 then return false,'Please wait.' end
 rate[src]=GetGameTimer()
 if locked then return false,'The crusher is busy.' end
 if YardBedBlocked and YardBedBlocked() then return false,'Remove the scrap bale from the bed before crushing another vehicle.' end
 if type(net)~='number' or net%1~=0 or net<=0 then return false,'Invalid vehicle.' end
 local veh=NetworkGetEntityFromNetworkId(net)
 if veh==0 or not DoesEntityExist(veh) or GetEntityType(veh)~=2 or GetEntityRoutingBucket(veh)~=0 or not CrusherInside(GetEntityCoords(veh)) then return false,'Place the vehicle in the crusher bed first.' end
 if GetVehicleType(veh)~='automobile' and GetVehicleType(veh)~='bike' and GetVehicleType(veh)~='quadbike' then return false,'Only road vehicles fit this crusher.' end
 if occupied(veh) then return false,'Everyone must exit the vehicle first.' end
 if YardCanCrushVehicle and not YardCanCrushVehicle(veh) then return false,'Finish stripping this vehicle first.' end
 locked=true
 local plate=GetVehicleNumberPlateText(veh)
 if Config.BlockOwnedVehicles then
  local normalizedPlate = (plate or ''):upper():gsub('%s', '')
  local ok,owned=pcall(function() return MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE REPLACE(UPPER(plate), \' \', \'\') = ? LIMIT 1',{normalizedPlate}) end)
  if not ok then
   print(('[Wonkys_VehicleCrusher] Ownership lookup failed: %s'):format(tostring(owned)))
   locked=false;return false,'Vehicle ownership check failed; see server console for details.'
  end
  if owned then locked=false;return false,'Registered player vehicles cannot be crushed.' end
 end
 -- Recheck after the database yield and before reserving the entity.
 if not allowed(src) or not atPanel(src) or not DoesEntityExist(veh) or not CrusherInside(GetEntityCoords(veh)) or occupied(veh) then locked=false;return false,'Vehicle or operator moved; try again.' end
 if YardCanCrushVehicle and not YardCanCrushVehicle(veh)then locked=false;return false,'Finish stripping this vehicle first.'end
 local p=player(src)
 local rewards={}
 for _,item in ipairs(Config.Rewards) do
  if not exports.ox_inventory:Items(item.name) then locked=false;return false,'Missing inventory item: '..item.name end
  rewards[#rewards+1]={name=item.name,count=math.random(item.min,item.max)}
 end
 active={src=src,cid=p.PlayerData.citizenid,entity=veh,net=net,start=GetGameTimer(),rewards=rewards,model=GetEntityModel(veh),plate=plate}
 Entity(veh).state:set('wonkyCrushing',true,true)
 FreezeEntityPosition(veh,true)
 TriggerClientEvent('wonkycrusher:sync',-1,snapshot())
 return true,'Crushing started. Keep clear of the bed.'
end)
lib.callback.register('wonkycrusher:collect',function(src)
 if not allowed(src) or not atPanel(src) then return false,'Use the control panel.' end
 local p=player(src);local cid=p.PlayerData.citizenid
 if claimLocks[cid] then return false,'Collection already in progress.' end
 claimLocks[cid]=true
 local items=pending(cid);local remaining={};local count=0
 for _,item in ipairs(items) do
  local carried=exports.ox_inventory:CanCarryItem(src,item.name,item.count)
  local ok=carried and exports.ox_inventory:AddItem(src,item.name,item.count)
  if ok then count=count+item.count else remaining[#remaining+1]=item end
 end
 store(cid,remaining);claimLocks[cid]=nil
 if #remaining>0 then return count>0,('Collected %d materials; make inventory space and collect the rest.'):format(count) end
 return count>0,count>0 and ('Collected %d materials.'):format(count) or 'No materials are waiting for you.'
end)
CreateThread(function()
 while true do
  Wait(250)
  if active then
   local a=active;local elapsed=GetGameTimer()-a.start
   if not a.deleted then
    local v=a.entity
    if not a.deletionRequested and (not DoesEntityExist(v) or GetEntityModel(v)~=a.model or GetVehicleNumberPlateText(v)~=a.plate or not CrusherInside(GetEntityCoords(v))) then stopCycle('Crushing stopped: vehicle is no longer in the bed.')
    elseif not a.deletionRequested and occupied(v) then stopCycle('Crushing stopped: someone entered the vehicle.')
    elseif not a.deletionRequested and elapsed>=Config.CrushAt then
     DeleteEntity(v)
     -- Rewards are issued only after server-side deletion is confirmed.
     a.deletionRequested=true
    end
    if active==a and a.deletionRequested then
     if not DoesEntityExist(v) then
      a.deleted=true
      if YardOnCrushed then
       YardOnCrushed(a)
       if player(a.src) and player(a.src).PlayerData.citizenid==a.cid then notify(a.src,'Vehicle recycled. Remove the scrap bale with a forklift and take it to sorting.','success') end
      else
       local items=pending(a.cid)
       for _,item in ipairs(a.rewards) do items[#items+1]=item end
       store(a.cid,items)
       if player(a.src) and player(a.src).PlayerData.citizenid==a.cid then notify(a.src,'Vehicle recycled. Collect materials at the control panel.','success') end
      end
     elseif elapsed>Config.CrushAt+2000 then stopCycle('Vehicle could not be removed; no rewards issued.') end
    end
   end
   if active==a and elapsed>=Config.Duration then stopCycle() end
  end
 end
end)
AddEventHandler('playerDropped',function() rate[source]=nil end)
AddEventHandler('onResourceStop',function(name) if name==GetCurrentResourceName() then stopCycle() end end)

lib.callback.register('wonkycrusher:emergencyStop',function(src)
 if not allowed(src) or not atPanel(src) then return false,'Use the control panel as a mechanic or tow operator.' end
 if not active then return false,'The crusher is already stopped.' end
 stopCycle('Emergency stop activated. The head is returning to its raised position.')
 return true,'Crusher stopped. Damage already applied cannot be reversed.'
end)
