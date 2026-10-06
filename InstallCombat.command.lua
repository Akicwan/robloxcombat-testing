local rs=game:GetService('ReplicatedStorage')
local kit=rs:FindFirstChild('ParryCombat') or Instance.new('Folder') kit.Name='ParryCombat' kit.Parent=rs
local event=kit:FindFirstChild('CombatEvent') or Instance.new('RemoteEvent') event.Name='CombatEvent' event.Parent=kit
do local p=kit local s=p:FindFirstChild('Config') or Instance.new('ModuleScript') s.Name='Config' s.Source=[====[
-- Shared, tunable prototype values. Times are seconds; distances are studs.
local Config = {
    Health = 150, WalkSpeed = 16, PostureMax = 100, PostureRegen = 15,
    PostureRegenDelay = 2, ParryWindow = 0.26, ParryCooldown = 1.15,
    ParryGrace = 0.18, ParryStun = 0.38, ParryPosture = 24,
    BlockAngle = 0.05, GuardBreak = 1.15, HitStun = 0.28,
    DodgeDuration = 0.48, DodgeInvulnerability = 0.26, DodgeSpeed = 38,
    DodgeCooldown = 1.05, RollCancelEarliest = 0.09, RollCancelRecovery = 0.08,
    FeintCooldown = 1.0, FeintRecovery = 0.14, ComboReset = 1.4, ComboMax = 4,
    -- Windup means time-to-CONTACT. The visible cutting motion starts at SwingStart.
    Light = {SwingStart = 0.27, Windup = 0.46, Active = 0.09, Recovery = 0.21, FeintUntil = 0.25, Damage = 12, Posture = 25, Range = 7, Width = 6},
    Finisher = {SwingStart = 0.31, Windup = 0.53, Active = 0.10, Recovery = 0.38, FeintUntil = 0.28, Damage = 16, Posture = 32, Range = 7.5, Width = 6.5, Knockback = 34, KnockbackDuration = 0.24},
    Heavy = {SwingStart = 0.47, Windup = 0.72, Active = 0.12, Recovery = 0.42, Damage = 24, Posture = 100, Range = 8, Width = 6.5, Cooldown = 2.1, BreaksBlock = true},
    Sounds = {
        Hit = {Id = "rbxassetid://7171761940", Volume = 0.65, Speed = 1.05},
        Parry = {Id = "rbxassetid://5763723309", Volume = 0.8, Speed = 1.15},
        Block = {Id = "rbxassetid://87182755732271", Volume = 0.6, Speed = 0.85},
    },
    Modes = {"Passive", "Block", "Parry drill", "Sparring"},
}
function Config.Attack(kind, combo)
    if kind == "Light" and combo == Config.ComboMax then return Config.Finisher end
    return Config[kind]
end
return Config

]====] s.Parent=p end
do local p=kit local s=p:FindFirstChild('CombatAnimations') or Instance.new('ModuleScript') s.Name='CombatAnimations' s.Source=[====[
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

]====] s.Parent=p end
do local p=game.ServerScriptService local s=p:FindFirstChild('CombatService') or Instance.new('ModuleScript') s.Name='CombatService' s.Source=[====[
-- Server owns action admission, hit detection, damage, cooldowns and posture.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kit = ReplicatedStorage:WaitForChild("ParryCombat")
local Config = require(Kit.Config)
local Animations = require(Kit.CombatAnimations)
local Event = Kit.CombatEvent
local Combat = {Fighters = {}}
local function now() return workspace:GetServerTimeNow() end
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function emit(kind, model, other) Event:FireAllClients(kind, model, other) end
local function state(s, name, duration)
    s.state, s.started, s.ends = name, now(), now() + (duration or 0)
    s.model:SetAttribute("ActionStart", s.started)
    s.model:SetAttribute("ActionDuration", duration or 0)
    s.model:SetAttribute("CombatState", name)
end
local function posture(s, value)
    s.posture = math.clamp(value,0,Config.PostureMax)
    s.model:SetAttribute("Posture", s.posture)
    s.lastPosture = now()
end
local function stat(s,name)
    s.model:SetAttribute(name,(s.model:GetAttribute(name) or 0)+1)
end
local function stopMotion(s)
    if s.root and s.root.Parent then
        local v=s.root.AssemblyLinearVelocity
        s.root.AssemblyLinearVelocity=Vector3.new(0,v.Y,0)
    end
end
function Combat.Register(model, isBot)
    if Combat.Fighters[model] then return Combat.Fighters[model] end
    local h=model:FindFirstChildOfClass("Humanoid")
    local root=model:FindFirstChild("HumanoidRootPart")
    if not h or not root then return end
    local s={model=model,hum=h,root=root,bot=isBot,posture=0,state="Idle",started=now(),ends=0,
        parryReady=0,dodgeReady=0,heavyReady=0,feintReady=0,grace=0,held=false,
        combo=0,lastAttack=0,lastPosture=0,hit={},nextAI=now()+2,mode="Passive",attackCount=0}
    Combat.Fighters[model]=s
    h.MaxHealth=Config.Health h.Health=Config.Health h.WalkSpeed=Config.WalkSpeed
    h.BreakJointsOnDeath=false
    model:SetAttribute("Posture",0)
    model:SetAttribute("PostureMax",Config.PostureMax)
    model:SetAttribute("TrainingBot",isBot == true)
    model:SetAttribute("TrainingMode",s.mode)
    state(s,"Idle",0)
    for _,n in ipairs({"Hits","Parries","Dodges","Feints","RollCancels","GuardBreaks"}) do model:SetAttribute(n,0) end
    CollectionService:AddTag(model,"CombatFighter")
    if isBot then root:SetNetworkOwner(nil) end
    h.Died:Connect(function() s.held=false state(s,"Defeated",3) end)
    return s
end
function Combat.Reset(s, position)
    s.hum.Health=s.hum.MaxHealth s.held=false s.grace=0 s.combo=0 s.lastAttack=0 s.previousCombo=0
    s.parryReady=0 s.dodgeReady=0 s.heavyReady=0 s.feintReady=0
    s.hit={} s.knockUntil=0 s.nextAI=now()+1.5 posture(s,0) stopMotion(s)
    s.model:SetAttribute("Combo",0)
    s.model:SetAttribute("LastAttack",0)
    for _,name in ipairs({"ParryReady","DodgeReady","HeavyReady","FeintReady","KnockUntil"}) do s.model:SetAttribute(name,0) end
    if position then s.model:PivotTo(position) end
    state(s,"Idle",0)
end
local function guardbreak(s)
    s.held=false s.grace=0 posture(s,0) state(s,"GuardBroken",Config.GuardBreak)
    emit("GuardBreak",s.model)
end
local function stun(s,duration)
    s.held=false s.grace=0 s.combo=0 s.model:SetAttribute("Combo",0) state(s,"Stunned",duration) stopMotion(s)
end
local function damage(s,amount)
    if s.bot and s.hum.Health<=amount then
        s.hum.Health=1 s.held=false state(s,"Defeated",2)
        emit("Notice",s.model,"Partner defeated · resetting")
    else s.hum:TakeDamage(amount) end
end
local function applyHit(a,b,attack)
    local t=now()
    if b.hum.Health<=0 or b.state=="Defeated" then return end
    if b.state=="Dodge" and t-b.started<Config.DodgeInvulnerability then
        stat(b,"Dodges") emit("DodgeSuccess",b.model) return
    end
    if (b.state=="Parry" and t-b.started<=Config.ParryWindow) or t<b.grace then
        b.parryReady=0 b.model:SetAttribute("ParryReady",0) b.grace=t+Config.ParryGrace
        posture(b,b.posture-30) posture(a,a.posture+Config.ParryPosture)
        stat(b,"Parries")
        if a.posture>=Config.PostureMax then guardbreak(a) else stun(a,Config.ParryStun) end
        state(b,b.held and "Block" or "Idle",0)
        emit("ParrySuccess",b.model,a.model) return
    end
    local toward=flat(a.root.Position-b.root.Position)
    local facing=toward.Magnitude<0.01 or flat(b.root.CFrame.LookVector):Dot(toward.Unit)>=Config.BlockAngle
    if b.state=="Block" and facing then
        posture(b,b.posture+attack.Posture)
        if attack.BreaksBlock or b.posture>=Config.PostureMax then
            guardbreak(b) stat(a,"GuardBreaks")
            damage(b,attack.Damage*0.3)
        else emit("BlockHit",b.model) end
        return
    end
    posture(b,b.posture+attack.Posture*0.35)
    b.parryReady=0 b.model:SetAttribute("ParryReady",0)
    damage(b,attack.Damage) stat(a,"Hits")
    if b.hum.Health>0 and b.state~="Defeated" then stun(b,attack.Knockback and 0.48 or Config.HitStun) end
    local dir=flat(b.root.Position-a.root.Position)
    if dir.Magnitude>0 then
        if attack.Knockback then
            b.knockDirection=dir.Unit b.knockSpeed=attack.Knockback b.knockUntil=t+attack.KnockbackDuration
            b.model:SetAttribute("KnockDirection",b.knockDirection)
            b.model:SetAttribute("KnockSpeed",b.knockSpeed)
            b.model:SetAttribute("KnockUntil",b.knockUntil)
            emit("Finisher",b.model,a.model)
        else b.root:ApplyImpulse(dir.Unit*b.root.AssemblyMass*(a.attackKind=="Heavy" and 12 or 2)) end
    end
    emit("Hit",b.model,a.model)
end
function Combat.Action(s, action, direction)
    if not s or not s.model.Parent or s.hum.Health<=0 then return false end
    local t=now()
    if action=="BlockEnd" then
        s.held=false if s.state=="Block" then state(s,"Idle",0) end return true
    end
    if action=="Cancel" then
        if s.state=="Dodge" and t-s.started>=Config.RollCancelEarliest then
            stopMotion(s) state(s,"RollCancel",Config.RollCancelRecovery)
            stat(s,"RollCancels") emit("RollCancel",s.model) return true
        elseif s.state=="Light" and t-s.started<Config.Attack("Light",s.combo).FeintUntil and t>=s.feintReady then
            s.feintReady=t+Config.FeintCooldown
            s.model:SetAttribute("FeintReady",s.feintReady)
            s.combo=s.previousCombo or 0
            s.model:SetAttribute("Combo",s.combo)
            state(s,"Feint",Config.FeintRecovery) stat(s,"Feints") emit("Feint",s.model) return true
        end
        return false
    end
    -- A short hit stun still permits defensive parries, preventing infinite light combos.
    local canDefend=s.state=="Stunned" and t-s.started>=0.12
    local free=s.state=="Idle" or s.state=="Block"
    if action=="Parry" then
        if not (free or canDefend) then return false end
        s.held=true
        if t>=s.parryReady then
            s.parryReady=t+Config.ParryCooldown s.model:SetAttribute("ParryReady",s.parryReady)
            state(s,"Parry",Config.ParryWindow)
        else state(s,"Block",0) end
        return true
    end
    if not free then return false end
    if action=="Light" or action=="Heavy" then
        if action=="Heavy" and t<s.heavyReady then return false end
        s.held=false s.attackKind=action s.hit={} s.lastHitSample=nil
        if action=="Light" then
            s.previousCombo=(t-s.lastAttack>Config.ComboReset) and 0 or s.combo
            s.combo=s.previousCombo%Config.ComboMax+1
            s.lastAttack=t s.model:SetAttribute("Combo",s.combo) s.model:SetAttribute("LastAttack",t)
        else s.heavyReady=t+Config.Heavy.Cooldown s.model:SetAttribute("HeavyReady",s.heavyReady) end
        local a=Config.Attack(action,s.combo) state(s,action,a.Windup+a.Active+a.Recovery)
        emit("SwingStart",s.model,action) return true
    elseif action=="Dodge" and t>=s.dodgeReady then
        if typeof(direction)~="Vector3" then direction=-s.root.CFrame.LookVector end
        direction=flat(direction)
        if direction.X~=direction.X or direction.Z~=direction.Z or direction.Magnitude>1e4 then return false end
        if direction.Magnitude<0.01 then direction=-flat(s.root.CFrame.LookVector) end
        s.dodgeDirection=direction.Unit s.held=false s.grace=0
        s.dodgeReady=t+Config.DodgeCooldown s.model:SetAttribute("DodgeReady",s.dodgeReady)
        s.model:SetAttribute("DodgeDirection",s.dodgeDirection)
        state(s,"Dodge",Config.DodgeDuration) emit("DodgeStart",s.model) return true
    end
    return false
end
local function hitbox(s)
    local a=Config.Attack(s.attackKind,s.combo)
    local age=math.min(now()-s.started,a.Windup+a.Active)
    local previous=math.max(a.Windup,s.lastHitSample or a.Windup)
    local bladeSegments={}
    -- Sweep only the sharpened blade, excluding the grip, guard and blunt ricasso.
    -- Authoritative pose curves are shared with the client; no client hit claims are used.
    for step=0,3 do
        local t=previous+(age-previous)*step/3
        local blade=s.root.CFrame*Animations.WeaponFrame(s.attackKind,s.combo,t)
        table.insert(bladeSegments,{blade:PointToWorldSpace(Vector3.new(0,-1.15,0)),blade:PointToWorldSpace(Vector3.new(0,-3.76,0))})
    end
    s.lastHitSample=age
    for _,other in pairs(Combat.Fighters) do
        if other~=s and not s.hit[other] and other.model.Parent then
            local p=s.root.CFrame:PointToObjectSpace(other.root.Position)
            if p.Z<1 and p.Z>-a.Range and math.abs(p.X)<a.Width/2 and math.abs(p.Y)<4 then
                local bladeContact=false
                for _,segment in ipairs(bladeSegments) do
                    local v=segment[2]-segment[1]
                    local t=math.clamp((other.root.Position-segment[1]):Dot(v)/v:Dot(v),0,1)
                    if (other.root.Position-(segment[1]+v*t)).Magnitude<=1.45 then bladeContact=true break end
                end
                if not bladeContact then continue end
                local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude
                rp.FilterDescendantsInstances={s.model,other.model}
                local obstruct=workspace:Raycast(s.root.Position,other.root.Position-s.root.Position,rp)
                if not obstruct then
                    s.hit[other]=true applyHit(s,other,a)
                    if s.state~="Light" and s.state~="Heavy" then break end
                end
            end
        end
    end
end
local function botThink(s,t)
    if s.mode=="Passive" then return end
    local target,dist=nil,math.huge
    for _,o in pairs(Combat.Fighters) do
        if not o.bot and o.hum.Health>0 and o.model.Parent then
            local d=(o.root.Position-s.root.Position).Magnitude
            if d<dist then target,dist=o,d end
        end
    end
    if not target or dist>65 then return end
    local delta=flat(target.root.Position-s.root.Position)
    if delta.Magnitude>0.1 and s.state~="Dodge" then s.root.CFrame=CFrame.lookAt(s.root.Position,s.root.Position+delta) end
    if s.mode=="Block" then
        if s.state=="Idle" then s.held=true state(s,"Block",0) end return
    end
    if s.mode=="Sparring" and dist>5 and s.state=="Idle" then
        s.hum:Move(delta.Unit)
    else s.hum:Move(Vector3.zero) end
    if s.state=="Idle" and dist<8 and t>=s.nextAI then
        s.attackCount+=1
        Combat.Action(s,s.attackCount%3==0 and "Heavy" or "Light")
        s.nextAI=t+(s.mode=="Parry drill" and 1.65 or 1.05)
        if s.mode=="Sparring" and s.attackCount%5==0 then
            local started=s.started
            task.delay(0.13,function()
                if s.started==started then Combat.Action(s,"Cancel") s.nextAI=now()+0.22 end
            end)
        end
    elseif s.mode=="Sparring" and s.state=="Idle" and (target.state=="Light" or target.state=="Heavy") and dist<8 then
        local a=Config.Attack(target.state,target.combo)
        if t-target.started>a.Windup-0.12 and t>=s.parryReady and s.attackCount%3~=0 then
            Combat.Action(s,"Parry")
            task.delay(0.27,function() Combat.Action(s,"BlockEnd") end)
        end
    end
end
RunService.Heartbeat:Connect(function(dt)
    local t=now()
    for model,s in pairs(Combat.Fighters) do
        if not model.Parent then Combat.Fighters[model]=nil continue end
        if s.state=="Defeated" then
            if s.bot and t>s.ends then Combat.Reset(s,s.home) end continue
        end
        local age=t-s.started
        if s.state=="Light" or s.state=="Heavy" then
            local a=Config.Attack(s.state,s.combo)
            if age>=a.Windup and age<=a.Windup+a.Active then hitbox(s) end
        elseif s.state=="Dodge" then
            local v=s.root.AssemblyLinearVelocity
            local speed=Config.DodgeSpeed*(1-0.45*math.clamp(age/Config.DodgeDuration,0,1))
            local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={model}
            if workspace:Raycast(s.root.Position,s.dodgeDirection*2.5,rp) then speed=0 end
            s.root.AssemblyLinearVelocity=s.dodgeDirection*speed+Vector3.new(0,v.Y,0)
        end
        if s.knockUntil and t<s.knockUntil then
            local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={model}
            local blocked=workspace:Raycast(s.root.Position,s.knockDirection*2,rp)
            local v=s.root.AssemblyLinearVelocity
            s.root.AssemblyLinearVelocity=(blocked and Vector3.zero or s.knockDirection*s.knockSpeed)+Vector3.new(0,v.Y,0)
        elseif s.knockUntil and s.knockUntil>0 then
            s.knockUntil=0 stopMotion(s)
        end
        if s.ends>0 and t>=s.ends and s.state~="Idle" and s.state~="Block" then
            if s.state=="Dodge" then stopMotion(s) end
            state(s,s.held and "Block" or "Idle",0)
        end
        local st=s.state
        s.hum.WalkSpeed=(st=="Stunned" or st=="GuardBroken" or st=="Dodge") and 0 or ((st=="Block" or st=="Parry") and 7 or ((st=="Light" or st=="Heavy") and 10 or Config.WalkSpeed))
        s.hum.JumpPower=st=="Idle" and 45 or 0
        s.hum.JumpHeight=st=="Idle" and 6 or 0
        s.hum.AutoRotate=not s.bot and st~="Dodge"
        if t-s.lastPosture>Config.PostureRegenDelay and s.posture>0 and st=="Idle" then
            s.posture=math.max(0,s.posture-Config.PostureRegen*dt) model:SetAttribute("Posture",s.posture)
        end
        if s.bot then botThink(s,t) end
    end
end)
return Combat

]====] s.Parent=p end
do local p=game.ServerScriptService local s=p:FindFirstChild('CombatServer') or Instance.new('Script') s.Name='CombatServer' s.Source=[====[
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Kit=RS:WaitForChild("ParryCombat")
local Combat=require(script.Parent.CombatService)
local Event=Kit.CombatEvent
local Animations=require(Kit.CombatAnimations)
local arena=workspace:WaitForChild("ParryArena")
local bot=arena:WaitForChild("TrainingPartner")
local botState=Combat.Register(bot,true)
botState.home=bot:GetPivot()
local function equip(character)
    if character:FindFirstChild("PracticeSword") then return end
    local arm=character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
    if not arm then return end
    local sword=Kit.PracticeSword:Clone() sword.Parent=character
    local grip=Instance.new("Motor6D") grip.Name="SwordGrip"
    grip.Part0=arm grip.Part1=sword.Handle grip.C0=Animations.Grip grip.Parent=arm
end
equip(bot)
local function spawnCharacter(c)
    local h=c:WaitForChild("Humanoid") c:WaitForChild("HumanoidRootPart")
    local ff=c:FindFirstChildOfClass("ForceField") if ff then ff:Destroy() end
    equip(c) Combat.Register(c,false)
    c:PivotTo(CFrame.lookAt(Vector3.new(0,5,12),Vector3.new(0,5,0)))
    h.Died:Connect(function() local s=Combat.Fighters[c] if s then s.held=false end end)
end
local function playerAdded(p)
    p.CharacterAdded:Connect(spawnCharacter)
    if p.Character then task.spawn(spawnCharacter,p.Character) end
end
Players.PlayerAdded:Connect(playerAdded)
for _,p in ipairs(Players:GetPlayers()) do playerAdded(p) end
local rates={}
Players.PlayerRemoving:Connect(function(p) rates[p]=nil end)
Event.OnServerEvent:Connect(function(player,action,direction,sequence)
    if type(action)~="string" then return end
    local t=os.clock() local rate=rates[player]
    if not rate or t-rate.time>=1 then rate={time=t,count=0} rates[player]=rate end
    rate.count+=1 if rate.count>35 then return end
    local s=Combat.Fighters[player.Character]
    if not s then return end
    if action=="TrainingMode" then
        if (s.root.Position-botState.root.Position).Magnitude>80 then return end
        if rate.lastMode and t-rate.lastMode<0.4 then return end rate.lastMode=t
        local modes=require(Kit.Config).Modes
        local i=table.find(modes,botState.mode) or 1
        botState.mode=modes[i%#modes+1]
        Combat.Reset(botState,botState.home)
        bot:SetAttribute("TrainingMode",botState.mode)
        Event:FireAllClients("Mode",bot,botState.mode)
        return
    elseif action=="ResetTraining" then
        if rate.lastReset and t-rate.lastReset<1 then return end rate.lastReset=t
        Combat.Reset(s,CFrame.lookAt(Vector3.new(0,5,12),Vector3.new(0,5,0)))
        Combat.Reset(botState,botState.home)
        Event:FireClient(player,"Notice",nil,"Training reset") return
    end
    local accepted=Combat.Action(s,action,direction)
    Event:FireClient(player,"Ack",sequence,accepted)
end)
print("[Parry Combat] Ready. M1 attack | F parry/block | Q dodge | R heavy | M2 feint/cancel | T mode | G reset")

]====] s.Parent=p end
do local p=game.StarterPlayer.StarterPlayerScripts local s=p:FindFirstChild('CombatClient') or Instance.new('LocalScript') s.Name='CombatClient' s.Source=[====[
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local CAS=game:GetService("ContextActionService")
local UIS=game:GetService("UserInputService")
local CollectionService=game:GetService("CollectionService")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local player=Players.LocalPlayer
local Kit=RS:WaitForChild("ParryCombat")
local Config=require(Kit.Config)
local Animations=require(Kit.CombatAnimations)
local Event=Kit.CombatEvent
local camera=workspace.CurrentCamera
local char,hum,root
local sequence=0
local predicted=nil
local buffered=nil
local locked=true
local feedbackUntil=0
local rigs={}
local colors={gold=Color3.fromRGB(239,197,114),cyan=Color3.fromRGB(111,221,218),red=Color3.fromRGB(244,111,100),white=Color3.fromRGB(232,234,226),muted=Color3.fromRGB(149,165,175)}
local function now() return workspace:GetServerTimeNow() end
local function make(class,props,parent)
    local i=Instance.new(class) for k,v in pairs(props) do i[k]=v end i.Parent=parent return i
end
local gui=make("ScreenGui",{Name="ParryCombatHUD",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},player:WaitForChild("PlayerGui"))
local function label(parent,text,pos,size,fontSize,color)
    return make("TextLabel",{BackgroundTransparency=1,Position=pos,Size=size,Text=text,TextColor3=color or colors.white,TextSize=fontSize or 14,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left},parent)
end
local title=label(gui,"IRON / ECHO",UDim2.new(0,32,0,32),UDim2.fromOffset(350,30),26,colors.gold)
label(gui,"COMBAT LAB     /     PARRY PROTOTYPE",UDim2.new(0,34,0,65),UDim2.fromOffset(370,20),11,colors.muted)
local panel=make("Frame",{Name="Controls",BackgroundColor3=Color3.fromRGB(17,24,31),BackgroundTransparency=0.12,BorderSizePixel=0,Position=UDim2.new(0,28,0.5,-130),Size=UDim2.fromOffset(238,250)},gui)
make("UICorner",{CornerRadius=UDim.new(0,10)},panel)
label(panel,"MOVE WITH INTENT",UDim2.fromOffset(18,14),UDim2.fromOffset(205,20),12,colors.gold)
local rows={"M1    4 swings · final hit pushes","F       Tap parry / hold block","Q      Directional dodge","R       Critical · breaks block","M2    Feint / cancel dodge","T       Cycle training mode","G      Reset health & positions","X       Toggle target lock"}
for i,text in ipairs(rows) do label(panel,text,UDim2.fromOffset(18,40+(i-1)*24),UDim2.fromOffset(210,23),12) end
local top=make("Frame",{BackgroundColor3=Color3.fromRGB(17,24,31),BackgroundTransparency=0.12,BorderSizePixel=0,AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,30),Size=UDim2.fromOffset(360,92)},gui)
make("UICorner",{CornerRadius=UDim.new(0,10)},top)
local modeLabel=label(top,"TRAINING PARTNER  /  PASSIVE",UDim2.fromOffset(16,10),UDim2.fromOffset(328,22),13,colors.gold)
local enemyState=label(top,"Approach the partner to begin",UDim2.fromOffset(16,36),UDim2.fromOffset(328,18),11,colors.muted)
local enemyBar=make("Frame",{BackgroundColor3=colors.red,BorderSizePixel=0,Position=UDim2.fromOffset(16,64),Size=UDim2.new(1,-32,0,4)},top)
local enemyPosture=make("Frame",{BackgroundColor3=colors.gold,BorderSizePixel=0,Position=UDim2.fromOffset(16,75),Size=UDim2.new(0,0,0,3)},top)
local bottom=make("Frame",{AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-30),Size=UDim2.fromOffset(460,126),BackgroundColor3=Color3.fromRGB(17,24,31),BackgroundTransparency=0.1,BorderSizePixel=0},gui)
make("UICorner",{CornerRadius=UDim.new(0,10)},bottom)
local stateLabel=label(bottom,"READY",UDim2.fromOffset(18,10),UDim2.fromOffset(424,22),13,colors.cyan)
local hpBack=make("Frame",{BackgroundColor3=Color3.fromRGB(45,53,61),BorderSizePixel=0,Position=UDim2.fromOffset(18,42),Size=UDim2.fromOffset(424,8)},bottom)
local hpFill=make("Frame",{BackgroundColor3=colors.cyan,BorderSizePixel=0,Size=UDim2.fromScale(1,1)},hpBack)
local postBack=make("Frame",{BackgroundColor3=Color3.fromRGB(45,53,61),BorderSizePixel=0,Position=UDim2.fromOffset(18,58),Size=UDim2.fromOffset(424,5)},bottom)
local postFill=make("Frame",{BackgroundColor3=colors.gold,BorderSizePixel=0,Size=UDim2.fromScale(0,1)},postBack)
local healthLabel=label(bottom,"",UDim2.fromOffset(280,10),UDim2.fromOffset(162,22),11,colors.muted) healthLabel.TextXAlignment=Enum.TextXAlignment.Right
local cooldownLabel=label(bottom,"",UDim2.fromOffset(18,77),UDim2.fromOffset(424,22),12)
local tip=label(bottom,"Blue = parry window   ·   Red = block-breaking critical",UDim2.fromOffset(18,103),UDim2.fromOffset(424,16),10,colors.muted)
local notice=label(gui,"Press T to choose a training mode",UDim2.new(0.5,-250,0.72,0),UDim2.fromOffset(500,32),21,colors.gold) notice.TextXAlignment=Enum.TextXAlignment.Center
local statsLabel=label(gui,"",UDim2.new(1,-245,1,-120),UDim2.fromOffset(222,85),12,colors.muted)
local lockLabel=label(gui,"TARGET LOCK  /  ON",UDim2.new(1,-225,0,40),UDim2.fromOffset(200,26),12,colors.cyan)
local reticle=label(gui,"◇",UDim2.fromOffset(0,0),UDim2.fromOffset(36,36),28,colors.gold) reticle.AnchorPoint=Vector2.new(0.5,0.5) reticle.TextXAlignment=Enum.TextXAlignment.Center
local function message(text,color)
    notice.Text=text notice.TextColor3=color or colors.gold feedbackUntil=now()+1.7
end
local function activeState(model)
    if model==char and predicted and now()-predicted.time<0.2 then return predicted.name,predicted.time,predicted.combo end
    return model:GetAttribute("CombatState") or "Idle",model:GetAttribute("ActionStart") or 0,model:GetAttribute("Combo") or 1
end
local function target()
    local arena=workspace:FindFirstChild("ParryArena") return arena and arena:FindFirstChild("TrainingPartner")
end
local function request(action)
    if not char or not hum or hum.Health<=0 then return end
    local st=activeState(char)
    local dir
    if action=="Dodge" then
        dir=hum.MoveDirection
        if dir.Magnitude<0.1 then dir=-root.CFrame.LookVector end
    end
    sequence+=1
    if (action=="Light" or action=="Heavy" or action=="Dodge" or action=="Parry") and (st=="Idle" or st=="Block") then
        local name=action
        local ready=char:GetAttribute(({Dodge="DodgeReady",Heavy="HeavyReady",Parry="ParryReady"})[action] or "_") or 0
        if now()>=ready then
            local last=char:GetAttribute("LastAttack") or 0
            local nextCombo=now()-last>Config.ComboReset and 1 or (char:GetAttribute("Combo") or 0)%Config.ComboMax+1
            predicted={name=name,time=now(),combo=nextCombo,sequence=sequence}
        end
    elseif action=="Cancel" then
        if st=="Light" and now()-(char:GetAttribute("ActionStart") or 0)<Config.Attack("Light",char:GetAttribute("Combo") or 1).FeintUntil then
            predicted={name="Feint",time=now(),combo=1,sequence=sequence}
        elseif st=="Dodge" then predicted={name="RollCancel",time=now(),combo=1,sequence=sequence} end
    end
    Event:FireServer(action,dir,sequence)
end
local function attack(action)
    if not char then return end
    local st,started=activeState(char)
    if st=="Light" or st=="Heavy" or st=="Feint" or st=="RollCancel" then
        local dur=char:GetAttribute("ActionDuration") or 0
        if now()-started>dur-0.24 then buffered={action=action,expires=now()+0.30} end
    else request(action) end
end
local bindings={Attack={Enum.UserInputType.MouseButton1},Parry={Enum.KeyCode.F},Dodge={Enum.KeyCode.Q},Heavy={Enum.KeyCode.R,Enum.UserInputType.MouseButton3},Cancel={Enum.UserInputType.MouseButton2},Mode={Enum.KeyCode.T},Reset={Enum.KeyCode.G},Lock={Enum.KeyCode.X}}
for name,keys in pairs(bindings) do
    CAS:BindActionAtPriority("Combat"..name,function(_,input)
        if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
        if input==Enum.UserInputState.Begin then
            if name=="Attack" then attack("Light")
            elseif name=="Heavy" then attack("Heavy")
            elseif name=="Mode" then request("TrainingMode")
            elseif name=="Reset" then request("ResetTraining")
            elseif name=="Lock" then locked=not locked
            else request(name) end
        elseif input==Enum.UserInputState.End and name=="Parry" then request("BlockEnd") end
        return Enum.ContextActionResult.Sink
    end,false,3000,table.unpack(keys))
end
UIS.WindowFocusReleased:Connect(function() request("BlockEnd") end)
local function onCharacter(c)
    char=c hum=c:WaitForChild("Humanoid") root=c:WaitForChild("HumanoidRootPart")
    predicted=nil buffered=nil
    player.CameraMinZoomDistance=8 player.CameraMaxZoomDistance=22
    camera.CameraSubject=hum camera.CameraType=Enum.CameraType.Custom
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then task.spawn(onCharacter,player.Character) end
local function registerRig(model)
    if rigs[model] then return end
    local joints={}
    for _,v in ipairs(model:GetDescendants()) do
        if v:IsA("Motor6D") or v:IsA("AnimationConstraint") then joints[v.Name]=v end
    end
    local glow=make("Highlight",{Name="CombatTelegraph",Enabled=false,FillColor=colors.red,OutlineColor=colors.red,FillTransparency=0.7,OutlineTransparency=0.1,DepthMode=Enum.HighlightDepthMode.Occluded},model)
    rigs[model]={model=model,joints=joints,poses={},glow=glow}
    -- Tags can arrive before the rig's descendants finish replicating.
    model.DescendantAdded:Connect(function(v)
        if v:IsA("Motor6D") or v:IsA("AnimationConstraint") then joints[v.Name]=v end
    end)
    task.delay(0.5,function()
        if model.Parent then
            for _,v in ipairs(model:GetDescendants()) do if v:IsA("Motor6D") or v:IsA("AnimationConstraint") then joints[v.Name]=v end end
        end
    end)
end
for _,m in ipairs(CollectionService:GetTagged("CombatFighter")) do registerRig(m) end
CollectionService:GetInstanceAddedSignal("CombatFighter"):Connect(registerRig)
local function rot(x,y,z) return CFrame.Angles(math.rad(x),math.rad(y),math.rad(z)) end
local function smooth(a) a=math.clamp(a,0,1) return a*a*(3-2*a) end
local function blend(a,b,t) return a:Lerp(b,smooth(t)) end
local function animate(model,rig,dt)
    local h=model:FindFirstChildOfClass("Humanoid") local r=model:FindFirstChild("HumanoidRootPart")
    if not h or not r or not Animations.Ready(rig) then return end
    local st,start,combo=activeState(model)
    local elapsed=now()-start
    local speed=Vector3.new(r.AssemblyLinearVelocity.X,0,r.AssemblyLinearVelocity.Z).Magnitude
    local moving=math.clamp(speed/16,0,1)
    local cycle=now()*10
    local pose=Animations.Guard(rig)
    pose.Root=pose.Root*CFrame.new(0,math.sin(now()*2.5)*0.012,0)*rot(-moving*3,0,0)
    pose.RightHip=pose.RightHip*rot(math.sin(cycle)*25*moving,0,0)
    pose.LeftHip=pose.LeftHip*rot(-math.sin(cycle)*25*moving,0,0)
    if rig.state~=st or (rig.actionStart~=start and st~="Idle") then
        rig.entry=table.clone(rig.poses)
        for n,v in pairs(pose) do if not rig.entry[n] then rig.entry[n]=v end end
        rig.state=st rig.actionStart=start
    end
    if st=="Light" or st=="Heavy" then
        pose=Animations.Attack(st,combo,elapsed,rig.entry,rig)
    elseif st=="Parry" then
        pose=Animations.Parry(rig,elapsed)
    elseif st=="Block" then
        pose=Animations.Block(rig)
    elseif st=="Dodge" then
        local a=math.clamp(elapsed/Config.DodgeDuration,0,1)
        local direction=model:GetAttribute("DodgeDirection") or -r.CFrame.LookVector
        local localDir=r.CFrame:VectorToObjectSpace(direction)
        pose.Root=CFrame.new(0,-math.sin(a*math.pi)*0.8,0)*CFrame.Angles(-localDir.Z*a*math.pi*2,0,-localDir.X*a*math.pi*2)
        pose.RightShoulder=pose.RightShoulder*rot(65,0,-15) pose.LeftShoulder=rot(65,0,15)
        pose.RightElbow=pose.RightElbow*rot(30,0,0) pose.LeftElbow=rot(30,0,0)
        pose.RightHip=rot(-55,0,0) pose.LeftHip=rot(-55,0,0)
    elseif st=="Stunned" or st=="GuardBroken" or st=="Defeated" then
        pose.Root=rot(st=="GuardBroken" and 35 or -16,0,0)
        pose.RightShoulder=pose.RightShoulder*rot(15,0,-25) pose.LeftShoulder=rot(10,0,25)
        pose.RightElbow=pose.RightElbow*rot(25,0,0) pose.LeftElbow=rot(20,0,0)
        pose.Neck=rot(20,0,0)
    elseif st=="Feint" then
        pose.RightShoulder=pose.RightShoulder*rot(25,15,-25) pose.Root=rot(-6,-12,0)
    end
    for name,joint in pairs(rig.joints) do
        if name~="SwordGrip" then
            local desired=pose[name] or CFrame.identity
            local previous=rig.poses[name] or CFrame.identity
            -- Attack curves are already eased; extra smoothing would lag behind contact.
            local value=(st=="Light" or st=="Heavy" or st=="Parry") and desired or previous:Lerp(desired,1-math.exp(-dt*(st=="Dodge" and 45 or 22)))
            joint.Transform=value rig.poses[name]=value
        end
    end
    local sword=model:FindFirstChild("PracticeSword")
    local attackData=(st=="Light" or st=="Heavy") and Config.Attack(st,combo) or nil
    local critical=st=="Heavy" and elapsed<Config.Heavy.Windup+Config.Heavy.Active
    rig.glow.Enabled=critical or st=="Parry"
    rig.glow.FillColor=critical and colors.red or colors.cyan
    rig.glow.OutlineColor=rig.glow.FillColor
    rig.glow.FillTransparency=critical and (0.65+0.12*math.sin(elapsed*24)) or 0.85
    if sword then
        local trail=sword:FindFirstChild("BladeTrail",true)
        if trail then
            trail.Enabled=(attackData~=nil and elapsed>=attackData.SwingStart and elapsed<attackData.Windup+attackData.Active) or (st=="Parry" and elapsed>0.05 and elapsed<0.19)
            trail.Color=ColorSequence.new(critical and colors.red or st=="Parry" and colors.gold or colors.white)
        end
        local light=sword:FindFirstChild("CriticalGlow",true)
        if light then light.Brightness=critical and (1.2+math.sin(elapsed*24)*0.3) or 0 end
    end
end
RunService.PreSimulation:Connect(function(dt)
    for model,rig in pairs(rigs) do
        if model.Parent then animate(model,rig,dt) else rigs[model]=nil end
    end
    if char and root then
        local untilTime=char:GetAttribute("KnockUntil") or 0
        if now()<untilTime then
            local direction=char:GetAttribute("KnockDirection")
            local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={char}
            local blocked=workspace:Raycast(root.Position,direction*2,rp)
            root.AssemblyLinearVelocity=(blocked and Vector3.zero or direction*(char:GetAttribute("KnockSpeed") or 0))+Vector3.new(0,root.AssemblyLinearVelocity.Y,0)
        end
    end
end)
local audioFolder=make("Folder",{Name="CombatAudio"},game:GetService("SoundService"))
local audioTemplates={}
for name,data in pairs(Config.Sounds) do
    local sound=make("Sound",{Name=name,SoundId=data.Id,Volume=data.Volume,PlaybackSpeed=data.Speed,RollOffMinDistance=7,RollOffMaxDistance=75,RollOffMode=Enum.RollOffMode.InverseTapered},audioFolder)
    if name=="Block" then make("EqualizerSoundEffect",{HighGain=-9,MidGain=1,LowGain=2},sound) end
    if name=="Parry" then make("EqualizerSoundEffect",{HighGain=3,MidGain=1,LowGain=-4},sound) end
    audioTemplates[name]=sound
end
task.spawn(function() pcall(function() game:GetService("ContentProvider"):PreloadAsync(audioFolder:GetChildren()) end) end)
local function playSound(name,model)
    local at=model and model:FindFirstChild("HumanoidRootPart") local template=audioTemplates[name]
    if not at or not template then return end
    local sound=template:Clone() sound.PlaybackSpeed*=1+(math.random()-0.5)*0.07 sound.Parent=at
    sound:Play() Debris:AddItem(sound,4)
end
local function pulse(model,color)
    if not model or not model.Parent then return end
    local hl=make("Highlight",{FillColor=color,OutlineColor=color,FillTransparency=0.55,OutlineTransparency=0.1,DepthMode=Enum.HighlightDepthMode.Occluded},model)
    TweenService:Create(hl,TweenInfo.new(0.3),{FillTransparency=1,OutlineTransparency=1}):Play() Debris:AddItem(hl,0.32)
end
local function sparks(model,color,position)
    local r=model and model:FindFirstChild("HumanoidRootPart") if not r then return end
    for i=1,9 do
        local p=make("Part",{Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Material=Enum.Material.Neon,Color=color,Size=Vector3.new(0.07,0.07,0.6),CFrame=CFrame.new(position or (r.CFrame*CFrame.new(0,0.8,-1.2)).Position)},workspace)
        local d=Vector3.new(math.random()-0.5,math.random()-0.35,math.random()-0.5)*5
        TweenService:Create(p,TweenInfo.new(0.22),{Position=p.Position+d,Transparency=1,Size=Vector3.new(0.01,0.01,0.1)}):Play() Debris:AddItem(p,0.25)
    end
end
Event.OnClientEvent:Connect(function(kind,model,extra)
    if kind=="Ack" then
        if predicted and predicted.sequence==model then predicted=nil end return
    elseif kind=="Mode" then message("TRAINING  /  "..string.upper(extra)) return
    elseif kind=="Notice" then message(extra) return
    elseif kind=="ParrySuccess" then
        playSound("Parry",model) pulse(model,colors.gold)
        local sword=model and model:FindFirstChild("PracticeSword")
        local blade=sword and sword:FindFirstChild("Handle")
        sparks(model,colors.gold,blade and blade.CFrame:PointToWorldSpace(Vector3.new(0,-1.5,0)))
        if model==char then message("PARRY  ·  YOUR TURN",colors.cyan) end
    elseif kind=="BlockHit" then playSound("Block",model) pulse(model,colors.gold) sparks(model,colors.gold) if model==char then message("BLOCK  ·  POSTURE RISING") end
    elseif kind=="GuardBreak" then playSound("Block",model) pulse(model,colors.red) sparks(model,colors.red) if model==char then message("GUARD BROKEN",colors.red) else message("GUARD BREAK  ·  PUNISH",colors.gold) end
    elseif kind=="Hit" then playSound("Hit",model) pulse(model,colors.red) if model==char then message("HIT  ·  TIME YOUR PARRY",colors.red) end
    elseif kind=="Finisher" then sparks(model,colors.white) if extra==char then message("FLOURISH  ·  SPACE CREATED",colors.white) end
    elseif kind=="DodgeSuccess" then pulse(model,colors.cyan) if model==char then message("EVADED",colors.cyan) end
    elseif kind=="Feint" then pulse(model,colors.white) if model==char then message("FEINT",colors.white) end
    elseif kind=="RollCancel" then if model==char then message("ROLL CANCEL",colors.cyan) end
    end
end)
local function cooldown(attribute)
    local remain=math.max(0,(char:GetAttribute(attribute) or 0)-now()) return remain>0 and string.format("%.1f",remain) or "READY"
end
RunService:BindToRenderStep("CombatCamera",Enum.RenderPriority.Camera.Value+1,function(dt)
    if not char or not char.Parent or not root then return end
    local bot=target() local br=bot and bot:FindFirstChild("HumanoidRootPart")
    local st=activeState(char)
    if buffered then
        if now()>buffered.expires then buffered=nil
        elseif st=="Idle" then local action=buffered.action buffered=nil request(action) end
    end
    if locked and br and hum.Health>0 then
        local delta=Vector3.new(br.Position.X-root.Position.X,0,br.Position.Z-root.Position.Z)
        if delta.Magnitude>1 then
            hum.AutoRotate=false
            if st~="Dodge" then root.CFrame=root.CFrame:Lerp(CFrame.lookAt(root.Position,root.Position+delta),1-math.exp(-dt*22)) end
            local focus=root.Position+Vector3.new(0,2,0)
            local back=-delta.Unit
            local desired=focus+back*13+Vector3.new(0,5,0)+root.CFrame.RightVector*2
            local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={char,bot}
            local hit=workspace:Raycast(focus,desired-focus,rp)
            if hit then desired=hit.Position+hit.Normal*0.5 end
            camera.CameraType=Enum.CameraType.Scriptable
            camera.CFrame=camera.CFrame:Lerp(CFrame.lookAt(desired,focus+delta.Unit*4),1-math.exp(-dt*12))
        end
    else
        camera.CameraType=Enum.CameraType.Custom hum.AutoRotate=st~="Dodge"
    end
    lockLabel.Text="TARGET LOCK  /  "..(locked and "ON" or "OFF")
    reticle.Visible=locked and br~=nil
    if br then
        local point,visible=camera:WorldToViewportPoint(br.Position+Vector3.new(0,3.7,0))
        reticle.Position=UDim2.fromOffset(point.X,point.Y) reticle.Visible=locked and visible
        local bh=bot:FindFirstChildOfClass("Humanoid")
        enemyBar.Size=UDim2.new(bh and bh.Health/bh.MaxHealth or 0,-32*(bh and bh.Health/bh.MaxHealth or 0),0,4)
        enemyPosture.Size=UDim2.new(0,(bot:GetAttribute("Posture") or 0)/Config.PostureMax*328,0,3)
        modeLabel.Text="TRAINING PARTNER  /  "..string.upper(bot:GetAttribute("TrainingMode") or "Passive")
        local bst=bot:GetAttribute("CombatState") or "Idle"
        local hints={Passive="Practice attacks, feints, and movement",Block="Use heavies to break the frontal guard",["Parry drill"]="Face the partner. Tap F just before impact.",Sparring="Mix attacks, feints, parries, and dodges"}
        enemyState.Text=(bst=="Idle" or bst=="Block") and (hints[bot:GetAttribute("TrainingMode")] or "Ready") or string.upper(bst)
    end
    stateLabel.Text=string.upper(st)..(st=="Parry" and "  /  DEFLECT WINDOW" or (st=="Light" and "  /  "..tostring(char:GetAttribute("Combo") or 1).." OF 4" or ""))
    stateLabel.TextColor3=(st=="Stunned" or st=="GuardBroken") and colors.red or colors.cyan
    hpFill.Size=UDim2.fromScale(hum.Health/hum.MaxHealth,1)
    postFill.Size=UDim2.fromScale((char:GetAttribute("Posture") or 0)/Config.PostureMax,1)
    healthLabel.Text=string.format("%d / %d HP",math.ceil(hum.Health),hum.MaxHealth)
    cooldownLabel.Text="F  "..cooldown("ParryReady").."     Q  "..cooldown("DodgeReady").."     R  "..cooldown("HeavyReady")
    statsLabel.Text=string.format("SESSION PRACTICE\n%d hits    %d parries    %d evades\n%d feints    %d roll cancels",char:GetAttribute("Hits") or 0,char:GetAttribute("Parries") or 0,char:GetAttribute("Dodges") or 0,char:GetAttribute("Feints") or 0,char:GetAttribute("RollCancels") or 0)
    notice.TextTransparency=now()>feedbackUntil and math.min(1,(now()-feedbackUntil)*2) or 0
end)

]====] s.Parent=p end

