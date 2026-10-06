-- Run on the Studio client. Verify the actual R15 joint chain and cutting edge.
local Anim=require(game.ReplicatedStorage.ParryCombat.CombatAnimations)
local Config=require(game.ReplicatedStorage.ParryCombat.Config)
local model=game.Players.LocalPlayer.Character
local joints={}
for _,joint in model:GetDescendants() do
    if joint:IsA("AnimationConstraint") or joint:IsA("Motor6D") then joints[joint.Name]=joint end
end
local rig={model=model,joints=joints}
assert(Anim.Ready(rig),"R15 combat joints missing")
local function actualBlade(pose)
    local root=model.HumanoidRootPart.CFrame
    local lower=root*joints.Root.C0*pose.Root*joints.Root.C1:Inverse()
    local torso=lower*joints.Waist.C0*pose.Waist*joints.Waist.C1:Inverse()
    local arm=torso*joints.RightShoulder.C0*pose.RightShoulder*joints.RightShoulder.C1:Inverse()
    local fore=arm*joints.RightElbow.C0*pose.RightElbow*joints.RightElbow.C1:Inverse()
    local hand=fore*joints.RightWrist.C0*pose.RightWrist*joints.RightWrist.C1:Inverse()
    return hand*Anim.Grip
end
local result={}
local guard=actualBlade(Anim.Guard(rig))
local raised=-guard.UpVector
table.insert(result,{name="One-handed raised guard points forward",passed=raised.Y>0.7 and raised:Dot(model.HumanoidRootPart.CFrame.LookVector)>0.35,bladeDirection=tostring(raised)})
local function localTip(blade)
    return model.HumanoidRootPart.CFrame:PointToObjectSpace(blade:PointToWorldSpace(Vector3.new(0,-3.76,0)))
end
local catch=localTip(actualBlade(Anim.Parry(rig,0.07)))
local deflect=localTip(actualBlade(Anim.Parry(rig,0.16)))
table.insert(result,{name="Parry crosses and deflects the incoming blade",passed=catch.X< -0.8 and deflect.X>2 and catch.Y>2 and deflect.Y>2,catch=tostring(catch),deflect=tostring(deflect)})
for combo=1,4 do
    local profile=Config.Attack("Light",combo)
    local largestReachError=0
    local leastEdgeAlignment=1
    local arc=0
    local previous=nil
    for sample=1,50 do
        local t=profile.SwingStart+0.015+(profile.Windup+profile.Active-profile.SwingStart-0.03)*sample/50
        local blade=actualBlade(Anim.Attack("Light",combo,t,nil,rig))
        local before=actualBlade(Anim.Attack("Light",combo,t-0.001,nil,rig))
        local after=actualBlade(Anim.Attack("Light",combo,t+0.001,nil,rig))
        local tip=Vector3.new(0,-3.76,0)
        local currentTip=blade:PointToWorldSpace(tip)
        local velocity=after:PointToWorldSpace(tip)-before:PointToWorldSpace(tip)
        local axis=-blade.UpVector
        local tangent=velocity-axis*velocity:Dot(axis)
        if tangent.Magnitude>0.001 then leastEdgeAlignment=math.min(leastEdgeAlignment,blade.RightVector:Dot(tangent.Unit)) end
        if previous then arc+=(currentTip-previous).Magnitude end
        previous=currentTip
        local target=model.HumanoidRootPart.CFrame*Anim.WeaponFrame("Light",combo,t)
        largestReachError=math.max(largestReachError,(blade.Position-target.Position).Magnitude)
    end
    table.insert(result,{name="M1 "..combo.." broad edge-leading swing",passed=largestReachError<0.04 and leastEdgeAlignment>0.95 and arc>4,edgeAlignment=leastEdgeAlignment,arcStuds=arc,reachError=largestReachError})
end
return game.HttpService:JSONEncode(result)
