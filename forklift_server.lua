local loads, reserved = {}, {}
local function permitted(src,fork)
 local p=exports.qbx_core:GetPlayer(src);local ped=GetPlayerPed(src)
 if not p or not p.PlayerData.job or not Config.Jobs[p.PlayerData.job.name] then return false end
 if ped==0 or not DoesEntityExist(fork) or GetPedInVehicleSeat(fork,-1)~=ped then return false end
 if GetPlayerRoutingBucket(src)~=GetEntityRoutingBucket(fork) then return false end
 for model in pairs(Config.Forklift.models) do if GetEntityModel(fork)==joaat(model) then return true end end
 return false
end
local function occupied(v)
 for _,p in ipairs(GetAllPeds()) do if GetVehiclePedIsIn(p,false)==v then return true end end
 return false
end
local function release(fork)
 local load=loads[fork];if not load then return end
 if DoesEntityExist(fork) then Entity(fork).state:set('wonkyForkCargo',false,true) end
 TriggerClientEvent('wonkycrusher:forkRelease',-1,load.net)
 reserved[load.entity]=nil;loads[fork]=nil
end
lib.callback.register('wonkycrusher:forklift',function(src,forkNet,cargoNet)
 if type(forkNet)~='number' then return false,'Invalid forklift.' end
 local fork=NetworkGetEntityFromNetworkId(forkNet)
 if fork==0 or not permitted(src,fork) then return false,'Operate a forklift as mechanic or tow.' end
 if loads[fork] then release(fork);return true,'Vehicle released. Lower the forks before reversing away.' end
 if YardForkHasLoad and YardForkHasLoad(forkNet) then return false,'Release the scrap bale first.' end
 if type(cargoNet)~='number' or cargoNet==forkNet then return false,'No suitable vehicle on the forks.' end
 local cargo=NetworkGetEntityFromNetworkId(cargoNet)
 if cargo==0 or not DoesEntityExist(cargo) or GetEntityType(cargo)~=2 then return false,'Invalid vehicle.' end
 if reserved[cargo] or Entity(cargo).state.wonkyCrushing then return false,'That vehicle is already in use.' end
 local typ=GetVehicleType(cargo)
 if typ~='automobile' and typ~='bike' and typ~='quadbike' then return false,'This type cannot be carried.' end
 if GetEntityRoutingBucket(cargo)~=GetEntityRoutingBucket(fork) or #(GetEntityCoords(cargo)-GetEntityCoords(fork))>Config.Forklift.pickupDistance+2.0 then return false,'Move the forks closer to the vehicle.' end
 if occupied(cargo) then return false,'Everyone must leave the load vehicle.' end
 local load={entity=cargo,net=cargoNet,src=src,forkNet=forkNet}
 loads[fork]=load;reserved[cargo]=fork
 Entity(fork).state:set('wonkyForkCargo',{net=cargoNet},true)
 return true,'Vehicle secured. Use the normal fork lift controls.'
end)
CreateThread(function()
 while true do
  Wait(1000)
  for fork,load in pairs(loads) do
   if not DoesEntityExist(fork) or not DoesEntityExist(load.entity) or occupied(load.entity) or GetEntityRoutingBucket(fork)~=GetEntityRoutingBucket(load.entity) then release(fork) end
  end
 end
end)
AddEventHandler('playerDropped',function()
 local src=source
 for fork,load in pairs(loads) do if load.src==src then release(fork) end end
end)
AddEventHandler('onResourceStop',function(r)
 if r~=GetCurrentResourceName() then return end
 for fork in pairs(loads) do release(fork) end
end)
