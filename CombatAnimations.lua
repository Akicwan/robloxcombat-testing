-- Original one-handed combat animation for standard Roblox R15 characters.
-- The sword path is shared with server hit detection; the client solves the arm.
local Config=require(script.Parent.Config)
local Anim={}
local V=Vector3.new
local function rot(x,y,z) return CFrame.Angles(math.rad(x),math.rad(y),math.rad(z)) end
local function ease(t) t=math.clamp(t,0,1) return t*t*(3-2*t) end
Anim.Grip=CFrame.new(0,-0.02,-0.12)*rot(90,0,0)

local function key(hilt,tip,edge,turn,lean,weight)
    return {hilt=hilt,tip=tip,edge=edge,turn=turn,lean=lean,weight=weight}
end
-- Low right hilt, high forward blade, sharp edge toward the opponent.
local guard=key(V(0.60,-0.30,-0.62),V(1.38,2.92,-2.68),V(0,-0.54,-0.84),-8,-3,0)
local block=key(V(0.48,0.05,-0.82),V(-0.25,2.65,-3.24),V(0,-0.7,-0.7),-11,-4,-0.06)
-- A rapid lift across the incoming line, then an outward sword deflection.
local parryCatch=key(V(0.33,0.27,-0.79),V(-1.20,2.77,-2.45),V(0,-0.40,-0.90),-20,-9,-0.14)
local parryDeflect=key(V(0.90,0.18,-0.78),V(2.45,2.42,-2.80),V(0,-0.45,-0.88),23,-7,0.18)
local cuts={
    { -- A high right chamber, then a broad diagonal cut through the center.
        wind=key(V(1.05,0.40,-0.27),V(3.02,3.22,-0.80),V(-0.25,-0.38,-0.9),-33,-13,-0.19),
        contact=key(V(0.40,-0.10,-1.02),V(-0.35,0.64,-4.54),V(-0.7,-0.54,-0.28),22,10,0.28),
        follow=key(V(0.10,-0.30,-0.72),V(-2.31,-2.03,-3.08),V(-0.7,-0.54,-0.15),34,18,0.36),
    },
    { -- Wind low across the left hip and cut back up through the opponent.
        wind=key(V(0.30,-0.43,-0.56),V(-1.90,-2.61,-2.86),V(0.66,0.54,-0.48),30,8,-0.14),
        contact=key(V(0.60,-0.01,-0.82),V(1.17,1.07,-4.39),V(0.7,0.52,-0.3),-21,-7,0.25),
        follow=key(V(0.92,0.48,-0.74),V(2.61,3.18,-2.59),V(0.52,0.69,-0.32),-34,-14,0.33),
    },
    { -- Winding back on the right produces a full horizontal slash.
        wind=key(V(0.98,-0.05,-0.43),V(3.12,0.75,-3.14),V(-0.84,0,-0.54),-36,-9,-0.19),
        contact=key(V(0.39,-0.04,-1.04),V(0.10,0.45,-4.61),V(-0.95,-0.02,-0.31),18,5,0.28),
        follow=key(V(-0.34,-0.17,-0.89),V(-2.91,-0.02,-3.54),V(-0.88,-0.09,-0.39),35,10,0.36),
    },
    { -- An overhead flourish finishes with extra recovery and knockback.
        wind=key(V(0.72,0.82,-0.41),V(1.06,4.38,-1.02),V(-0.16,-0.96,-0.19),-25,-17,-0.24),
        contact=key(V(0.28,-0.04,-1.04),V(0.36,0.14,-4.68),V(-0.13,-0.98,-0.11),13,15,0.36),
        follow=key(V(0.19,-0.33,-0.72),V(-0.31,-2.38,-3.70),V(-0.28,-0.90,-0.25),26,24,0.42),
    },
}
local critical={
    wind=key(V(0.39,1.02,-0.36),V(0.86,4.61,-0.99),V(-0.13,-0.98,-0.11),-17,-20,-0.22),
    contact=key(V(0.28,-0.18,-1.09),V(0.47,-0.10,-4.77),V(-0.14,-0.98,-0.08),10,23,0.41),
    follow=key(V(-0.07,-0.63,-0.76),V(0.18,-2.74,-3.82),V(-0.17,-0.97,-0.10),23,28,0.45),
}
local function interpolate(a,b,t)
    t=ease(t)
    return key(a.hilt:Lerp(b.hilt,t),a.tip:Lerp(b.tip,t),a.edge:Lerp(b.edge,t),a.turn+(b.turn-a.turn)*t,a.lean+(b.lean-a.lean)*t,a.weight+(b.weight-a.weight)*t)
