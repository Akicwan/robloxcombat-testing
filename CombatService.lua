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
