-- 01_scramble.lua
-- Découpe l'item sélectionné en tranches égales, puis les mélange au hasard.

-- ===== Réglages =====
local nombreTranches = 16
local dureeFondu     = 0.005 -- 5 ms de fondu pour éviter les clics

math.randomseed(os.time())

-- ===== 1. Récupérer l'item sélectionné =====
local item = reaper.GetSelectedMediaItem(0, 0)
if item == nil then
  reaper.ShowMessageBox("Sélectionnez un item audio d'abord !", "Oups", 0)
  return
end

local position      = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
local longueur      = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
local tailleTranche = longueur / nombreTranches

reaper.Undo_BeginBlock()

-- ===== 2. Découper =====
-- On coupe toujours le morceau de droite (le "reste"), comme avec des ciseaux.
local tranches = { item }
local reste = item

for i = 1, nombreTranches - 1 do
  reste = reaper.SplitMediaItem(reste, position + i * tailleTranche)
  table.insert(tranches, reste)
end

-- ===== 3. Mélanger =====
-- On pioche les tranches une par une dans un "sac", au hasard.
local melange = {}

for i = 1, nombreTranches do
  local k = math.random(1, #tranches)            -- un numéro au hasard dans le sac
  table.insert(melange, table.remove(tranches, k)) -- on la sort du sac, on la range
end

-- ===== 4. Replacer les tranches dans le nouvel ordre =====
for i = 1, #melange do
  local tranche = melange[i]
  reaper.SetMediaItemInfo_Value(tranche, "D_POSITION", position + (i - 1) * tailleTranche)
  reaper.SetMediaItemInfo_Value(tranche, "D_LENGTH", tailleTranche)
  reaper.SetMediaItemInfo_Value(tranche, "D_FADEINLEN", dureeFondu)
  reaper.SetMediaItemInfo_Value(tranche, "D_FADEOUTLEN", dureeFondu)
end

reaper.Undo_EndBlock("Scramble", -1)
reaper.UpdateArrange()
