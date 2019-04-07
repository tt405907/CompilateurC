%{
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
struct Arbre {
    struct Arbre *enfant[100];
    char* type_noeud;
    char* nom_expr;
    char* valeur;
    char* dataType;
    int lineNo;
    int nbr_enfants;
};
// On garde lineNO ? Quel est son réel intérré ? à par peut être graphique sur 
// l'affichage pour savoir quel résultat provient de quel ligne
struct Arbre * creation_noeud(int lineNo,char* type_noeud, char* nom_expr, char* valeur, char* dataType, int nbr_enfants, ...){
    struct Arbre * noeud = (struct Arbre*) malloc(sizeof(struct Arbre));
    noeud->type_noeud = type_noeud;
    noeud->nom_expr = nom_expr;
    noeud->valeur= valeur;
    noeud->dataType = dataType;
    noeud->lineNo = lineNo;
    noeud->nbr_enfants = nbr_enfants;
    va_list ap;
    int i;
    va_start(ap, nbr_enfants);
    for (int i=0; i < nbr_enfants; i++)
	{
        noeud->enfant[i]=va_arg(ap, struct Arbre *);
    }
    va_end(ap);
    return noeud;
}
%}
%union {
    char* str;
    struct Arbre * ast;
}
%token IDENTIFICATEUR CONSTANTE VOID INT FOR WHILE IF ELSE SWITCH CASE DEFAULT
%token BREAK RETURN PLUS MOINS MUL DIV LSHIFT RSHIFT BAND BOR LAND LOR LT GT 
%token GEQ LEQ EQ NEQ NOT EXTERN
%left PLUS MOINS
%left MUL DIV
%left LSHIFT RSHIFT
%left BOR BAND
%left LAND LOR
%nonassoc THEN
%nonassoc ELSE
%left OP
%left REL
%type<ast> programme liste_declarations liste_fonctions declaration fonction liste_declarateurs declarateur liste_parms parm liste_instructions instruction iteration selection saut affectation bloc appel variable condition expression liste_expressions binary_rel binary_comp binary_op
%type<str> type
%start programme
%%
programme :	
		liste_declarations liste_fonctions {$$=creation_noeud(yylineno, STR(programme), none, none, none,  2, $1, $2); }
;
liste_declarations :	
		liste_declarations declaration {$$=creation_noeud(yylineno, "liste_declarations" none, none, none,  2, $1, $2); }
	|	
;
liste_fonctions :	
		liste_fonctions fonction {$$=creation_noeud(yylineno, "liste_fonctions" none, none, none,  2, $1, $2); }
|               fonction {$$=$1;}
;
declaration :	
		type liste_declarateurs ';' {$$=creation_noeud(yylineno, "declaration", none, none, $1, 1, $2); }
;
liste_declarateurs :	
		liste_declarateurs ',' declarateur {$$=creation_noeud(yylineno, "liste_declarateurs" none, none, none,  2, $1, $2); }
	|	declarateur {$$=$1;}
;
declarateur	:	
		IDENTIFICATEUR {$$ = newnode(yylineno, "declarateur", $1, none, none, 0);}
	|	declarateur '[' CONSTANTE ']' {$$ = newnode(yylineno, "declarateur_tab", none, none, none, 2,$1,$3);}
;
fonction :	
		type IDENTIFICATEUR '(' liste_parms ')' '{' liste_declarations liste_instructions '}' {$$=newnode(yylineno,"fonction", $2, none, $1,  3,$4,$7,$8);}
	|	EXTERN type IDENTIFICATEUR '(' liste_parms ')' ';' {$$=newnode(yylineno,"ext_fonction", $3, none, $2,  1,$5);}
;
type :	
		VOID {$$="VOID";}
	|	INT {$$="INT";}
;
liste_parms :	
		liste_parms ',' parm {$$ = newnode(yylineno,"liste_parms", none, none, integer,  2, $1,$2);}
	|	
;
parm :	
		INT IDENTIFICATEUR {$$ = newnode(yylineno,"parm", $2, none, "INT",  0);}
;
liste_instructions :	
		liste_instructions instruction {$$ = newnode(yylineno,"liste_instructions", none, none, integer,  2, $1,$2);}
	|
;
instruction :	
		iteration {$$=$1;}
	|	selection {$$=$1;}
	|	saut {$$=$1;}
	|	affectation ';' {$$=$1;}
	|	bloc {$$=$1;}
	|	appel {$$=$1;}
