// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab

static	Datum	stack[$];	/* the stack */

Inst		prog[*];	/* the machine */
shortint	progp;		/* next free spot for code generation */
shortint	pc;		/* program counter during execution */

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

function void bltin();		/* evaluate built-in on top of stack */
	Datum d;
	d = pop();
	d.val = exec_bltin(prog[pc++].sym, d.val) ;
	push(d);
endfunction

function void eval();		/* evaluate variable on stack */
	Datum d;
	d = pop();
	if (d.sym.type_ == `UNDEF)
		$error($psprintf("undefined variable %s", d.sym.name));
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
		$error("division by zero");
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
		$error($psprintf("assignment to non-variable %s", d1.sym.name));
	d1.sym.val = d2.val;
	d1.sym.type_ = `VAR;
        symlist[d1.sym.name] = d1.sym;
	push(d2);
endfunction

function void print();		/* pop top value from stack, print it */
	Datum d;
	d = pop();
	$display("\t%0f\n", d.val);
endfunction

function shortint icode(string f);	/* install one instruction or operand */
	shortint oprogp = progp;
	prog[progp++].ins = f;
	return oprogp;
endfunction

function shortint ocode(Symbol s);	/* install one operand */
	shortint oprogp = progp;
	prog[progp++].sym = s;
	return oprogp;
endfunction

function void execute(shortint p);	/* run the machine */
	for (pc = p; prog[pc].ins != "STOP";) begin
		case(prog[pc++].ins)
			"print" : print();	/* pop top value from stack, print it */
			"constpush" : constpush();	/* push constant onto stack */
			"varpush" : varpush();	/* push variable onto stack */
			"bltin" : bltin();	/* evaluate built-in on top of stack */
			"eval" : eval();	/* evaluate variable on stack */
			"add" : add();		/* add top two elems on stack */
			"sub" : sub();		/* subtract top of stack from next */
			"mul" : mul();
			"div" : div();
			"negate" : negate();
			"power" : power();
			"assign" : assign_();	/* assign top value to next value */
		endcase
	end
endfunction
