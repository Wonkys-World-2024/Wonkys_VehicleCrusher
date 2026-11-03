local frame, head, hidden = nil, nil, false
local lastProgress=0.0
local cfg = Config.OriginalPress
local anchor = vec3(cfg.position.x,cfg.position.y,cfg.position.z)
function CrusherVisualReady() return head and DoesEntityExist(head) and frame and DoesEntityExist(frame) end
local function clear()
 if head and DoesEntityExist(head) then DeleteEntity(head) end
 if frame and DoesEntityExist(frame) then DeleteEntity(frame) end
 head,frame=nil,nil
 if hidden then RemoveModelHide(anchor.x,anchor.y,anchor.z,cfg.hideRadius,joaat('prop_ind_crusher'),false);hidden=false end
end
local function spawn()
 local models={joaat('wonky_crusher_frame'),joaat('wonky_crusher_head')}
 for _,hash in ipairs(models) do
  if not IsModelInCdimage(hash) or not IsModelValid(hash) then
   print('[Wonky Crusher] Custom press model unavailable. Check stream/wonky_crusher_parts.ytyp and its DLC_ITYP_REQUEST manifest entry.');return false
  end
  RequestModel(hash)
 end
 local deadline=GetGameTimer()+10000
 while (not HasModelLoaded(models[1]) or not HasModelLoaded(models[2])) and GetGameTimer()<deadline do Wait(50) end
 if not HasModelLoaded(models[1]) or not HasModelLoaded(models[2]) then print('[Wonky Crusher] Press model loading timed out; original remains visible.');return false end
 frame=CreateObjectNoOffset(models[1],anchor.x,anchor.y,anchor.z,false,false,false)
 head=CreateObjectNoOffset(models[2],anchor.x,anchor.y,anchor.z,false,false,false)
 if not frame or frame==0 or not head or head==0 then clear();return false end
 for _,obj in ipairs({frame,head}) do
  SetEntityHeading(obj,cfg.position.w);FreezeEntityPosition(obj,true);SetEntityAsMissionEntity(obj,true,true);SetEntityLodDist(obj,200)
 end
 SetEntityCollision(frame,true,true)
 -- The moving head is visual only. Scripted deformation handles crushing without launching the car.
 SetEntityCollision(head,false,false)
 CreateModelHide(anchor.x,anchor.y,anchor.z,cfg.hideRadius,joaat('prop_ind_crusher'),true);hidden=true
 for _,hash in ipairs(models) do SetModelAsNoLongerNeeded(hash) end
 return true
end
CreateThread(function()
 local retry=0
 while true do
  local near=#(GetEntityCoords(PlayerPedId())-anchor)<cfg.streamDistance
  if near then
   if not CrusherVisualReady() and GetGameTimer()>retry then clear();spawn();retry=GetGameTimer()+15000 end
   if CrusherVisualReady() then
    local elapsed=CrusherCycleElapsed and CrusherCycleElapsed() or nil
    local t=0
    if elapsed then
     if elapsed<3000 then t=0 elseif elapsed<16000 then t=(elapsed-3000)/13000 elseif elapsed<18000 then t=1 else t=1-math.min(1,(elapsed-18000)/4000) end
    end
    t=t*t*(3-2*t)
    if not elapsed then t=math.max(0,lastProgress-GetFrameTime()/3.0) end
    lastProgress=t
    SetEntityCoordsNoOffset(head,anchor.x,anchor.y,anchor.z-cfg.travel*t,false,false,false)
   end
   Wait(0)
  else
   if head or frame or hidden then clear() end
   Wait(1000)
  end
 end
end)
RegisterCommand('crusherpressdebug',function()
 print(('Wonky Press: frame=%s head=%s hiddenOriginal=%s travel=%.2f position=%.3f,%.3f,%.3f heading=%.2f'):format(tostring(frame),tostring(head),tostring(hidden),cfg.travel,anchor.x,anchor.y,anchor.z,cfg.position.w))
end,false)
AddEventHandler('onResourceStop',function(r)if r==GetCurrentResourceName() then clear() end end)
