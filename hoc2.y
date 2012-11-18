%{
#include <stdio.h>
#include <ctype.h>
#include <signal.h>
#include <setjmp.h>
#include "hoc.h"

double mem[26];
%}
%union {
	double val;
	int index;
}
%token <val>	NUMBER
%token <index>	VAR
%type  <val>	expr
%right	'='
%left	'+' '-'
%left	'*' '/'
%left   UNARYMINUS
%%
list:
|	list '\n'
|	list expr '\n'
	{
		printf("%.8g\n", $2);
	}
|	list error '\n'
	{
		yyerrok;
	}
expr:
	NUMBER
|	VAR
	{
		$$ = mem[$1];
	}
|	VAR '=' expr
	{
		$$ = mem[$1] = $3;
	}
|	'-' expr
	{
		$$ = mem['p'-'a'] = -$2;
	}
|	expr '+' expr
	{
		$$ = mem['p'-'a'] = $1 + $3;
	}
|	expr '-' expr
	{
		$$ = mem['p'-'a'] = $1 - $3;
	}
|	expr '*' expr
	{
		$$ = mem['p'-'a'] = $1 * $3;
	}
|	expr '/' expr
	{
		if($3 == 0) {
			execerror("division by zero", "");
		}
		$$ = mem['p'-'a'] = $1 / $3;
	}
|	'(' expr ')'
	{
		$$ = mem['p'-'a'] = $2;
	}
%%
char *progname;
int  lineno = 1;

jmp_buf begin;

int
main(int argc, char **argv)
{
	progname = argv[0];
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
	if(islower(c)) {
		yylval.index = c - 'a';
		return VAR;
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
