%{

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>
#include <string.h>
#include <stdarg.h>
#include "calculadora.tab.h" 

#define SENTENCE_MAX_LENGTH 256
#define TEMP_PREFIX "$t"

extern FILE *yyout;
extern int yylineno;
extern int yylex();
/*extern void yyerror(char*);*/

char *c3a_instructions[100];
int current_line = 1;
int temp_comp = 1;

void printSentencies();
void NumASentencia(Array indexSentences, int num);
Array creaLlista(int numero);
Array mergeLists(Array lista1, Array lista2);
sym_value_type copiaValue(sym_value_type original);

void gen_c3a(int args_count, ...);
void freeSentencies(); 
char* generate_temp();
void genC3A_aritmetica(sym_value_type *s0, sym_value_type s1, sym_value_type s2, const char* operador);
void genC3A_salt_cond(sym_value_type s1, const char *operador, sym_value_type s2, char *jump);
void calcula_literal(sym_value_type *s0, sym_value_type s1, sym_value_type s2, const char* oper);
void declare_array(char* arrayName, int elems);
void assign_array(const char* arrayName, int index, sym_value_type r);

%}

%code requires {
		#include "calculadora_funcions.h"
		#include "symtab.h"
}

%union{

	struct{
		char *lexema;
		sym_value_type value;
	} id;
	
	struct {
		Array list_false;
		Array list_true;
	} expresion_bool;
	
	Array sent;
	sym_value_type expr_aritmetica;
	
	struct {
		int quad;
		Array lls;
		char *lloc;
	} quad_data;
	
	char *cadena;
	int entero;
}

%token <id> ID ID_ARITM ID_BOOL ARRAY_ID
%token <cadena> INTEGER FLOAT
%token <expresion_bool> BOOL_TRUE BOOL_FALSE
%token <sent> FI_SENT

%token TABLE DOUBLE ENTER 
%token ASSIGN SUMA RESTA MULT DIV MOD POT NOT AND OR
%token GT GE LT LE EQ NE BOOL
%token REPEAT WHILE FOR IN TO DO UNTIL DONE IF THEN ELSE FI
%token ABRIR_PAR CERRAR_PAR ABRIR_COR CERRAR_COR

%type <expr_aritmetica> expresion_aritmetica expre_prec1_arit expre_prec2_arit expre_base_arit P R
%type <expresion_bool> expresion_booleana expresion_prec1_bool expresion_prec2_bool expre_base_bool

%type <sent> llista_sentencias sentencia assignacio N simple iterativa condicional iterativa_incondicional iterativa_condicional iterativa_indexada

%type <cadena> operel
%type <entero> M
%type <id> id 
%type <quad_data> Q

%%

programa : llista_sentencias { 
				printSentencies();
				freeSentencies();
			} 
;

llista_sentencias: llista_sentencias M sentencia {
						NumASentencia($1, $2);
						$$ = $3;
					}
					| sentencia
; 

sentencia: simple FI_SENT | iterativa FI_SENT | condicional FI_SENT | FI_SENT;

simple: assignacio { $$ = $1; }
		| procediments { $$ = $$; }
;					

assignacio: id ASSIGN expresion_aritmetica {
				$1.value = $3;
				sym_enter($1.lexema, &$1.value);
				char *valor = $3.agregado != NULL ? $3.agregado : $3.lloc;
				gen_c3a(3, $1.lexema, ":=", valor);
			}
			| id ASSIGN expresion_booleana {
				$1.value.tipus = BOOLEAN;
				if ($3.list_false.size > 0) {
					$1.value.lloc = "0";
					NumASentencia($3.list_false, current_line);
					gen_c3a(3, $1.lexema, ":=", "0");
					$$ = creaLlista(current_line);
					gen_c3a(1, "GOTO");
				}
				
				if ($3.list_true.size > 0) {
					$1.value.lloc = "1";
					NumASentencia($3.list_true, current_line);
					gen_c3a(3, $1.lexema, ":=", "1");
					$$ = mergeLists($$, creaLlista(current_line));
					gen_c3a(1, "GOTO");
				}
			}
;

id: ID | ID_ARITM | ID_BOOL;


