# Csound (bis) - Consolider les bases et aller plus loin

[Documentation](https://csound.com/manual/)

## Introduction

Ce chapitre est un complément aux chapitres 2 et 3. Il a deux objectifs :

1. **Revenir sur les fondamentaux** qui posent souvent problème : les p-fields, les trois vitesses (i, k, a), la lecture des messages d'erreur. Si ces notions sont claires, tout le reste devient beaucoup plus simple.
2. **Aller plus loin** avec des outils qui ouvrent de nouvelles possibilités musicales :
   - faire communiquer les instruments (et ajouter une réverbération),
   - travailler avec des sons enregistrés,
   - moduler le son pour le rendre vivant,
   - fabriquer ses propres opcodes,
   - composer "à l'avance" avec des boucles et des instruments qui se relancent eux-mêmes.

À la fin du chapitre, on enrichira l'installation générative du chapitre 3 avec tous ces éléments.

## 1. Retour sur les fondamentaux

### 1.1 Les p-fields : la carte d'identité d'une note

Chaque note envoyée à un instrument (dans le score, avec `schedule` ou avec `schedulek`) est une liste de valeurs : les **p-fields** (*parameter fields*). Les trois premiers ont toujours le même sens :

| p-field | Sens | Exemple |
|---|---|---|
| `p1` | quel instrument | `1` ou `"MonInstrument"` |
| `p2` | quand (début, en secondes) | `0.5` |
| `p3` | combien de temps (durée, en secondes) | `2` |
| `p4`, `p5`... | **ce que vous voulez** : c'est vous qui décidez | fréquence, amplitude... |

Dans le score :
```c
;  p1  p2   p3   p4    p5
i  1   0    2    440   0.3
```

Et exactement la même note, depuis le code :
```c
schedule 1, 0, 2, 440, 0.3
```

Dans l'instrument, on récupère ces valeurs avec `p4`, `p5`... Une bonne habitude : les ranger tout de suite dans des variables avec un nom parlant, en haut de l'instrument.

```c
instr 1
    ifreq = p4   // p4 = fréquence
    iamp  = p5   // p5 = amplitude
    ...
endin
```

À retenir : **à partir de p4, les p-fields n'ont pas de sens imposé**. Leur signification, c'est vous qui la définissez dans l'instrument, et il faut respecter le même ordre au moment de déclencher les notes.

### 1.2 Les trois vitesses, concrètement

On a vu les préfixes **i**, **k** et **a**. Voici ce qui se passe vraiment quand une note est jouée :

1. **Au début de la note**, Csound exécute une fois toutes les lignes de l'instrument qui concernent des variables **i** : c'est l'*initialisation*.
2. **Ensuite, en boucle, jusqu'à la fin de la note**, Csound exécute toutes les lignes **k** et **a**, par petits paquets.

La taille de ces paquets, c'est `ksmps`. Avec `sr = 44100` et `ksmps = 32` :
- à chaque tour de boucle, Csound calcule **32 échantillons** audio d'un coup (les variables **a** sont donc des paquets de 32 valeurs) ;
- et chaque variable **k** est calculée **une seule fois** par paquet, soit `44100 / 32 ≈ 1378` fois par seconde.

On peut le vérifier avec ce petit instrument, qui compte les tours de boucle :

```c
instr Compteur
    kcompte init 0
    kcompte = kcompte + 1
    printk 1, kcompte   // affiche kcompte toutes les secondes
endin
```

La console affiche 1 (le tout premier tour), puis environ 1378, 2756, 4134... : la ligne `kcompte = kcompte + 1` est exécutée environ 1378 fois par seconde.

Et pour voir la différence entre **i** et **k** :

```c
instr Difference
    ival = random:i(0, 1)   // tiré UNE fois, au début de la note
    kval = random:k(0, 1)   // tiré à CHAQUE tour de boucle
    print ival
    printk 0.5, kval        // affiche kval toutes les 0.5 secondes
endin
```

`ival` est affiché une seule fois et ne change jamais ; `kval` change à chaque affichage.

**Les suffixes `:i` et `:k`** : quand on écrit une fonction dans un calcul (la *syntaxe fonctionnelle*, comme `random:k(0, 1)`), le suffixe indique à Csound à quelle vitesse la calculer. `random:i` tire une valeur au début de la note, `random:k` en tire une nouvelle à chaque tour de boucle. Sans suffixe, Csound essaie de deviner, et se trompe parfois : mieux vaut toujours l'écrire.

**Récapitulatif :**

| | Calculée | Exemple d'usage |
|---|---|---|
| **i** | une fois, au début de la note | hauteur, durée, amplitude de la note, tirages "une fois pour toutes" |
| **k** | ~1378 fois par seconde (avec ksmps = 32) | enveloppes, LFO, décisions, compteurs, temps écoulé |
| **a** | 44100 fois par seconde (par paquets de ksmps) | le signal audio |

**Conséquence importante sur les conditions** : un `if` qui compare des variables **i** n'est évalué qu'une fois, au début de la note. Un `if` qui compare des variables **k** est évalué à chaque tour de boucle. C'est pour cela que l'instrument de contrôle du chapitre 3 utilise `ktime` (et pas `itime`) : il faut regarder l'heure en permanence.

**Et les variables globales** : un `g` devant le préfixe (`gi`, `gk`, `ga`) rend la variable visible par **tous** les instruments. Sans `g`, une variable n'existe qu'à l'intérieur de son instrument (et même : à l'intérieur de chaque note).

