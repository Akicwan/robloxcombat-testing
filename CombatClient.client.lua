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