end
local function sampled(kind,combo,time)
    local info=Config.Attack(kind,combo)
    local stroke=kind=="Heavy" and critical or cuts[math.clamp(combo,1,4)]
    local t=math.max(0,time)
    if t<info.SwingStart then return interpolate(guard,stroke.wind,t/info.SwingStart) end
    if t<info.Windup then return interpolate(stroke.wind,stroke.contact,(t-info.SwingStart)/(info.Windup-info.SwingStart)) end
    if t<info.Windup+info.Active then return interpolate(stroke.contact,stroke.follow,(t-info.Windup)/info.Active) end
    return interpolate(stroke.follow,guard,(t-info.Windup-info.Active)/info.Recovery)
end
local function cuttingKey(kind,combo,time)
    local k=sampled(kind,combo,time)
    local info=Config.Attack(kind,combo)
    local t=math.max(0,time)
    local finish=info.Windup+info.Active
    if t<info.SwingStart-0.07 then return k end
    local moment=math.clamp(t,info.SwingStart+0.012,finish-0.012)
    local previous=sampled(kind,combo,moment-0.012)
    local nextKey=sampled(kind,combo,moment+0.012)
    local aim=(k.tip-k.hilt).Unit
    local motion=nextKey.tip-previous.tip
    local edge=motion-aim*motion:Dot(aim)
    if edge.Magnitude>0.005 then
        local amount=1
        if t<info.SwingStart then amount=ease((t-info.SwingStart+0.07)/0.07)
        elseif t>finish then amount=1-ease((t-finish)/0.10) end
        k.edge=k.edge:Lerp(edge.Unit,amount)
    end
    return k
end
local function swordFrame(k)
    local direction=(k.tip-k.hilt).Unit
    local edge=k.edge-direction*k.edge:Dot(direction)
    edge=edge.Unit
    local up=-direction
    return CFrame.fromMatrix(k.hilt,edge,up,edge:Cross(up))
end
function Anim.WeaponFrame(kind,combo,time) return swordFrame(cuttingKey(kind,combo,time)) end
function Anim.GuardFrame() return swordFrame(guard) end
local required={"Root","Waist","Neck","RightShoulder","RightElbow","RightWrist","LeftShoulder","LeftElbow","LeftWrist","RightHip","LeftHip"}
function Anim.Ready(rig)
    for _,name in ipairs(required) do if not rig.joints[name] then return false end end
    return true
end
local function boneFrame(localBone,direction,bend)
    local worldY=-direction
    local worldX=bend-direction*bend:Dot(direction)
    if worldX.Magnitude<0.001 then worldX=V(1,0,0)-direction*direction.X end
    worldX=worldX.Unit
    local world=CFrame.fromMatrix(V(0,0,0),worldX,worldY,worldX:Cross(worldY))
    local localY=-localBone
    local localX=V(1,0,0)-localBone*localBone.X
    if localX.Magnitude<0.001 then localX=V(0,0,1) end
    localX=localX.Unit
    local basis=CFrame.fromMatrix(V(0,0,0),localX,localY,localX:Cross(localY))
    return world*basis:Inverse()
end
local function jointPose(joint,parentFrame,partFrame)
    return joint.C0:Inverse()*parentFrame:Inverse()*partFrame*joint.C1