### 1.3 Lire les messages d'erreur

Quand Csound refuse de démarrer, il écrit un message dans la console. Il faut apprendre à le lire : il donne presque toujours la solution. Voici les trois erreurs les plus fréquentes.

**Erreur 1 : variable sans préfixe**
```c
freq = 440                  // FAUX : pas de préfixe i, k ou a
ifreq = 440                 // JUSTE
```
Message : `Unable to find opcode entry for '=' with matching argument types`

**Erreur 2 : variable utilisée avant d'être définie** (souvent une faute de frappe)
```c
aout poscil 0.2, kfreq      // kfreq n'a jamais été créée plus haut
```
Message : `Variable 'kfreq' used before defined`

**Erreur 3 : mauvaise vitesse pour un argument**

Certains opcodes exigent des valeurs **i** pour certains arguments (dans la documentation, les arguments commencent alors par `i`). Par exemple, `madsr` a besoin de valeurs i, car il calcule la forme de l'enveloppe une fois pour toutes au début de la note :
```c
katt = 0.01
kenv madsr katt, 0.1, 0.5, 0.2    // FAUX : katt est une variable k
```
Message : `Unable to find opcode entry for 'madsr' with matching argument types`

Dans les deux cas "`Unable to find opcode entry`", le réflexe est le même : aller voir la page de l'opcode dans la documentation, et vérifier le préfixe attendu pour chaque argument. Règle générale : on peut donner une valeur **i** là où une valeur **k** est attendue, mais pas l'inverse.

**Pas une erreur, mais un avertissement à surveiller :**
```
number of samples out of range:     3456     3456
```
Cela veut dire que le son **sature** : des échantillons dépassent `0dbfs` (1). Baissez les amplitudes. C'est particulièrement fréquent quand plusieurs notes se superposent : les amplitudes s'additionnent.

### 1.4 Penser en notes et en décibels

Deux conversions à connaître pour penser musicalement plutôt qu'en valeurs brutes :

```c
icps = cpsmidinn(69)      // note MIDI -> fréquence : 69 = la 440 Hz, 60 = do central
iamp = ampdbfs(-12)       // décibels -> amplitude : -12 dB ≈ 0.25 ; 0 dB = 1 (le maximum)
```

Le décibel est plus proche de notre perception : chaque fois qu'on retire 6 dB, l'amplitude est divisée par 2. Pour une installation où plusieurs sons se superposent, des amplitudes entre `-24` et `-12` dB sont un bon point de départ.

