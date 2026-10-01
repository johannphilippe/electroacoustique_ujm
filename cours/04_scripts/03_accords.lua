-- 03_accords.lua
-- Fabrique un accord à partir de l'item sélectionné :
-- chaque note de l'accord est une copie transposée du son.

-- ===== Réglages =====
-- Intervalles en demi-tons par rapport au son d'origine (0 = le son lui-même)
local accord = { -12, 0, 3, 7, 10 } -- basse à l'octave + accord mineur 7

-- "pitch" : on transpose sans changer la durée (traitement numérique)
-- "bande" : on change la vitesse de lecture, comme un magnétophone
--           (plus aigu = plus court, plus grave = plus long)
local mode = "pitch"

local volumeCopies = 0.7

-- ===== Outil =====
local function dupliquer(item, piste, position)
  local _, chunk = reaper.GetItemStateChunk(item, "", false)
  chunk = chunk:gsub("{.-}", "")
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

local take           = reaper.GetActiveTake(item)
local pitchOrigine   = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
local vitesseOrigine = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")

reaper.Undo_BeginBlock()

-- ===== 2. Une copie transposée par note de l'accord =====
for i = 1, #accord do
  local intervalle = accord[i]

  if intervalle ~= 0 then -- le 0, c'est l'item d'origine : pas besoin de le copier
    local copie     = dupliquer(item, piste, position)
    local takeCopie = reaper.GetActiveTake(copie)

    if mode == "pitch" then
      reaper.SetMediaItemTakeInfo_Value(takeCopie, "D_PITCH", pitchOrigine + intervalle)
    else
      local ratio = 2 ^ (intervalle / 12) -- +12 demi-tons = vitesse x2
      reaper.SetMediaItemTakeInfo_Value(takeCopie, "B_PPITCH", 0) -- ne pas préserver la hauteur
      reaper.SetMediaItemTakeInfo_Value(takeCopie, "D_PLAYRATE", vitesseOrigine * ratio)
      reaper.SetMediaItemInfo_Value(copie, "D_LENGTH", longueur / ratio)
    end

    reaper.SetMediaItemInfo_Value(copie, "D_VOL", volumeCopies)
  end
end

reaper.Undo_EndBlock("Accord", -1)
reaper.UpdateArrange()
