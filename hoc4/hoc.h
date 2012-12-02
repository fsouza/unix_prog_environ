#define nil 0

struct Symbol
{
	char *name;
	short type;
	union
	{
		double val;
		double (*ptr)();
	} u;
	struct Symbol *next;
};

union Datum
{
	double val;
	struct Symbol *sym;
};

typedef struct Symbol Symbol;
typedef union Datum Datum;

Symbol *install(char *s, int t, double d);
Symbol *lookup(char *s);

extern Datum pop();

typedef int (*Inst)();

#define STOP (Inst)0

extern Inst prog[];
extern void eval(), add(), sub(), mul(), division(), negate(), power();
extern void assign(), bltin(), varpush(), constpush(), print();

void init();
void initcode();
void execute(Inst *p);
void *emalloc(unsigned int n);
void yyerror(char *s, ...);
void warning(char *s, char *t);
void execerror(char *s, char *t);
void fpecatch();
int yylex();
