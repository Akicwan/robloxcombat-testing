$ErrorActionPreference = 'Stop'
$combatFolder = $PSScriptRoot
$combatHeader = @'
local rs=game:GetService('ReplicatedStorage')
local kit=rs:FindFirstChild('ParryCombat') or Instance.new('Folder') kit.Name='ParryCombat' kit.Parent=rs
local event=kit:FindFirstChild('CombatEvent') or Instance.new('RemoteEvent') event.Name='CombatEvent' event.Parent=kit
'@
$combatMap = @(
    @('CombatConfig.lua','Config','ModuleScript','kit'),
    @('CombatAnimations.lua','CombatAnimations','ModuleScript','kit'),
    @('CombatService.lua','CombatService','ModuleScript','game.ServerScriptService'),
    @('CombatServer.server.lua','CombatServer','Script','game.ServerScriptService'),
    @('CombatClient.client.lua','CombatClient','LocalScript','game.StarterPlayer.StarterPlayerScripts')
)
$combatText = $combatHeader + "`n"
foreach ($combatEntry in $combatMap) {
    $combatSource = Get-Content -Raw -LiteralPath (Join-Path $combatFolder $combatEntry[0])
    $combatText += "do local p=$($combatEntry[3]) local s=p:FindFirstChild('$($combatEntry[1])') or Instance.new('$($combatEntry[2])') s.Name='$($combatEntry[1])' s.Source=[====[`n$combatSource`n]====] s.Parent=p end`n"
}
$arenaSource = Get-Content -Raw -LiteralPath (Join-Path $combatFolder 'InstallArena.lua')
$refinementSource = Get-Content -Raw -LiteralPath (Join-Path $combatFolder 'RefineAssets.lua')
$defaultAvatarSource = Get-Content -Raw -LiteralPath (Join-Path $combatFolder 'InstallDefaultAvatar.lua')
$refinementCall = "`nlocal function refineAssets()`n$refinementSource`nend`nrefineAssets()`n"
$defaultAvatarCall = "`nlocal function installDefaultAvatar()`n$defaultAvatarSource`nend`ninstallDefaultAvatar()`n"
$fullInstall = $combatText + "`nlocal function installArena()`n$arenaSource`nend`ninstallArena()`n" + $refinementCall + $defaultAvatarCall
Set-Content -LiteralPath (Join-Path $combatFolder 'InstallCombat.command.lua') -Value $fullInstall -Encoding utf8
Set-Content -LiteralPath (Join-Path $combatFolder 'InstallRefinement.command.lua') -Value ($combatText + $refinementCall + $defaultAvatarCall) -Encoding utf8
Write-Output 'Generated full installer and in-place refinement installer.'
