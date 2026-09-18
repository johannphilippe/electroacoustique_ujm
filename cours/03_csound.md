# Csound - Instruments, conditions et algorithmes musicaux

[Documentation](https://csound.com/manual/)

## Introduction

Dans ce chapitre, on quitte l'exemple tout prêt du chapitre précédent pour apprendre à construire ses propres outils. Trois compétences vont s'articuler ensemble, et c'est leur combinaison qui vous permettra, à la fin de ce chapitre, de réaliser une petite **installation sonore générative** :

1. **Fabriquer son instrument** : comprendre les briques de base du signal (oscillateur, filtre, enveloppe) pour concevoir un son qui vous appartient.
2. **Programmer ses conditions de déclenchement** : décider *quand* les événements sonores doivent se produire, sans intervention humaine — le cœur d'une installation.
3. **Penser des algorithmes musicaux** : décider *quoi* jouer (quelle hauteur, quelle durée, quelle décision) plutôt que d'écrire des notes une par une.

Pas de panique si vous n'avez jamais programmé : Csound reste un langage assez direct, proche du geste musical (un instrument, une partition), et vous disposez déjà d'une bibliothèque d'outils sur la plateforme en ligne.

## 1. Fabriquer son instrument

### Rappel : les trois vitesses du son dans Csound

Csound distingue en permanence trois types de variables, reconnaissables à leur préfixe :

- **i** (*init*) : une valeur calculée une seule fois, au déclenchement de la note (ex : `ifreq`).
- **k** (*control*) : une valeur qui peut changer, mais rafraîchie à un taux "de contrôle" plus lent que l'audio (ex : une enveloppe, un LFO, une décision). C'est largement suffisant pour tout ce qui n'a pas besoin d'être aussi précis qu'un signal audio.
- **a** (*audio*) : le signal audio à proprement parler, calculé à la fréquence d'échantillonnage (ex : `aout`).

Un instrument, c'est donc en général : des valeurs **i** qui fixent les paramètres de départ (fréquence, amplitude...), des valeurs **k** qui font évoluer le son dans le temps (enveloppe, filtre...), et un ou plusieurs signaux **a** qu'on envoie finalement en sortie avec `outs`.

### L'oscillateur : la matière première

Un oscillateur lit une forme d'onde à une certaine vitesse (la fréquence). C'est la brique de base de toute synthèse. `poscil` est l'oscillateur le plus simple :

```c
aout poscil kamp, kcps, ifn
```

- `kamp` : amplitude (volume)
- `kcps` : fréquence en Hz
- `ifn` : la table qui contient la forme d'onde (une sinusoïde, par exemple)

Il faut donc, avant de jouer, préparer cette table. On utilise `ftgen`, qui génère une fonction (`GEN10` construit une onde à partir d'harmoniques — `1` seul harmonique donne une sinusoïde pure) :

```c
giSine ftgen 0, 0, 4096, 10, 1   // une table de 4096 points, une sinusoïde pure
```

Exemple minimal d'instrument :

```c
instr MonSon
    aout poscil p5, p4, giSine
    outs aout, aout
endin
```

Vous pouvez aussi utiliser `vco2`, un oscillateur anti-aliasé qui propose plusieurs formes d'ondes classiques (scie, carré, triangle) sans passer par une table :

```c
aout vco2 kamp, kcps, 0   // 0 = dent de scie ; 2 = carré ; 4 = triangle
```

### Le filtre : sculpter le timbre

Un filtre retire ou renforce certaines fréquences. Deux filtres simples à connaître pour commencer :

- `tone` : un filtre passe-bas doux, qui adoucit les aigus.
```c
aout2 tone aout, khp   // khp = fréquence de coupure
```
- `moogladder` : un filtre passe-bas plus marqué, avec une résonance réglable (le classique du synthé analogique).
```c
aout2 moogladder aout, kcf, kres   // kcf = coupure, kres = résonance (0-1)
```

### Exemple complet : un instrument simple

```c
instr MonInstrument
    ifreq  = p4
    iamp   = p5
    asig   vco2 iamp, ifreq, 0
    afilt  moogladder asig, ifreq * 4, 0.3
    outs afilt, afilt
endin
```

C'est déjà un instrument utilisable — mais il lui manque une chose essentielle : une **enveloppe**. Sans elle, le son démarre et s'arrête brutalement (un *clic*), et n'a aucune vie musicale.

## 2. Les enveloppes : donner une forme dans le temps

Une enveloppe, c'est la courbe d'évolution d'un paramètre (le plus souvent l'amplitude) au fil du temps. Elle sert à deux choses :

1. **Éviter les clics** : un signal audio ne doit jamais démarrer ou s'arrêter brusquement (discontinuité), sous peine de produire un artefact numérique désagréable.
2. **Donner un geste** : une attaque rapide et un relâchement long ne raconte pas la même chose qu'une attaque lente (fondu) — c'est votre premier outil d'expression.

### `linen` : la plus simple

```c
aout linen asig, irise, idur, idec
```

`irise` (montée) et `idec` (descente) en secondes, `idur` la durée totale de la note (souvent `p3`).

### `madsr` : l'enveloppe ADSR musicale

ADSR = Attack, Decay, Sustain, Release. C'est l'enveloppe classique des synthétiseurs, et `madsr` a l'avantage de s'adapter automatiquement à la durée de la note (`p3`), y compris si elle est très courte :

```c
kenv madsr iatt, idec, islev, irel
aout = asig * kenv
```

- `iatt` : temps de montée
- `idec` : temps de descente vers le niveau de maintien
- `islev` : niveau de maintien (0-1)
- `irel` : temps de relâchement, déclenché automatiquement en fin de note

### `linseg` / `expseg` : des enveloppes sur mesure

Pour des formes plus personnelles, `linseg` (segments linéaires) et `expseg` (segments exponentiels, plus proches de la perception de l'oreille) permettent de dessiner n'importe quelle courbe :

```c
kenv linseg 0, 0.01, 1, p3 - 0.3, 0.6, 0.29, 0
// valeur, durée, valeur, durée, valeur...
```

### Instrument complet, avec enveloppe

```c
instr MonInstrument
    ifreq  = p4
    iamp   = p5
    kenv   madsr 0.01, 0.15, 0.6, 0.4
    asig   vco2 iamp, ifreq, 0
    afilt  moogladder asig, ifreq * 4, 0.3
    aout   = afilt * kenv
    outs aout, aout
endin
```

À retenir : **toute note doit avoir une enveloppe**, même minimale. C'est un réflexe à prendre dès maintenant.

## 3. Programmer ses conditions de déclenchement

Jusqu'ici, c'est vous qui décidiez quand une note se déclenche (dans le score, ou en live-coding en tapant `schedulek`). Pour une installation, personne n'est là pour déclencher les événements : c'est le code lui-même qui doit en décider, en continu, de façon autonome.

### Le principe : un instrument de contrôle

Comme vu au chapitre 2, on écrit un **instrument de contrôle** — un instrument qui ne fait pas de son, mais qui observe le temps et déclenche d'autres instruments avec `schedulek` :

```c
gknext init 0   // variable globale : le moment du prochain événement

instr Controle
    ktime timeinsts   // temps écoulé (s) depuis le lancement de cet instrument

    if ktime >= gknext then
        schedulek(1, 0, 2, 220, 0.3)
        gknext = ktime + random:k(1, 4)   // prochain événement dans 1 à 4 secondes
    endif
endin
```

Ce motif est le cœur de toute installation sonore générative : au lieu d'un `metro` strictement périodique (mécanique, prévisible), on tire aléatoirement la date du **prochain** événement à chaque fois. Le résultat est beaucoup plus organique, moins "machine".

### Combiner plusieurs conditions

On peut complexifier la logique avec des `if / elseif / else`, des compteurs, ou des variables globales partagées entre instruments :

```c
gknext  init 0
gkcompte init 0

instr Controle
    ktime timeinsts

    if ktime >= gknext then
        gkcompte = gkcompte + 1

        if gkcompte % 5 == 0 then
            // tous les 5 événements : un son plus long et plus grave
            schedulek(1, 0, 4, 110, 0.4)
        else
            schedulek(1, 0, 1.5, 440, 0.25)
        endif

        gknext = ktime + random:k(0.5, 3)
    endif
endin
```

`%` est l'opérateur *modulo* : `gkcompte % 5 == 0` est vrai un événement sur cinq. C'est une manière simple de faire évoluer une installation sans la rendre totalement aléatoire — un mélange de règle et de hasard.

### Pourquoi c'est utile pour une installation

Une installation sonore doit pouvoir vivre seule, potentiellement pendant des heures, sans que cela devienne répétitif ou prévisible. Les outils ci-dessus permettent de :
- faire varier le tempo des événements (aléatoire borné),
- introduire des ruptures régulières mais non systématiques (compteurs, modulo),
- faire évoluer l'installation lentement dans le temps (voir la section suivante et l'exercice).

## 4. Algorithmes musicaux : décider quoi jouer

Une fois qu'on sait *quand* déclencher un événement, il reste à décider *quoi* jouer : quelle hauteur, quelle durée, quelle amplitude. Plutôt que d'écrire des notes une à une, on écrit une **règle** qui les génère.

### Choisir une hauteur dans une échelle

On stocke une échelle dans un tableau (array), puis on y pioche un indice au hasard :

```c
gkScale[] fillarray 0, 2, 4, 7, 9   // pentatonique majeure (degrés)

instr Controle
    ...
    kidx     = int(random:k(0, 5))          // indice entier entre 0 et 4
    kdegre   = gkScale[kidx]
    kmidi    = 60 + kdegre                   // transposé sur le do central
    kcps     = cpsmidinn(kmidi)
    ...
endin
```

`cpsmidinn` convertit une note MIDI en fréquence — bien plus pratique que de manipuler des Hz directement quand on pense en notes.

### Générer un rythme

Le même principe s'applique aux durées : on tire la prochaine échéance dans une liste de valeurs rythmiques plutôt que dans un intervalle continu, pour obtenir un rythme qui "sonne" musicalement plutôt que du pur hasard :

```c
gkDurees[] fillarray 0.25, 0.5, 0.5, 1, 1.5

kidxD    = int(random:k(0, 5))
kduree   = gkDurees[kidxD]
gknext   = ktime + kduree
```

### Prendre des décisions (probabilités)

Pour introduire de la variété sans tout randomiser, on compare un tirage aléatoire entre 0 et 1 à un seuil de probabilité :

```c
if random:k(0, 1) < 0.15 then
    // 15% de chances : un événement "rare" (silence, son exceptionnel...)
    schedulek(2, 0, 3, 55, 0.5)
else
    schedulek(1, 0, kduree, kcps, 0.25)
endif
```

C'est le même principe qu'un dé qu'on lance : on décide d'une probabilité musicale (rare/fréquent), pas d'une règle fixe.

### Faire évoluer l'algorithme dans le temps

Une installation gagne à ne pas rester statique. On peut faire dériver lentement un paramètre global avec `line` ou `expon`, sur toute la durée de vie de l'instrument de contrôle :

```c
instr Controle
    kdensite line 0.2, 600, 0.9   // passe de 0.2 à 0.9 en 600 secondes (10 minutes)
    ...
    if random:k(0, 1) < kdensite then
        ...
    endif
endin
```

## 5. Exercice : une petite installation sonore générative

Vous disposez maintenant de tout ce qu'il faut. L'exercice consiste à assembler ces trois briques (instrument, conditions, algorithme) en une installation courte et autonome. Rien de sophistiqué n'est attendu : l'objectif est de manipuler les outils, pas de produire une œuvre aboutie.

**Cahier des charges minimal :**

- Un instrument sonore personnel (oscillateur + filtre au choix), muni d'une **enveloppe**.
- Un instrument de contrôle qui déclenche les événements **sans horloge strictement périodique** (dates tirées aléatoirement, comme vu en section 3).
- Un algorithme simple de choix de hauteurs (échelle + tirage), et si possible de durées.
- Une installation capable de tourner indéfiniment : `f 0 z` dans le score, et une note infinie pour l'instrument de contrôle (`i 2 0 -1`, comme au chapitre 2).
- Bonus : faire évoluer un paramètre global lentement dans le temps (densité, registre, timbre...) pour que l'installation ne soit pas figée.

**Exemple complet assemblant tous les éléments du chapitre :**

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

gkScale[]  fillarray 0, 2, 4, 7, 9
gkDurees[] fillarray 0.5, 1, 1, 1.5, 2
gknext     init 0

instr 1   // instrument sonore
    ifreq = p4
    iamp  = p5
    kenv    madsr 0.02, 0.2, 0.5, 0.6
    asig    vco2 iamp, ifreq, 0
    afilt   moogladder asig, ifreq * 3, 0.25
    aout    = afilt * kenv
    outs aout, aout
endin

instr 2   // instrument de contrôle
    ktime    timeinsts
    kdensite line 0.3, 900, 0.8   // évolue sur 15 minutes

    if ktime >= gknext then
        kidx    = int(random:k(0, 5))
        kdegre  = gkScale[kidx]
        kmidi   = 48 + kdegre + (12 * int(random:k(0, 3)))
        kcps    = cpsmidinn(kmidi)

        kidxD   = int(random:k(0, 5))
        kduree  = gkDurees[kidxD]

        if random:k(0, 1) < kdensite then
            schedulek(1, 0, kduree, kcps, 0.2)
        endif

        gknext = ktime + kduree * (2 - kdensite)
    endif
endin

</CsInstruments>

<CsScore>
f 0 z
i 2 0 -1
</CsScore>
</CsoundSynthesizer>
```

Partez de cet exemple, modifiez l'échelle, le timbre, le filtre, la logique de décision : c'est en le détournant que vous comprendrez vraiment chaque brique.

## Pour aller plus loin

[Documentation Csound](https://csound.com/manual/) — cherchez-y directement le nom de chaque opcode utilisé dans ce chapitre (`poscil`, `vco2`, `moogladder`, `madsr`, `linseg`, `timeinsts`, `random`, `fillarray`...) pour découvrir leurs variantes et paramètres additionnels.
