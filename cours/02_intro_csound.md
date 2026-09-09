# Csound 

## Introduction 

A l'origine, et toujours aujourd'hui, Csound distingue par essence deux *blocs* de code : 
- **orchestra** : la description des instruments électroniques, décrits sous la forme de code 
- **score** : les instructions pour les instruments, sous la forme d'une partition numérique (une sorte de micro langage)

Avec le temps, il a été possible d'unifier ces deux éléments dans un seul fichier de balise, le fichier *.csd*, à l'aide d'un système de balises XML. 

```c
<CsoundSynthesizer>
<CsOptions>
// Ici les options 
-odac 
</CsOptions>


<CsInstruments> // Début de l'orchestre

// Ici les paramètres audio 
sr = 44100 // Fréquence d'échantillonnage 
ksmps = 32 // Taux de contrôle 
nchnls = 2 // Nombre de canaux 
0dbfs = 1 // 0dbfs

// La liste des instruments : le code de l'orchestre
instr 1
  ksig line 0, p3, 1
  aout SimpleSine p4, p5 * ksig
  outs aout, aout
endin

</CsInstruments> // Fin de l'orchestre

<CsScore> // Début du score 
// Ici le score 
//p1=instr, p2=start, p3=duration, p4=freq, p5=amp
i 1 0 2 440 0.5
i 1 2.5 1.5 880 0.3
</CsScore> // Fin du score
</CsoundSynthesizer>
```


C'est la forme canonique de l'utilisation de Csound. 

Mais grâce aux travaux de Steven Yi et Victor Lazzarini (notamment), Csound a pu devenir un langage utilisable en situation de live-coding. 
En effet, à partir de la version 6, il n'est plus nécessaire d'utiliser le score : l'opcode `schedulek` permet de déclencher des événements en temps-réel, en réaction à des événements (comme des conditions par exemple). 



```c
<CsoundSynthesizer>
<CsOptions>
// Ici les options 
-odac 
</CsOptions>


<CsInstruments> // Début de l'orchestre

// Ici les paramètres audio 
sr = 44100 // Fréquence d'échantillonnage 
ksmps = 32 // Taux de contrôle 
nchnls = 2 // Nombre de canaux 
0dbfs = 1 // 0dbfs

// La liste des instruments : le code de l'orchestre
instr 1
  ksig line 0, p3, 1
  aout SimpleSine p4, p5 * ksig
  outs aout, aout
endin

instr 2 // Instrument de contrôle 
    kmetronome = metro:k(1) // métronome à 1Hz = 1 fois par seconde 
    if(kmetronome != 0) then 
        schedulek(1, 0, 1, random:k(200, 500), 0.2) // générer une note à une amplitude random
    endif
endin 

</CsInstruments> // Fin de l'orchestre

<CsScore> // Début du score 

f 0 z // On dit que Csound tourne "forever" 
i 2 0 -1  // On créé une note infinie pour l'instrument de contrôle 

</CsScore> // Fin du score
</CsoundSynthesizer>
```


## Platforme de live-coding Csound en ligne 

[Ici](https://ide.csound.com/editor/HMZBmgs0OvuQOZg6kh0e)

Dans cette plateforme, vous pouvez déjà vous approprier quelques éléments  de Csound. 
Le fichier Documentation.orc vous explique les éléments de syntaxe, et les différents sons / outils de contrôle que je fournis. Dans un second temps, on ira plus loin.

