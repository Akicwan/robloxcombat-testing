-- Weapon-led swordsmanship: hilt targets drive arm IK; the sharp edge leads the cut.
local Config=require(script.Parent.Config)
local Anim={}
local V=Vector3.new
local function rot(x,y,z) return CFrame.Angles(math.rad(x),math.rad(y),math.rad(z)) end
local function smooth(t) t=math.clamp(t,0,1) return t*t*(3-2*t) end
Anim.Grip=CFrame.new(0,-0.02,-0.12)*rot(90,0,0)
local function bladeFrame(position,aim,edge)
    aim=aim.Unit edge=(edge-aim*edge:Dot(aim)).Unit
    return CFrame.fromMatrix(position,edge,-aim,edge:Cross(-aim))
end
local guardFrame=bladeFrame(V(0.05,0.04,-0.74),V(0.06,0.84,-0.54),V(1,0,0))
local guardRoot=rot(-2,-10,0)
local function solveArm(side,hand,pose)
    local sign=side=="Right" and 1 or -1
    local shoulder=V(sign*1.4,0.65,0)
    local wrist=hand:PointToWorldSpace(V(0,0.2,0))
    local delta=wrist-shoulder
    local distance=math.clamp(delta.Magnitude,0.1,1.62)
    local direction=delta.Unit
    local pole=V(sign*1,-0.5,0.15)
    local outward=(pole-direction*pole:Dot(direction)).Unit
    local upperLength,lowerLength=0.825,0.8
    local along=(upperLength^2-lowerLength^2+distance^2)/(2*distance)
    local height=math.sqrt(math.max(0,upperLength^2-along^2))
    local elbow=shoulder+direction*along+outward*height
    wrist=shoulder+direction*distance
    local downUpper=(elbow-shoulder).Unit
    local downFore=(wrist-elbow).Unit
    local right=downUpper:Cross(downFore)
    if right.Magnitude<0.001 then right=V(sign,0,0) end right=right.Unit
    local upper=CFrame.fromMatrix(shoulder+downUpper*0.35,right,-downUpper,right:Cross(-downUpper))
    local fore=CFrame.fromMatrix(elbow+downFore*0.4,right,-downFore,right:Cross(-downFore))
    hand=CFrame.new(wrist)*hand.Rotation*CFrame.new(0,-0.2,0)
    pose[side.." Shoulder"]=CFrame.new(shoulder):Inverse()*upper*CFrame.new(0,0.35,0)
    pose[side.." Elbow"]=CFrame.new(0,0.475,0)*upper:Inverse()*fore*CFrame.new(0,0.4,0)
    pose[side.." Wrist"]=CFrame.new(0,0.4,0)*fore:Inverse()*hand*CFrame.new(0,0.2,0)
end
local function bodyPose(weapon,body,weight,support)
    local pose={RootJoint=body,Neck=rot(-weight*3,0,0),["Right Hip"]=rot(-7+weight*14,7,2),["Left Hip"]=rot(7-weight*14,-7,-2)}
    local localWeapon=body:Inverse()*weapon
    solveArm("Right",localWeapon*Anim.Grip:Inverse(),pose)
    if support then
        solveArm("Left",localWeapon*CFrame.new(0,0.39,0)*Anim.Grip:Inverse(),pose)
    else
        pose["Left Shoulder"]=rot(6+weight*8,10,18)
        pose["Left Elbow"]=rot(75-weight*22,0,0)
        pose["Left Wrist"]=rot(-8,0,0)
    end
    return pose