expresion_aritmetica: expre_prec1_arit
				| expresion_aritmetica SUMA expre_prec1_arit{ genC3A_aritmetica(&$$, $1, $3, "ADD");  }
				| expresion_aritmetica RESTA expre_prec1_arit { genC3A_aritmetica(&$$, $1, $3, "SUB");  }
				| SUMA expre_prec1_arit { $$ = $2;  }
				| RESTA expre_prec1_arit {
					$$.tipus = $2.tipus;
					if ($2.is_id == true) {
						$$.lloc = generate_temp();
						if ($2.tipus == ENTERO) {
							gen_c3a(4, $$.lloc, ":=", "CHSI", $2.lloc);
						} else {
							gen_c3a(4, $$.lloc, ":=", "CHSF", $2.lloc);
						}
					} else {
						$$.agregado = (char *)malloc(sizeof(char)*5);
						if ($2.tipus == ENTERO) sprintf($$.agregado, "%d", atoi($2.lloc));
						else sprintf($$.agregado, "%.1f", atof($2.lloc));
					}
				}
;

expre_prec1_arit: expre_prec2_arit
				| expre_prec1_arit MULT expre_prec2_arit { genC3A_aritmetica(&$$, $1, $3, "MUL"); }
				| expre_prec1_arit DIV expre_prec2_arit { 
					if (($3.tipus == ENTERO && atoi($3.lloc) == 0) || ($3.tipus == REAL && atof($3.lloc) == 0)){
						yyerror("No es pot dividir entre 0");
					}
					else {
						genC3A_aritmetica(&$$, $1, $3, "DIV");
					}
				}
				| expre_prec1_arit MOD expre_prec2_arit {
					if ($1.tipus == ENTERO && $3.tipus == ENTERO){
						genC3A_aritmetica(&$$, $1, $3, "MOD");
					}
					else yyerror("Nomes es fa modul entre enters");
				}
;

expre_prec2_arit: expre_base_arit
				| expre_prec2_arit POT expre_base_arit {
					if ($3.tipus == ENTERO) {
						int exp = atoi($3.lloc);
						sym_value_type temp = copiaValue($1);
						int i; 
						for (i=0; i < exp-1; i++){
							genC3A_aritmetica(&$$, $1, temp, "MUL");
							temp = copiaValue($$);
						}
					} else yyerror("OPERACIO NO DISPONIBLE");
				}
;

expre_base_arit: ABRIR_PAR expresion_aritmetica CERRAR_PAR { $$ = $2; }
				| INTEGER { $$.tipus = ENTERO; $$.lloc = $1; $$.is_id = false; };
				| FLOAT { $$.tipus = REAL; $$.lloc = $1; $$.is_id = false; }
				| BOOL_TRUE { $$.tipus = BOOLEAN; $$.lloc = "1"; $$.is_id = false; }
				| BOOL_FALSE { $$.tipus = BOOLEAN; $$.lloc = "0"; $$.is_id = false; }
				| ID_ARITM { 
					if (sym_lookup($1.lexema, &$1.value) != SYMTAB_OK) {
						fprintf(stderr, "Error semàntic en la línea %d: Variable '%s' no definida. \n", yylineno, $1.lexema);
					}
					$$.tipus = $1.value.tipus;
					$$.lloc = $1.lexema;
					$$.is_id = true;
				}
;

expresion_booleana: expresion_prec1_bool
				| expresion_booleana OR M expresion_prec1_bool {
					NumASentencia($1.list_false, $3);
					$$.list_true = mergeLists($1.list_true, $4.list_true);
					$$.list_false = $4.list_false;
				}
;

expresion_prec1_bool: expresion_prec2_bool
				| expresion_prec1_bool AND M expresion_prec2_bool {
					NumASentencia($1.list_true, $3);
					$$.list_true = $4.list_true;
					$$.list_false = mergeLists($1.list_false, $4.list_false);
				}
;

expresion_prec2_bool: expre_base_bool 
				| NOT expresion_prec2_bool {
					$$.list_true = $2.list_false;
					$$.list_false = $2.list_true;
				}
;

