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
