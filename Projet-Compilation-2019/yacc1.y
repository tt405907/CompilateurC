%{
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
//#include "yacc1.tab.h"


void yyerror(const char *s)
{
	fflush(stdout);
	fprintf(stderr, "*** %s\n", s);
}

int yylex();
FILE *yyin;
FILE *yyout;
int yylineno;
char* integer="INT";
char* floating="float";
char* none = "none";
char* assign = "=";

char* tab="  ";
char indent[100]="";
void incIndent(){
    strcat(indent, tab);
}
void decIndent(){
    int len = strlen(indent);
    indent[len-2]='\0';
}


struct Arbre {
    struct Arbre *enfant[100];
    char* type_noeud;
    char* nom_expr;
    char* valeur;
    char* dataType;
    int lineNo;
    int nbr_enfants;
};



typedef struct list_f {
	struct Arbre *val;
	struct list_f *next;
}list_f;

struct list_f *listprogramme;

struct list_f *cons(struct Arbre *node, struct list_f *list) {
	struct list_f *newlist =(struct list_f*) malloc(sizeof(struct list_f));
	newlist->val = node;
	newlist->next = list;
	return newlist;
}
void freelist(struct list_f *list) {
	if (list == NULL) return;
	freelist(list->next);
	free(list);
}

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

void printNode(struct Arbre *node){
    printf("%s<Tree lineNo=\"%d\" nodeType=\"%s\" string=\"%s\" value=\"%s\" dataType=\"%s\">\n", 
        indent,
        node->lineNo,
        node->type_noeud,
        node->nom_expr,
        node->valeur, 
        node->dataType);
    int i;
    if (node->nbr_enfants > 0){
        printf("%s<Child>\n", indent);
        incIndent();
        for (i=0;i<node->nbr_enfants;i++){
            printNode(node->enfant[i]);
        }
        decIndent();
        printf("%s</Child>\n", indent);
    }
    printf("%s</Tree>\n", indent);
}

void printlist(struct list_f *list) {
	if (list == NULL) return;
	printNode(list->val);
	printlist(list->next);
}

%}
%union {
    char* str;
    struct Arbre *ast;
	struct list_f *list;
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
%type<ast> GEQ LEQ EQ NEQ NOT EXTERN BREAK RETURN PLUS MUL DIV LSHIFT RSHIFT BAND BOR LAND LOR LT GT  MOINS CONSTANTE IDENTIFICATEUR liste_declarations declaration fonction liste_declarateurs declarateur liste_parms parm liste_instructions instruction iteration selection saut affectation bloc appel variable condition expression liste_expressions binary_rel binary_comp binary_op
%type<str> type 
%type<list> liste_fonctions

%start programme
%%
programme :	
		liste_declarations liste_fonctions {listprogramme = $2; }
;
liste_declarations :	
		liste_declarations declaration {$$=creation_noeud(yylineno, "liste_declarations", none, none, none,  2, $1, $2); }
	|	declaration {$$=$1;}
;
liste_fonctions :	
		liste_fonctions fonction {$$ = cons($2, $1); }
|               fonction {$$ = cons($1, NULL);}
;
declaration :	
		type liste_declarateurs ';' {$$=creation_noeud(yylineno , "declaration",none, none, none, 1, $2); }
;
liste_declarateurs :	
		liste_declarateurs ',' declarateur {$$=creation_noeud(yylineno, "liste_declarateurs" ,none, none, none,  2, $1, $3); }
	|	declarateur {$$=$1;}
;
declarateur	:	
		IDENTIFICATEUR {$$ = creation_noeud(yylineno, "declarateur", none, none, none, 0);}
	|	declarateur '[' CONSTANTE ']' {$$ = creation_noeud(yylineno, "declarateur_tab", none, none, none, 2,$1,$3);}
;
fonction :	
		type IDENTIFICATEUR '(' liste_parms ')' '{' liste_declarations liste_instructions '}' {$$=creation_noeud(yylineno,"fonction", none, none, $1,  3,$4,$7,$8);}
	|	EXTERN type IDENTIFICATEUR '(' liste_parms ')' ';' {$$=creation_noeud(yylineno,"ext_fonction", none, none, $2,  1,$5);}
;
type :	
		VOID {$$="VOID";}
	|	INT {$$="INT";}
;
liste_parms :	
		liste_parms ',' parm {$$ = creation_noeud(yylineno,"liste_parms", none, none, "integer",  2, $1,$3);}
	|	parm {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
;
parm :	
		INT IDENTIFICATEUR {$$ = creation_noeud(yylineno,"parm", none, none, "INT",  0);}
;
liste_instructions :	
		liste_instructions instruction {$$ = creation_noeud(yylineno,"liste_instructions", none, none, integer,  2, $1,$2);}
	|   instruction {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
;
instruction :	
		iteration {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
	|	selection {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
	|	saut {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
	|	affectation ';' {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
	|	bloc {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
	|	appel {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
;
iteration :	
		FOR '(' affectation ';' condition ';' affectation ')' instruction {$$ =creation_noeud(yylineno,"FOR", none, none, "INT",  4, $3,$5,$7,$9);}
	|	WHILE '(' condition ')' instruction {$$ =creation_noeud(yylineno,"WHILE", none, none, none,  2, $3, $5);}
;
selection :	
		IF '(' condition ')' instruction %prec THEN {$$ =creation_noeud(yylineno,"IF", none, none,none,  2, $3,$5);}
	|	IF '(' condition ')' instruction ELSE instruction {$$ =creation_noeud(yylineno,"IF_ELSE", none, none, none,  3, $3,$5,$7);}
	|	SWITCH '(' expression ')' instruction {$$ =creation_noeud(yylineno,"SWITCH", none, none, none,  2, $3,$5);}
	|	CASE CONSTANTE ':' instruction {$$ =creation_noeud(yylineno,"CASE", "CONSTANTE", none, none,  1, $4);}
	|	DEFAULT ':' instruction {$$ =creation_noeud(yylineno,"DEFAULT", none, none, none,  1, $3);}
;
saut :	
		BREAK ';' {$$ =creation_noeud(yylineno,"BREAK", none, none,none,  0);}
	|	RETURN ';'  {$$ =creation_noeud(yylineno,"RETURN", none, none,none,  0);}
	|	RETURN expression ';' {$$ =creation_noeud(yylineno,"RETURN_ex", none, none,none,  1, $2);}
;
affectation :	
		variable '=' expression {$$ =creation_noeud(yylineno,"affectation", "=", none,none,  2,$1 ,$3);}
;
bloc :	
		'{' liste_declarations liste_instructions '}' {$$ =creation_noeud(yylineno,"bloc", none, none,none,  2,$2 ,$3);}
;
appel :	
		IDENTIFICATEUR '(' liste_expressions ')' ';'  {$$ =creation_noeud(yylineno,"appel", none, none,none,  1,$3);}
;
variable :	
		IDENTIFICATEUR {$$ =creation_noeud(yylineno,"variable", none, none,none,  0);}
	|	variable '[' expression ']' {$$ =creation_noeud(yylineno,"variable_exp", none, none,none,  2,$1,$3);}
;
expression :	
		'(' expression ')'  {$$ =creation_noeud(yylineno,"expression", none, none,none,  1,$2);}
	|	expression binary_op expression %prec OP 
	|	MOINS expression {$$ =creation_noeud(yylineno,"exp_moins_expression", none, none,none,  1,$1,$2);}
	|	CONSTANTE {$$ =creation_noeud(yylineno,"exp_CONSTANTE", none, none,none,  0);}
	|	variable  {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
	|	IDENTIFICATEUR '(' liste_expressions ')' {$$ =creation_noeud(yylineno,"exp_IDENTIFICATEUR", none, none,none,  1,$3);}
;
liste_expressions :	
		liste_expressions ',' expression {$$ =creation_noeud(yylineno,"liste_expressions", none, none,none,  2,$1,$3);}
	|   expression {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
;
condition :	
		NOT '(' condition ')' { $$ =creation_noeud(yylineno,"NOT", none, none,none,  1,$3);}
	|	condition binary_rel condition %prec REL 
	|	'(' condition ')'  { $$ =creation_noeud(yylineno,"condition", none, none,none,  1,$2);}
	|	expression binary_comp expression  { $$ =creation_noeud(yylineno,"condition_comp", none, none,none,  3,$1,$2,$3);}
;
binary_op :	
		PLUS {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
	|       MOINS {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
	|	MUL {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
	|	DIV {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
	|       LSHIFT {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
	|       RSHIFT {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
	|	BAND {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
	|	BOR {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
;
binary_rel :	
		LAND {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
	|	LOR {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
;
;
;
binary_comp :	
		LT {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
	|	GT {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
	|	GEQ {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
	|	LEQ {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
	|	EQ {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
	|	NEQ {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
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
		int res = yyparse();  
		if (res != 0) exit(1);
		printlist(listprogramme);

} 



