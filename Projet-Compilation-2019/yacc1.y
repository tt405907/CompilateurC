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
%start programme
%%




programme :	
		liste_declarations liste_fonctions
;

liste_declarations :	
		liste_declarations declaration 
	|	
;

liste_fonctions :	
		liste_fonctions fonction
|               fonction
;

declaration :	
		type liste_declarateurs ';'
;

liste_declarateurs :	
		liste_declarateurs ',' declarateur
	|	declarateur
;

declarateur	:	
		IDENTIFICATEUR
	|	declarateur '[' CONSTANTE ']'
;

fonction :	
		type IDENTIFICATEUR '(' liste_parms ')' '{' liste_declarations liste_instructions '}'
	|	EXTERN type IDENTIFICATEUR '(' liste_parms ')' ';'
;

type :	
		VOID
	|	INT
;

liste_parms :	
		liste_parms ',' parm
	|	
;

parm :	
		INT IDENTIFICATEUR
;

liste_instructions :	
		liste_instructions instruction
	|
;

instruction :	
		iteration
	|	selection
	|	saut
	|	affectation ';'
	|	bloc
	|	appel
;

iteration :	
		FOR '(' affectation ';' condition ';' affectation ')' instruction
	|	WHILE '(' condition ')' instruction
;

selection :	
		IF '(' condition ')' instruction %prec THEN
	|	IF '(' condition ')' instruction ELSE instruction
	|	SWITCH '(' expression ')' instruction
	|	CASE CONSTANTE ':' instruction
	|	DEFAULT ':' instruction
;

saut :	
		BREAK ';'
	|	RETURN ';'
	|	RETURN expression ';'
;

affectation :	
		variable '=' expression
;

bloc :	
		'{' liste_declarations liste_instructions '}'
;

appel :	
		IDENTIFICATEUR '(' liste_expressions ')' ';'
;

variable :	
		IDENTIFICATEUR
	|	variable '[' expression ']'
;

expression :	
		'(' expression ')'
	|	expression binary_op expression %prec OP
	|	MOINS expression
	|	CONSTANTE
	|	variable
	|	IDENTIFICATEUR '(' liste_expressions ')'
;

liste_expressions :	
		liste_expressions ',' expression
	|
;

condition :	
		NOT '(' condition ')'
	|	condition binary_rel condition %prec REL
	|	'(' condition ')'
	|	expression binary_comp expression
;

binary_op :	
		PLUS 
	|       MOINS
	|	MUL
	|	DIV
	|       LSHIFT
	|       RSHIFT
	|	BAND
	|	BOR
;

binary_rel :	
		LAND
	|	LOR
;

binary_comp :	
		LT
	|	GT
	|	GEQ
	|	LEQ
	|	EQ
	|	NEQ
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