## 2. Faire communiquer les instruments : le bus de réverbération

Jusqu'ici, chaque instrument envoyait son son directement vers la sortie avec `outs`. Mais comment ajouter une réverbération commune à toutes les notes ?

Mauvaise idée : mettre une réverbération *dans* l'instrument. Chaque note aurait alors sa propre réverbération, qui s'arrête brutalement avec la note (la réverbération a besoin de continuer après la fin du son), et le calcul serait multiplié par le nombre de notes.

Bonne idée : faire comme sur une table de mixage, avec un **bus d'effet** (un *send*). Chaque note envoie une partie de son signal dans une variable audio **globale**, et un instrument unique, qui tourne en permanence, applique la réverbération à tout ce qu'il reçoit.

```c
gaRevL init 0   // le "tuyau" gauche du bus de réverbération
gaRevR init 0   // le "tuyau" droit

instr Voix
    ifreq = p4
    iamp  = p5
    aenv  madsr 0.01, 0.2, 0.5, 0.5
    asig  vco2 iamp, ifreq, 0
    asig  moogladder asig, ifreq * 3, 0.2
    asig  = asig * aenv

    outs asig, asig                  // le son "sec", directement en sortie
    gaRevL = gaRevL + asig * 0.3     // on envoie 30% du signal dans le bus
    gaRevR = gaRevR + asig * 0.3
endin

instr Reverb   // défini EN DERNIER : voir plus bas
    aL, aR reverbsc gaRevL, gaRevR, 0.85, 12000
    outs aL, aR
    clear gaRevL, gaRevR             // on vide le bus pour le tour suivant
endin

schedule "Reverb", 0, -1             // la réverbération tourne en permanence
```

### Pas à pas

- **`gaRevL = gaRevL + ...`** : on *ajoute* le signal au bus (et on ne le remplace pas). Ainsi, si 10 notes jouent en même temps, les 10 signaux s'additionnent dans le bus.
- **`reverbsc`** : une réverbération stéréo de bonne qualité. `0.85` est la taille de la pièce (entre 0 et 1 : plus c'est haut, plus la réverbération est longue), `12000` la fréquence de coupure en Hz (plus c'est bas, plus la réverbération est sombre).
- **`clear`** : une fois la réverbération calculée, on remet le bus à zéro. Sans cette ligne, le signal s'accumulerait indéfiniment et saturerait en quelques secondes.
- **`schedule "Reverb", 0, -1`** : une durée négative signifie "infinie". Cette ligne, écrite en dehors de tout instrument, est exécutée au démarrage.

**L'ordre des instruments est important.** À chaque tour de boucle, Csound calcule les instruments **dans l'ordre de leur numéro**. Il faut donc que toutes les voix aient *rempli* le bus avant que la réverbération ne le *lise* et le *vide*. Les instruments nommés reçoivent un numéro dans l'ordre où ils apparaissent dans le code : il suffit donc d'écrire l'instrument `Reverb` **en dernier**. (Avec des instruments numérotés, on lui donne un grand numéro, comme `instr 99`.)

Ce principe du bus est général : on peut créer de la même façon un bus de délai (`vdelay`, `delayr`/`delayw`), un bus de filtre commun, etc.

## 3. Travailler avec des sons enregistrés

Csound ne sert pas qu'à la synthèse : il peut aussi lire, transformer et découper des fichiers audio, comme on l'a fait dans Reaper au chapitre précédent.

L'opcode `diskin2` lit un fichier son :

```c
instr Lecteur
    Sfichier = "voix.wav"          // S = variable de texte (String)
    ivitesse = p4                  // 1 = normal, 2 = une octave plus haut, 0.5 = une octave plus bas
    iamp     = p5

    // Un point de départ au hasard dans le fichier
    idebut = random:i(0, filelen(Sfichier))

    asig diskin2 Sfichier, ivitesse, idebut, 1   // le dernier 1 = lire en boucle
    aenv linen iamp, 0.05, p3, 0.2
    asig = asig * aenv
    outs asig, asig
endin
```

