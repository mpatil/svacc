// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab

static	Datum	stack[$];	/* the stack */

Inst		prog[*];	/* the machine */
shortint	progp;		/* next free spot for code generation */
static shortint	pc;		/* program counter during execution */

function void initcode();	/* initialize for code generation */
	stack = {};
	progp = 0;
endfunction

function void push(Datum d);		/* push d onto stack */
	stack.push_front(d);
endfunction

function Datum pop();	/* pop and return top elem from stack */
	return stack.pop_front();
endfunction

function void constpush();	/* push constant onto stack */
	Datum d;
	d.val = prog[pc++].sym.val;
	push(d);
endfunction

function void varpush();	/* push variable onto stack */
	Datum d;
	d.sym = prog[pc++].sym;
	push(d);
endfunction

function void whilecode();
	Datum d;
	shortint savepc = pc;	/* loop body */

	execute(savepc + 2);	/* condition */
	d = pop();
	while (d.val) begin
		execute(prog[savepc].ptr);	/* body */
		execute(savepc + 2);
		d = pop();
	end
	pc = prog[savepc + 1].ptr;  /* next statement */
endfunction

function void ifcode();
	Datum d;
	shortint savepc = pc;	/* then part */

	execute(savepc + 3);	/* condition */
	d = pop();
	if (d.val)
		execute(prog[savepc].ptr);
	else if (prog[prog[savepc + 1].ptr].ins != "STOP") /* else part? */
		execute(prog[savepc + 1].ptr);
	pc = prog[savepc + 2].ptr;	 /* next stmt */
endfunction

function void bltin();		/* evaluate built-in on top of stack */
	Datum d;
	d = pop();
	d.val = exec_bltin(prog[pc++].sym, d.val) ;
	push(d);
endfunction

function void eval();		/* evaluate variable on stack */
	Datum d;
	d = pop();
	if (d.sym.type_ != `VAR && d.sym.type_ != `UNDEF)
		execerror("attempt to evaluate non-variable", d.sym.name);
	if (d.sym.type_ == `UNDEF)
		execerror("undefined variable", d.sym.name);
	d.val = d.sym.val;
	push(d);
endfunction

function void add();		/* add top two elems on stack */
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val += d2.val;
	push(d1);
endfunction

function void sub();	/* subtract top of stack from next */
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val -= d2.val;
	push(d1);
endfunction

function void mul();
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val *= d2.val;
	push(d1);
endfunction

function void div();
	Datum d1, d2;
	d2 = pop();
	if (d2.val == 0.0)
		execerror("division by zero", "");
	d1 = pop();
	d1.val /= d2.val;
	push(d1);
endfunction

function void negate();
	Datum d;
	d = pop();
	d.val = -d.val;
	push(d);
endfunction

function void gt();
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = real'(d1.val > d2.val);
	push(d1);
endfunction

function void lt();
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = real'(d1.val < d2.val);
	push(d1);
endfunction

function void ge();
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = real'(d1.val >= d2.val);
	push(d1);
endfunction

function void le();
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = real'(d1.val <= d2.val);
	push(d1);
endfunction

function void eq();
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = real'(d1.val == d2.val);
	push(d1);
endfunction

function void ne();
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = real'(d1.val  !=  d2.val);
	push(d1);
endfunction

function void and_();
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = real'(d1.val != 0.0 && d2.val != 0.0);
	push(d1);
endfunction

function void or_();
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = real'(d1.val != 0.0 || d2.val != 0.0);
	push(d1);
endfunction

function void not_();
	Datum d;
	d = pop();
	d.val = real'(d.val == 0.0);
	push(d);
endfunction

function void power();
	Datum d1, d2;
	d2 = pop();
	d1 = pop();
	d1.val = pow(d1.val, d2.val);
	push(d1);
endfunction

function void assign_();	/* assign top value to next value */
	Datum d1, d2;
	d1 = pop();
	d2 = pop();
	if (d1.sym.type_ != `VAR && d1.sym.type_ != `UNDEF)
		execerror("assignment to non-variable", d1.sym.name);
	d1.sym.val = d2.val;
	d1.sym.type_ = `VAR;
	push(d2);
endfunction

function void print();		/* pop top value from stack, print it */
	Datum d;
	d = pop();
	$display("\t%0f", d.val);
endfunction

function void prexpr();	/* print numeric value */
	Datum d;
	d = pop();
	$display("%0f", d.val);
endfunction

function shortint icode(string f);	/* install one instruction */
	shortint oprogp = progp;
	prog[progp].ptr = progp;
	prog[progp++].ins = f;
	return oprogp;
endfunction

function shortint ocode(Symbol s);	/* install one operand */
	shortint oprogp = progp;
	prog[progp].ptr = progp;
	prog[progp++].sym = s;
	return oprogp;
endfunction

function void pcode(shortint l, Inst r);	/* install one code pointer */
	prog[l].ptr = r.ptr;
endfunction

function void execute(shortint p);	/* run the machine */
	for (pc = p; prog[pc].ins != "STOP";) begin
		case(prog[pc++].ins)
			"print"     : print();	/* pop top value from stack, print it */
			"constpush" : constpush();	/* push constant onto stack */
			"varpush"   : varpush();	/* push variable onto stack */
			"whilecode" : whilecode();
			"ifcode"    : ifcode();
			"bltin"     : bltin();	/* evaluate built-in on top of stack */
			"eval"      : eval();	/* evaluate variable on stack */
			"add"       : add();		/* add top two elems on stack */
			"sub"       : sub();		/* subtract top of stack from next */
			"mul"       : mul();
			"div"       : div();
			"negate"    : negate();
			"gt"        : gt();
			"lt"        : lt();
			"ge"        : ge();
			"le"        : le();
			"eq"        : eq();
			"ne"        : ne();
			"and"       : and_();
			"or"        : or_();
			"not"       : not_();
			"power"     : power();
			"assign"    : assign_();	/* assign top value to next value */
			"pop"		: pop();
			"prexpr"    : prexpr();
			default		: $error("unknown instruction");
		endcase
	end
endfunction

