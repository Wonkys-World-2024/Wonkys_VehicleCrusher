local cfg=Config.Yard
if not cfg.enabled then return end
local bales,bins,objects,props,zones={},{},{},{},{}
local stripping=false
local alertLight
local function notify(ok,msg)lib.notify({title='Wonky Recycling Yard',description=msg,type=ok and 'success'or'error'})end
local function call(name,...)
 local success,ok,msg=pcall(lib.callback.await,name,false,...)
 if success then notify(ok,msg or (ok and 'Done.'or'Request failed.'))else notify(false,'Request failed; check F8 and server console.')end
end
local function model(name)
 local h=joaat(name)
 if not IsModelInCdimage(h)or not IsModelValid(h)then print('[Wonky Yard] Model unavailable: '..name);return end
 RequestModel(h);local deadline=GetGameTimer()+7000
 while not HasModelLoaded(h)and GetGameTimer()<deadline do Wait(50)end
 if HasModelLoaded(h)then return h end
end
local function prop(name,pos,heading,ground)
 local h=model(name);if not h then return end
 local mn=GetModelDimensions(h);local e=CreateObjectNoOffset(h,pos.x,pos.y,pos.z-(ground and mn.z or 0),false,false,false)
 if e~=0 then SetEntityHeading(e,heading or 0);FreezeEntityPosition(e,true);props[#props+1]=e end
 SetModelAsNoLongerNeeded(h);return e
end
-- A scrap load is one invisible attachment root plus all configured scrap pieces.
local function destroyLoad(load)
 for _,e in ipairs(load.pieces)do if DoesEntityExist(e)then DeleteEntity(e)end end
 if DoesEntityExist(load.root)then DeleteEntity(load.root)end
end
local function createLoad(b)
 local h=model(cfg.baleModel);if not h then return end
 local anchor=CreateObjectNoOffset(h,b.x,b.y,b.z,false,false,false)
 SetModelAsNoLongerNeeded(h)
 if anchor==0 then return end
 SetEntityVisible(anchor,false,false);SetEntityCollision(anchor,false,false);FreezeEntityPosition(anchor,true)
 local load={root=anchor,pieces={}}
 for i,name in ipairs(cfg.scrapModels or {cfg.baleModel})do
  local hash=model(name)
  if hash then
   local mn=GetModelDimensions(hash)
   local e=CreateObjectNoOffset(hash,b.x,b.y,b.z,false,false,false)
   SetModelAsNoLongerNeeded(hash)
   if e~=0 then
    SetEntityCollision(e,false,false);SetEntityAsMissionEntity(e,true,true)
    -- Fixed layout on every client; distribute all parts over a compact footprint.
    local x=((i-1)%5-2)*0.32
    local y=(math.floor((i-1)/5)-2)*0.30
    local z=-mn.z+((i-1)%3)*0.06
    AttachEntityToEntity(e,anchor,0,x,y,z,0,0,((i*137)%360),false,false,false,false,2,true)
    load.pieces[#load.pieces+1]=e
   end
  end
 end
 if #load.pieces==0 then destroyLoad(load);return end
 return load
end
RegisterNetEvent('wonkyyard:state',function(b,s)bales=b or{};bins=s or{}end)
local function balePosition(b)
 if b.carrier and NetworkDoesEntityExistWithNetworkId(b.carrier)then
  local e=NetToVeh(b.carrier);if e~=0 and DoesEntityExist(e)then return GetEntityCoords(e)end
 end
 return vec3(b.x,b.y,b.z)
end
local function nearestBale(pos,radius,looseOnly)
 local found,dist=nil,radius
 for id,b in pairs(bales)do if not looseOnly or not b.carrier then local d=#(balePosition(b)-pos);if d<dist then found=id;dist=d end end end
 return found
end
function YardTryForkBale(fork)
 local net=VehToNet(fork)
 local id
 for key,b in pairs(bales)do if b.kind=='fork'and b.carrier==net then id=key;break end end
 id=id or nearestBale(GetEntityCoords(fork),5.5,true)
 if not id then return false end
 call('wonkyyard:baleFork',net,id);return true
end
function YardForkHasBale(fork)
 local net=VehToNet(fork);for _,b in pairs(bales)do if b.kind=='fork'and b.carrier==net then return true end end;return false
end
local function text(pos,str)
 local ok,x,y=World3dToScreen2d(pos.x,pos.y,pos.z)
 if not ok then return end
 SetTextScale(0.0,0.3);SetTextFont(4);SetTextCentre(true);SetTextColour(70,185,255,255);SetTextOutline()
 BeginTextCommandDisplayText('STRING');AddTextComponentSubstringPlayerName(str);EndTextCommandDisplayText(x,y)
end
local function stripPart(entity,part)
 if stripping then return end
 local ok,msg=lib.callback.await('wonkyyard:stripStart',false,VehToNet(entity),part)
 if not ok then return notify(false,msg)end
 stripping=true
 local p=cfg.parts[part];local idx=GetEntityBoneIndexByName(entity,p.bone)
 local target=idx~=-1 and GetWorldPositionOfEntityBone(entity,idx)or GetEntityCoords(entity)
 TaskTurnPedToFaceCoord(PlayerPedId(),target.x,target.y,target.z,750)
 local done=lib.progressCircle({duration=cfg.stripDuration,label=p.label,position='bottom',canCancel=true,useWhileDead=false,disable={move=true,car=true,combat=true},anim={dict='mini@repair',clip='fixing_a_ped'}})
 stripping=false;call('wonkyyard:stripFinish',VehToNet(entity),part,not done)
end
RegisterNetEvent('wonkyyard:stripped',function(net,part)
 if not NetworkDoesEntityExistWithNetworkId(net)then return end
 local v=NetToVeh(net);if v==0 or not NetworkHasControlOfEntity(v)then return end
 if part=='wheels'then for _,i in ipairs({0,1,4,5})do SetVehicleTyreBurst(v,i,true,1000.0)end
 elseif part=='battery'then SetVehicleEngineOn(v,false,true,true)
 elseif part=='trim'then for i=0,7 do SmashVehicleWindow(v,i)end end
end)
local function weighVehicle()
 local w=cfg.weighbridge
  local found,dist=nil,5
  for _,v in ipairs(GetGamePool('CVehicle'))do local d=#(GetEntityCoords(v)-vec3(w.x,w.y,w.z));if d<dist then found=v;dist=d end end
  if not found then return notify(false,'Place a vehicle on the weighbridge.')end
  local mass=GetVehicleHandlingFloat(found,'CHandlingData','fMass');local desc=('Estimated handling mass: **%.0f kg**\n\nExpected crusher materials:\n'):format(mass)
  for _,r in ipairs(Config.Rewards)do desc=desc..('\n%s: %d–%d'):format(r.name,r.min,r.max)end
  lib.alertDialog({header='Wonky Weighbridge',content=desc..'\n\nEstimate only; stripping adds separate bonuses.',centered=true})
end
CreateThread(function()
 local options={}
 for key,p in pairs(cfg.parts)do
  local part=key
  options[#options+1]={name='wonkyyard_strip_'..part,label=p.label,icon='fa-solid fa-screwdriver-wrench',distance=2.5,
   canInteract=function(e)return not stripping and #(GetEntityCoords(PlayerPedId())-cfg.center)<cfg.radius and not Entity(e).state.wonkyCrushing end,
   onSelect=function(data)stripPart(data.entity,part)end}
 end
 options[#options+1]={name='wonkyyard_bale_load',label='Secure nearby scrap bale on trailer',icon='fa-solid fa-trailer',distance=4,
  canInteract=function(e)return (GetVehicleClass(e)==11 or GetVehicleClass(e)==20) and nearestBale(GetEntityCoords(e),7,true)~=nil end,
  onSelect=function(data)local id=nearestBale(GetEntityCoords(data.entity),7,true);if id then call('wonkyyard:baleTrailer',id,VehToNet(data.entity),false)end end}
 options[#options+1]={name='wonkyyard_bale_unload',label='Unload scrap bale from trailer',icon='fa-solid fa-trailer',distance=4,
  canInteract=function(e)if not NetworkGetEntityIsNetworked(e)then return false end;local n=VehToNet(e);for _,b in pairs(bales)do if b.carrier==n and b.kind=='trailer'then return true end end end,
  onSelect=function(data)local n=VehToNet(data.entity);for id,b in pairs(bales)do if b.carrier==n and b.kind=='trailer'then call('wonkyyard:baleTrailer',id,n,true);break end end end}
 exports.ox_target:addGlobalVehicle(options)
 zones[#zones+1]=exports.ox_target:addBoxZone({coords=vec3(Config.Panel.x,Config.Panel.y,Config.Panel.z),size=vec3(2,2,2.5),options={
  {name='wonkyyard_stop',label='EMERGENCY STOP',icon='fa-solid fa-hand',onSelect=function()call('wonkycrusher:emergencyStop')end},
  {name='wonkyyard_delivery',label='Request NPC scrap delivery',icon='fa-solid fa-truck',onSelect=function()call('wonkyyard:delivery')end},
  {name='wonkyyard_stripcollect',label='Collect stripping bonuses',icon='fa-solid fa-toolbox',onSelect=function()call('wonkyyard:stripCollect')end},
 }})
 zones[#zones+1]=exports.ox_target:addSphereZone({coords=cfg.sorting,radius=3,options={{name='wonkyyard_sort',label='Sort scrap bale into material bins',icon='fa-solid fa-recycle',distance=3,onSelect=function()
  local id=nearestBale(cfg.sorting,5,true);if not id then return notify(false,'Use the forklift to place a bale here and release it.')end
  if lib.progressCircle({duration=6000,label='Sorting recovered materials',canCancel=true,disable={move=true,combat=true},anim={dict='mini@repair',clip='fixing_a_ped'}})then call('wonkyyard:baleSort',id)end
 end}}})
 for i,bin in ipairs(cfg.bins)do
  local index=i
  zones[#zones+1]=exports.ox_target:addBoxZone({coords=bin.pos+vec3(0,0,0.8),size=vec3(2,2,2),rotation=bin.heading or 0,options={{name='wonkyyard_bin_'..i,label=bin.label..' storage',icon='fa-solid fa-box',distance=3,onSelect=function()
   local input=lib.inputDialog(bin.label..' — '..(bins[bin.item]or 0)..' stored',{{type='select',label='Action',required=true,options={{value='withdraw',label='Withdraw'},{value='deposit',label='Deposit'}}},{type='number',label='Quantity',min=1,max=1000,required=true,default=1}})
   if input then call('wonkyyard:bin',index,input[1],input[2])end
  end}}})
 end
 local ok,b,s=pcall(function()return lib.callback.await('wonkyyard:state',false)end);if ok then bales=b or{};bins=s or{}end
