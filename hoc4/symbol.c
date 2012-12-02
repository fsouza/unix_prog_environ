#include <stdlib.h>
#include <string.h>
#include "hoc.h"
#include "y.tab.h"

static Symbol *symlist = nil;

Symbol *
lookup(char *s)
{
	Symbol *sp;
	for(sp = symlist; sp != nil; sp = sp->next) {
		if(strcmp(sp->name, s) == 0) {
			return sp;
		}
	}
	return nil;
}

Symbol *
install(char *s, int t, double d)
{
	Symbol *sp = (Symbol *)emalloc(sizeof(Symbol));
	sp->name = (char *)emalloc(strlen(s)+1);
	strcpy(sp->name, s);
	sp->type = t;
	sp->u.val = d;
	sp->next = symlist;
	symlist = sp;
	return sp;
}

void *
emalloc(unsigned int n)
{
	void *p;
	p = malloc(n);
	if(p == nil) {
		execerror("out of memory", nil);
	}
	return p;
}