- **Les variables `S`** contiennent du texte (ici, un nom de fichier). C'est un quatrième type de variable, à côté de i, k et a.
- **`filelen`** donne la durée du fichier en secondes.
- **`diskin2`** : fichier, vitesse de lecture (qui change aussi la hauteur, comme le mode "bande" du chapitre Reaper), point de départ en secondes, et lecture en boucle (`1`) ou non (`0`).
- **Mono ou stéréo** : `diskin2` renvoie autant de signaux que le fichier a de canaux. Pour un fichier stéréo, il faut écrire `aL, aR diskin2 ...`. Sinon, Csound affiche une erreur.
- Le fichier doit se trouver dans le même dossier que le fichier `.csd` (ou être importé dans le projet sur la plateforme en ligne).

**Pour transposer en demi-tons** plutôt qu'en vitesse : `ivitesse = 2 ^ (idemitons / 12)`, la même formule que dans le chapitre Reaper.

Avec quelques notes courtes, des départs au hasard et des vitesses variées, on obtient déjà une forme simple de **synthèse granulaire** :

```c
instr Grains
    kmetro metro 20   // 20 grains par seconde
    if kmetro == 1 then
        schedulek("Lecteur", 0, random:k(0.05, 0.2), random:k(0.5, 2), 0.2)
    endif
endin
```

Pour aller plus loin dans cette direction, Csound propose des opcodes spécialisés : `partikkel`, `syncgrain`, `fog`...

## 4. Moduler le son : le rendre vivant

Un son dont tous les paramètres sont fixes sonne vite "électronique" au mauvais sens du terme. Les sons acoustiques bougent en permanence : un violon a du vibrato, un souffle varie, une note de piano change de timbre en s'éteignant. On peut reproduire cette vie avec des **modulations** : des signaux de contrôle (k) qui font varier un paramètre.

### Le LFO : une oscillation lente

Un LFO (*Low Frequency Oscillator*) est un oscillateur trop lent pour être entendu comme un son (en dessous de 20 Hz), mais qui sert à faire osciller un paramètre :

```c
instr Vibrato
    ifreq = p4
    kvib  lfo 0.01, 5                    // oscille entre -0.01 et +0.01, 5 fois par seconde
    asig  vco2 0.2, ifreq * (1 + kvib), 0
    ...
endin
```

La fréquence oscille de ±1% autour de `ifreq`, 5 fois par seconde : c'est un **vibrato**. Appliqué à l'amplitude, ce serait un **trémolo** ; appliqué à la coupure d'un filtre, un effet *wah* régulier.

### Le hasard lissé : `randomi` et `randomh`

Le LFO est régulier, donc prévisible. Pour une évolution plus organique, on utilise des valeurs aléatoires qui changent à une certaine vitesse :

```c
kcoupure randomi 300, 3000, 2    // nouvelle valeur entre 300 et 3000, 2 fois par seconde, reliées en douceur
kcoupure randomh 300, 3000, 2    // pareil, mais par paliers (sans transition)
```

- `randomi` (*interpolated*) glisse d'une valeur à l'autre : idéal pour un filtre qui "respire".
- `randomh` (*hold*) saute d'une valeur à l'autre : idéal pour des changements nets, rythmiques.

### Placer le son dans l'espace : `pan2`

```c
ipan   = random:i(0, 1)          // 0 = gauche, 0.5 = centre, 1 = droite
aL, aR pan2 asig, ipan
outs aL, aR
```

Avec une valeur `k` (un LFO par exemple), le son se déplace pendant la note.

### Une précision importante : les enveloppes en `a`

Au chapitre 3, on écrivait `kenv madsr ...`. Or, on l'a vu, une variable **k** n'est mise à jour que tous les 32 échantillons : sur une attaque très rapide, l'enveloppe progresse donc "en escalier", ce qui peut produire un léger grésillement (*zipper noise*). La plupart des générateurs d'enveloppe peuvent aussi calculer en **a** : il suffit de changer le préfixe.

