-- Called only by the network owner, at a throttled interval during an active cycle.
function CrusherApplyDamage(vehicle, elapsed)
 local progress=math.max(0,math.min(1,(elapsed-3500)/12500))
 SetEntityInvincible(vehicle,false)
 SetVehicleCanBreak(vehicle,true)
 SetVehicleCanBeVisiblyDamaged(vehicle,true)
 local mn,mx=GetModelDimensions(GetEntityModel(vehicle))
 for _,x in ipairs({mn.x*0.7,0.0,mx.x*0.7}) do
  for _,y in ipairs({mn.y*0.7,0.0,mx.y*0.7}) do
   SetVehicleDamage(vehicle,x,y,mx.z,170.0+progress*350.0,1.5,true)
  end
 end
 if elapsed>=4500 then
  for i=0,7 do if IsVehicleWindowIntact(vehicle,i) then SmashVehicleWindow(vehicle,i) end end
 end
 if elapsed>=6500 then
  SetVehicleTyresCanBurst(vehicle,true)
  for _,i in ipairs({0,1,4,5}) do if not IsVehicleTyreBurst(vehicle,i,false) then SetVehicleTyreBurst(vehicle,i,true,1000.0) end end
 end
 -- false keeps each broken door as falling debris rather than deleting it.
 for _,stage in ipairs({{8500,0},{9500,1},{10500,2},{11500,3},{12500,4},{13500,5}}) do
  local at,door=stage[1],stage[2]
  if elapsed>=at and GetIsDoorValid(vehicle,door) and not IsVehicleDoorDamaged(vehicle,door) then
   SetVehicleDoorCanBreak(vehicle,door,true)
   SetVehicleDoorOpen(vehicle,door,false,true)
   SetVehicleDoorBroken(vehicle,door,false)
  end
 end
 SetVehicleBodyHealth(vehicle,math.max(1.0,350.0-progress*349.0))
 SetVehicleUndriveable(vehicle,true)
end
