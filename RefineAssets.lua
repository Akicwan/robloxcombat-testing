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
