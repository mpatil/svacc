// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab

`define ICODE 0
`define OCODE 1
`define NCODE 2
`define PCODE 3

static	Datum	stack[$];	/* the stack */

Inst		prog[*];	/* the machine */
shortint	progp;		/* next free spot for code generation */
static shortint	pc;		/* program counter during execution */
shortint	progbase = 0; /* start of current subprogram */
int			returning;	/* 1 if return stmt seen */

typedef struct {	/* proc/func call stack frame */
	Symbol		sp;		/* symbol table entry */
	shortint	retpc;	/* where to resume after return */
	shortint	argn;	/* n-th argument on stack */
	shortint	nargs;	/* number of arguments */
} Frame;

Frame		frame[*];
shortint	fp;		/* frame pointer */

function void initcode();	/* initialize for code generation */
	progp = progbase;
	stack = {};
	fp = 0;
	returning = 0;
endfunction

function void dump_prog();
	int i;

	/* if ( `DEBUG == 0 ) return; */
	if ( `PRINT_MACHINE == 0 ) return;

	for (i = 0; i < progp; i++) begin
		$write(" %6d ",i);
		case ( prog[i].type_ )
			`ICODE: $write("%12s %12s"," Inst: ", prog[i].ins);
			`OCODE: begin 
						$write("%12s %12s ", " Symbol: ", prog[i].sym.name);
						case(prog[i].sym.type_)
							`VAR: if (prog[i].sym.sval != "") $write (" %12s %12f", prog[i].sym.sval, prog[i].sym.val); else $write (" %20f ", prog[i].sym.val); 
							`UNDEF: $write(" %12s ", "Undefined"); 
							default: if (prog[i].sym.sval != "") $write (" %12s", prog[i].sym.sval); else $write (" %20f ", prog[i].sym.val); 
						endcase
						$write(" %12d ", prog[i].sym.defn);
					end
			`NCODE: $write("%12s %12d", " Nargs: ", prog[i].nargs);
			`PCODE: $write("%12s %12d", " Ptr: ", prog[i].ptr);
		endcase
		$display();
	end
	$display("PROGBASE: %12d", progbase);
endfunction

function void trace_prog();   /* list each inst as executed */
		$write(" %6d   %0d ", pc, prog[pc].type_);
		case ( prog[pc].type_ )
			`ICODE: $display(" %s","code");
			`OCODE: $display(" %s","code");
			`NCODE: $display(" %s","code");
			`PCODE: $display(" %s","code");
		endcase
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
		if (returning)
			break;
		execute(savepc + 2);
		d = pop();
	end
	if (!returning)
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
	if (!returning)
		pc = prog[savepc + 2].ptr;	 /* next stmt */
endfunction

function void define(Symbol sp);	/* put func/proc in symbol table */
	sp.defn = progbase;	/* start of code */
	progbase = progp;	/* next code starts here */
endfunction

function void call(); 		/* call a function */
	Symbol sp = prog[pc].sym; /* symbol table entry */
						      /* for function */
    fp++;
	frame[fp].sp = sp;
	frame[fp].nargs = prog[pc + 1].nargs;
	frame[fp].retpc = pc + 2;
	frame[fp].argn = stack.size() - 2;	/* last argument, pointer from bottom of stack */
	execute(sp.defn);
	returning = 0;
endfunction

function void ret(); 		/* common return from func or proc */
	int i;
	for (i = 0; i < frame[fp].nargs; i++)
		pop();	/* pop arguments */
	pc = frame[fp].retpc;
	--fp;
	returning = 1;
endfunction

function void funcret(); 	/* return from a function */
	Datum d;
	if (frame[fp].sp.type_ == `PROCEDURE)
		execerror(frame[fp].sp.name, "(proc) returns value");
	d = pop();	/* preserve function return value */
	ret();
	push(d);
endfunction

function void procret(); 	/* return from a procedure */
	if (frame[fp].sp.type_ == `FUNCTION)
		execerror(frame[fp].sp.name,
			"(func) returns no value");
	ret();
endfunction

function shortint getarg(); 	/* return pointer to argument */
	int nargs = prog[pc++].nargs;
	if (nargs > frame[fp].nargs)
	    execerror("not enough arguments", "");
	return stack.size() - (frame[fp].argn - frame[fp].nargs + nargs + 1) - 1;
endfunction

function void arg(); 	/* push argument onto stack */
	Datum d;
	d.val = stack[getarg()].val;
	push(d);
endfunction

function void argassign(); 	/* store top of stack in argument */
	Datum d;
	d = pop();
	push(d);	/* leave value on stack */
	stack[getarg()].val = d.val;
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

function void exch();         /* exchange two top stack elements */
        Datum d1, d2;

        d1 = pop();
        d2 = pop();
        push(d1);
        push(d2);
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
	$write("\t%0f", d.val);
endfunction

function void prexpr();	/* print numeric value */
	Datum d;
	d = pop();
	$write("%0f", d.val);
endfunction

function void prstr();		/* print string value */ 
	string val = prog[pc++].sym.sval;
	$write("%s", val);
endfunction

function void varread();	/* read into variable */
	Datum d;
	Symbol var_ = prog[pc++].sym; /* symbol table entry */

	case($fscanf(file_din, "%f", var_.val))
		`EOF: begin
			d.val = 0.0;
			var_.val = 0.0;
		end
		0: execerror("non-number read into", var_.name);
		default: d.val = 1.0;
	endcase

	var_.type_ = `VAR;
	push(d);
endfunction

function shortint icode(string f);	/* install one instruction */
	shortint oprogp = progp;
	prog[progp].ptr = progp;
	prog[progp].type_ = `ICODE;
	prog[progp++].ins = f;
	return oprogp;
endfunction

function shortint ocode(Symbol s);	/* install one operand */
	shortint oprogp = progp;
	prog[progp].ptr = progp;
	prog[progp].type_ = `OCODE;
	prog[progp++].sym = s;
	return oprogp;
endfunction

function void pcode(shortint l, Inst r);	/* install one code pointer */
	prog[l].type_ = `PCODE;
	prog[l].ptr = r.ptr;
endfunction

function shortint ncode(int n);	/* install one operand */
	shortint oprogp = progp;
	prog[progp].type_ = `NCODE;
	prog[progp].ptr = progp;
	prog[progp++].nargs = n;
	return oprogp;
endfunction

function void execute(shortint p);	/* run the machine */
	for (pc = p; prog[pc].ins != "STOP" && !returning;) begin
		string cmd = prog[pc++].ins;
		case(cmd)
			"print"     : print();	/* pop top value from stack, print it */
			"constpush" : constpush();	/* push constant onto stack */
			"varpush"   : varpush();	/* push variable onto stack */
			"whilecode" : whilecode();
			"ifcode"    : ifcode();
			"call"      : call();
			"funcret"   : funcret();
			"procret"   : procret();
			"arg"       : arg();
			"argassign" : argassign();
			"bltin"     : bltin();	/* evaluate built-in on top of stack */
			"eval"      : eval();	/* evaluate variable on stack */
			"add"       : add();		/* add top two elems on stack */
			"sub"       : sub();		/* subtract top of stack from next */
			"mul"       : mul();
			"div"       : div();
			"negate"    : negate();
			"exch"      : exch();
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
			"prstr"     : prstr();
			"varread"   : varread();
			default		: execerror("unknown instruction", cmd);
		endcase
	end
endfunction