local function installArena()
-- Run once in Studio Edit mode; only replaces objects owned by this prototype.
local RS=game:GetService("ReplicatedStorage")
local function make(class,name,props,parent)
    local i=Instance.new(class) i.Name=name
    for k,v in pairs(props or {}) do i[k]=v end i.Parent=parent return i
end
local old=workspace:FindFirstChild("ParryArena") if old then old:Destroy() end
local arena=make("Model","ParryArena",{},workspace)
local slate=Color3.fromRGB(38,49,58)
local gold=Color3.fromRGB(197,158,89)
local function part(name,size,cf,color,material,parent)
    return make("Part",name,{Size=size,CFrame=cf,Color=color,Material=material or Enum.Material.SmoothPlastic,Anchored=true,TopSurface=Enum.SurfaceType.Smooth,BottomSurface=Enum.SurfaceType.Smooth},parent or arena)
end
part("TrainingDeck",Vector3.new(84,1,84),CFrame.new(0,0,0),slate,Enum.Material.Slate)
for _,x in ipairs({-42,42}) do part("Border",Vector3.new(1,2,84),CFrame.new(x,0.75,0),gold,Enum.Material.Metal) end
for _,z in ipairs({-42,42}) do part("Border",Vector3.new(84,2,1),CFrame.new(0,0.75,z),gold,Enum.Material.Metal) end
for ring,radius in ipairs({12,25,37}) do
    for i=1,64 do
        local theta=i*math.pi*2/64
        local p=part("ArenaInlay",Vector3.new(0.12,0.035,radius*math.pi*2/64+0.08),CFrame.new(math.cos(theta)*radius,0.526,math.sin(theta)*radius)*CFrame.Angles(0,-theta,0),ring==1 and gold or Color3.fromRGB(67,83,92),Enum.Material.Metal)
        p.CanCollide=false p.CanQuery=false
    end