expre_base_bool: ABRIR_PAR expresion_booleana CERRAR_PAR { $$ = $2; }
				| expresion_aritmetica operel expresion_aritmetica {
					$$.list_true = creaLlista(current_line);
					genC3A_salt_cond($1, $2, $3, "");
					$$.list_false = creaLlista(current_line);
					gen_c3a(1, "GOTO");
				}
				| ID_BOOL {
					sym_lookup($1.lexema, &$1.value);
					$$.list_true = creaLlista(current_line);
					gen_c3a(5, "IF", $1.lexema, "EQ", "1", "GOTO");
					$$.list_false = creaLlista(current_line);
					gen_c3a(1, "GOTO");
				}
;

operel: GT {$$="GT";} 
		| LT {$$="LT";} 
		| GE {$$="GE";} 
		| LE {$$="LE";} 
		| EQ {$$="EQ";} 
		| NE {$$="NE";}
;

iterativa: iterativa_incondicional | iterativa_condicional | iterativa_indexada;

iterativa_incondicional: REPEAT expresion_aritmetica R M DO llista_sentencias DONE {
			if ($3.tipus == ENTERO) gen_c3a(5, $3.lloc, ":=", $3.lloc, "ADDI", "1");
			else if ($3.tipus == REAL) gen_c3a(5, $3.lloc, ":=", $3.lloc, "ADDF", "1");
			else yyerror("Bad request");
			char *temp_current_line = malloc(sizeof(char)*5);
			sprintf(temp_current_line, "%d", $4);
			genC3A_salt_cond($3, "LT", $2, temp_current_line); 
		}
;

iterativa_condicional: WHILE M expresion_booleana DO M llista_sentencias DONE {
							NumASentencia($3.list_true, $5);
							NumASentencia($6, $2);
							$$ = $3.list_false;
							char *m_buffer = malloc(sizeof(char)*5);
							sprintf(m_buffer, "%d", $2);
							gen_c3a(2, "GOTO", m_buffer);
						}
						| DO M llista_sentencias UNTIL expresion_booleana {
							NumASentencia($5.list_true, $2);
							$$ = $5.list_false;
						}
;

iterativa_indexada: Q DO llista_sentencias DONE {
						NumASentencia($3, current_line);
						gen_c3a(5, $1.lloc, ":=", $1.lloc, "+", "1");
						char *quad_buffer = malloc(sizeof(char)*5);
						sprintf(quad_buffer, "%d", $1.quad);
						gen_c3a(2, "GOTO", quad_buffer);
						$$ = $1.lls;
					}
;

Q: P TO expresion_aritmetica {
		$$.quad = current_line;
		char *quad_buffer = malloc(sizeof(char)*5);
		sprintf(quad_buffer, "%d", current_line+2);
		genC3A_salt_cond($1, "LE", $3, quad_buffer);
		$$.lls = creaLlista(current_line);
		gen_c3a(1, "GOTO");
		$$.lloc = $1.lloc;
	}
;

P: FOR id IN expresion_aritmetica {
		gen_c3a(3, $2.lexema, ":=", $4.lloc);
		$$.lloc = $2.lexema;
		$$.tipus = $4.tipus;
	}
;

condicional: IF expresion_booleana THEN M llista_sentencias FI {
				NumASentencia($2.list_true, $4);
				$$ = mergeLists($2.list_false, $5);
			}
			| IF expresion_booleana THEN M llista_sentencias ELSE N M llista_sentencias FI {
				NumASentencia($2.list_true, $4);
				NumASentencia($2.list_false, $8);
				$$ = mergeLists($5, mergeLists($7, $9));
			}
;

M : { $$ = current_line; }
N : { 
		$$ = creaLlista(current_line);
		gen_c3a(1, "GOTO"); 
	}
R: {
		$$.lloc = malloc(sizeof(char)*5);
		$$.tipus = ENTERO;
		strcpy($$.lloc, generate_temp());
		gen_c3a(3, $$.lloc, ":=", "0");
	}
;

procediments: put;

put: id{
		sym_lookup($1.lexema, &$1.value);
		gen_c3a(2, "PARAM", $1.lexema);
		char *op = malloc(sizeof(char)*5);
		strcpy(op, "PUT");
		if ($1.value.tipus == ENTERO) strcat(op, "I,");
		else if ($1.value.tipus==REAL) strcat(op, "F,");
		gen_c3a(3, "CALL", op, "1");
	}
;

%%

void printSentencies(){
	for (int i=1; i < current_line; i++){
		fprintf(yyout, "%d: %s\n", i, c3a_instructions[i]);
	}
	fprintf(yyout, "%d: HALT\n", current_line);
}