end
Anim.Guard=bodyPose(guardFrame,guardRoot,0,true)
Anim.Block=bodyPose(bladeFrame(V(0.12,0.45,-0.9),V(-0.65,0.73,-0.22),V(0.4,0.6,0.7)),rot(0,-8,0),-0.2,true)
local strokes={
    {axis=V(0.68,-0.73,0),from=-72,to=53,hiltA=V(0.62,0.46,-0.50),hiltB=V(-0.08,-0.08,-1.02),turnA=-24,turnB=24},
    {axis=V(-0.6,0.8,0),from=-68,to=55,hiltA=V(-0.02,-0.10,-0.77),hiltB=V(0.65,0.35,-0.88),turnA=22,turnB=-22},
    {axis=V(0.12,-0.99,0),from=-78,to=62,hiltA=V(0.76,0.24,-0.43),hiltB=V(-0.10,0.08,-1.00),turnA=-28,turnB=27},
    {axis=V(0.96,-0.28,0),from=-82,to=61,hiltA=V(0.39,0.65,-0.45),hiltB=V(0.06,-0.14,-1.08),turnA=-18,turnB=20},
}
local critical={axis=V(1,0,0),from=-90,to=65,hiltA=V(0.18,0.78,-0.38),hiltB=V(0.12,-0.2,-1.06),turnA=-8,turnB=8}
local function cuttingFrame(stroke,angle,fraction)
    local axis=stroke.axis.Unit
    local aim=CFrame.fromAxisAngle(axis,math.rad(angle)):VectorToWorldSpace(V(0,0,-1))
    -- Blade local X is its cutting edge, Z its broad face. Align X to the arc tangent.
    return bladeFrame(stroke.hiltA:Lerp(stroke.hiltB,smooth(fraction)),aim,axis:Cross(aim))
end
local function sample(kind,combo,time)
    local data=Config.Attack(kind,combo)
    local stroke=kind=="Heavy" and critical or strokes[math.clamp(combo,1,4)]
    local chamber=cuttingFrame(stroke,stroke.from,0)
    local finish=cuttingFrame(stroke,stroke.to,1)
    local t=math.max(0,time)
    local chamberEnd=data.SwingStart-0.045
    local weapon,weight,turn,lean
    if t<chamberEnd then
        local u=smooth(t/chamberEnd)
        weapon=guardFrame:Lerp(chamber,u) weight=-u*0.6 turn=-10+(stroke.turnA+10)*u lean=-3*u
    elseif t<data.SwingStart then
        weapon=chamber weight=-0.6 turn=stroke.turnA lean=-3
    elseif t<data.Windup+data.Active then
        local u=(t-data.SwingStart)/(data.Windup-data.SwingStart)
        local fraction,angle
        if u<=1 then
            local eased=u*u*(2-u)
            angle=stroke.from*(1-eased) fraction=eased*0.64
        else
            local follow=(t-data.Windup)/data.Active
            -- Match contact angular velocity, then ease to a stop before returning to guard.
            local tangent=math.abs(stroke.from)*data.Active/((data.Windup-data.SwingStart)*stroke.to)
            local arc=(-2*follow^3+3*follow^2)+(follow^3-2*follow^2+follow)*tangent
            angle=stroke.to*arc fraction=0.64+0.36*arc
        end
        weapon=cuttingFrame(stroke,angle,fraction)
        weight=-0.6+1.5*fraction turn=stroke.turnA+(stroke.turnB-stroke.turnA)*fraction lean=-3+14*fraction
    else
        local u=smooth((t-data.Windup-data.Active)/data.Recovery)
        weapon=finish:Lerp(guardFrame,u) weight=0.9*(1-u) turn=stroke.turnB+(-10-stroke.turnB)*u lean=11*(1-u)
    end
    local body=CFrame.new(0,-math.abs(weight)*0.10,-math.max(0,weight)*0.10)*rot(lean,turn,weight*2)
    return weapon,body,weight
end
function Anim.WeaponFrame(kind,combo,time) return (sample(kind,combo,time)) end
function Anim.Attack(kind,combo,time,entry)
    local weapon,body,weight=sample(kind,combo,time)
    local pose=bodyPose(weapon,body,weight,kind=="Heavy")
    if kind=="Light" and time<0.20 then
        for _,name in ipairs({"Left Shoulder","Left Elbow","Left Wrist"}) do
            pose[name]=(entry and entry[name] or Anim.Guard[name]):Lerp(pose[name],smooth(time/0.20))
        end
    end
    if entry and time<0.10 then
        local alpha=smooth(time/0.10)
        for name,value in pairs(pose) do pose[name]=(entry[name] or Anim.Guard[name] or value):Lerp(value,alpha) end
    end
    local data=Config.Attack(kind,combo)
    if time>data.Windup+data.Active then
        local alpha=smooth((time-data.Windup-data.Active)/data.Recovery)
        for _,name in ipairs({"Left Shoulder","Left Elbow","Left Wrist"}) do pose[name]=pose[name]:Lerp(Anim.Guard[name],alpha) end
    end
    return pose
end
return Anim
