#include <stdio.h>
#include <math.h>
#include "hoc.h"
#include "y.tab.h"

#define NSTACK 512
#define NPROG  2000

static Datum stack[NSTACK];
static Datum *stackp;

Inst prog[NPROG];
Inst *progp;
Inst *pc;

void
initcode()
{
	stackp = stack;
	progp = prog;
}

void
push(Datum d)
{
	if(stackp >= &stack[NSTACK]) {
		execerror("stack overflow", nil);
	}
	*stackp++ = d;
}

Datum
pop()
{
	if(stackp <= stack) {
		execerror("stack underflow", nil);
	}
	return *--stackp;
}

Inst *
code(Inst f)
{
	Inst *oprogp = progp;
	if(progp >= &prog[NPROG]) {
		execerror("program too big", nil);
	}
	*progp++ = f;
	return oprogp;
}

void
execute(Inst *p)
{
	for(pc = p; *pc != STOP; ) {
		(*(*pc++))();
	}
}

void
constpush()
{
	Datum d;
	d.val = ((Symbol *)*pc++)->u.val;
	push(d);
}

void
varpush()
{
	Datum d;
	d.sym = (Symbol *)(*pc++);
	push(d);
}

void
add()
{
	Datum d1, d2;
	d1 = pop();
	d2 = pop();
	d1.val += d2.val;
	push(d1);
}

void
sub()
{
	Datum d1, d2;
	d1 = pop();
	d2 = pop();
	d1.val -= d2.val;
	push(d1);
}

void
mul()
{
	Datum d1, d2;
	d1 = pop();
	d2 = pop();
	d1.val *= d2.val;
	push(d1);
}

void
division()
{
	Datum d1, d2;
	d1 = pop();
	d2 = pop();
	if(d2.val == 0) {
		execerror("zero division error", nil);
	}
	d1.val /= d2.val;
	push(d1);
}

void
negate()
{
	Datum d = pop();
	d.val *= -1;
	push(d);
}

void
power()
{
	Datum d1, d2;
	d1 = pop();
	d2 = pop();
	d1.val = pow(d1.val, d2.val);
	push(d1);
}

void
eval()
{
	Datum d = pop();
	if(d.sym->type == UNDEF) {
		execerror("undefined variable", d.sym->name);
	}
	d.val = d.sym->u.val;
	push(d);
}

void
assign()
{
	Datum d1, d2;
	d1 = pop();
	d2 = pop();
	if(d1.sym->type != VAR && d1.sym->type != UNDEF) {
		execerror("assignment to non-variable", d1.sym->name);
	}
	d1.sym->u.val = d2.val;
	d1.sym->type = VAR;
	push(d2);
}

void
print()
{
	Datum d = pop();
	printf("\t%.8g\n", d.val);
}

void
bltin()
{
	Datum d = pop();
	d.val = (*(double (*)())(*pc++))(d.val);
	push(d);
}

void
prexpr()
{
	Datum d = pop();
	printf("%.8g\n", d.val);
}

void
gt()
{
	Datum d1, d2;
	d1 = pop();
	d2 = pop();
	d1.val = (double)(d1.val > d2.val);
	push(d1);
}

void
lt()
{
	Datum d1, d2;
	d1 = pop();
	d2 = pop();
	d1.val = (double)(d1.val < d2.val);
	push(d1);
}

void
eq()
{
	Datum d1, d2;
	d1 = pop();
	d2 = pop();
	d1.val = (double)(d1.val == d2.val);
	push(d1);
}

void
ge()
{
	Datum d1, d2;
	d1 = pop();
	d2 = pop();
	d1.val = (double)(d1.val >= d2.val);
	push(d1);
}

void
le()
{
	Datum d1, d2;
	d1 = pop();
	d2 = pop();
	d1.val = (double)(d1.val <= d2.val);
	push(d1);
}

void
ne()
{
	Datum d1, d2;
	d1 = pop();
	d2 = pop();
	d1.val = (double)(d1.val != d2.val);
	push(d1);
}

void
and()
{
	Datum d1, d2;
	d1 = pop();
	d2 = pop();
	d1.val = (double)(d1.val && d2.val);
	push(d1);
}

void
or()
{
	Datum d1, d2;
	d1 = pop();
	d2 = pop();
	d1.val = (double)(d1.val || d2.val);
	push(d1);
}

void
not()
{
	Datum d = pop();
	d.val = (double)(!d.val);
	push(d);
}

void
whilecode()
{
	Datum d;
	Inst *savepc = pc;
	execute(savepc + 2);
	d = pop();
	while(d.val) {
		execute(*((Inst **)(savepc)));
		execute(savepc + 2);
		d = pop();
	}
	pc = *((Inst **)(savepc + 1));
}

void
ifcode()
{
	Datum d;
	Inst *savepc = pc;
	execute(savepc + 3);
	d = pop();
	if(d.val) {
		execute(*((Inst **)(savepc)));
	} else if(*((Inst **)(savepc + 1))) {
		execute(*((Inst **)(savepc + 1)));
	}
	pc = *((Inst **)(savepc + 2));
}