;
iteration :	
		FOR '(' affectation ';' condition ';' affectation ')' instruction {$$ = newnode(yylineno,"FOR", none, none, "INT",  4, $3,$5,$7,$9);}
	|	WHILE '(' condition ')' instruction {$$ = newnode(yylineno,"WHILE", none, none, none,  2, $3, $5);}
;
selection :	
		IF '(' condition ')' instruction %prec THEN {$$ = newnode(yylineno,"IF", none, none,none,  2, $3,$5);}
	|	IF '(' condition ')' instruction ELSE instruction {$$ = newnode(yylineno,"IF_ELSE", none, none, none,  4, $3,$5,$7;}
	|	SWITCH '(' expression ')' instruction {$$ = newnode(yylineno,"SWITCH", none, none, none,  2, $3,$5);}
	|	CASE CONSTANTE ':' instruction {$$ = newnode(yylineno,"CASE", CONSTANTE, none, none,  1, $4);}
	|	DEFAULT ':' instruction {$$ = newnode(yylineno,"DEFAULT", none, none, none,  1, $3);}
;
saut :	
		BREAK ';' {$$ = newnode(yylineno,"BREAK", none, none,none,  0);}
	|	RETURN ';'  {$$ = newnode(yylineno,"RETURN", none, none,none,  0);}
	|	RETURN expression ';' {$$ = newnode(yylineno,"RETURN_ex", none, none,none,  1, $2);}
;
affectation :	
		variable '=' expression {$$ = newnode(yylineno,"affectation", "=", none,none,  2,$1 ,$3);}
;
bloc :	
		'{' liste_declarations liste_instructions '}' {$$ = newnode(yylineno,"bloc", none, none,none,  2,$2 ,$3);}
;
appel :	
		IDENTIFICATEUR '(' liste_expressions ')' ';'  {$$ = newnode(yylineno,"appel", $1, none,none,  1,$3);}
;
variable :	
		IDENTIFICATEUR {$$ = newnode(yylineno,"variable", $1, none,none,  0);}
	|	variable '[' expression ']' {$$ = newnode(yylineno,"variable_exp", none, none,none,  2,$1,$3);}
;
expression :	
		'(' expression ')'  {$$ = newnode(yylineno,"expression", none, none,none,  1,$1,$3);}
	|	expression binary_op expression %prec OP 
	|	MOINS expression {$$ = newnode(yylineno,"exp_moins_expression", none, none,none,  1,$1,$3);}
	|	CONSTANTE {$$ = newnode(yylineno,"exp_CONSTANTE", $1, none,none,  0);}
	|	variable  {$$ = newnode(yylineno,"exp_variable", none, none,none,  1,$1);}
	|	IDENTIFICATEUR '(' liste_expressions ')' {$$ = newnode(yylineno,"exp_IDENTIFICATEUR", $1, none,none,  1,$3);}
;
liste_expressions :	
		liste_expressions ',' expression {$$ = newnode(yylineno,"liste_expressions", none, none,none,  2,$1,$3);}
	|
;
condition :	
		NOT '(' condition ')' { $$ = newnode(yylineno,"NOT", none, none,none,  1,$3);}
	|	condition binary_rel condition %prec REL 
	|	'(' condition ')'  { $$ = newnode(yylineno,"condition", none, none,none,  1,$2);}
	|	expression binary_comp expression  { $$ = newnode(yylineno,"condition_comp", none, none,none,  3,$1,$2,$3);}
;
binary_op :	
		PLUS {$$=$1;}
	|       MOINS {$$=$1;}
	|	MUL {$$=$1;}
	|	DIV {$$=$1;}
	|       LSHIFT {$$=$1;}
	|       RSHIFT {$$=$1;}
	|	BAND {$$=$1;}
	|	BOR {$$=$1;}
;
binary_rel :	
		LAND {$$=$1;}
	|	LOR {$$=$1;}
;
binary_comp :	
		LT {$$=$1;}
	|	GT {$$=$1;}
	|	GEQ {$$=$1;}
	|	LEQ {$$=$1;}
	|	EQ {$$=$1;}
	|	NEQ {$$=$1;}
;
%%
void main(int args,char** argv)
{
	if (args > 1)
	{
    		FILE *file;
    		file = fopen(argv[1], "r");
    		if (!file)
    		{
    		    fprintf(stderr, "failed open");
        		exit(1);
    		}
    		yyin=file;
    		//printf("success open %s\n", argv[1]);
	}
	else
	{
    		printf("no input file\n");
    		exit(1);
	}
		//printf("<?xml version=\"1.0\"?>\n<root>\n");
		yyparse();  
		//printf("</root>\n");
		return 0; 
} 
void yyerror(char *s){
	fprintf(stderr,"%s\n",s);}






