-- 02_rythme.lua
-- Découpe l'item sélectionné en tranches, puis construit un rythme
-- (comme un séquenceur pas-à-pas) sur une nouvelle piste, à partir du curseur d'édition.

-- ===== Réglages =====
local nombreTranches = 8
local repetitions    = 4
local dureeFondu     = 0.003

-- Le motif : 16 pas (double-croches). 1 = on joue une tranche, 0 = silence.
local motif = { 1, 0, 0, 1,   0, 0, 1, 0,   1, 0, 1, 0,   0, 1, 0, 0 }

math.randomseed(os.time())

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
  local index = reaper.CountTracks(0)   -- nombre de pistes = index de la future dernière piste
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

local position      = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
local longueur      = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
local tailleTranche = longueur / nombreTranches

-- Durée d'un pas : une double-croche au tempo du projet
local bpm      = reaper.Master_GetTempo()
local dureePas = 60 / bpm / 4

reaper.Undo_BeginBlock()

-- ===== 2. Découper (même code que le scramble) =====
local tranches = { item }
local reste = item
for i = 1, nombreTranches - 1 do
  reste = reaper.SplitMediaItem(reste, position + i * tailleTranche)
  table.insert(tranches, reste)
end

-- ===== 3. Construire le rythme =====
local piste  = nouvellePiste("Rythme")
local depart = reaper.GetCursorPosition()
local dureeNote = math.min(dureePas, tailleTranche)

for n = 1, #motif * repetitions do
  local pas = ((n - 1) % #motif) + 1 -- revient à 1 après le dernier pas du motif

  if motif[pas] == 1 then
    local instant = depart + (n - 1) * dureePas
    local tranche = tranches[math.random(1, #tranches)]

    local copie = dupliquer(tranche, piste, instant)
    reaper.SetMediaItemInfo_Value(copie, "D_LENGTH", dureeNote)
    reaper.SetMediaItemInfo_Value(copie, "D_FADEINLEN", dureeFondu)
    reaper.SetMediaItemInfo_Value(copie, "D_FADEOUTLEN", dureeFondu)
  end
end

reaper.Undo_EndBlock("Rythme de tranches", -1)
reaper.UpdateArrange()
