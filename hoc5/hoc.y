%{
#include <stdio.h>
#include <ctype.h>
#include <signal.h>
#include <setjmp.h>
#include "hoc.h"
#define code2(c1, c2)     code(c1); code(c2)
#define code3(c1, c2, c3) code(c1); code(c2); code(c3)
%}
%union {
	Symbol *sym;
	Inst   *inst;
}
%token <sym>	NUMBER PRINT VAR BLTIN UNDEF WHILE IF ELSE
%type  <val>	stmt asgn expr stmtlist cond while if end
%right	'='
%left   OR
%left   AND
%left   GT GE LT LE EQ NE
%left	'+' '-'
%left	'*' '/'
%left   UNARYMINUS NOT
%right  '^'
%%
list:
|	list '\n'
|   list asgn '\n'
	{
		code2(pop, STOP); return 1;
	}
|	list stmt '\n'
	{
		code(STOP); return 1;
	}
|	list expr '\n'
	{
		code2(print, STOP); return 1;
	}
|	list error '\n'
	{
		yyerrok;
	}
asgn:
	VAR '=' expr
	{
		code3(varpush, (Inst)$1, assign);
	}
stmt:
	expr
	{
		code(pop);
	}
|	PRINT expr
	{
		code(prexpr);
		$$ = $2;
	}
|	while cond stmt end
	{
		($1)[1] = (Inst)$3;
		($1)[2] = (Inst)$4;
	}
|	if cond stmt end
	{
		($1)[1] = (Inst)$3;
		($1)[2] = (Inst)$4;
	}
|	if cond stmt end ELSE stmt end
	{
		($1)[1] = (Inst)$3;
		($1)[2] = (Inst)$6;
		($1)[3] = (Inst)$7;
	}
|	'{' stmtlist '}'
	{
		$$ = $2;
	}
cond:
	'(' expr ')'
	{
		code(STOP);
		$$ = $2;
	}
while:
	WHILE
	{
		$$ = code3(whilecode, STOP, STOP);
	}
if:
	IF
	{
		$$ = code(ifcode);
		code3(STOP, STOP, STOP);
	}
end:
	{
		code(STOP);
		$$ = progp;
	}
stmtlist:
	{
		$$ = progp;
	}
|	stmtlist '\n'
|	stmtlist stmt
expr:
	NUMBER
	{
		code2(constpush, (Inst)$1);
	}
|	VAR
	{
		code3(varpush, (Inst)$1, eval);
	}
|	asgn
|   BLTIN '(' expr ')'
	{
		code2(bltin, (Inst)$1->u.ptr);
	}
|	'(' expr ')'
|	expr '+' expr
	{
		code(add);
	}
|	expr '-' expr
	{
		code(sub);
	}
|	expr '*' expr
	{
		code(mul);
	}
|	expr '/' expr
	{
		code(division);
	}
|	expr '^' expr
	{
		code(power);
	}
|	'-' expr %prec UNARYMINUS
	{
		code(negate);
	}
|	expr GT expr
	{
		code(gt);
	}
|	expr GE expr
	{
		code(ge);
	}
|	expr LT expr
	{
		code(lt);
	}
|	expr LE expr
	{
		code(le);
	}
|	expr NE expr
	{
		code(ne);
	}
|	expr AND expr
	{
		code(and);
	}
|	expr OR expr
	{
		code(or);
	}
|	NOT expr
	{
		$$ = $2;
		code(not);
	}
%%
char *progname;
int  lineno = 1;

jmp_buf begin;

int
main(int argc, char **argv)
{
	if(argc > 0) {
		progname = argv[0];
	}
	init();
	setjmp(begin);
	signal(SIGFPE, fpecatch);
	for(initcode(); yyparse(); initcode()) {
		execute(prog);
	}
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
		double d;
		ungetc(c, stdin);
		scanf("%lf", &d);
		yylval.sym = install("", NUMBER, d);
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
	switch(c) {
	case '>':
		return follow('=', GE, GT);
	case '<':
		return follow('=', LE, LT);
	case '=':
		return follow('=', EQ, '=');
	case '!':
		return follow('=', NE, NOT);
	case '|':
		return follow('|', OR, '|');
	case '&':
		return follow('&', AND, '&');
	case '\n':
		lineno++;
		return '\n';
	}
	return c;
}

int
follow(int expect, int ifyes, int ifno)
{
	int c = getchar();
	if(c == expect) {
		return ifyes;
	}
	ungetc(c, stdin);
	return ifno;
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