void NumASentencia(Array indexSentences, int num) {
	int i;
	char *num_buffer = malloc(sizeof(char) * 5);
	sprintf(num_buffer, "%d", num);
	for (i=0; i < indexSentences.size; i++) {
		strcat(c3a_instructions[indexSentences.llista[i]], num_buffer);
	}
}

Array creaLlista(int numero) {
	Array resultat;
	
	resultat.llista = malloc(100 * sizeof(int));
	if (resultat.llista == NULL){
		fprintf(stderr, "Error al asignar mem\n");
		exit(1);
	}
	
	resultat.llista[0] = numero;
	resultat.size = 1;
	return resultat;
}

Array mergeLists(Array lista1, Array lista2) {
	Array resultat;
	
	resultat.llista = malloc(100 * sizeof(int));
	int i;
	for (i=0; i < lista1.size; i++){
		resultat.llista[i]=lista1.llista[i];
	}
	int j;
	for(j=0; j < lista2.size; j++) {
		resultat.llista[i] = lista2.llista[j];
		i++;
	}
	
	resultat.size = lista1.size + lista2.size;
	
	return resultat;
}

sym_value_type copiaValue(sym_value_type original) {
	sym_value_type copia;
	
	if (original.lloc != NULL) {
		copia.lloc = (char *)malloc(sizeof(char)*strlen(original.lloc)+2);
		strcpy(copia.lloc, original.lloc);
	}
	
	if (original.agregado != NULL) {
		copia.agregado = (char *)malloc(sizeof(char)*strlen(original.agregado)+2);
		strcpy(copia.agregado, original.agregado);
	}
	
	copia.is_id = original.is_id;
	copia.tipus = original.tipus;
	
	return copia;
}
	

void gen_c3a(int args_count, ...){
	va_list args;
	va_start(args, args_count);
	
	size_t total_length = 1;
	va_list temp_args; 
	va_copy(temp_args, args);
	
	for(int i=0; i < args_count; i++){
		total_length += strlen(va_arg(temp_args, char*)) + 1;
	}
	va_end(temp_args);
	
	char *buffer = malloc(total_length * sizeof(char));
	if (!buffer) {
		fprintf(stderr, "Error: no s'ha assignat memoria per la instrucció\n");
		exit(1);
	}
	buffer[0] = '\0';
	
	for (int i=0; i < args_count; i++) {
		strcat(buffer, va_arg(args, char*));
		strcat(buffer, " ");
	}
	va_end(args);
	
	c3a_instructions[current_line++] = buffer;
}

void freeSentencies() {
	for (int i=0; i < current_line; i++) {
		free(c3a_instructions[i]);
	}
}

char *generate_temp() {
	char *buffer = (char *) malloc(sizeof(char)*3+sizeof(int));
	sprintf(buffer, "%s0%d", TEMP_PREFIX, temp_comp++);
	return buffer;
}

void genC3A_aritmetica(sym_value_type *s0, sym_value_type s1, sym_value_type s2, const char* operador){
	if (s1.is_id == false && s2.is_id == false) calcula_literal(s0, s1, s2, operador);
	else {
		s0->is_id = true;
		s0->agregado = NULL;
		char *value1 = s1.agregado!= NULL ? s1.agregado : s1.lloc;
		char *value2 = s2.agregado!=NULL ? s2.agregado: s2.lloc;
		char *op = (char *)malloc(sizeof(char)*strlen(operador)+2);
		strcpy(op, operador);
		
		if (s1.tipus == s2.tipus) {
			s0->lloc = generate_temp();
			s0->tipus = s1.tipus;
			if (strcmp(op, "MOD")!=0) {
				if (s1.tipus == ENTERO) strcat (op, "I");
				else strcat(op, "F");
			}
			gen_c3a(5, s0->lloc, ":=", value1, op, value2);
		} else if (s1.tipus == REAL || s2.tipus == REAL) {
			if (strcmp(op, "MOD") != 0) strcat(op, "F");
			s0->tipus = REAL;
			if (s1.tipus == REAL) {
				char *castedValue;
				if (s2.is_id == true) {
					castedValue = generate_temp();
					gen_c3a(4, castedValue, ":=", "I2F", value2);
				} else {
					castedValue = (char *) malloc(sizeof(char)*5);
					sprintf(castedValue, "%.1f", atof(value2));
				}
				s0->lloc = generate_temp();
				gen_c3a(5, s0->lloc, ":=", value1, op, castedValue);
			} else if (s2.tipus == REAL) {
				char *castedValue;
				if (s1.is_id == true) {
					castedValue = generate_temp();
					gen_c3a(4, castedValue, ":=", "I2F", value1);
				} else {
					castedValue = (char *)malloc(sizeof(char)*5);
					sprintf(castedValue, "%.1f", atof(value1));
				}
				s0->lloc = generate_temp();
				gen_c3a(5, s0->lloc, ":=", castedValue, op, value2);
			}
			else yyerror("OPERACIO NO PERMESA");
		}
		else yyerror("OPERACIO NO PERMESA");
		free(op);
	}
}