end
for x=-3,3 do
    local p=part("TileSeam",Vector3.new(0.04,0.025,82),CFrame.new(x*10,0.518,0),Color3.fromRGB(55,65,73)) p.CanCollide=false p.CanQuery=false
end
for z=-3,3 do
    local p=part("TileSeam",Vector3.new(82,0.025,0.04),CFrame.new(0,0.518,z*10),Color3.fromRGB(55,65,73)) p.CanCollide=false p.CanQuery=false
end
for _,x in ipairs({-34,34}) do
    for _,z in ipairs({-34,34}) do
        part("PillarBase",Vector3.new(5,1,5),CFrame.new(x,1,z),Color3.fromRGB(24,33,40),Enum.Material.Slate)
        part("Pillar",Vector3.new(2.8,12,2.8),CFrame.new(x,7,z),Color3.fromRGB(49,62,70),Enum.Material.Slate)
        part("PillarCap",Vector3.new(4,0.5,4),CFrame.new(x,13.2,z),gold,Enum.Material.Metal)
        local lamp=part("Beacon",Vector3.new(1,2,1),CFrame.new(x,14.4,z),Color3.fromRGB(126,230,224),Enum.Material.Neon)
        make("PointLight","Glow",{Color=lamp.Color,Brightness=1.4,Range=22},lamp)
    end
