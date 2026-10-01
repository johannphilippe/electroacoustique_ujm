-- 00_rebond.lua
-- Échauffement : une "balle qui rebondit".
-- Sélectionnez un item audio court (un son percussif), puis lancez le script.

-- ===== Réglages =====
local nombreRebonds = 12    -- combien de copies
local facteurTemps  = 0.8   -- chaque écart est 80% du précédent
local facteurVolume = 0.85  -- chaque rebond est 85% moins fort que le précédent

-- ===== Outil : dupliquer un item à une position donnée =====
-- (boîte noire : pas besoin de comprendre l'intérieur pour l'utiliser)
local function dupliquer(item, piste, position)
  local _, chunk = reaper.GetItemStateChunk(item, "", false)
  chunk = chunk:gsub("{.-}", "") -- REAPER génèrera de nouveaux identifiants
  local copie = reaper.AddMediaItemToTrack(piste)
  reaper.SetItemStateChunk(copie, chunk, false)
  reaper.SetMediaItemInfo_Value(copie, "D_POSITION", position)
  reaper.SetMediaItemSelected(copie, false)
  return copie
end

-- ===== 1. Récupérer l'item sélectionné =====
local item = reaper.GetSelectedMediaItem(0, 0)
if item == nil then
  reaper.ShowMessageBox("Sélectionnez un item audio d'abord !", "Oups", 0)
  return
end

local piste    = reaper.GetMediaItem_Track(item)
local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
local longueur = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

-- ===== 2. Créer les rebonds =====
reaper.Undo_BeginBlock()

local ecart  = longueur -- le premier écart est égal à la durée du son
local volume = 1

for i = 1, nombreRebonds do
  position = position + ecart
  ecart    = ecart * facteurTemps
  volume   = volume * facteurVolume

  local copie = dupliquer(item, piste, position)
  reaper.SetMediaItemInfo_Value(copie, "D_VOL", volume)
end

reaper.Undo_EndBlock("Rebond", -1)
reaper.UpdateArrange()