void calcula_literal(sym_value_type *s0, sym_value_type s1, sym_value_type s2, const char* oper) {
	s0->is_id=false;
	float value1 = s1.agregado!=NULL ? atof(s1.agregado) : atof(s1.lloc);
	float value2 = s2.agregado!=NULL ? atof(s2.agregado) : atof(s2.lloc);
	float result;

	if (strcmp(oper, "MUL")==0) result = value1 * value2; 
	else if (strcmp(oper, "DIV")==0) result = value1 / value2;
	else if (strcmp(oper, "ADD")==0) result = value1 + value2;
	else if (strcmp(oper, "SUB")==0) result = value1 - value2;
	else if (strcmp(oper, "MOD")==0) result = (int)value1 % (int)value2;
	else yyerror("OPERACION NO ENCONTRADA.");

	s0->agregado = (char *) malloc(sizeof(char)*5);
	if (s1.tipus == REAL || s2.tipus == REAL){
		s0->tipus = REAL;
		sprintf(s0->agregado, "%.1f", result);
	}
	else { /* Both are integers*/
		s0->tipus = ENTERO;
		sprintf(s0->agregado, "%d", (int)result);
	}
}



void genC3A_salt_cond(sym_value_type s1, const char *oprel, sym_value_type s2, char *jump){
	if (strcmp(oprel, "EQ") == 0 || strcmp(oprel, "NE") == 0) {
		if (s1.tipus == s2.tipus) {
			char *op = (char *)malloc(sizeof(char)*strlen(oprel)+2);
			strcpy(op, oprel);
			if (s1.tipus == ENTERO) strcat(op, "");
			else strcat(op, "");
			gen_c3a(6, "IF", s1.lloc, op, s2.lloc, "GOTO", jump);
			free(op);
		}
		else yyerror("Dos variables de diferent tipus");
	} else {
		char *op = (char *)malloc(sizeof(char)*strlen(oprel)+2);
		strcpy(op, oprel);
		if (s1.tipus == s2.tipus) {
			if (s1.tipus == ENTERO) {
				strcat(op, "I"); 
			} else {
				strcat(op, "F");
			}
			gen_c3a(6, "IF", s1.lloc, op, s2.lloc, "GOTO", jump);
		} else if (s1.tipus == REAL || s2.tipus == REAL) {
			strcat(op, "F");
			if (s1.tipus == REAL) {
				char *castedValue;
				if (s2.is_id == true) {
					castedValue = generate_temp();
					gen_c3a(4, castedValue, ":=", "I2F", s2.lloc);
				} else {
					castedValue = (char *)malloc(sizeof(char)*5);
					sprintf(castedValue, "%.1f", atof(s2.lloc));
				}
				gen_c3a(6, "IF", s1.lloc, op, s2.lloc, "GOTO", jump);
			} else if (s2.tipus == REAL) {
				char *castedValue;
				if (s1.is_id == true) {
					castedValue = generate_temp();
					gen_c3a(4, castedValue, ":=", "I2F", s1.lloc);
				} else {
					castedValue = (char *) malloc(sizeof(char)*5);
					sprintf(castedValue, "%.1f", atof(s1.lloc));
				}
				gen_c3a(6, "IF", s1.lloc, op, s2.lloc, "GOTO", jump);
			} else yyerror("OPERACIO NO PERMESA");
		} else yyerror("OPERACIO NO PERMESA");
		free(op);
	}				
}