end
local board=part("TrainingSign",Vector3.new(20,6,0.6),CFrame.new(0,7,-32),Color3.fromRGB(18,26,34),Enum.Material.Metal)
local surface=make("SurfaceGui","Sign",{Face=Enum.NormalId.Back,CanvasSize=Vector2.new(1000,300)},board)
make("TextLabel","Title",{BackgroundTransparency=1,Size=UDim2.new(1,0,0.5,0),Text="IRON / ECHO",Font=Enum.Font.GothamBold,TextSize=70,TextColor3=gold},surface)
make("TextLabel","Subtitle",{BackgroundTransparency=1,Position=UDim2.fromScale(0,0.5),Size=UDim2.fromScale(1,0.5),Text="READ  ·  DEFLECT  ·  RESPOND",Font=Enum.Font.GothamMedium,TextSize=30,TextColor3=Color3.fromRGB(198,214,219)},surface)
local function rig(name,color,parent)
    local m=make("Model",name,{},parent)
    local function body(n,size,pos,c,trans)
        return make("Part",n,{Size=size,Position=pos,Color=c,Transparency=trans or 0,CanCollide=n=="Torso" or n=="Head",CanTouch=false,TopSurface=Enum.SurfaceType.Smooth,BottomSurface=Enum.SurfaceType.Smooth},m)
    end
    local root=body("HumanoidRootPart",Vector3.new(2,2,1),Vector3.new(0,3,0),color,1) root.CanCollide=false
    local torso=body("Torso",Vector3.new(2,2,1),Vector3.new(0,3,0),color)
    local head=body("Head",Vector3.new(2,1,1),Vector3.new(0,4.5,0),Color3.fromRGB(209,192,160))
    make("SpecialMesh","HeadMesh",{MeshType=Enum.MeshType.Head,Scale=Vector3.new(1.15,1.15,1.15)},head)
    local ra=body("Right Arm",Vector3.new(1,2,1),Vector3.new(1.5,3,0),color)
    local la=body("Left Arm",Vector3.new(1,2,1),Vector3.new(-1.5,3,0),color)
    local rl=body("Right Leg",Vector3.new(1,2,1),Vector3.new(0.5,1,0),Color3.fromRGB(35,41,48))
    local ll=body("Left Leg",Vector3.new(1,2,1),Vector3.new(-0.5,1,0),Color3.fromRGB(35,41,48))
    local function joint(n,a,b,c0,c1) make("Motor6D",n,{Part0=a,Part1=b,C0=c0,C1=c1},a) end
    joint("RootJoint",root,torso,CFrame.identity,CFrame.identity)
    joint("Neck",torso,head,CFrame.new(0,1,0),CFrame.new(0,-0.5,0))
    joint("Right Shoulder",torso,ra,CFrame.new(1.5,0.5,0),CFrame.new(0,0.5,0))
    joint("Left Shoulder",torso,la,CFrame.new(-1.5,0.5,0),CFrame.new(0,0.5,0))
    joint("Right Hip",torso,rl,CFrame.new(0.5,-1,0),CFrame.new(0,1,0))
    joint("Left Hip",torso,ll,CFrame.new(-0.5,-1,0),CFrame.new(0,1,0))
    local h=make("Humanoid","Humanoid",{DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None,RequiresNeck=true,MaxHealth=150,Health=150},m)
    make("Animator","Animator",{},h)
    m.PrimaryPart=root
    -- Simple helmet and chest trim, welded and lightweight.
    local visor=body("Visor",Vector3.new(1.35,0.17,0.15),Vector3.new(0,4.55,-0.56),Color3.fromRGB(126,230,224))
    visor.Material=Enum.Material.Neon visor.CanCollide=false visor.Massless=true
    make("WeldConstraint","VisorWeld",{Part0=head,Part1=visor},visor)
    return m
