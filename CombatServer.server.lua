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
