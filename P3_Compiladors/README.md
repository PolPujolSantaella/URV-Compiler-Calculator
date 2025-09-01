# P3_Calculadora

## Descripció
Aquest projecte implementa un compilador bàsic per un llenguatge que inclou operacions aritmètiques i lògiques, estructures de control (com if, while i for). El compilador genera un codi intermediari en format de intruccions de tres direccions (C3A) que es pot utilitzar per la generació de codi màquina o base per optimitzacions.

## Compilació
1. Clona el repositori:
   ```bash
   git clone https://github.com/PolPujolSantaella/CompiladorCalculadoraC3A.git
   cd P2_C3A_Calculadora
   ```

2. Compila el projecte
   ```bash
   make all
   ```

## Execució
Per provar el joc de proves que he realitzat només cal fer un:
   ```bash
   make eg
   ```
Aquest et genera un arxiu ex_sortida.out que conté la sortida corresponent.

## Per netejar-ho tot menys arxius fonts
   ```bash
   make clean
   ```

## Decissions de disseny
A part de totes le decissions de disseny de les pràctiques anteriors, ara tenim deficions per els literals booleans, sentencies iteratives (while, for, do-until) i condicionals (if-else, if). També es destaca la diferenciació entre ID_BOOL i ID_ARITM. 

Pel que fa la taula de símbols he afegit les variables agregado i is_id.

- agregado: Es una string que té el valor "agregat" d'una operació. Es guarden els resultat d'aquelles operacions que es poden realitzar en temps d'execució.
- is_id: Variable necessària per evitar realitzar operacions en temps d'execució amb identificadors.


## Limitacions

Per manca de temps falta la implementació de les sentències condicionals amb switch.

