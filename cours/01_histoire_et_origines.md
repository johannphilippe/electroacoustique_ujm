# Origines de l'informatique musicale 

## La machine abstraite, l'information discrète 

L'informatique, telle qu'on la connaît : c'est la capacité à faire réaliser à une machine des opérations de natures très diverses, en la programmant. 
L'ordinateur, en lui-même, est la concrétisation la plus aboutie de ce besoin d'une machine répondant à une grande variété de besoins. 
Il y a, dans l'histoire, en fait très peu de machines de ce genre dont le fonctionnement varie en fonction des instructions qu'on lui donne. 

L'une des premières machines à intégrer ce concept de programmation : le métier jacquard (1801), programmable avec des cartes perforées.  
![Métier Jacquard](https://upload.wikimedia.org/wikipedia/commons/e/ef/Metier_jacquard.jpg?utm_source=fr.wikipedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled)
Grâces aux cartes perforées, on décrit à la machine le motif à réaliser. 

C'est la première machine d'une petite liste de machines programmables, parmi lesquelles la machine analytique de Charles Babbage, et la machine de Turing. 
Les recherches d'Ada Lovelace au milieu du 19è siècle permettent d'imaginer une magine qui agirait de manière abstraite sur différents médiums (image, texte, son...), tant que ces derniers sont représentés dans le format de la machine. C'est poussée par cette idée que naît la toute théorique machine analytique de Charles Babbage. Basée sur des cartes à trous (programmes), la machine pose les fondements de l'ordinateur : mémoire, des périphériques (entrée, sortie), une "processeur" (unité de calcul) etc. 

![Machine analytique de Charles Babbage](https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a4/Analytical_Engine_%282290032530%29.jpg/960px-Analytical_Engine_%282290032530%29.jpg?utm_source=fr.wikipedia.org&utm_campaign=imageinfo&utm_content=thumbnail)

Ada Lovelace écrit à ce sujet que cette machine a vocation à "nous aider à effectuer ce que nous savons déjà dominer". Elle rejoint Marshall McLuhan qui écrira plus tard (pour comprendre les médias) que l'évolution des médias ne modifie en rien la nature de l'activité humaine, mais uniquement sa vitesse et la taille du flux. 

L'autre caractéristique centrale de l'ordinateur, c'est de travailler sur de l'information discrète : une série de points plutôt qu'un événement continue, contrairement à un phénomène physique, électronique etc. 

## Des transistors et des hommes

Un siècle plus tard, dans les années 1950, l'électronique se répand, et Alan Turing a conceptualisé la "machine de Turing" en 1936 : un modèle intellectuel pour conceptualiser les appareils de calculs. 
Après quelques tentatives plus ou moins fructueuses dans les années 1940, les années 1950 voient les premiers ordinateurs se développer dans les laboratoires de recherche.

Entre-temps, en 1928 est paru le théorème fondamental qui rendra possible de *faire du son avec un ordinateur* (entre autres choses) : le théorème de l'échantillonnage de Shannon & Nyquist. 
"La représentation discrète d'un signal exige des échantillons régulièrement espacés à une fréquence d'échantillonnage supérieure au double de la fréquence maximale présente dans ce signal."
Ce théorème est **FONDAMENTAL**. Sans lui, pas d'enregistrement numérique, pas de synthèse sonore fidèle, pas de traitement du son fidèle : rien de tout cela n'aurait été possible. 

### MUSIC 

Dans les années 1950, aux Bell Labs, nous allons retrouver les pionniers de l'informatique musicale, dont le père : Max Matthews. 
En 1957, il créé le premier programme/langage d'informatique musicale reconnu : *MUSIC*. C'est le début d'une liste, puisque Matthews développera MUSIC-II, MUSIC-III etc jusqu'à MUSIC-V. 
Le programme permet de synthétiser des formes d'ondes.

![Max Matthews](https://upload.wikimedia.org/wikipedia/commons/c/c0/Max_Mathews_on_80th_birthday.jpg?utm_source=en.wikipedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled)

[Bicycle for two 1962](https://www.youtube.com/watch?v=ZFUVR-clo8g&list=RDZFUVR-clo8g&start_radio=1)

Le programme MUSIC et ses successeurs fonctionnent toujours d'une manière similaire : des routines (opérateurs) de traitement du signal (appelés *opcodes*, important pour la suite) appliquent une certaine opération sur un signal (générateur, modulation, etc). Par exemple, un opcode permet de générer une onde sinusoidale à une fréquence donnée. 
Ces *opcodes* sont donc combinés pour créer des *instruments*. 
La logique de MUSIC est donc la suivante : l'utilisateur créé ses *instruments*, il fabrique sa lutherie. 
Ces instruments sont décrits dans un premier fichier, appelé *orchestre*. 
Un deuxième fichier *score* (partition), décrit quelles sont les événements à jouer pour les instruments. 

Nous sommes dans les années 1950/1960, donc il faut imaginer que la puissance informatique n'est pas la même. 
Tout est en temps différé. C'est à dire qu'une fois qu'un utilisateur a écrit le code pour générer du son, il faut ensuite exécuter le programme pendant des heures (des jours) avant d'obtenir le fichier audio résultant. 

Max Matthews est à l'origine d'un grand nombre de conventions que nous retrouvons dans tous les logiciels et langages aujourd'hui, y compris dans le live-coding.

### Les héritiers 

#### Csound : l'héritier légitime 

En 1985, Barry Vercoe réécrit MUSIC en langage C au MIT. 
Csound est un langage de programmation & un environnement temps-réel (programme) fidèle à la logique de MUSIC. 
Le langage intègre les mêmes concepts : des opcodes pour construire des instruments, qui composent un orchestre, et un fichier score pour décrire les événements musicaux. 
Jusqu'à ce jour, Csound est maintenu, développé et mis à jour. Csound reste et demeure open-source, gratuit, libre, accessible. Le travail des développeurs récents (John Ffitch, Victor Lazzarini, Steven Yi) permet qu'il soit simple à installer, configurer, utiliser (et même utilisable sur le web). 
La version Csound 6 fait référence, la version 7 est à venir prochainement. 

Entre autres compositeurs qui l'ont utilisés, on peut citer : Jean-Claude Risset, Tristan Murail, James Tenney, Horacio Vaggione. 

[Jacopo Greco d'Alceo - Mélanines](https://soundcloud.com/user-406213194/sets/tous-leger)

#### Max-MSP & Pure Data : la logique modulaire 

1988, Miller Puckette développe Max à l'IRCAM. 
Il s'agit, après quelques tentatives, d'un système de programmation graphique, nodale, modulaire. Pour faire simple : on créé des objets qui sont des petits modules, qu'on branche les uns aux autres. 
Max MSP ensuite (MSP = Max Signal Processing) distingue deux types de signaux : commande (contrôle) et audio. 
L'histoire de Max (puis Max MSP) est chaotique, puisque le développement quitte l'IRCAM rapidememnt dans les années 1990, avant de s'autonomiser en 1997 (Cycling 74), puisi d'être racheté par l'entreprise d'Ableton Live (2018). Mais surtout, avec les années, Max devient une machinerie de plus en plus complexe, héritant d'une dette technique importante, et intégrant énormément de nouvelles fonctionnalités. Et, le logiciel est demeuré propriétaire depuis environs 30 ans. 
Max MSP fait référence dans la musique contemporaine, notamment en France du fait de l'influence de l'IRCAM notamment. Donc un grand nombre de compositeur.rice.s en ont été utilisateurs.  

En 1996, Puckette développe Pure Data : une version ascétique, open-source de Max, dont la version *Vanilla* (brute, originale) fait référence dans le monde libre. Max étant devenu une usine trop complexe, Pure Data n'embarque que les briques essentielles au traitement audio et à la création musicale, dans une interface graphique simple, sans fioritures.
C'est naturellement que Pure Data trouve une communauté rapidement. Et cette communauté créé de nombreux embranchements techniques pour le logiciel : exports VST, interfaces plus modernes, fonctionnalités externes (objets externals)...  

[Rino Petrozziello - algorithmic patch in Max MSP](www.youtube.com/watch?v=S21lXSpQ_Cs&list=RDS21lXSpQ_Cs&start_radio=1)

#### Supercollider 

Apparu en 1996, et développé par James McCartney, il se pose en alternative directe à Csound en étant un outil puissant de création musicale. 
Sa syntaxe est plus moderne (celle de Csound hérite de MUSIC I, bien qu'elle ait été modernisée). 
Il prend rapidement en charge la modification de code à la volée (compilation JIT), ce qui en fait une base solide pour le développement de nombreux langages de live-coding. 

[SuperCollider_X.X](https://soundcloud.com/supercollider-x)

#### Common Lisp et le traitement de données : l'autre visage de l'informatique musicale 

Common Lisp Music, la version embarquée de Music V dans LISP. 
Lisp, c'est la dimension *Composition Assistée par Ordinateur* dans l'histoire de l'informatique musicale. 
Utilisé à l'IRCAM, mais pas seulement, il s'agit de la dimension "manipulation des données abstraites" qui est fondamentale en informatique musicale.
Basée sur le langage Lisp : très en vogue dans les années 1980 / 90, il s'agit de considérer les données musicales comme abstraites, et d'y appliquer des transformations musicales qui prendraient un temps trop conséquent à la main : renversement de séries, calcul de combinatoires, chaînes de markov etc.
Les algorithmes font notamment du tirage de valeurs en combinant des données et permettent de "concevoir" la musique plutôt que de la restituer.  

Cette méthode Lisp, donne entre autres naissance à Open Music, développé à l'IRCAM, qui est un de leurs seuls projets open-source et multiplateforme. 
Toutefois, il tombe peu à peu en désuétude. 

Aujourd'hui, un grand nombre de langages et projets permettent de traiter la donnée musicale abstraitement : Python et son grand nombre de librairies, Lua (embarqué dans de nombreux logiciels comme Reaper ou Renoise), etc. Ils sont autrement plus accessibles que le Lisp & Open Music. 

#### Et bien d'autres 

- Faust : langage créé à Lyon, développé depuis 2002 par Yann Orlarey et Stéphane Letz, Romain Michon, et autres contributeurs. C'est plus un langage de description de circuits audio (traitement du signal, DSP) qu'un outil de composition.
- Chuck : langage à la marge, alternative à Csound et Supercollider, insistant sur la notion de primitive temporelle "Strongly timed language". Apparu en 2003. 

#### Pour en découvrir d'autres 

[Curated list of awesome music programming languages](https://github.com/zoejane/awesome-music-programming)

## Et la pratique musicale dans tout ça 

Chaque technologie, langage, logiciel induit une *praxis*, c'est-à-dire une manière de se représenter les choses (ici : la musique). 
Aucun outil n'est neutre. 
C'est pourquoi l'arbre généalogique complexe des héritiers de MUSIC peut être observé pour mettre en évidence des pratiques, des esthétiques, et des foyers géographiques et musicaux. 