```c
aenv madsr 0.005, 0.1, 0.6, 0.3   // enveloppe calculée à chaque échantillon
asig = asig * aenv
```

Règle simple : **une enveloppe d'amplitude est plutôt en a**. Pour tout le reste (filtre, vibrato, décisions), k suffit largement.

## 5. Créer ses propres opcodes

À force d'écrire des instruments, on recopie souvent les mêmes lignes (un oscillateur + un filtre, par exemple). Csound permet de les rassembler dans un **opcode personnalisé** (*UDO*, *User-Defined Opcode*). C'est l'équivalent des fonctions en Lua. D'ailleurs, le `SimpleSine` du chapitre 2 n'est rien d'autre qu'un UDO fourni sur la plateforme !

```c
opcode Timbre, a, kkk
    kamp, kfreq, kbrillance xin     // les entrées

    a1   vco2 kamp, kfreq, 0
    a2   vco2 kamp, kfreq * 1.005, 0   // un 2e oscillateur, légèrement désaccordé
    amix = (a1 + a2) * 0.5
    aout moogladder amix, kfreq * kbrillance, 0.2

    xout aout                        // la sortie
endop
```

Et on l'utilise comme n'importe quel opcode :

```c
instr Voix
    aenv madsr 0.01, 0.2, 0.5, 0.5
    asig Timbre p5, p4, 3
    asig = asig * aenv
    outs asig, asig
endin
```

### Pas à pas

La première ligne `opcode Timbre, a, kkk` se lit ainsi :
- `Timbre` : le nom de notre opcode ;
- `a` : ce qu'il **renvoie** (ici, un signal audio) ;
- `kkk` : ce qu'il **reçoit** (ici, trois valeurs k). Chaque lettre correspond à une entrée.

Ensuite :
- `xin` récupère les entrées, dans l'ordre ;
- `xout` renvoie le résultat ;
- `endop` termine la définition.

Les deux oscillateurs légèrement désaccordés (0.5% d'écart) produisent des *battements* : le son devient plus large, plus riche (un effet de *chorus*).

À retenir : un UDO se définit **avant** les instruments qui l'utilisent. C'est une excellente manière de se constituer une bibliothèque de sons personnels, réutilisables d'un projet à l'autre.

## 6. Composer "à l'avance" dans Csound

Au chapitre 3, l'instrument de contrôle prenait ses décisions **en temps réel**, à chaque tour de boucle (avec des variables k). Mais Csound sait aussi composer "à l'avance", comme on l'a fait avec les scripts Lua dans Reaper : au moment où une note démarre, elle peut calculer et programmer toute une série d'autres notes.

### 6.1 Les boucles à l'initialisation : `while`

Comme la boucle `for` en Lua, la boucle `while` répète un bloc de code tant qu'une condition est vraie. Avec des variables **i**, toute la boucle s'exécute instantanément au début de la note :

```c
instr Arpege
    iracine  = p4                      // note MIDI de départ
    iNotes[] fillarray 0, 4, 7, 11, 14 // accord majeur 7/9
    indx     = 0

    while indx < lenarray(iNotes) do
        schedule "Voix", indx * 0.12, 3, cpsmidinn(iracine + iNotes[indx]), 0.08
        indx += 1
    od
endin
```

Une seule note `Arpege` programme 5 notes `Voix`, chacune décalée de 0.12 seconde : c'est un arpège. `schedule` (sans `k`) est la version **i** de `schedulek` : elle est exécutée une fois, au début de la note.

- `lenarray` donne la taille d'un tableau ;
- `indx += 1` est un raccourci pour `indx = indx + 1` ;
- `od` ferme la boucle (c'est `do` à l'envers) ;
- attention : les tableaux Csound commencent à l'indice **0** (contrairement à Lua !).

Essayez `indx * 0` (toutes les notes ensemble : un accord), ou `indx * random:i(0.05, 0.4)`.

### 6.2 Les instruments qui se relancent eux-mêmes

Une note peut programmer... une nouvelle note **du même instrument**. On obtient une chaîne d'événements qui s'auto-entretient. Voici la balle qui rebondit du chapitre Reaper, en Csound :

```c
instr Rebond
    irestants = p4     // combien de rebonds il reste
    iamp      = p5
    iecart    = p6

    schedule "Voix", 0, 0.3, 880, iamp

    if irestants > 0 then
        schedule p1, iecart, 0.1, irestants - 1, iamp * 0.85, iecart * 0.8
    endif
endin

schedule "Rebond", 0, 0.1, 12, 0.3, 0.5
```

À chaque rebond, la note joue un son, puis programme le rebond suivant avec un rebond de moins, une amplitude plus faible et un écart plus court. Quand `irestants` arrive à 0, la chaîne s'arrête. (`p1` désigne l'instrument lui-même.)

