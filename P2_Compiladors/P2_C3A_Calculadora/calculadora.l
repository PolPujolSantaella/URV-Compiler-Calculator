%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "calculadora.tab.h"
#include "calculadora_funcions.h"

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

"repeat"						{ return REPEAT; }
"do"							{ return DO; }
"done"							{ return DONE; }

"TABLE"							{ return TABLE; }


{lletra}({lletra}|{digit})*						{ sym_value_type value;
													yylval.id.lexema = (char *)malloc(sizeof(char)*(yyleng+1));
													yylval.id.lexema[yyleng] = '\0';
													strncpy(yylval.id.lexema, yytext, yyleng+1);
													if (sym_lookup(yytext, &value) == SYMTAB_OK){
														switch (value.tipus) {
															case ARRAY:
																return ARRAY_ID;
															default:
																return ID_ARITM; 
														}
													} else {
														return ID_ARITM;
													}
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