end
local starter=game.StarterPlayer:FindFirstChild("StarterCharacter") if starter then starter:Destroy() end
rig("StarterCharacter",Color3.fromRGB(65,104,118),game.StarterPlayer)
local bot=rig("TrainingPartner",Color3.fromRGB(123,78,64),arena)
bot:PivotTo(CFrame.lookAt(Vector3.new(0,3.5,-3),Vector3.new(0,3.5,12)))
local oldSword=RS.ParryCombat:FindFirstChild("PracticeSword") if oldSword then oldSword:Destroy() end
local sword=make("Model","PracticeSword",{},RS.ParryCombat)
local handle=part("Handle",Vector3.new(0.22,0.75,0.22),CFrame.identity,Color3.fromRGB(50,40,35),Enum.Material.Leather,sword)
local blade=part("Blade",Vector3.new(0.32,2.9,0.12),CFrame.new(0,-1.8,0),Color3.fromRGB(204,219,225),Enum.Material.Metal,sword)
local edge=part("Edge",Vector3.new(0.055,2.9,0.13),CFrame.new(0.16,-1.8,0),Color3.fromRGB(151,239,235),Enum.Material.Neon,sword)
local guard=part("Guard",Vector3.new(1,0.13,0.32),CFrame.new(0,-0.36,0),gold,Enum.Material.Metal,sword)
local pommel=part("Pommel",Vector3.new(0.32,0.2,0.32),CFrame.new(0,0.45,0),gold,Enum.Material.Metal,sword)
for _,p in ipairs(sword:GetChildren()) do
    if p:IsA("BasePart") then
        p.Anchored=false p.Massless=true p.CanCollide=false p.CanTouch=false p.CanQuery=false
        if p~=handle then make("WeldConstraint","SwordWeld",{Part0=handle,Part1=p},p) end
    end
