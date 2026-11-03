local cfg=Config.ForkliftGarage
local zones={}
local working=false
local function action(which)
 if working then return end
 working=true
 local success,ok,msg,net=pcall(lib.callback.await,'wonkyyard:forkliftGarage',false,which)
 working=false
 lib.notify({title='Wonky Yard Forklift',description=success and msg or 'Request failed; check server console.',type=success and ok and 'success'or'error'})
 if success and ok and net then
  local deadline=GetGameTimer()+8000
  while not NetworkDoesEntityExistWithNetworkId(net)and GetGameTimer()<deadline do Wait(100)end
  if NetworkDoesEntityExistWithNetworkId(net)then
   local v=NetToVeh(net)
   if v~=0 then SetVehicleFuelLevel(v,100.0);SetVehicleDoorsLocked(v,1)end
  end
 end
end
CreateThread(function()
 local c=cfg.collection
 zones[#zones+1]=exports.ox_target:addBoxZone({coords=vec3(c.x,c.y,c.z),size=vec3(2,2,2.5),rotation=c.w,options={
  {name='wonkyyard_fork_collect',label='Collect yard forklift',icon='fa-solid fa-truck-ramp-box',distance=3,onSelect=function()action('spawn')end},
  {name='wonkyyard_fork_return',label='Return yard forklift',icon='fa-solid fa-square-parking',distance=3,onSelect=function()action('store')end}
 }})
 local p=cfg.parking
 zones[#zones+1]=exports.ox_target:addBoxZone({coords=vec3(p.x,p.y,p.z),size=vec3(4,4,3),rotation=p.w,options={
  {name='wonkyyard_fork_store_bay',label='Return yard forklift (exit and unload first)',icon='fa-solid fa-square-parking',distance=4,onSelect=function()action('store')end}
 }})
end)
AddEventHandler('onResourceStop',function(r)
 if r==GetCurrentResourceName()then for _,id in ipairs(zones)do exports.ox_target:removeZone(id)end end
end)
