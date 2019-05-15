D                       [0-9]
L                       [a-zA-Z_]
H                       [a-fA-F0-9]
C                       "/*"((\*+[^/*])|([^*]))*\**"*/"

%option yylineno
%{
#include <stdio.h>
#include <string.h>
#include "yacc1.tab.h"


/* Ne g�re pas les commentaires. A rajouter */
/* Supprimer les lignes dont vous n'avez pas besoin. */

%}


%%
"break"                 { return BREAK; }
"case"                  { return CASE; }
"default"               { return DEFAULT; }
"else"                  { return ELSE; }
"extern"                { return EXTERN; }
"for"                   { return FOR; }
"if"                    { return IF; }
"int"                   { return INT; }
"return"                { return RETURN; }
"switch"                { return SWITCH; }
"void"                  { return VOID; }
"while"                 { return WHILE; }

{L}({L}|{D})*           { yylval.str = strdup(yytext); return IDENTIFICATEUR;  }

{D}+    { yylval.str = strdup(yytext); return CONSTANTE;  }


{C} { }

">>"                    { return RSHIFT; }
"<<"                    { return LSHIFT; }
"&&"                    { return LAND; }
"||"                    { return LOR; }
"<="                    { return LEQ; }
">="                    { return GEQ; }
"=="                    { return EQ; }
"!="                    { return NEQ; }

"+"                     { return PLUS; }
"-"                     { return MOINS; }
"*"                     { return MUL; }
"/"                     { return DIV; }
"&"                     { return BAND; }
"|"                     { return BOR; }
"!"                     { return NOT; }
"<"                     { return LT; }
">"                     { return GT; }

[ \t\v\n\f]             {  }
.                       { return yytext[0]; }
%%
 