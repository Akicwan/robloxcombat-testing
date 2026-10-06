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
