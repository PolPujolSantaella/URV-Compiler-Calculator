# CompiladorCalculadoraC3A

## Aprenentatges
Aquest projecte ha permès aprofundir en diversos conceptes clau de la construcció de compiladors, incloent-hi:
- Taula de símbols: Com gestionar la taula de símbols per emmagatzemar variables i estructures
- Anàlisi lèxic, sintàctic, semàntic
- Atributs i comprovació de tipus
- Utilització conjunta de Flex, Bison i Symtab
- Generació de Codi de tres adreces (C3A): Creació d'un sistema que genera codi intermediari en format de 3 adreces, una representació semàntica d'alta qualitat del codi original.

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
# Descripció del Projecte
Aquest projecte implementa un compilador simple dissenyat per processar un llenguatge de càlcul bàsic. El compilador genera codi intermediari en format C3A per la seva posterior execució. El llenguatge suportat gestiona:

- Expressions aritmètiques: Operacions bàsiques com suma, resta, multiplicació, divisió, mòdul i potència.
- Sentències iteratives: Ús de bucles repeat-do-done per a repeticions
- Procediments predefinits: Com el procediment put per a la sortida de valors
- Taules unidimensionals: Declaració, assignació i consulta de taules unidimensionals, amb operacions de desplaçament.

## Decissions de disseny

Apart de totes les decissions de disseny de la pràctica anterior:

- Generació de Codi Intemig: S'han implementat funcions auxiliars com generate_temp per a la generació de variables temporals úniques, i gen_c3a per a simplificar la creació de codi intermediari.
- Taules unidimensionals: Al analitzador lèxic, he diferenciat els identificadors de variables normals (ID_ARITM) i identificadors de taules (ARRAY_ID) per gestionar correctament les operacions específiques d'assignació i consulta.
- Tipus de Dades: Una correcta comprovació de tipus durant la fase semàntica per assegurar que les operacions s'executin només amb tipus compatibles.

## Limitacions

- Operacions amb Taules Unidimensionals: Només es poden declarar, assignar i consultar. No es permeten fer operacions aritmètiques (com suma, resta...) a no ser que es consulti en una variable abans.
- Tipus Limitats: Només es poden operar tipus bàsics: enters i reals.

