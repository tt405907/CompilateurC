%{
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
//#include "yacc1.tab.h"
extern int nextname();
int yyerror(char* s) {
	fprintf(stderr, "%s\n", s);
}
#define STR(VAR) (#VAR)
int yylex();
FILE *yyin;
FILE *yyout;
FILE *outfile;
int yylineno;
char* integer="INT";
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
    printf("%s<Tree lineNo=\"%d\" nodeType=\"%s\" string=\"%s\" value=\"%s\" dataType=\"%s\" name= %d>\n", 
        indent,
        node->lineNo,
        node->type_noeud,
        node->nom_expr,
        node->valeur, 
        node->dataType,node->name);
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
void printnodeDOT(struct Arbre* node,int parentName) {
	if (node == NULL){return;}
	else{
	if (node->name != 0){ //printf("%d %s\n", node->name, node->type_noeud);
							 fprintf(outfile,"%d %s\n", node->name, node->type_noeud);
							}
	if (node->nbr_enfants > 0){
	for (int i=0;i<node->nbr_enfants;i++) {
		struct Arbre* fils = node->enfant[i];
		if(fils != NULL){
			if(node->name != 0 ){
				printnodeDOT(fils,node->name);
			}
			else{
				printnodeDOT(fils,parentName);
			}
			
		}
		if(fils->name != 0 && node->name != 0){
			//printf("%d -> %d \n", node->name, fils->name);
			fprintf(outfile,"%d -> %d \n", node->name, fils->name);
		}
		else if (fils->name != 0 && node->name == 0){
			//printf("%d -> %d \n",  parentName,fils->name);
			fprintf(outfile,"%d -> %d \n",  parentName,fils->name);
		}
	}}}}

void printlistDOT(struct list_f *list) {
	if (list == NULL) return;
	printnodeDOT(list->val,0);
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
%type<ast> variable_tab selection_switch  liste_declarations GEQ LEQ EQ NEQ NOT EXTERN BREAK RETURN PLUS MUL DIV LSHIFT RSHIFT BAND BOR LAND LOR LT GT  MOINS CONSTANTE declaration fonction liste_declarateurs declarateur liste_parms parm liste_instructions instruction iteration selection saut affectation bloc appel variable condition expression liste_expressions binary_rel binary_comp binary_op
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
		type IDENTIFICATEUR '(' liste_parms ')' bloc {
			char* buffer = NULL;
asprintf(&buffer, "[label=\"%s, %s\" shape=invtrapezium color=blue]", $2, $1);
								$$=creation_noeud(yylineno,buffer, $2, none, $1,  1,$6);$$->name = nextname();}
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
		liste_instructions instruction {int nb = $1->nbr_enfants;$1->nbr_enfants= $1->nbr_enfants+1 ;$1->enfant[nb] = $2;$$=$1;}
	|   instruction { $$ =creation_noeud(yylineno,"listes interne", none, none, none,  1,$1);}

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
	|	SWITCH '(' expression ')' '{' selection_switch '}'  {$$ =creation_noeud(yylineno,"[label=\"SWITCH\"]", none, none, none,  1,$6);$$->name = nextname();}
	//|	CASE CONSTANTE ':' liste_instructions {$$ =creation_noeud(yylineno,"[label=\"CASE\"]", none, none,none,  1, $4);$$->name = nextname();}
	//|	DEFAULT ':' liste_instructions {$$ =creation_noeud(yylineno,"[label=\"DEFAULT\"]", none, none, none,  1, $3);$$->name = nextname();}
;
selection_switch	:
		selection_switch CASE CONSTANTE ':' liste_instructions {
			char* buffer = NULL;
			asprintf(&buffer, "[label=\"CASE %s\"]", $3 );
			struct Arbre *tree =creation_noeud(yylineno,buffer, none, none,none,  1, $5);tree->name = nextname();
			int nb = $1->nbr_enfants;$1->nbr_enfants= $1->nbr_enfants+1 ;$1->enfant[nb] =tree;$$=$1;
		}
	|	selection_switch DEFAULT ':' liste_instructions {
			struct Arbre *tree  = creation_noeud(yylineno,"[label=\"DEFAULT\"]", none, none, none,  1, $4);tree->name = nextname();
			int nb = $$->nbr_enfants;$$->nbr_enfants= $$->nbr_enfants+1 ;$$->enfant[nb] =tree;}
	|  			{ $$ =creation_noeud(yylineno,"listes interne", none, none, none,  0); }

;

saut :	
		BREAK ';' {$$ =creation_noeud(yylineno,"[label=\"BREAK\" shape=box]", "break", none,none,  0);$$->name = nextname();}
	|	RETURN ';'  {$$ =creation_noeud(yylineno,"[label=\"RETURN\" shape=trapezium color=blue]" , "return", none,none,  0);$$->name = nextname();}
	|	RETURN expression ';' {$$ =creation_noeud(yylineno,"[label=\"RETURN\" shape=trapezium color=blue]", none, none,none,  1, $2);$$->name = nextname();}
;
affectation :	
		variable '=' expression {$$ =creation_noeud(yylineno,"[label=\":=\"]", $1->nom_expr, none,none,  2,$1 ,$3);$$->name =nextname();}
;
bloc :	
		'{' liste_declarations liste_instructions '}' {$$ =creation_noeud(yylineno,"[label=\"BLOC\"]", none, none,none,  1 ,$3);$$->name = nextname();}
;
appel :	
		IDENTIFICATEUR '(' liste_expressions ')' ';'  {char* buffer = NULL;
asprintf(&buffer, "[label=\"%s\" shape=septagon]", $1);$$ =creation_noeud(yylineno,buffer, none, none,none,  1,$3);$$->name = nextname();}
;
variable :	
		IDENTIFICATEUR {char* buffer = NULL;
						asprintf(&buffer, "[label=\"%s\"]", $1);
						$$ =creation_noeud(yylineno,buffer, $1, none,"var",  0);
						$$->name = nextname();}
	|	variable_tab '[' expression ']' {$$ =creation_noeud(yylineno,"[label=\"TAB\"]", none, none,none, 0);$$->name = nextname();
										
										int nb = $$->nbr_enfants;$$->nbr_enfants= $$->nbr_enfants+1 ;$$->enfant[nb] =$1;
										struct Arbre *node = $1;
										for (int i=0;i<node->nbr_enfants;i++) {
											struct Arbre* fils = node->enfant[i];
											int nb = $$->nbr_enfants;$$->nbr_enfants= $$->nbr_enfants+1 ;$$->enfant[nb] =fils;
											
										}
										$1->nbr_enfants=0;
										}
;
variable_tab :
	|	IDENTIFICATEUR {char* buffer = NULL;
						asprintf(&buffer, "[label=\"%s\"]", $1);
						$$ =creation_noeud(yylineno,buffer, $1, none,"var",  0);
						$$->name = nextname();}
	|	variable_tab '[' expression ']' {
										int nb = $$->nbr_enfants;$$->nbr_enfants= $$->nbr_enfants+1 ;$$->enfant[nb] =$3;$$=$1;}
;




expression :	
		'(' expression ')'  {$$ = $2;}
	|	expression binary_op expression %prec OP {int nb = $2->nbr_enfants;
											$2->nbr_enfants= $2->nbr_enfants+2 ;
											$2->enfant[nb] = $1;
											$2->enfant[nb+1] = $3;
											$$=$2; 
											}
	|	MOINS expression {$$ =creation_noeud(yylineno,"[label= \"-\"]", none, none,none,  1,$2);$$->name = nextname();}
	|	CONSTANTE {char* b = NULL;asprintf(&b, "[label=\"%s\"]", $1);  $$ =creation_noeud(yylineno,b,none,b,none,  0);$$->name = nextname();}
	|	variable  {$$ = $1;}
	|	IDENTIFICATEUR '(' liste_expressions ')' {	char* buffer = NULL;
													asprintf(&buffer, "[label=\"%s\" shape=septagon]", $1);
													$$ =creation_noeud(yylineno,buffer, none, none,none,  1,$3);$$->name = nextname();}
;
liste_expressions :	
		liste_expressions ',' expression {int nb = $3->nbr_enfants;$3->nbr_enfants= $3->nbr_enfants+1 ;$3->enfant[nb] = $1;$$=$3; }
	|   expression {$$ = $1;}
	|  { $$ = NULL; }
;
condition :	
		NOT '(' condition ')' { $$ =creation_noeud(yylineno,"NOT", none, none,none,  1,$3);$$->name = nextname();}
	|	condition binary_rel condition %prec REL 
	|	'(' condition ')'  { $$ = $2;}
	|	expression binary_comp expression  {int nb = $2->nbr_enfants;
											$2->nbr_enfants= $2->nbr_enfants+2 ;
											$2->enfant[nb] = $1;
											$2->enfant[nb+1] = $3;
											$$=$2; 
											}
;
binary_op :	
		PLUS {$$ = creation_noeud(yylineno,"[label= \"+\"]", "+", none,none,  0); $$->name = nextname();}
	|   MOINS {$$ =creation_noeud(yylineno,"[label= \"-\"]", "-", none,none,  0);$$->name = nextname();}
	|	MUL {$$ =creation_noeud(yylineno,"[label= \"*\"]", "*", none,none,  0);$$->name = nextname();}
	|	DIV {$$ =creation_noeud(yylineno,"[label= \"/\"]", "/", none,none,  0);$$->name = nextname();}
	|   LSHIFT {$$ =creation_noeud(yylineno,"[label= \"<<\"]", "<<", none,none,  0);$$->name = nextname();}
	|   RSHIFT {$$ =creation_noeud(yylineno,"[label= \">>\"]", ">>", none,none,  0);$$->name = nextname();}
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
		LT {$$ =creation_noeud(yylineno,"[label= \"<\"]", "<", none,none,0);$$->name = nextname();}
	|	GT {$$ =creation_noeud(yylineno,"[label= \">\"]", ">", none,none, 0);$$->name = nextname();}
	|	GEQ {$$ =creation_noeud(yylineno,"[label= \">=\"]", ">=", none,none,0);$$->name = nextname();}
	|	LEQ {$$ =creation_noeud(yylineno,"[label= \"<=\"]", "<=", none,none, 0);$$->name = nextname();}
	|	EQ {$$ =creation_noeud(yylineno,"[label= \"==\"]", "==", none,none, 0);$$->name = nextname();}
	|	NEQ {$$ =creation_noeud(yylineno,"[label= \"!=\"]", "!=", none,none, 0);$$->name = nextname();}
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
		//printlist(listprogramme);
		outfile = fopen("file.dot", "w");
		if (outfile == NULL)
			{
				printf("Error opening file!\n");
				exit(1);
			}
		fprintf(outfile,"digraph G { \n");
		printlistDOT(listprogramme);
		fprintf(outfile,"}");
		fclose(outfile);
}


