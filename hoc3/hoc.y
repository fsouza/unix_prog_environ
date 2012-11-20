%{
#include <stdio.h>
#include <ctype.h>
#include <signal.h>
#include <setjmp.h>
#include "hoc.h"

extern double Pow();
%}
%union {
	double val;
	Symbol *sym;
}
%token <val>	NUMBER
%token <sym>	VAR BLTIN UNDEF
%type  <val>	expr asgn
%right	'='
%left	'+' '-'
%left	'*' '/'
%left   UNARYMINUS
%right  '^'
%%
list:
|	list '\n'
|   list asgn '\n'
|	list expr '\n'
	{
		printf("%.8g\n", $2);
	}
|	list error '\n'
	{
		yyerrok;
	}
asgn:
	VAR '=' expr
	{
		$$ = $1->u.val = $3;
		$1->type = VAR;
	}
expr:
	NUMBER
|	VAR
	{
		if($1->type == UNDEF) {
			execerror("undefined variable", $1->name);
		}
		$$ = $1->u.val;
	}
|	asgn
|   BLTIN '(' expr ')'
	{
		$$ = (*($1->u.ptr))($3);
	}
|	expr '+' expr
	{
		$$ = $1 + $3;
	}
|	expr '-' expr
	{
		$$ = $1 - $3;
	}
|	expr '*' expr
	{
		$$ = $1 * $3;
	}
|	expr '/' expr
	{
		if($3 == 0) {
			execerror("division by zero", "");
		}
		$$ = $1 / $3;
	}
|	expr '^' expr
	{
		$$ = Pow($1, $3);
	}
|	'(' expr ')'
	{
		$$ = $2;
	}
|	'-' expr %prec UNARYMINUS
	{
		$$ = -$2;
	}
%%
char *progname;
int  lineno = 1;

jmp_buf begin;

int
main(int argc, char **argv)
{
	progname = argv[0];
	init();
	setjmp(begin);
	signal(SIGFPE, fpecatch);
	yyparse();
	return 0;
}

int
yylex()
{
	int c;
	while((c = getchar()) == ' ' || c == '\t');
	if(c == EOF) {
		return 0;
	}
	if(c == '.' || isdigit(c)) {
		ungetc(c, stdin);
		scanf("%lf", &yylval.val);
		return NUMBER;
	}
	if(isalpha(c)) {
		Symbol *s;
		char sbuf[100], *p;
		p = sbuf;
		do {
			*p++ = c;
		} while((c=getchar()) != EOF && isalnum(c));
		ungetc(c, stdin);
		*p = '\0';
		if((s = lookup(sbuf)) == NULL) {
			s = install(sbuf, UNDEF, 0.0);
		}
		yylval.sym = s;
		return s->type == UNDEF ? VAR : s->type;
	}
	if(c == '\n') {
		lineno++;
	}
	return c;
}

void
yyerror(char *s, ...)
{
	warning(s, (char *)0);
}

void
execerror(char *s, char *t)
{
	warning(s, t);
	longjmp(begin, 0);
}

void
warning(char *s, char *t)
{
	fprintf(stderr, "%s: %s", progname, s);
	if(t) {
		fprintf(stderr, "%s", t);
	}
	fprintf(stderr, " near line %d\n", lineno);
}

void
fpecatch()
{
	execerror("floating point exception", NULL);
}
