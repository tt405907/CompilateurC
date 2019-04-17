%{
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
//#include "yacc1.tab.h"


int yyerror(char* s) {
	fprintf(stderr, "%s\n", s);
}

#define STR(VAR) (#VAR)
int yylex();
FILE *yyin;
FILE *yyout;
int yylineno;
char* integer="INT";
char* floating="float";
char* none = "none";
char* assign = "=";

char* tab="   ";
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
	int name;
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
	noeud->name = 0;
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
	if(node == NULL){printf("NULL... \n");}
	else{
    printf("%s<Tree lineNo=\"%d\" nodeType=\"%s\" string=\"%s\" value=\"%s\" dataType=\"%s\">\n", 
        indent,
        node->lineNo,
        node->type_noeud,
        node->nom_expr,
        node->valeur, 
        node->dataType);
    int i;
    if (node->nbr_enfants > 0){
        printf("%s< %d Child>\n", indent,node->nbr_enfants);
        incIndent();
        for (i=0;i<node->nbr_enfants;i++){
            printNode(node->enfant[i]);
        }
        decIndent();
        printf("%s</Child>\n", indent);
    }
    printf("%s</Tree>\n", indent);
}}



void printnodeDOT(struct Arbre* node) {
	if (node == NULL) return;
	if (node->name != 0){ printf("%d %s\n", node->name, node->type_noeud);}
	
	for (int i=0;i<node->nbr_enfants;i++) {
		printnodeDOT(node->enfant[i]);
		if(node->enfant[i]->name != 0) printf("%d -> %d\n", node->name, node->enfant[i]->name);
		printf("%d -> %d\n", node->name, node->enfant[i]->name);
	}
}

void printlistDOT(struct list_f *list) {
	if (list == NULL) return;
	printnodeDOT(list->val);
	printlistDOT(list->next);
}

void printlist(struct list_f *list) {
	if (list == NULL) return;
	printNode(list->val);
	printlist(list->next);
}

%}
%error-verbose;

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
%type<ast> liste_declarations GEQ LEQ EQ NEQ NOT EXTERN BREAK RETURN PLUS MUL DIV LSHIFT RSHIFT BAND BOR LAND LOR LT GT  MOINS CONSTANTE declaration fonction liste_declarateurs declarateur liste_parms parm liste_instructions instruction iteration selection saut affectation bloc appel variable condition expression liste_expressions binary_rel binary_comp binary_op
%type<str> type IDENTIFICATEUR
%type<list> liste_fonctions

%start programme
%%
programme :	
		liste_declarations liste_fonctions {listprogramme = $2; }
;
liste_declarations :	
		liste_declarations declaration
	|	{$$=NULL;}
;
liste_fonctions :	
		liste_fonctions fonction {$$ = cons($2, $1); }
|      fonction {$$ = cons($1, NULL);}
;
declaration :	
		type liste_declarateurs ';' {$$=creation_noeud(yylineno , "declaration",none, none, none, 1, $2); }
;
liste_declarateurs :	
		liste_declarateurs ',' declarateur {$$=creation_noeud(yylineno, "liste_declarateurs" ,none, none, none,  2, $1, $3); }
	|	declarateur {$$=$1;}
;
declarateur	:	
		IDENTIFICATEUR 
	|	declarateur '[' CONSTANTE ']' {$$ = creation_noeud(yylineno, "declarateur_tab", none, none, none, 2,$1,$3);}
;
fonction :	
		type IDENTIFICATEUR '(' liste_parms ')' '{' liste_declarations liste_instructions '}' {
								$$=creation_noeud(yylineno,"[label=lala shape=invtrapezium color=blue]", $2, none, $1,  3,$4,$7,$8);$$->name = nextname();}
	|	EXTERN type IDENTIFICATEUR '(' liste_parms ')' ';' {$$ = NULL; }
;
type :	
		VOID {$$="VOID";}
	|	INT {$$="INT";}
;
liste_parms :	
		liste_parms ',' parm {$$ = creation_noeud(yylineno,"liste_parms", none, none, "integer",  2, $1,$3);}
	|   parm {$$=$1;}	
	|	{$$=NULL;}
;
parm :	
		INT IDENTIFICATEUR {$$ = creation_noeud(yylineno,"parm", none, none, "INT",  0);}
;
liste_instructions :	
		liste_instructions instruction {$$ = creation_noeud(yylineno,"liste_instructions", none, none, "intermediate node",  2, $1,$2);}
	|   { $$ = NULL; }
;
instruction :	
		iteration {$$ =$1;}
	|	selection {$$ =$1;}
	|	saut {$$ =$1;}
	|	affectation ';' {$$ = $1;}
	|	bloc {$$ = $1;}
	|	appel {$$ =$1;}
;
iteration :	
		FOR '(' affectation ';' condition ';' affectation ')' instruction {$$ =creation_noeud(yylineno,"[label=\"FOR\"]", none, none, "INT",  4, $3,$5,$7,$9);$$->name = nextname();}
	|	WHILE '(' condition ')' instruction {$$ =creation_noeud(yylineno,"[label=\"WHILE\"]", none, none, none,  2, $3, $5);$$->name = nextname();}
;
selection :	
		IF '(' condition ')' instruction %prec THEN {$$ =creation_noeud(yylineno,"[label=\"IF\" shape=diamond]", none, none,none,  2, $3,$5);$$->name = nextname();}
	|	IF '(' condition ')' instruction ELSE instruction {$$ =creation_noeud(yylineno,"[label=\"IF\" shape=diamond]", none, none, none,  3, $3,$5,$7);$$->name = nextname();}
	|	SWITCH '(' expression ')' instruction {$$ =creation_noeud(yylineno,"SWITCH", none, none, none,  2, $3,$5);$$->name = nextname();}
	|	CASE CONSTANTE ':' instruction {$$ =creation_noeud(yylineno,"CASE", "CONSTANTE", none, none,  1, $4);$$->name = nextname();}
	|	DEFAULT ':' instruction {$$ =creation_noeud(yylineno,"DEFAULT", none, none, none,  1, $3);$$->name = nextname();}
