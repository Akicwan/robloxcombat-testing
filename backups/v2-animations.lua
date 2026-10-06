-- Original authored pose curves. Contact keys share the server's time-to-hit.
local Config=require(script.Parent.Config)
local Anim={}
local function r(v) return CFrame.Angles(math.rad(v[1]),math.rad(v[2]),math.rad(v[3])) end
local function pose(shoulder,elbow,wrist,body,left,leftElbow,hips,shift)
    return {
        RootJoint=CFrame.new(shift or Vector3.zero)*r(body),
        Neck=r({-body[1]*0.5,-body[2]*0.65,-body[3]*0.4}),
        ["Right Shoulder"]=r(shoulder), ["Right Elbow"]=r({elbow,0,0}), ["Right Wrist"]=r(wrist),
        ["Left Shoulder"]=r(left), ["Left Elbow"]=r({leftElbow,0,0}), ["Left Wrist"]=r({-8,0,0}),
        ["Right Hip"]=r(hips[1]), ["Left Hip"]=r(hips[2]),
    }
end
local guard=pose({35,-8,-12},58,{-8,5,-8},{-2,-12,0},{15,0,12},52,{{-7,7,3},{7,-7,-3}})
Anim.Guard=guard
-- Each stroke has a different chamber, contact line and follow-through.
local swings={
    { -- 1: descending forehand, right shoulder to left hip.
        chamber=pose({115,-32,38},78,{-18,-5,-15},{-6,-32,-5},{24,5,18},70,{{-15,10,5},{12,-8,-3}},Vector3.new(0,-0.09,0.12)),
        contact=pose({65,28,-28},18,{-2,0,12},{10,22,4},{12,-10,22},60,{{12,-8,2},{-14,8,-3}},Vector3.new(0,-0.13,-0.22)),
        finish=pose({12,48,-48},25,{15,8,18},{14,34,8},{4,-12,28},40,{{15,-10,3},{-18,8,-3}},Vector3.new(0,-0.1,-0.25)),
    },
    { -- 2: rising backhand, left hip to right shoulder.
        chamber=pose({20,42,-55},75,{12,0,20},{8,32,5},{22,-8,30},75,{{12,-8,4},{-13,8,-4}},Vector3.new(0,-0.16,0.06)),
        contact=pose({84,-22,20},15,{-8,0,-12},{0,-20,-3},{12,10,16},52,{{-12,8,3},{14,-8,-4}},Vector3.new(0,-0.06,-0.22)),
        finish=pose({125,-38,42},40,{-15,-5,-15},{-5,-30,-5},{20,8,18},62,{{-15,10,3},{16,-10,-3}},Vector3.new(0,0,-0.12)),
    },
    { -- 3: compact diagonal cut with a sharper hip turn.
        chamber=pose({100,-45,50},90,{-20,-8,-18},{-3,-38,-4},{20,8,20},70,{{-16,12,4},{15,-10,-3}},Vector3.new(0,-0.10,0.1)),
        contact=pose({72,15,-18},12,{0,0,10},{8,16,3},{10,-15,25},50,{{15,-10,3},{-16,10,-4}},Vector3.new(0,-0.12,-0.28)),
        finish=pose({32,50,-48},24,{12,0,20},{10,40,5},{4,-18,30},38,{{18,-10,2},{-19,10,-3}},Vector3.new(0,-0.13,-0.26)),
    },
    { -- 4: wide backhand flourish with a forward weight transfer.
        chamber=pose({42,46,-60},95,{0,0,12},{7,38,5},{30,-12,32},80,{{15,-12,4},{-18,10,-4}},Vector3.new(0,-0.24,0.15)),
        contact=pose({88,-12,12},8,{-2,0,-6},{10,-18,-4},{20,10,18},40,{{-18,12,3},{20,-10,-4}},Vector3.new(0,-0.10,-0.42)),
        finish=pose({95,-58,55},28,{-15,-10,-16},{4,-42,-8},{10,15,24},45,{{-22,12,4},{22,-12,-3}},Vector3.new(0,-0.05,-0.30)),
    },
}
local heavy={
    chamber=pose({145,-10,12},62,{-12,0,0},{-10,-8,0},{115,12,-18},80,{{-16,10,3},{15,-10,-3}},Vector3.new(0,-0.16,0.1)),
    contact=pose({72,0,-5},10,{0,0,0},{22,6,0},{55,8,-25},55,{{20,-8,3},{-20,8,-3}},Vector3.new(0,-0.24,-0.38)),
    finish=pose({18,8,-12},28,{18,0,0},{28,12,0},{25,8,-15},55,{{24,-8,3},{-22,8,-3}},Vector3.new(0,-0.2,-0.32)),
}
local function mix(a,b,t)
    local out={} for name,v in pairs(a) do out[name]=v:Lerp(b[name] or v,t) end return out
end
local function smooth(t) t=math.clamp(t,0,1) return t*t*(3-2*t) end
function Anim.Attack(kind,combo,time,entry)
    local data=Config.Attack(kind,combo)
    local keys=kind=="Heavy" and heavy or swings[math.clamp(combo,1,4)]
    local chamberEnd=data.SwingStart-0.06
    if time<chamberEnd then
        return mix(entry or guard,keys.chamber,smooth(time/chamberEnd))
    elseif time<data.SwingStart then
        return keys.chamber
    elseif time<data.Windup then
        -- Accelerate through the arc; the contact pose arrives just as hitboxes open.
        local u=math.clamp((time-data.SwingStart)/(data.Windup-data.SwingStart),0,1)
        return mix(keys.chamber,keys.contact,u*u*(2-u))
    elseif time<data.Windup+data.Active then
        return mix(keys.contact,keys.finish,smooth((time-data.Windup)/data.Active))
    end
    return mix(keys.finish,guard,smooth((time-data.Windup-data.Active)/data.Recovery))
end
return Anim