end)
CreateThread(function()
 while true do
  Wait(1000)
  local here=GetEntityCoords(PlayerPedId());local near=#(here-cfg.center)<180
  if near and not next(props)then
   local a=Config.CrusherAlert
   alertLight=prop(a.model,vec3(a.position.x,a.position.y,a.position.z),a.position.w,false)
   if alertLight and alertLight~=0 then SetEntityCollision(alertLight,false,false);SetEntityLights(alertLight,true)end
   -- Material storage uses target zones on the existing mapped skips; no bin props spawned.
   local p=cfg.sortingPanel
   prop(Config.PanelModel,vec3(p.x,p.y,p.z),p.w,false)
   local w=cfg.weighbridgePanel
   local box=prop(Config.PanelModel,vec3(w.x,w.y,w.z),w.w,false)
   if box and box~=0 then exports.ox_target:addLocalEntity(box,{{name='wonkyyard_weigh',label='Weigh vehicle / estimate recycling yield',icon='fa-solid fa-weight-scale',distance=2.5,onSelect=weighVehicle}})end
  elseif not near and next(props)then for _,e in ipairs(props)do exports.ox_target:removeLocalEntity(e);if DoesEntityExist(e)then DeleteEntity(e)end end;props={}end
  for id,load in pairs(objects)do if not bales[id]or not near then destroyLoad(load);objects[id]=nil end end
  if near then for id,b in pairs(bales)do if not objects[id]then
   objects[id]=createLoad(b)
  end end end
 end
end)
CreateThread(function()
 local wasCycle=false
 while true do
  local near=#(GetEntityCoords(PlayerPedId())-cfg.center)<180
  if near then
   for id,load in pairs(objects)do
    local e=load.root
    local b=bales[id]
    if b and DoesEntityExist(e)then
     local carrier=b.carrier and NetworkDoesEntityExistWithNetworkId(b.carrier)and NetToVeh(b.carrier)or 0
     if carrier~=0 and DoesEntityExist(carrier)then
      if not IsEntityAttachedToEntity(e,carrier)then
       local bone=-1;local x,y,z=0,0.35,0.15
       if b.kind=='fork'then
        local o=Config.Forklift.scrapOffset or vec3(0,1.25,-0.50);x,y,z=o.x,o.y,o.z
        for _,n in ipairs(Config.Forklift.boneNames)do local idx=GetEntityBoneIndexByName(carrier,n);if idx~=-1 then bone=idx;break end end
        if bone<0 then bone=Config.Forklift.fallbackBone end
       else bone=0;y=-2.0+(b.slot or 0)*1.2;z=1.2 end
       AttachEntityToEntity(e,carrier,bone,x,y,z,0,0,0,false,false,false,false,2,true)
      end
     else
      if IsEntityAttached(e)then DetachEntity(e,true,true)end
      SetEntityCoordsNoOffset(e,b.x,b.y,b.z,false,false,false)
     end
    end
   end
   for _,bin in ipairs(cfg.bins)do if #(GetEntityCoords(PlayerPedId())-bin.pos)<16 then text(bin.pos+vec3(0,0,1.4),bin.label..' | '..(bins[bin.item]or 0))end end
   text(cfg.sorting+vec3(0,0,1.2),'SCRAP SORTING — release scrap here')
   local w=cfg.weighbridge
   DrawMarker(1,w.x,w.y,w.z-0.1,0,0,0,0,0,w.w,cfg.weighbridgeSize.x,cfg.weighbridgeSize.y,0.12,0,150,255,100,false,false,2,false,nil,nil,false)
   text(vec3(w.x,w.y,w.z+0.7),'WEIGHBRIDGE')
   local elapsed=CrusherCycleElapsed and CrusherCycleElapsed()
   if elapsed then
    if not wasCycle then SendNUIMessage({action='warning',elapsed=elapsed/1000});wasCycle=true end
    local a=Config.CrusherAlert
    local lit=(math.floor(elapsed/(a.flashInterval or 450))%2)==0
    if alertLight and DoesEntityExist(alertLight)then SetEntityLights(alertLight,not lit)end
    if lit then
     local p=a.position
     DrawLightWithRange(p.x,p.y,p.z+0.08,255,140,0,3.0,3.0)
    end
   else
    wasCycle=false
    if alertLight and DoesEntityExist(alertLight)then SetEntityLights(alertLight,true)end
   end
   Wait(0)
  else Wait(1000)end
 end
end)
RegisterNetEvent('wonkyyard:driveDelivery',function(vnet,pnet)
 local deadline=GetGameTimer()+12000
 while (not NetworkDoesEntityExistWithNetworkId(vnet)or not NetworkDoesEntityExistWithNetworkId(pnet))and GetGameTimer()<deadline do Wait(100)end
 if not NetworkDoesEntityExistWithNetworkId(vnet)or not NetworkDoesEntityExistWithNetworkId(pnet)then return end
 local v,p=NetToVeh(vnet),NetToPed(pnet)
 if v==0 or p==0 then return end
 local controlDeadline=GetGameTimer()+5000
 while (not NetworkHasControlOfEntity(v)or not NetworkHasControlOfEntity(p))and GetGameTimer()<controlDeadline do
  NetworkRequestControlOfEntity(v);NetworkRequestControlOfEntity(p);Wait(50)
 end
 if not NetworkHasControlOfEntity(v)or not NetworkHasControlOfEntity(p)then return notify(false,'Delivery control failed; the supplier will clear the vehicle.')end
 SetPedIntoVehicle(p,v,-1);SetBlockingOfNonTemporaryEvents(p,true);SetDriverAbility(p,1.0);SetDriverAggressiveness(p,0.0)
 SetVehicleBodyHealth(v,350.0);SetVehicleEngineHealth(v,600.0);SetVehicleDirtLevel(v,15.0)
 local b=cfg.deliveryBay
 TaskVehicleDriveToCoordLongrange(p,v,b.x,b.y,b.z,7.0,786603,4.0)
 local blip=AddBlipForEntity(v);SetBlipSprite(blip,68)
 deadline=GetGameTimer()+150000
 while DoesEntityExist(v)and DoesEntityExist(p)and GetGameTimer()<deadline do
  if #(GetEntityCoords(v)-vec3(b.x,b.y,b.z))<7 then
   BringVehicleToHalt(v,2.0,1500,false);Wait(1500)
   if lib.callback.await('wonkyyard:deliveryArrived',false,vnet)then
    TaskLeaveVehicle(p,v,0);notify(true,'Customer delivered a scrap vehicle. Strip it or load it with the forklift.')
   end
   break
  end
  Wait(1000)
 end
 if DoesBlipExist(blip)then RemoveBlip(blip)end
end)
AddEventHandler('onResourceStop',function(r)
 if r~=GetCurrentResourceName()then return end
 for _,id in ipairs(zones)do exports.ox_target:removeZone(id)end
 for _,e in ipairs(props)do exports.ox_target:removeLocalEntity(e);if DoesEntityExist(e)then DeleteEntity(e)end end
 for _,load in pairs(objects)do destroyLoad(load)end
 local names={'wonkyyard_bale_load','wonkyyard_bale_unload'};for k in pairs(cfg.parts)do names[#names+1]='wonkyyard_strip_'..k end
 exports.ox_target:removeGlobalVehicle(names)
end)
