local CurTime = CurTime
local fnFindInBox = ents.FindInBox

local fMinCheckInterval = 1             -- Minimum time in seconds between each check
local tOffset = Vector(20, 20, 20)      -- The offset (relative to the player bounds) in which we check for other players
local tDirA = Vector(-30, -30, 0)       -- The direction in which we send the first stuck player
local tDirB = Vector(30, 30, 0)         -- The direction in which we send the second stuck player

local tStuckPlayers = {}
local tNextCollisionCheck = {}

local function checkForCollisions(pPlayer)
    if not pPlayer:Alive() or pPlayer:InVehicle() then return end

    if tStuckPlayers[pPlayer] then
        pPlayer:SetCollisionGroup(COLLISION_GROUP_PLAYER)
        tStuckPlayers[pPlayer] = nil
    end

    local tPos = pPlayer:GetPos()
    local tEntsInBox = fnFindInBox(tPos + pPlayer:OBBMins() + tOffset, tPos + pPlayer:OBBMaxs() - tOffset)

    for i = 1, #tEntsInBox do
        local eOtherEnt = tEntsInBox[i]
        if not eOtherEnt or not eOtherEnt:IsValid() or (eOtherEnt == pPlayer) then continue end
        if not eOtherEnt:IsPlayer() or not eOtherEnt:Alive() or eOtherEnt:InVehicle() then continue end

        tStuckPlayers[pPlayer] = true
    
        pPlayer:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        pPlayer:SetVelocity(tDirA)

        eOtherEnt:SetVelocity(tDirB)
    end
end

hook.Add("SetupMove", "APSO:Move", function(pPlayer, oMove)
    local fTime = CurTime()
    if tNextCollisionCheck[pPlayer] and (fTime < tNextCollisionCheck[pPlayer]) then return end

    tNextCollisionCheck[pPlayer] = (fTime + fMinCheckInterval)

    if (oMove:GetVelocity():LengthSqr() > 0) then
        checkForCollisions(pPlayer)
    end
end)

hook.Add("PlayerDisconnected", "APSO:Disconnect", function(pPlayer)
    tStuckPlayers[pPlayer] = nil
    tNextCollisionCheck[pPlayer] = nil
end)