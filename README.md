
MIDI microtonal : 
```
	; Remplacer "imid" par une note MIDI (microtonale)
        imicrotonal = 440 * exp(0.0577622645 * (imid - 69))                                    
```


Opcode complet : 
```
; utilisable tel quel 
opcode jmtofk, k,k
	kmid xin
        kout = 440 * exp(0.0577622645 * (kmid - 69))
        xout kout
endop
```