end
local a=make("Attachment","TrailBase",{Position=Vector3.new(0,-0.5,0)},handle)
local b=make("Attachment","TrailTip",{Position=Vector3.new(0,-3.25,0)},handle)
make("Trail","BladeTrail",{Attachment0=a,Attachment1=b,Lifetime=0.13,MinLength=0.05,FaceCamera=true,LightEmission=0.8,Color=ColorSequence.new(Color3.fromRGB(150,230,226)),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.25),NumberSequenceKeypoint.new(1,1)}),Enabled=false},handle)
sword.PrimaryPart=handle
local spawn=workspace:FindFirstChildOfClass("SpawnLocation")
if spawn then spawn.CFrame=CFrame.new(0,0.7,12) spawn.Transparency=1 spawn.CanCollide=false spawn.Duration=0 end
local lighting=game:GetService("Lighting")
lighting.ClockTime=16 lighting.Brightness=2 lighting.Ambient=Color3.fromRGB(98,113,128) lighting.OutdoorAmbient=Color3.fromRGB(125,137,150)
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(35,32,40),Vector3.new(0,1,0))
return "Arena, original R6 fighters and sword created."

end
installArena()

local function refineAssets()
-- Idempotent upgrade of the existing prototype rig and sword in Edit mode.
local kit=game.ReplicatedStorage.ParryCombat
local function make(class,name,props,parent)
    local i=Instance.new(class) i.Name=name for k,v in pairs(props) do i[k]=v end i.Parent=parent return i
