-- Lampwrights blessing NPC (creature 900013). Gives level-appropriate class buffs.
local BUFFER = 900013
local TEXT = 68 -- stock npc_text "Greetings, $n."

-- {min player level, spell id}; highest matching rank wins
local BUFFS = {
  { {1,1243},{12,1244},{24,1245},{36,2791},{48,10937},{60,10938},{70,25389},{80,48161} }, -- Power Word: Fortitude
  { {1,1126},{10,5232},{20,6756},{30,5234},{40,8907},{50,9884},{60,9885},{70,26990},{80,48469} }, -- Mark of the Wild
  { {1,1459},{14,1460},{28,1461},{42,10156},{56,10157},{70,27126},{80,42995} }, -- Arcane Intellect
  { {20,20217} }, -- Blessing of Kings
}

local function rankFor(ranks, level)
  local spell
  for _, r in ipairs(ranks) do
    if level >= r[1] then spell = r[2] end
  end
  return spell
end

local function OnHello(event, player, creature)
  player:GossipClearMenu()
  player:GossipMenuAddItem(0, "Bless me for the road.", 0, 1)
  player:GossipSendMenu(TEXT, creature)
end

local function OnSelect(event, player, creature, sender, intid)
  if intid == 1 then
    local level = player:GetLevel()
    for _, ranks in ipairs(BUFFS) do
      local spell = rankFor(ranks, level)
      if spell then player:AddAura(spell, player) end
    end
    creature:SendUnitSay("Walk in the light of the lamp, " .. player:GetName() .. ".", 0)
  end
  player:GossipComplete()
end

RegisterCreatureGossipEvent(BUFFER, 1, OnHello)
RegisterCreatureGossipEvent(BUFFER, 2, OnSelect)
