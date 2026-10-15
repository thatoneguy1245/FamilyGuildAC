-- Lampwrights plate ranks. A rank is earned by turning in its promotion quest to Halric Stone.
local HALRIC = 900011
local COPPER_CONTRACTS = { 900001, 900002, 900003, 900004 }
-- Add later ranks here (Silver, Gold, ...) when their promotion quests exist.
local PROMOTIONS = { { quest = 900101, plate = "Iron", level = 10 } }

local function plateOf(player)
  local plate = "Copper"
  for _, p in ipairs(PROMOTIONS) do
    if player:GetQuestRewardStatus(p.quest) then plate = p.plate end
  end
  return plate
end

local function boardLine(player)
  local done = 0
  for _, q in ipairs(COPPER_CONTRACTS) do
    if player:GetQuestRewardStatus(q) then done = done + 1 end
  end
  return "Job Board: " .. done .. " of " .. #COPPER_CONTRACTS .. " Copper contracts done. Iron promotion opens at level 10 once all are done."
end

local function tell(player)
  player:SendBroadcastMessage("|cffffd100[Lampwrights]|r Your plate: " .. plateOf(player) .. ".")
  if plateOf(player) == "Copper" then player:SendBroadcastMessage(boardLine(player)) end
end

-- On login, and when a player types "#plate" in chat.
RegisterPlayerEvent(3, function(event, player) tell(player) end)
RegisterPlayerEvent(18, function(event, player, msg)
  if msg == "#plate" then tell(player) return false end
end)

-- Halric announces promotions.
RegisterCreatureEvent(HALRIC, 34, function(event, player, creature, quest)
  for _, p in ipairs(PROMOTIONS) do
    if quest:GetId() == p.quest then
      creature:SendUnitYell(player:GetName() .. " now wears the " .. p.plate .. " plate of the Lampwrights!", 0)
      SendWorldMessage("|cffffd100[Lampwrights]|r " .. player:GetName() .. " was promoted to " .. p.plate .. ".")
    end
  end
end)
