# Reaper & Lua - Composer des séquences algorithmiques en temps différé

[Documentation de l'API ReaScript](https://www.reaper.fm/sdk/reascript/reascripthelp.html)

## Introduction

Dans les chapitres précédents, on a vu deux visages de l'informatique musicale :
- l'héritage de **MUSIC** (Csound) : on fabrique des instruments, et on programme *quand* et *quoi* ils jouent, en temps réel ;
- l'autre visage, évoqué au chapitre 1 : la **Composition Assistée par Ordinateur** (Lisp, Open Music...), où l'on ne produit pas directement du son, mais où l'on **manipule des données musicales** avec des algorithmes.

Ce chapitre explore ce second visage, avec un outil très accessible : **Reaper**, et son langage de script intégré, **Lua** (via *ReaScript*).

L'idée est simple : au lieu de découper, copier, déplacer, transposer des sons à la main dans la timeline (ce qui peut prendre des heures), on écrit un petit programme qui le fait à notre place, en une fraction de seconde. C'est du **temps différé**, comme aux débuts de MUSIC : l'algorithme *écrit* le résultat dans la timeline, puis on écoute. Et si le résultat ne plaît pas : `Ctrl+Z`, on change un réglage, on relance.

La différence avec Csound, c'est que le résultat reste **éditable à la main** : une fois le script exécuté, les sons sont là, sous vos yeux, sous forme d'items dans Reaper. On peut garder ce qui fonctionne, supprimer le reste, relancer un script sur une partie seulement... C'est un va-et-vient entre l'algorithme et l'oreille.

Au programme :
1. Les bases de Lua (pour celles et ceux qui n'ont jamais programmé)
2. Comment Reaper voit un projet : pistes, items, takes
3. Échauffement : une balle qui rebondit
4. Scramble : découper un son et mélanger les morceaux
5. Rythme : faire un séquenceur avec des tranches de son
6. Accords : dupliquer et transposer un son
7. Bonus : un nuage granulaire, et un hommage à Steve Reich

Tous les scripts de ce chapitre sont aussi disponibles sous forme de fichiers dans le dossier [04_scripts](04_scripts/).

## 1. Créer et lancer un script dans Reaper

1. Ouvrir la liste des actions : menu **Actions > Show action list** (raccourci : `?`).
2. En bas de la fenêtre : **New action... > New ReaScript...**
3. Choisir un nom de fichier finissant par **`.lua`** (par exemple `mon_script.lua`) dans le dossier `Scripts` proposé par défaut.
4. Un éditeur de code s'ouvre. On écrit le script, et **`Ctrl+S`** l'enregistre *et* l'exécute.

Pour utiliser un script déjà écrit (ceux du dossier `04_scripts` par exemple) : **New action... > Load ReaScript...**, puis choisir le fichier. Il apparaît alors dans la liste des actions : on peut le lancer par un double-clic, lui attribuer un raccourci clavier, ou l'ajouter à une barre d'outils.

**Afficher un message** : Reaper dispose d'une petite console. Pour y écrire quelque chose :

```lua
reaper.ShowConsoleMsg("Bonjour !\n")
```

Le `\n` signifie "retour à la ligne". C'est l'outil de base pour comprendre ce que fait votre programme : afficher des valeurs.

**En cas d'erreur**, l'éditeur affiche un message indiquant le numéro de la ligne en cause. Pas de panique : c'est le quotidien de toute personne qui programme, même expérimentée. Lisez le message, allez voir la ligne, cherchez la faute de frappe.

## 2. Les bases de Lua

Lua est un langage conçu pour être petit et simple. On le trouve dans Reaper, mais aussi dans Renoise, dans de nombreux jeux vidéo, etc. Voici tout ce dont on a besoin pour ce chapitre.

### Les commentaires

Tout ce qui suit `--` est ignoré par la machine : c'est une note pour les humains.

```lua
-- Ceci est un commentaire
```

### Les variables

Une variable, c'est une **boîte avec un nom**, dans laquelle on range une valeur. On la crée avec le mot `local` :

```lua
local nombreTranches = 16          -- un nombre entier
local duree = 0.5                  -- un nombre à virgule (avec un point !)
local nom = "Mon son"              -- du texte (une "chaîne de caractères"), entre guillemets
local actif = true                 -- vrai ou faux (true / false)
```

On peut ensuite changer le contenu de la boîte :

```lua
duree = duree * 2                  -- duree vaut maintenant 1
```

Remarque : `local` ne s'écrit qu'**une seule fois**, à la création de la variable.

### Les calculs

```lua
local a = 10 + 3     -- 13
local b = 10 - 3     -- 7
local c = 10 * 3     -- 30
local d = 10 / 4     -- 2.5
local e = 2 ^ 3      -- 8 (puissance)
local f = 10 % 3     -- 1 (modulo : le reste de la division, comme en Csound)
```

Pour coller du texte, on utilise `..` :

```lua
local message = "La durée est de " .. duree .. " secondes\n"
reaper.ShowConsoleMsg(message)
```

### Les conditions : `if`

Exactement comme en Csound, on peut décider de faire quelque chose seulement si une condition est vraie :

```lua
if duree > 2 then
  reaper.ShowConsoleMsg("C'est long\n")
elseif duree > 1 then
  reaper.ShowConsoleMsg("C'est moyen\n")
else
  reaper.ShowConsoleMsg("C'est court\n")
end
```

Les comparaisons possibles : `==` (égal), `~=` (différent, attention c'est un tilde !), `<`, `>`, `<=`, `>=`.

Chaque bloc `if` se termine par `end`.

### Les boucles : `for`

Une boucle répète un bloc de code plusieurs fois. C'est **l'outil central de ce chapitre** : c'est elle qui fait le travail répétitif à notre place.

```lua
for i = 1, 5 do
  reaper.ShowConsoleMsg("Tour numéro " .. i .. "\n")
end
```

Résultat dans la console :
```
Tour numéro 1
Tour numéro 2
Tour numéro 3
Tour numéro 4
Tour numéro 5
```

La variable `i` prend successivement les valeurs 1, 2, 3, 4, 5. On s'en sert pour calculer des positions dans le temps, par exemple : `position = i * 0.5` donnera 0.5, 1, 1.5, 2, 2.5 secondes.

### Les tables (listes)

Une table, c'est une **liste de valeurs**, rangées dans l'ordre (l'équivalent des *arrays* de Csound, avec `fillarray`) :

```lua
local gamme = { 0, 2, 4, 7, 9 }   -- pentatonique majeure

reaper.ShowConsoleMsg(gamme[1] .. "\n")   -- affiche 0 : le PREMIER élément
reaper.ShowConsoleMsg(gamme[3] .. "\n")   -- affiche 4
reaper.ShowConsoleMsg(#gamme .. "\n")     -- affiche 5 : le nombre d'éléments
```

**Attention, piège classique** : en Lua, le premier élément d'une table est le numéro **1** (et pas 0 comme dans beaucoup d'autres langages, dont Csound).

Quelques opérations utiles :

```lua
table.insert(gamme, 11)            -- ajoute 11 à la fin de la liste
local x = table.remove(gamme, 2)   -- retire le 2e élément de la liste, et le range dans x
```

Parcourir une table avec une boucle :

```lua
for i = 1, #gamme do
  reaper.ShowConsoleMsg("Degré : " .. gamme[i] .. "\n")
end
```

### Le hasard

```lua
math.randomseed(os.time())       -- à mettre au début du script : "mélanger le jeu de cartes"

local de = math.random(1, 6)     -- un nombre ENTIER entre 1 et 6 (comme un dé)
local r  = math.random()         -- un nombre à virgule entre 0 et 1
```

Pour piocher un élément au hasard dans une table :

```lua
local degre = gamme[math.random(1, #gamme)]
```

Et pour décider avec une probabilité (même principe qu'en Csound) :

```lua
if math.random() < 0.3 then
  -- 30% de chances que ce code soit exécuté
end
```

### Les fonctions

Une fonction, c'est un **morceau de code auquel on donne un nom**, pour pouvoir le réutiliser. Elle peut recevoir des valeurs (les *paramètres*) et en renvoyer une (avec `return`) :

```lua
local function aleatoire(min, max)
  return min + math.random() * (max - min)
end

local duree = aleatoire(0.5, 2)   -- un nombre à virgule entre 0.5 et 2
```

Une fonction doit être écrite **avant** l'endroit où on l'utilise dans le script.

En Reaper, on utilise énormément de fonctions déjà écrites pour nous : toutes celles qui commencent par `reaper.` (par exemple `reaper.ShowConsoleMsg`). C'est ce qu'on appelle l'**API** de Reaper : la liste des commandes qu'un script peut donner au logiciel.

### Petit exercice d'échauffement

Écrire un script qui affiche dans la console 8 notes MIDI tirées au hasard dans la gamme pentatonique, sur le do central (60) :

```lua
math.randomseed(os.time())
local gamme = { 0, 2, 4, 7, 9 }

for i = 1, 8 do
  local note = 60 + gamme[math.random(1, #gamme)]
  reaper.ShowConsoleMsg("Note " .. i .. " : " .. note .. "\n")
end
```

## 3. Comment Reaper voit un projet

Pour manipuler un projet par le code, il faut connaître le vocabulaire de Reaper :

- **Projet** : l'ensemble de votre session. Dans l'API, le projet courant est désigné par le nombre `0`.
- **Piste** (*track*) : une ligne horizontale de la timeline.
- **Item** : un rectangle posé sur une piste. Il a une **position** (en secondes), une **longueur** (en secondes), un volume, des fondus (*fades*)...
- **Take** : le *contenu* de l'item. Un item peut contenir plusieurs takes, mais un seul est actif. C'est le take qui sait quel fichier son est lu, à partir d'où dans le fichier (*offset*), à quelle vitesse, avec quelle transposition.

On peut résumer : **l'item, c'est le cadre ; le take, c'est ce qu'on voit à travers le cadre.**

```
      position                                  position + longueur
         |                                               |
         v                                               v
         +-----------------------------------------------+
Piste 1  |  ITEM  (cadre : position, longueur, volume)   |
         |  TAKE  (contenu : fichier, offset, pitch...)  |
         +-----------------------------------------------+
```

### Lire et modifier les propriétés

L'API suit toujours la même logique : une fonction `Get...` pour lire une propriété, une fonction `Set...` pour la modifier. On désigne la propriété par un petit code en texte :

```lua
-- Lire la position d'un item (en secondes)
local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

-- La modifier : déplacer l'item à 10 secondes
reaper.SetMediaItemInfo_Value(item, "D_POSITION", 10)
```

Les propriétés dont on aura besoin :

| Sur l'**item** (`Get/SetMediaItemInfo_Value`) | Signification |
|---|---|
| `D_POSITION` | position dans la timeline (secondes) |
| `D_LENGTH` | longueur (secondes) |
| `D_VOL` | volume (1 = volume normal, 0.5 = moitié, 0 = silence) |
| `D_FADEINLEN` | durée du fondu d'entrée (secondes) |
| `D_FADEOUTLEN` | durée du fondu de sortie (secondes) |

| Sur le **take** (`Get/SetMediaItemTakeInfo_Value`) | Signification |
|---|---|
| `D_PITCH` | transposition en demi-tons (sans changer la durée) |
| `D_PLAYRATE` | vitesse de lecture (1 = normal, 2 = deux fois plus vite) |
| `B_PPITCH` | préserver la hauteur quand on change la vitesse (1 = oui, 0 = non) |
| `D_STARTOFFS` | à partir d'où on lit dans le fichier son (secondes) |
| `D_PAN` | panoramique (-1 = gauche, 0 = centre, 1 = droite) |

Les autres fonctions importantes :

```lua
reaper.GetSelectedMediaItem(0, 0)   -- le premier item sélectionné du projet
reaper.GetMediaItem_Track(item)     -- la piste sur laquelle se trouve l'item
reaper.GetActiveTake(item)          -- le take actif de l'item
reaper.SplitMediaItem(item, temps)  -- coupe l'item ; renvoie le morceau de droite
reaper.GetCursorPosition()          -- position du curseur d'édition (secondes)
reaper.Master_GetTempo()            -- tempo du projet (BPM)
```

**Attention** : dans l'API de Reaper, on compte à partir de **0** (`GetSelectedMediaItem(0, 0)` = projet courant, premier item sélectionné), alors que les tables Lua commencent à **1**. C'est un piège fréquent.

### La structure type d'un script

Tous les scripts du chapitre suivent la même structure :

```lua
-- 1. Réglages : les valeurs qu'on peut modifier pour changer le résultat
local nombreTranches = 16

-- 2. Outils : nos fonctions utilitaires
local function ...

-- 3. Récupérer l'item sélectionné (et s'arrêter s'il n'y en a pas)
local item = reaper.GetSelectedMediaItem(0, 0)
if item == nil then
  reaper.ShowMessageBox("Sélectionnez un item audio d'abord !", "Oups", 0)
  return
end

-- 4. Le travail, encadré par un "bloc d'annulation"
reaper.Undo_BeginBlock()
-- ... ici, toutes les modifications ...
reaper.Undo_EndBlock("Nom de l'action", -1)

-- 5. Rafraîchir l'affichage
reaper.UpdateArrange()
```

Le **bloc d'annulation** (`Undo_BeginBlock` / `Undo_EndBlock`) permet d'annuler tout le travail du script en un seul `Ctrl+Z`. Indispensable pour expérimenter sans crainte.

`nil` signifie "rien" en Lua : si aucun item n'est sélectionné, la variable `item` ne contient rien, et on arrête le script avec `return`.

### Un outil tout prêt : `dupliquer`

Reaper n'a pas de fonction simple pour copier un item. Voici une fonction outil, que l'on copiera au début des scripts qui en ont besoin. **Vous n'avez pas besoin de comprendre son intérieur** : il suffit de savoir ce qu'elle fait.

```lua
-- Crée une copie de "item", sur la piste "piste", à la position "position" (secondes).
-- Renvoie la copie.
local function dupliquer(item, piste, position)
  local _, chunk = reaper.GetItemStateChunk(item, "", false)
  chunk = chunk:gsub("{.-}", "") -- REAPER génèrera de nouveaux identifiants
  local copie = reaper.AddMediaItemToTrack(piste)
  reaper.SetItemStateChunk(copie, chunk, false)
  reaper.SetMediaItemInfo_Value(copie, "D_POSITION", position)
  reaper.SetMediaItemSelected(copie, false)
  return copie
end
```

(Pour les curieux : elle récupère la "description texte" complète de l'item, en retire les identifiants uniques, et crée un nouvel item à partir de cette description.)

## 4. Échauffement : la balle qui rebondit

**Fichier : [00_rebond.lua](04_scripts/00_rebond.lua)**

Premier script, pour se mettre en jambes : on prend un son percussif court, et on le répète comme une balle qui rebondit. Chaque rebond arrive **un peu plus tôt** que le précédent, et **un peu moins fort**.

**Préparation** : importer un son court (un coup, un clic, une goutte...) dans Reaper, et le sélectionner.

```lua
-- ===== Réglages =====
local nombreRebonds = 12    -- combien de copies
local facteurTemps  = 0.8   -- chaque écart est 80% du précédent
local facteurVolume = 0.85  -- chaque rebond est 85% moins fort que le précédent

-- ===== Outil : dupliquer un item à une position donnée =====
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
```

### Pas à pas

1. On lit la **piste**, la **position** et la **longueur** de l'item sélectionné.
2. Deux variables vont évoluer à chaque tour de boucle : `ecart` (le temps jusqu'au prochain rebond) et `volume`.
3. À chaque tour :
   - on avance la position de la valeur de l'écart,
   - on réduit l'écart (× 0.8) → les rebonds se rapprochent : **accelerando**,
   - on réduit le volume (× 0.85) → **decrescendo**,
   - on pose une copie à cette position, avec ce volume.

C'est une **règle** très simple (multiplier par un facteur) qui produit un geste musical reconnaissable. Les copies finissent par se chevaucher : ce n'est pas un problème, Reaper joue tous les items superposés sur une même piste.

**À essayer** :
- `facteurTemps = 1.2` : les rebonds s'**espacent** (ralentissement).
- `facteurVolume = 1` : pas de decrescendo.
- `nombreRebonds = 50` avec `facteurTemps = 0.9` : on obtient un roulement qui se transforme en *texture*.

## 5. Scramble : découper et mélanger

**Fichier : [01_scramble.lua](04_scripts/01_scramble.lua)**

On découpe un son en tranches égales, et on les remet dans le désordre. Sur une voix, une mélodie, une boucle de batterie, le résultat est immédiatement intéressant : le son reste reconnaissable par son timbre, mais son discours est déconstruit. C'est un geste typique de la musique concrète et électroacoustique, et du *glitch*.

```lua
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
local tranches = { item }
local reste = item

for i = 1, nombreTranches - 1 do
  reste = reaper.SplitMediaItem(reste, position + i * tailleTranche)
  table.insert(tranches, reste)
end

-- ===== 3. Mélanger =====
local melange = {}

for i = 1, nombreTranches do
  local k = math.random(1, #tranches)
  table.insert(melange, table.remove(tranches, k))
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
```

### Pas à pas

**Étape 2 : découper.** On calcule la taille d'une tranche (`longueur / nombreTranches`). Puis on coupe, comme avec des ciseaux : `SplitMediaItem` coupe un item en deux et **renvoie le morceau de droite**. On recoupe ensuite ce morceau de droite, et ainsi de suite. À chaque coupe, on range le nouveau morceau dans la table `tranches`.

```
Départ :   [                item                ]
Coupe 1 :  [ t1 ][             reste            ]
Coupe 2 :  [ t1 ][ t2 ][         reste          ]
...
Fin :      [ t1 ][ t2 ][ t3 ][ t4 ] ... [ t16 ]
```

Note : il faut `nombreTranches - 1` coupes pour obtenir `nombreTranches` morceaux (pensez à un gâteau).

**Étape 3 : mélanger.** On imagine la table `tranches` comme un **sac**. À chaque tour, on pioche une tranche au hasard (`math.random(1, #tranches)`), on la **retire** du sac (`table.remove`), et on la range à la suite dans la table `melange`. Comme le sac se vide au fur et à mesure, chaque tranche n'est tirée qu'une seule fois : c'est un tirage **sans remise**.

**Étape 4 : replacer.** La première tranche de `melange` va à la position de départ, la deuxième juste après, etc. Le calcul `position + (i - 1) * tailleTranche` donne : départ + 0, départ + 1 tranche, départ + 2 tranches...

Et on ajoute à chaque tranche un **fondu très court** (5 ms) en entrée et en sortie. Souvenez-vous du chapitre Csound : *toute note doit avoir une enveloppe*. Couper un son n'importe où crée une discontinuité, donc un clic. Le fondu, c'est l'enveloppe minimale.

**À essayer** :
- Changer `nombreTranches` : 4 (on reconnaît encore la phrase), 64 (on n'entend plus que la texture).
- Si le son a un tempo, choisir un nombre de tranches qui tombe sur les temps (8 ou 16 tranches pour une mesure) : le résultat reste rythmiquement cohérent.
- Supprimer les fondus (`dureeFondu = 0`) pour entendre les clics : parfois, c'est une esthétique !

## 6. Rythme : un séquenceur de tranches

**Fichier : [02_rythme.lua](04_scripts/02_rythme.lua)**

On réutilise le découpage du scramble, mais cette fois pour **fabriquer un rythme**, à la manière d'un séquenceur pas-à-pas (une *boîte à rythmes*). On décrit un motif avec des `1` (on joue) et des `0` (silence), et le script pose une tranche prise au hasard sur chaque `1`, sur une nouvelle piste, au tempo du projet.

```lua
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
```

### Pas à pas

**Le motif** est une simple table de 16 cases : c'est notre partition rythmique. Les espaces entre les groupes de 4 ne servent qu'à la lisibilité (un groupe = un temps).

**La durée d'un pas.** À 120 BPM, une noire dure `60 / 120 = 0.5` seconde. Une double-croche, c'est un quart de noire : `0.5 / 4 = 0.125` seconde. D'où `dureePas = 60 / bpm / 4`. Le script lit le tempo du projet : changez-le, relancez, le rythme suit.

**Une nouvelle piste.** La fonction `nouvellePiste` crée une piste à la fin du projet et lui donne un nom. Le rythme y est écrit à partir du **curseur d'édition** : cliquez dans la timeline à l'endroit voulu avant de lancer le script.

**La boucle et le modulo.** On veut jouer le motif 4 fois, soit `16 × 4 = 64` pas. Le compteur `n` va de 1 à 64, mais le motif n'a que 16 cases. Le modulo (vu au chapitre Csound) permet de "revenir au début" :

```
n   = 1, 2, ..., 16, 17, 18, ..., 32, 33 ...
pas = 1, 2, ..., 16,  1,  2, ..., 16,  1 ...
```

**Sur chaque `1`** : on calcule l'instant du pas (`depart + (n - 1) * dureePas`), on pioche une tranche au hasard, on la copie à cet instant sur la nouvelle piste, et on la raccourcit à la durée d'un pas (pour un son sec et rythmique), avec des fondus.

**À essayer** :
- Écrire vos propres motifs (des motifs de 12 pas pour du ternaire, de 7 ou 5 pas pour des mesures asymétriques).
- **Des probabilités plutôt que des 1 et des 0** : remplacer le motif par des valeurs entre 0 et 1, et la condition par un tirage. Le motif devient "vivant", différent à chaque répétition :
  ```lua
  local motif = { 1, 0, 0.3, 0.8,   0, 0.2, 1, 0,   0.9, 0, 0.5, 0,   0.1, 0.7, 0, 0.4 }
  ...
  if math.random() < motif[pas] then
  ```
- **Des accents** : ajouter une variation de volume, par exemple plus fort sur le premier pas de chaque temps :
  ```lua
  if pas % 4 == 1 then
    reaper.SetMediaItemInfo_Value(copie, "D_VOL", 1)
  else
    reaper.SetMediaItemInfo_Value(copie, "D_VOL", 0.5)
  end
  ```
- Au lieu de piocher une tranche au hasard, les jouer dans l'ordre : `tranches[((n - 1) % #tranches) + 1]`.

## 7. Accords : dupliquer et transposer

**Fichier : [03_accords.lua](04_scripts/03_accords.lua)**

Un son (une note de voix, un bol tibétain, une corde pincée, et même un bruit) devient un accord : chaque note de l'accord est une **copie transposée** du son, posée au même endroit.

```lua
-- ===== Réglages =====
-- Intervalles en demi-tons par rapport au son d'origine (0 = le son lui-même)
local accord = { -12, 0, 3, 7, 10 } -- basse à l'octave + accord mineur 7

-- "pitch" : on transpose sans changer la durée (traitement numérique)
-- "bande" : on change la vitesse de lecture, comme un magnétophone
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

  if intervalle ~= 0 then
    local copie     = dupliquer(item, piste, position)
    local takeCopie = reaper.GetActiveTake(copie)

    if mode == "pitch" then
      reaper.SetMediaItemTakeInfo_Value(takeCopie, "D_PITCH", pitchOrigine + intervalle)
    else
      local ratio = 2 ^ (intervalle / 12)
      reaper.SetMediaItemTakeInfo_Value(takeCopie, "B_PPITCH", 0)
      reaper.SetMediaItemTakeInfo_Value(takeCopie, "D_PLAYRATE", vitesseOrigine * ratio)
      reaper.SetMediaItemInfo_Value(copie, "D_LENGTH", longueur / ratio)
    end

    reaper.SetMediaItemInfo_Value(copie, "D_VOL", volumeCopies)
  end
end

reaper.Undo_EndBlock("Accord", -1)
reaper.UpdateArrange()
```

### Pas à pas

**L'accord est une table d'intervalles**, en demi-tons, par rapport au son d'origine. Rappels : 12 demi-tons = une octave, 7 = une quinte, 4 = une tierce majeure, 3 = une tierce mineure. Les valeurs négatives transposent vers le grave.

Quelques accords à essayer :

```lua
local accord = { 0, 4, 7 }            -- majeur
local accord = { 0, 3, 7 }            -- mineur
local accord = { 0, 4, 7, 11 }        -- majeur 7
local accord = { -24, -12, 0, 12 }    -- octaves (épaississement)
local accord = { 0, 6, 11, 17 }       -- quartes augmentées/justes : plus "contemporain"
local accord = { 0, 3.5, 7.2, 10.8 }  -- micro-intervalles !
```

La dernière ligne rappelle qu'on n'est pas limité au tempérament égal : le son peut être transposé de n'importe quelle valeur, y compris des fractions de demi-ton. C'est le terrain de jeu de la musique spectrale (Tristan Murail, chapitre 1).

**La boucle** parcourt l'accord. Pour chaque intervalle différent de 0 (le 0, c'est l'item d'origine, déjà présent), on crée une copie au même endroit, et on la transpose.

**Deux manières de transposer** — c'est une question à la fois technique et esthétique :

- **Mode `"pitch"`** : Reaper change la hauteur **sans changer la durée** (propriété `D_PITCH`). C'est un traitement numérique (un algorithme de *pitch shifting*). Toutes les notes ont la même durée : on obtient un accord "propre", mais avec des transpositions extrêmes, le son se dégrade (artefacts, grain métallique).
- **Mode `"bande"`** : on change la **vitesse de lecture**, comme en accélérant ou ralentissant une bande magnétique (c'est ce que faisait le *phonogène* de Pierre Schaeffer). Plus aigu = plus rapide = plus court ; plus grave = plus lent = plus long. Le timbre se transforme de façon plus "naturelle" (les formants bougent avec la hauteur), et les notes de l'accord s'arrêtent à des moments différents : l'accord se *désagrège* dans le temps.

Le calcul du mode `"bande"` : monter d'une octave (12 demi-tons) = lire deux fois plus vite. De manière générale, le rapport de vitesse est `2 ^ (intervalle / 12)`. Il faut aussi ajuster la longueur de l'item (`longueur / ratio`), sinon l'item garderait sa longueur d'origine et on entendrait la suite du fichier (ou du silence).

**Le volume** : superposer 5 copies du même son, c'est additionner 5 signaux. On baisse donc le volume des copies (`volumeCopies = 0.7`) pour éviter la saturation. Surveillez l'indicateur de niveau du master !

### Pour aller plus loin : une progression d'accords

Une table peut contenir d'autres tables. On peut ainsi décrire une **suite d'accords**, et poser chaque accord l'un après l'autre :

```lua
local progression = {
  { 0, 4, 7 },     -- I
  { 5, 9, 12 },    -- IV
  { 7, 11, 14 },   -- V
  { 0, 4, 7 },     -- I
}

for a = 1, #progression do
  local accord  = progression[a]
  local instant = position + (a - 1) * longueur   -- chaque accord après le précédent

  for i = 1, #accord do
    local copie = dupliquer(item, piste, instant)
    local takeCopie = reaper.GetActiveTake(copie)
    reaper.SetMediaItemTakeInfo_Value(takeCopie, "D_PITCH", pitchOrigine + accord[i])
    reaper.SetMediaItemInfo_Value(copie, "D_VOL", volumeCopies)
  end
end
```

C'est une **boucle dans une boucle** : la boucle extérieure parcourt les accords, la boucle intérieure parcourt les notes de chaque accord.

## 8. Bonus : nuage granulaire

**Fichier : [04_nuage_granulaire.lua](04_scripts/04_nuage_granulaire.lua)**

La **synthèse granulaire** consiste à découper un son en minuscules fragments (des *grains*, de quelques dizaines de millisecondes), et à les redistribuer en masse pour créer des textures. L'idée vient de Iannis Xenakis (années 1950-60, sur bande magnétique, avec des ciseaux !), et a été développée numériquement par Curtis Roads et Barry Truax.

Aujourd'hui, la granulaire se fait en temps réel dans de nombreux plugins. Mais la faire en temps différé, avec un script, a un intérêt : chaque grain est un item visible, qu'on peut écouter, déplacer, supprimer. On *voit* le nuage.

```lua
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
```

### Pas à pas

Ce script introduit une idée nouvelle : **l'item comme fenêtre**. Plutôt que de découper le son (comme dans le scramble), chaque grain est une copie de l'item entier, dont on change deux choses :
- `D_STARTOFFS` (sur le take) : **à partir d'où** on lit dans le fichier son,
- `D_LENGTH` (sur l'item) : **pendant combien de temps**.

C'est comme regarder un paysage à travers une petite fenêtre qu'on déplace.

Pour chaque grain, on tire au hasard (grâce à notre fonction `aleatoire`) :
1. sa **durée** (entre 30 et 150 ms),
2. sa **transposition** (façon bande, donc elle modifie aussi la quantité de son lue),
3. **où lire** dans le son d'origine,
4. **où le placer** dans le nuage,
5. son **volume** et son **panoramique**.

Et chaque grain reçoit une **enveloppe** en forme de triangle (fondu d'entrée sur la première moitié, fondu de sortie sur la seconde) : en granulaire, l'enveloppe du grain est essentielle, c'est elle qui rend le nuage lisse plutôt que crépitant.

`PreventUIRefresh` demande à Reaper de ne pas redessiner l'écran à chaque grain créé : avec 300 grains, le script s'exécute bien plus vite.

**À essayer** :
- Des grains très courts (5-20 ms) : texture bruitée, crépitante. Des grains longs (200-500 ms) : on reconnaît le son d'origine.
- `transpositionMax = 0` : pas de transposition. `transpositionMax = 24` : nuage très étendu dans le registre.
- **Étirement granulaire (time-stretching)** : au lieu de lire n'importe où dans le son, faire avancer la tête de lecture avec le temps. Le son d'origine est alors "étiré" sur toute la durée du nuage :
  ```lua
  local instant      = depart + aleatoire(0, dureeNuage)
  local progression  = (instant - depart) / dureeNuage              -- de 0 à 1 le long du nuage
  local debutDansSon = progression * debutMax + aleatoire(-0.05, 0.05)
  debutDansSon = math.max(0, debutDansSon)
  ```
- **Un nuage qui évolue** : faire dépendre la durée des grains ou la transposition de `progression` (par exemple des grains de plus en plus longs), comme on faisait évoluer les paramètres avec `line` en Csound.

## 9. Bonus : phasing (hommage à Steve Reich)

**Fichier : [05_phasing.lua](04_scripts/05_phasing.lua)**

En 1965, Steve Reich compose *It's Gonna Rain* : un même fragment de voix enregistré sur deux magnétophones, qui tournent à des vitesses très légèrement différentes. Les deux boucles, d'abord à l'unisson, se décalent peu à peu, créant échos, rythmes et motifs qui n'existent dans aucune des deux boucles prises séparément. C'est le *phasing*.

En temps différé, c'est très simple à reproduire : deux pistes, la même boucle, mais sur la seconde, chaque répétition arrive avec un petit retard supplémentaire.

```lua
-- ===== Réglages =====
local repetitions = 40
local decalage    = 0.02 -- 20 ms de retard supplémentaire à chaque répétition

-- (fonctions dupliquer et nouvellePiste : voir plus haut)

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

reaper.SetMediaTrackInfo_Value(pisteA, "D_PAN", -0.7)
reaper.SetMediaTrackInfo_Value(pisteB, "D_PAN", 0.7)

-- ===== 2. Les deux boucles =====
for i = 0, repetitions - 1 do
  dupliquer(item, pisteA, position + i * longueur)
  dupliquer(item, pisteB, position + i * (longueur + decalage))
end

reaper.Undo_EndBlock("Phasing", -1)
reaper.UpdateArrange()
```

### Pas à pas

- La piste A répète la boucle régulièrement : position `i × longueur`.
- La piste B la répète avec une période un tout petit peu plus longue : `longueur + decalage`. Donc à la répétition 1, B est en retard de 20 ms ; à la répétition 10, de 200 ms ; à la répétition 40, de 800 ms.
- On place A à gauche et B à droite pour bien entendre le décalage se creuser dans l'espace stéréo.

Cette fois, la boucle commence à `0` (et non à `1`) : ainsi, la première répétition tombe exactement à la position de l'item d'origine, et les deux pistes démarrent à l'unisson.

**À essayer** : une phrase parlée courte (1 à 2 secondes) fonctionne très bien. Essayez des décalages plus petits (5 ms : effet de *flanger*, puis écho) ou plus grands.

## 10. Exercice : une courte pièce en temps différé

En combinant les scripts de ce chapitre, composer une courte pièce (1 à 2 minutes) à partir d'**un seul son** de votre choix (enregistré vous-même, idéalement).

**Cahier des charges minimal :**
- Utiliser au moins **trois** des scripts du chapitre, en modifiant leurs réglages.
- Modifier au moins **un** script en profondeur : changer sa règle, ajouter un tirage aléatoire, une probabilité, une évolution dans le temps...
- Retravailler le résultat à la main (supprimer, déplacer, ajouter des fondus, de l'automation) : l'algorithme propose, l'oreille dispose.

**Idées de scripts à inventer vous-même :**
- **Palindrome** : dupliquer un item et inverser la copie (l'action Reaper "Item properties: Toggle take reverse" s'appelle depuis un script avec `reaper.Main_OnCommand(41051, 0)`, sur les items sélectionnés).
- **Écho algorithmique** : comme la balle qui rebondit, mais avec des écarts constants et une transposition qui descend à chaque répétition.
- **Canon** : copier une phrase sur plusieurs pistes, chaque voix décalée dans le temps et transposée (comme dans un canon de Bach).
- **Stutter / bégaiement** : répéter plusieurs fois de suite certaines tranches choisies au hasard, dans le scramble.

## Pour aller plus loin

- [Documentation officielle de l'API ReaScript](https://www.reaper.fm/sdk/reascript/reascripthelp.html) (aussi disponible dans Reaper : **Help > ReaScript documentation**). Cherchez-y chaque fonction `reaper.` utilisée dans ce chapitre.
- [Documentation de l'API par X-Raym](https://www.extremraym.com/cloud/reascript-doc/), plus lisible, avec recherche.
- [Manuel de référence de Lua](https://www.lua.org/manual/5.4/manual.html) et le livre [Programming in Lua](https://www.lua.org/pil/contents.html) (première édition, gratuite en ligne).
- [ReaPack](https://reapack.com/) : un gestionnaire d'extensions pour Reaper, qui donne accès à des milliers de scripts écrits par la communauté. Lire le code des autres est une excellente manière d'apprendre.