;
saut :	
		BREAK ';' {$$ =creation_noeud(yylineno,"[label=\"BREAK\" shape=box]", "break", none,none,  0);$$->name = nextname();}
	|	RETURN ';'  {$$ =creation_noeud(yylineno,"[label=\"RETURN\" shape=trapezium color=blue]" , "return", none,none,  0);$$->name = nextname();}
	|	RETURN expression ';' {$$ =creation_noeud(yylineno,"[label=\"RETURN\" shape=trapezium color=blue]", none, none,none,  1, $2);$$->name = nextname();}
;
affectation :	
		variable '=' expression {$$ =creation_noeud(yylineno,"affectation", $1->nom_expr, none,none,  1 ,$3);}
;
bloc :	
		'{' liste_declarations liste_instructions '}' {$$ =creation_noeud(yylineno,"bloc", none, none,none,  2,$2 ,$3);$$->name = nextname();}
;
appel :	
		IDENTIFICATEUR '(' liste_expressions ')' ';'  {$$ =creation_noeud(yylineno,"appel", none, none,none,  1,$3);$$->name = nextname();}
;
variable :	
		IDENTIFICATEUR {$$ =creation_noeud(yylineno,"variable", $1, none,"var",  0);$$->name = nextname();}
	|	variable '[' expression ']' {$$ =creation_noeud(yylineno,"variable_exp", none, none,none,  2,$1,$3);$$->name = nextname();}
;
expression :	
		'(' expression ')'  {$$ =creation_noeud(yylineno,"expression", none, none,none,  1,$2);$$->name = nextname();}
	|	expression binary_op expression %prec OP {$$ = creation_noeud(yylineno,"operation",none,none,none,3,$1,$2,$3);$$->name = nextname(); }
	|	MOINS expression {$$ =creation_noeud(yylineno,"exp_moins_expression", none, none,none,  1,$1,$2);$$->name = nextname();}
	|	CONSTANTE {char* b = NULL;asprintf(&b, "%s", $1);  $$ =creation_noeud(yylineno,"exp_CONSTANTE",none,b,none,  0);$$->name = nextname();}
	|	variable  {$$ = $1;}
	|	IDENTIFICATEUR '(' liste_expressions ')' {$$ =creation_noeud(yylineno,"exp_IDENTIFICATEUR", none, none,none,  1,$3);$$->name = nextname();}
;
liste_expressions :	
		liste_expressions ',' expression {$$ =creation_noeud(yylineno,"liste_expressions", none, none,none,  2,$1,$3);}
	|   expression {$$ =creation_noeud(yylineno,"exp_variable", none, none,none,  1,$1);}
;
condition :	
		NOT '(' condition ')' { $$ =creation_noeud(yylineno,"NOT", none, none,none,  1,$3);$$->name = nextname();}
	|	condition binary_rel condition %prec REL 
	|	'(' condition ')'  { $$ = $2;}
	|	expression binary_comp expression  { $$ =creation_noeud(yylineno,"condition_comp", none, none,none,  3,$1,$2,$3);}
;
binary_op :	
		PLUS {$$ =creation_noeud(yylineno,"[label= \"+\"]", "+", none,none,  0);$$->name = nextname();}
	|       MOINS {$$ =creation_noeud(yylineno,"[label= \"-\"]", "-", none,none,  0);$$->name = nextname();}
	|	MUL {$$ =creation_noeud(yylineno,"[label= \"*\"]", "*", none,none,  0);$$->name = nextname();}
	|	DIV {$$ =creation_noeud(yylineno,"[label= \"/\"]", "/", none,none,  0);$$->name = nextname();}
	|       LSHIFT {$$ =creation_noeud(yylineno,"[label= \"<<\"]", "<<", none,none,  0);$$->name = nextname();}
	|       RSHIFT {$$ =creation_noeud(yylineno,"[label= \">>\"]", ">>", none,none,  0);$$->name = nextname();}
	|	BAND {$$ =creation_noeud(yylineno,"[label= \"&\"]", "&", none,none,  0);$$->name = nextname();}
	|	BOR {$$ =creation_noeud(yylineno,"[label= \"|\"]", "|", none,none,  0);$$->name = nextname();}
;
binary_rel :	
		LAND {$$ =creation_noeud(yylineno,"[label= \"&&\"]", "&&", none,none, 0);$$->name = nextname();}
	|	LOR {$$ =creation_noeud(yylineno,"[label= \"||\"]", "||", none,none, 0);$$->name = nextname();}
;
;
;
binary_comp :	
		LT {$$ =creation_noeud(yylineno,"[label= \"<\"]", "<", none,none,0);}
	|	GT {$$ =creation_noeud(yylineno,"[label= \">\"]", ">", none,none, 0);}
	|	GEQ {$$ =creation_noeud(yylineno,"[label= \">=\"]", ">=", none,none,0);}
	|	LEQ {$$ =creation_noeud(yylineno,"[label= \"<=\"]", "<=", none,none, 0);}
	|	EQ {$$ =creation_noeud(yylineno,"[label= \"==\"]", "==", none,none, 0);}
	|	NEQ {$$ =creation_noeud(yylineno,"[label= \"!=\"]", "!=", none,none, 0);}
;
%%


int name = 1;

int nextname() {
	return name++;
}
int yywrap() {}
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
		printlistDOT(listprogramme);

} 



