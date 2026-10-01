-- 04_nuage_granulaire.lua
-- Synthèse granulaire "en temps différé" : on éparpille des centaines de
-- minuscules fragments (grains) du son sélectionné sur une nouvelle piste.

-- ===== Réglages =====
local nombreGrains     = 300
local dureeNuage       = 10    -- secondes
local dureeGrainMin    = 0.03  -- 30 ms
local dureeGrainMax    = 0.15  -- 150 ms
local transpositionMax = 7     -- demi-tons, vers le haut ou vers le bas

math.randomseed(os.time())

-- ===== Outils =====
local function aleatoire(min, max)
  return min + math.random() * (max - min)
end

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

local longueur      = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
local take          = reaper.GetActiveTake(item)
local offsetOrigine = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1) -- on fige l'affichage pendant le calcul (plus rapide)

local piste  = nouvellePiste("Nuage")
local depart = reaper.GetCursorPosition()

-- ===== 2. Semer les grains =====
for i = 1, nombreGrains do
  local dureeGrain    = aleatoire(dureeGrainMin, dureeGrainMax)
  local transposition = aleatoire(-transpositionMax, transpositionMax)
  local vitesse       = 2 ^ (transposition / 12)

  -- Où lire dans le son d'origine (en restant à l'intérieur du son)
  local debutMax      = math.max(0, longueur - dureeGrain * vitesse)
  local debutDansSon  = aleatoire(0, debutMax)

  -- Où placer le grain dans le nuage
  local instant = depart + aleatoire(0, dureeNuage)

  local grain     = dupliquer(item, piste, instant)
  local takeGrain = reaper.GetActiveTake(grain)

  -- La fenêtre : quelle portion du son, pendant combien de temps
  reaper.SetMediaItemTakeInfo_Value(takeGrain, "D_STARTOFFS", offsetOrigine + debutDansSon)
  reaper.SetMediaItemInfo_Value(grain, "D_LENGTH", dureeGrain)

  -- La transposition "façon bande" (vitesse de lecture)
  reaper.SetMediaItemTakeInfo_Value(takeGrain, "B_PPITCH", 0)
  reaper.SetMediaItemTakeInfo_Value(takeGrain, "D_PLAYRATE", vitesse)

  -- L'enveloppe du grain : un fondu sur chaque moitié
  reaper.SetMediaItemInfo_Value(grain, "D_FADEINLEN", dureeGrain / 2)
  reaper.SetMediaItemInfo_Value(grain, "D_FADEOUTLEN", dureeGrain / 2)

  -- Volume et panoramique au hasard
  reaper.SetMediaItemInfo_Value(grain, "D_VOL", aleatoire(0.2, 0.7))
  reaper.SetMediaItemTakeInfo_Value(takeGrain, "D_PAN", aleatoire(-1, 1))
end

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Nuage granulaire", -1)
reaper.UpdateArrange()