end
local function buildPose(rig,k)
    local joints=rig.joints
    local result={}
    result.Root=CFrame.new(k.weight*0.12,-math.abs(k.weight)*0.08,-math.max(0,k.weight)*0.36)*rot(k.lean*0.28,k.turn*0.35,k.weight*6)
    result.Waist=rot(k.lean*0.72,k.turn*0.85,k.weight*9)
    result.Neck=rot(-k.lean*0.35,-k.turn*0.45,0)
    result.RightHip=rot(-k.weight*16,-k.turn*0.22,0)
    result.LeftHip=rot(k.weight*16,-k.turn*0.22,0)
    result.LeftShoulder=rot(-5+k.lean*0.6,-8,-7-math.abs(k.weight)*125)
    result.LeftElbow=rot(-14-math.abs(k.weight)*35,0,0)
    result.LeftWrist=CFrame.identity

    local root=rig.model:FindFirstChild("HumanoidRootPart")
    local rootJoint,waist=joints.Root,joints.Waist
    local lower=root.CFrame*rootJoint.C0*result.Root*rootJoint.C1:Inverse()
    local upperTorso=lower*waist.C0*result.Waist*waist.C1:Inverse()
    local sword=root.CFrame*swordFrame(k)
    local desiredHand=sword*Anim.Grip:Inverse()
    local wristJoint=joints.RightWrist
    local shoulderJoint,elbowJoint=joints.RightShoulder,joints.RightElbow
    local shoulder=(upperTorso*shoulderJoint.C0).Position
    local wrist=desiredHand:PointToWorldSpace(wristJoint.C1.Position)
    local toWrist=wrist-shoulder
    local upperBone=elbowJoint.C0.Position-shoulderJoint.C1.Position
    local lowerBone=wristJoint.C0.Position-elbowJoint.C1.Position
    local upperLength,lowerLength=upperBone.Magnitude,lowerBone.Magnitude
    local distance=math.clamp(toWrist.Magnitude,0.05,upperLength+lowerLength-0.02)
    local forward=toWrist.Unit
    local pole=root.CFrame:VectorToWorldSpace(V(1,0.28,-0.40))
    local outward=pole-forward*pole:Dot(forward)
    if outward.Magnitude<0.01 then outward=root.CFrame.RightVector end
    outward=outward.Unit
    local along=(upperLength^2-lowerLength^2+distance^2)/(2*distance)
    local elbow=shoulder+forward*along+outward*math.sqrt(math.max(0,upperLength^2-along^2))
    wrist=shoulder+forward*distance
    local upperDirection=(elbow-shoulder).Unit
    local lowerDirection=(wrist-elbow).Unit
    local upperRotation=boneFrame(upperBone.Unit,upperDirection,outward)
    local upperArm=CFrame.new(shoulder-upperRotation:VectorToWorldSpace(shoulderJoint.C1.Position))*upperRotation
    local lowerRotation=boneFrame(lowerBone.Unit,lowerDirection,outward)
    local lowerArm=CFrame.new(elbow-lowerRotation:VectorToWorldSpace(elbowJoint.C1.Position))*lowerRotation
    local hand=CFrame.new(wrist)*desiredHand.Rotation*CFrame.new(-wristJoint.C1.Position)
    result.RightShoulder=jointPose(shoulderJoint,upperTorso,upperArm)
    result.RightElbow=jointPose(elbowJoint,upperArm,lowerArm)
    result.RightWrist=jointPose(wristJoint,lowerArm,hand)
    return result
end
function Anim.Guard(rig) return buildPose(rig,guard) end
function Anim.Block(rig) return buildPose(rig,block) end
function Anim.Parry(rig,time)
    local k
    if time<0.07 then k=interpolate(guard,parryCatch,time/0.07)
    elseif time<0.16 then k=interpolate(parryCatch,parryDeflect,(time-0.07)/0.09)
    else k=interpolate(parryDeflect,block,(time-0.16)/0.10) end
    return buildPose(rig,k)
end
function Anim.Attack(kind,combo,time,entry,rig)
    local result=buildPose(rig,cuttingKey(kind,combo,time))
    if entry and time<0.08 then
        local amount=ease(time/0.08)
        for name,value in pairs(result) do result[name]=(entry[name] or value):Lerp(value,amount) end
    end
    return result
end
return Anim
