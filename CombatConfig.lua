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