end
local function articulate(model)
    if not model or not model:FindFirstChild("Torso") then return end
    if model:GetAttribute("ArticulatedArms") then return end
    for _,side in ipairs({"Right","Left"}) do
        local upper=model:FindFirstChild(side.." Arm")
        local shoulder=model.Torso:FindFirstChild(side.." Shoulder")
        upper.Size=Vector3.new(0.8,0.95,0.85)
        shoulder.C0=CFrame.new(side=="Right" and 1.4 or -1.4,0.65,0)
        shoulder.C1=CFrame.new(0,0.35,0)
        local function body(name,size,cf,color)
            return make("Part",name,{Size=size,CFrame=cf,Color=color,CanCollide=false,CanTouch=false,Massless=true,TopSurface=Enum.SurfaceType.Smooth,BottomSurface=Enum.SurfaceType.Smooth},model)
        end
        upper.CFrame=model.Torso.CFrame*shoulder.C0*shoulder.C1:Inverse()
        local fore=body(side.."Forearm",Vector3.new(0.66,0.8,0.7),upper.CFrame*CFrame.new(0,-0.875,0),upper.Color:Lerp(Color3.fromRGB(35,42,50),0.4))
        local hand=body(side.."Hand",Vector3.new(0.58,0.4,0.58),fore.CFrame*CFrame.new(0,-0.6,0),Color3.fromRGB(64,51,44))
        make("Motor6D",side.." Elbow",{Part0=upper,Part1=fore,C0=CFrame.new(0,-0.475,0),C1=CFrame.new(0,0.4,0)},upper)
        make("Motor6D",side.." Wrist",{Part0=fore,Part1=hand,C0=CFrame.new(0,-0.4,0),C1=CFrame.new(0,0.2,0)},fore)
        local cuff=body(side.."Bracer",Vector3.new(0.73,0.2,0.76),fore.CFrame*CFrame.new(0,-0.24,0),Color3.fromRGB(138,128,105))
        make("WeldConstraint","CuffWeld",{Part0=fore,Part1=cuff},cuff)
    end
    model:SetAttribute("ArticulatedArms",true)