**Attention** : sans condition d'arrêt, la chaîne ne s'arrête jamais. C'est parfois exactement ce qu'on veut, par exemple pour une installation.

### 6.3 Une marche aléatoire

Un tirage totalement aléatoire dans une gamme produit des sauts dans tous les sens. Une **marche aléatoire** (*random walk*) est plus mélodique : à chaque étape, on avance d'un degré vers le haut, d'un degré vers le bas, ou on reste sur place. La mélodie "se promène" dans la gamme, par mouvements conjoints.

```c
giGamme[] fillarray 0, 2, 4, 7, 9, 12, 14, 16, 19, 21   // pentatonique sur 2 octaves

instr Marche
    idegre = p4                                 // position actuelle dans la gamme
    schedule "Voix", 0, 1.5, cpsmidinn(48 + giGamme[idegre]), 0.1

    ipas     = int(random:i(0, 3)) - 1          // -1, 0 ou +1
    isuivant = limit(idegre + ipas, 0, lenarray(giGamme) - 1)
    schedule p1, random:i(0.25, 1), 0.1, isuivant
endin

schedule "Marche", 0, 0.1, 5
```

- `int(random:i(0, 3))` donne 0, 1 ou 2 ; en retirant 1, on obtient -1, 0 ou +1.
- `limit` empêche de sortir de la gamme (l'indice reste entre 0 et le dernier élément).
- La position actuelle est transmise d'une note à la suivante par le p-field `p4` : c'est la "mémoire" de la marche.

C'est le principe de nombreux algorithmes de composition : une règle simple, appliquée étape par étape, dont chaque résultat dépend du précédent. Les chaînes de Markov, très utilisées en composition algorithmique (Xenakis, Hiller), en sont une généralisation.

## 7. Exercice : enrichir l'installation

Reprenez votre installation générative du chapitre 3 (ou l'exemple complet de ce chapitre, ci-dessous), et ajoutez-y au moins **trois** des éléments suivants :

- un **bus de réverbération** ;
- un **opcode personnalisé** pour votre timbre ;
- au moins une **modulation** (LFO, `randomi`...) sur un paramètre du son ;
- une **spatialisation** avec `pan2` ;
- un instrument qui lit un **son enregistré** (idéalement enregistré par vous) ;
- une **marche aléatoire**, ou un autre instrument qui se relance lui-même ;
- une enveloppe d'amplitude en **a**.

**Exemple complet assemblant les éléments du chapitre :**

```c
<CsoundSynthesizer>
<CsOptions>
-odac
</CsOptions>

<CsInstruments>

sr     = 44100
ksmps  = 32
nchnls = 2
0dbfs  = 1

gaRevL    init 0
gaRevR    init 0
giGamme[] fillarray 0, 2, 4, 7, 9, 12, 14, 16, 19, 21

// ===== Notre timbre personnel =====
opcode Timbre, a, kkk
    kamp, kfreq, kbrillance xin
    a1   vco2 kamp, kfreq, 0
    a2   vco2 kamp, kfreq * 1.005, 0
    amix = (a1 + a2) * 0.5
    aout moogladder amix, kfreq * kbrillance, 0.2
    xout aout
endop

// ===== Instrument sonore =====
instr Voix
    ifreq = p4
    iamp  = p5

    aenv       madsr 0.02, 0.3, 0.5, 0.8
    kvib       lfo 0.004, 5
    kbrillance randomi 1.5, 4, 1
    asig       Timbre iamp, ifreq * (1 + kvib), kbrillance
    asig       = asig * aenv

    aL, aR pan2 asig, random:i(0.2, 0.8)
    outs aL, aR
    gaRevL = gaRevL + aL * 0.4
    gaRevR = gaRevR + aR * 0.4
endin

// ===== Marche aléatoire (mélodie) =====
instr Marche
    idegre = p4
    schedule "Voix", 0, random:i(1, 3), cpsmidinn(48 + giGamme[idegre]), ampdbfs(-12)

    ipas     = int(random:i(0, 3)) - 1
    isuivant = limit(idegre + ipas, 0, lenarray(giGamme) - 1)
    schedule p1, random:i(0.3, 1.5), 0.1, isuivant
endin

// ===== Accords occasionnels (arpèges graves) =====
instr Accords
    ktime timeinsts
    knext init 5
    if ktime >= knext then
        schedulek("Arpege", 0, 0.1, 36 + giGamme[int(random:k(0, 5))])
        knext = ktime + random:k(8, 15)
    endif
endin

instr Arpege
    iracine  = p4
    iNotes[] fillarray 0, 7, 12, 16
    indx     = 0
    while indx < lenarray(iNotes) do
        schedule "Voix", indx * 0.15, 6, cpsmidinn(iracine + iNotes[indx]), ampdbfs(-18)
        indx += 1
    od
endin

// ===== Réverbération : TOUJOURS en dernier =====
instr Reverb
    aL, aR reverbsc gaRevL, gaRevR, 0.88, 10000
    outs aL, aR
    clear gaRevL, gaRevR
endin

</CsInstruments>

<CsScore>
f 0 z
i "Reverb"  0 -1
i "Accords" 0 -1
i "Marche"  0 0.1 5
</CsScore>
</CsoundSynthesizer>
```

Remarquez que les deux logiques cohabitent : `Accords` décide **en temps réel** (variables k, comme au chapitre 3), tandis que `Marche` et `Arpege` composent **à l'avance** (variables i, `schedule`).

## Mémo : les vérifications à faire quand ça ne marche pas

1. Chaque variable a-t-elle un préfixe (`i`, `k`, `a`, `S`, et `g` si elle est globale) ?
2. Chaque variable est-elle créée **avant** d'être utilisée (faute de frappe ?) ?
3. Les arguments de chaque opcode ont-ils la bonne vitesse ? (vérifier dans la documentation)
4. Chaque `if` a-t-il son `endif`, chaque `while` son `od`, chaque `instr` son `endin`, chaque `opcode` son `endop` ?
5. Les p-fields envoyés (`schedule`, score) sont-ils dans le même ordre que ceux lus dans l'instrument ?
6. Le son sature-t-il (`samples out of range`) ? Baisser les amplitudes.
7. Un bus global : est-il vidé avec `clear`, et l'instrument d'effet est-il bien le dernier ?
8. Les tableaux Csound commencent à **0** (et ceux de Lua à 1).

## Pour aller plus loin

- [Documentation Csound](https://csound.com/manual/) : cherchez-y `diskin2`, `reverbsc`, `pan2`, `lfo`, `randomi`, `schedule`, `opcode`, `while`...
- [The Csound FLOSS Manual](https://flossmanual.csound.com/) : un manuel complet et gratuit, avec de nombreux exemples, du débutant à l'avancé. Les chapitres sur les UDO, les bus globaux et la granulaire complètent directement ce cours.
