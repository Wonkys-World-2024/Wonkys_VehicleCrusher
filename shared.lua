function CrusherCenter()
 return vec3(Config.Bed.x, Config.Bed.y, Config.Bed.z) + Config.BedOffset
end
function CrusherInside(p)
 local d = p - CrusherCenter()
 local a = math.rad(Config.Bed.w)
 local x = d.x * math.cos(a) + d.y * math.sin(a)
 local y = -d.x * math.sin(a) + d.y * math.cos(a)
 return math.abs(x) <= Config.BedHalfWidth and math.abs(y) <= Config.BedHalfLength and math.abs(d.z) <= Config.BedHeightTolerance
end
