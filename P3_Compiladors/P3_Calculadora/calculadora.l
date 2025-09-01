%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#include "calculadora.tab.h"
#include "calculadora_funcions.h"

#define YYLMAX 100

%}

%option yylineno
%option noyywrap
%option noinput
%option nounput

%x comment

lletra [a-zA-Z]
digit  [0-9]
endline "\n"
space [ \t\r]
line_comment "//"
open_block_comment "/*"
close_block_comment "*/"

%%

"("								{ return ABRIR_PAR; }
")"								{ return CERRAR_PAR; }

"["								{ return ABRIR_COR; }
"]"								{ return CERRAR_COR; }

":=" 							{ return ASSIGN; }
"+" 							{ return SUMA; }
"-" 							{ return RESTA; }
"*"								{ return MULT; }
"/"								{ return DIV; }
"**"							{ return POT; }
"%"								{ return MOD; }


">"								{ return GT; }
">="							{ return GE; }
"<"								{ return LT; }
"<="							{ return LE; }
"="								{ return EQ; }
"<>"							{ return NE; }

"not"							{ return NOT; }
"and"							{ return AND; }
"or"							{ return OR; }

"true"							{ return BOOL_TRUE; }
"false"							{ return BOOL_FALSE; }
	

"repeat"						{ return REPEAT; }
"while"							{ return WHILE; }
"for"							{ return FOR; }
"in"							{ return IN; }
".."							{ return TO; }
"do"							{ return DO; }
"until"							{ return UNTIL; }
"done"							{ return DONE; }


"if"							{ return IF; }
"then"							{ return THEN; }
"else"							{ return ELSE; }
"fi"							{ return FI; }


"TABLE"							{ return TABLE; }


{lletra}({lletra}|{digit})*						{ 
													sym_value_type value;
													yylval.id.lexema = (char *)malloc(sizeof(char)*(yyleng+1));
													yylval.id.lexema[yyleng] = '\0';
													strncpy(yylval.id.lexema, yytext, yyleng+1);
													if (sym_lookup(yytext, &value) == SYMTAB_OK) {
														switch (value.tipus) {
															case BOOLEAN:
																return ID_BOOL;
															default:
																return ID_ARITM;
														}
													}else return ID_ARITM;
												}
								
{endline} 										{ return FI_SENT; }

{line_comment}(.)*								{}
{open_block_comment} 							{ BEGIN(comment); }
<comment>[^*]*  								{}
<comment>"*"+[^*/]* 							{}	
<comment>{close_block_comment}{endline}? 		{BEGIN(INITIAL);} 

"-"?{digit}({digit})*							{ yylval.cadena = (char *)malloc(sizeof(char)* yyleng+1);
												strncpy(yylval.cadena, yytext, yyleng);
												yylval.cadena[yyleng] = '\0';
												return INTEGER;
												}
								
"-"?{digit}+"."{digit}+((?i:e)"-"?{digit}*)?	{ yylval.cadena = (char *)malloc(sizeof(char)*yyleng+1);
												strncpy(yylval.cadena, yytext, yyleng);
												yylval.cadena[yyleng] = '\0';
												return FLOAT;
												}
{space}+ 										{}

. { fprintf(stderr, "Error lèxic en la línea %d: '%s' \n", yylineno, yytext); exit(1); }


%%												