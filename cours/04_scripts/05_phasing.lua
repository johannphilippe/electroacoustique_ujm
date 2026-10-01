-- 05_phasing.lua
-- Hommage à Steve Reich (It's Gonna Rain, 1965) : le même son en boucle sur
-- deux pistes, l'une légèrement plus lente, qui se décale peu à peu.
-- Sélectionnez un item court (une phrase parlée, un motif...).

-- ===== Réglages =====
local repetitions = 40
local decalage    = 0.02 -- 20 ms de retard supplémentaire à chaque répétition

-- ===== Outils =====
local function dupliquer(item, piste, position)
  local _, chunk = reaper.GetItemStateChunk(item, "", false)
  chunk = chunk:gsub("{.-}", "")
  local copie = reaper.AddMediaItemToTrack(piste)
  reaper.SetItemStateChunk(copie, chunk, false)
  reaper.SetMediaItemInfo_Value(copie, "D_POSITION", position)
  reaper.SetMediaItemSelected(copie, false)
  return copie
end

local function nouvellePiste(nom)
  local index = reaper.CountTracks(0)
  reaper.InsertTrackAtIndex(index, true)
  local piste = reaper.GetTrack(0, index)
  reaper.GetSetMediaTrackInfo_String(piste, "P_NAME", nom, true)
  return piste
end

-- ===== 1. Récupérer l'item sélectionné =====
local item = reaper.GetSelectedMediaItem(0, 0)
if item == nil then
  reaper.ShowMessageBox("Sélectionnez un item audio d'abord !", "Oups", 0)
  return
end

local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
local longueur = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

reaper.Undo_BeginBlock()

local pisteA = nouvellePiste("Phase A (régulière)")
local pisteB = nouvellePiste("Phase B (en retard)")

-- Pan : A à gauche, B à droite, pour bien entendre le décalage
reaper.SetMediaTrackInfo_Value(pisteA, "D_PAN", -0.7)
reaper.SetMediaTrackInfo_Value(pisteB, "D_PAN", 0.7)

-- ===== 2. Les deux boucles =====
for i = 0, repetitions - 1 do
  dupliquer(item, pisteA, position + i * longueur)
  dupliquer(item, pisteB, position + i * (longueur + decalage))
end

reaper.Undo_EndBlock("Phasing", -1)
reaper.UpdateArrange()