end
articulate(game.StarterPlayer.StarterCharacter)
articulate(workspace.ParryArena.TrainingPartner)
local old=kit:FindFirstChild("PracticeSword") if old then old:Destroy() end
local sword=make("Model","PracticeSword",{},kit)
local steel=Color3.fromRGB(168,185,198)
local edge=Color3.fromRGB(220,231,235)
local brass=Color3.fromRGB(161,127,73)
local function part(name,size,cf,color,material,shape)
    return make("Part",name,{Size=size,CFrame=cf,Color=color,Material=material or Enum.Material.Metal,Shape=shape or Enum.PartType.Block,Massless=true,CanCollide=false,CanTouch=false,CanQuery=false,TopSurface=Enum.SurfaceType.Smooth,BottomSurface=Enum.SurfaceType.Smooth},sword)
end
local handle=part("Handle",Vector3.new(0.21,0.85,0.24),CFrame.identity,Color3.fromRGB(55,38,31),Enum.Material.Leather)
for i=0,7 do part("LeatherWrap",Vector3.new(0.235,0.04,0.27),CFrame.new(0,-0.36+i*0.1,0)*CFrame.Angles(0,0,math.rad(-7)),Color3.fromRGB(86,61,43),Enum.Material.Leather) end
for _,y in ipairs({-0.45,0.46}) do part("GripFerrule",Vector3.new(0.3,0.1,0.31),CFrame.new(0,y,0),brass) end
part("GuardCenter",Vector3.new(0.46,0.2,0.34),CFrame.new(0,-0.52,0),brass)
for _,side in ipairs({-1,1}) do
    for i=1,3 do
        part("SweptQuillon",Vector3.new(0.28,0.12,0.22),CFrame.new(side*(0.16+i*0.21),-0.52-i*i*0.022,0)*CFrame.Angles(0,0,math.rad(side*-i*7)),brass)
    end
    part("QuillonTip",Vector3.new(0.17,0.19,0.24),CFrame.new(side*0.85,-0.75,0),steel,Enum.Material.Metal,Enum.PartType.Ball)
end
part("Ricasso",Vector3.new(0.38,0.38,0.16),CFrame.new(0,-0.78,0),steel)
-- Continuous flats and bevels avoid a stepped silhouette. Mirrored wedges form the point.
part("Blade",Vector3.new(0.32,2.14,0.105),CFrame.new(0,-2.04,0),steel)
for _,side in ipairs({-1,1}) do
    part("CuttingBevel",Vector3.new(0.03,2.14,0.07),CFrame.new(side*0.17,-2.04,0)*CFrame.Angles(0,math.rad(side*25),0),edge)
    make("WedgePart","BladePoint",{Size=Vector3.new(0.085,0.65,0.185),CFrame=CFrame.new(side*0.0925,-3.435,0)*CFrame.Angles(0,side*math.pi/2,0)*CFrame.Angles(math.pi,0,0),Color=edge,Material=Enum.Material.Metal,Massless=true,CanCollide=false,CanTouch=false,CanQuery=false},sword)
end
for _,z in ipairs({-0.056,0.056}) do part("Fuller",Vector3.new(0.055,1.95,0.012),CFrame.new(0,-1.99,z),Color3.fromRGB(80,98,114)) end
part("WheelPommel",Vector3.new(0.36,0.39,0.22),CFrame.new(0,0.66,0),brass,Enum.Material.Metal,Enum.PartType.Ball)
for _,z in ipairs({-0.11,0.11}) do part("PommelInlay",Vector3.new(0.15,0.15,0.045),CFrame.new(0,0.66,z),Color3.fromRGB(55,126,135),Enum.Material.Glass,Enum.PartType.Ball) end
for _,p in ipairs(sword:GetChildren()) do
    if p:IsA("BasePart") and p~=handle then make("WeldConstraint","SwordWeld",{Part0=handle,Part1=p},p) end
end
local a=make("Attachment","TrailBase",{Position=Vector3.new(0,-1.0,0)},handle)
local b=make("Attachment","TrailTip",{Position=Vector3.new(0,-3.73,0)},handle)
make("Trail","BladeTrail",{Attachment0=a,Attachment1=b,Lifetime=0.085,MinLength=0.03,FaceCamera=true,LightEmission=0.35,Color=ColorSequence.new(Color3.fromRGB(208,226,235)),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.55),NumberSequenceKeypoint.new(1,1)}),Enabled=false},handle)
make("PointLight","CriticalGlow",{Color=Color3.fromRGB(255,45,35),Brightness=0,Range=8,Shadows=false},handle)
sword.PrimaryPart=handle
return "Articulated arms and refined sword installed"

end
refineAssets()

local function installDefaultAvatar()
-- Replace the prototype's custom R6 fighter with standard Roblox R15 avatars.
-- With no StarterCharacter, Roblox loads each player's normal avatar appearance.
local players=game:GetService("Players")
local model=players:CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"),Enum.HumanoidRigType.R15)
model.Name="TrainingPartner"
local humanoid=model:FindFirstChildOfClass("Humanoid")
humanoid.MaxHealth=150
humanoid.Health=150
humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
local arena=workspace:WaitForChild("ParryArena")
local previous=arena:FindFirstChild("TrainingPartner")
if previous then previous:Destroy() end
model.Parent=arena
model:PivotTo(CFrame.lookAt(Vector3.new(0,3.5,-3),Vector3.new(0,3.5,12)))
local starter=game.StarterPlayer:FindFirstChild("StarterCharacter")
if starter then starter:Destroy() end
return "Default player avatar enabled; R15 practice partner installed"

end
installDefaultAvatar()

