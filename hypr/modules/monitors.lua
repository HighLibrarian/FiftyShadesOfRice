------------------
---- MONITORS ----
------------------
-- rotations
-- 0: normal landscape
-- 1: normal portrait
-- 2: flipped landscape
-- 3: flipped portrait


-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

hl.monitor({
    output   = "desc: HP Inc. HP E24m G4 CNC2121H6V",
    mode     = "preferred",
    position = "auto-up",
    scale    = "auto",
    transform = 0
})

hl.monitor({
    output   = "desc: HP Inc. HP E24 G5 CNK3050FS6",
    mode     = "preferred",
    position = "auto-left",
    scale    = "auto",
    transform = 3
})


-- workspacerules (workspace 1-5 on main monitor)
hl.workspace_rule({ workspace = "1", monitor = "eDP-1", persistent = true})
hl.workspace_rule({ workspace = "2", monitor = "eDP-1", persistent = true})
hl.workspace_rule({ workspace = "3", monitor = "eDP-1", persistent = true})
hl.workspace_rule({ workspace = "4", monitor = "eDP-1", persistent = true})
hl.workspace_rule({ workspace = "5", monitor = "eDP-1", persistent = true})