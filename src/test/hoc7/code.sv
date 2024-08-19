// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab

`define ICODE 0
`define OCODE 1
`define NCODE 2
`define PCODE 3

class Process;
	typedef	real		Vec[];
	static Inst			prog[*];	/* the machine */
	static shortint		progp;		/* next free spot for code generation */
	static shortint		progbase = 0; /* start of current subprogram */
	static Symbol		symlist[string];  /* symbol table: linked list */
	static int			pid = 0 ;
	static bit			yydebug = 0;

	Datum				stack[$];	/* the stack */
	shortint			pc;			/* program counter during execution */
	Frame				frame[*];
	shortint			fp;			/* frame pointer */
	Vec					vecs[*];
	int					returning;	/* 1 if return stmt seen */
	int					breakout;	/* 1 if break stmt seen */

	function new(int pid = 0);
		this.pid = pid;
		pid++;
	endfunction

	task initcode();	/* initialize for code generation */
		progp = progbase;
		stack = {};
		frame.delete();
		fp = 0;
		returning = 0;
		breakout = 0;
	endtask

	task dump_stack();
		int i;
	
		/* if ( `DEBUG == 0 ) return; */
		if ( yydebug == 0 ) return;
	
		foreach (stack[i]) begin
			$write("** %6d ",i);
			if ( stack[i].sym ) begin
				$write("%12f %12s %12s ", stack[i].val, " Symbol: ", stack[i].sym.name);
				case(stack[i].sym.type_)
					`VAR: if (stack[i].sym.u.sval != "") $write (" %12s %12f", stack[i].sym.u.sval, stack[i].sym.u.val); else $write (" %20f ", stack[i].sym.u.val); 
					`UNDEF: $write(" %12s ", "Undefined"); 
					default: if (stack[i].sym.u.sval != "") $write (" %12s", stack[i].sym.u.sval); else $write (" %20f ", stack[i].sym.u.val); 
				endcase
				if(stack[i].sym.u.defn) $write(" %12d ", stack[i].sym.u.defn.code);
			end else
				$write("%12f ", stack[i].val);
			$display();
		end
	endtask
	
	task dump_prog();
		int i;
	
		if ( yydebug == 0 ) return;
	
		for (i = 0; i < progp; i++) begin
			$write("== %6d ",i);
			case ( prog[i].type_ )
				`ICODE: $write("%12s %12s"," Inst: ", prog[i].ins);
				`OCODE: begin 
							$write("%12s %12s ", " Symbol: ", prog[i].sym.name);
							case(prog[i].sym.type_)
								`VAR: if (prog[i].sym.u.sval != "") $write (" %12s %12f", prog[i].sym.u.sval, prog[i].sym.u.val); else $write (" %20f ", prog[i].sym.u.val); 
								`UNDEF: $write(" %12s ", "Undefined"); 
								default: if (prog[i].sym.u.sval != "") $write (" %12s", prog[i].sym.u.sval); else $write (" %20f ", prog[i].sym.u.val); 
							endcase
							if(prog[i].sym.u.defn) $write(" %12d ", prog[i].sym.u.defn.code);
						end
				`NCODE: $write("%12s %12d", " Nargs: ", prog[i].nargs);
				`PCODE: $write("%12s %12d", " Ptr: ", prog[i].ptr);
			endcase
			$display();
		end
		$display("PROGBASE: %12d", progbase);
	endtask
	
	task push(Datum d);		/* push d onto stack */
		#0;
		stack.push_front(d);
		if ( yydebug ) 
			$display("++++++++");
	endtask
	
	task pop(ref Datum d);	/* pop and return top elem from stack */
		if ( yydebug ) 
			$display("--------");
		d = stack.pop_front();
		#0;
	endtask
	
	task constpush();	/* push constant onto stack */
		Datum d;
	
		d.val = prog[pc++].sym.u.val;
		push(d);
	endtask
	
	task varpush();	/* push variable onto stack */
		Datum d;
	
		d.sym = prog[pc++].sym;
		push(d);
	endtask
	
	task forkcode();	/* fork { stmts }  */
		shortint savepc = pc;	
		shortint forkpc = savepc + 1;	
		shortint dpc;
		shortint i = 0;
	
		do begin
			Process p = new(i + 1);
			dpc = prog[forkpc].ptr;
	
			fork  
				automatic int epc = forkpc + 1 ;
				automatic Process q = p;
				begin
					q.execute(prog[epc].ptr);	/* fork body */
				end
			join_none
	
			forkpc = dpc; 
			i++;
		end while((dpc + 1) < prog[savepc].ptr);
	
		wait fork ; // wait for all jobs to end
	
		if (returning)
			execerror("", "Illegal return from within a fork");
		if (!returning)
			pc = prog[savepc].ptr;	/* next statement */
	endtask
	
	task waitcode();		/* # N */
		Datum d;
		pop(d);
		# (d.val);
	endtask
	
	task casecode();	/* case (n) { m: stmt ..}  */
		Datum d1;
		shortint savepc = pc;	/* first case condition expression */
		shortint cpc = prog[savepc].ptr;
		int do_def = 1;
	
		breakout = 0;
		execute(savepc + 3);	/* switch condition */
		pop(d1);
		do begin
			Datum d2;
			shortint dpc = cpc + 1;
	
			cpc = prog[cpc].ptr; 
	
			execute(prog[dpc].ptr);	/* case condition expression*/
			pop(d2);
	
			if (d1.val == d2.val) begin
				execute(pc + 1);/* case body */
				if (breakout)
					break;
				do_def = 0;
				break;
			end 
		end while((cpc + 1) < prog[savepc + 1].ptr);
	
		if (do_def == 1) begin
			execute(prog[savepc + 1].ptr);
		end
	
		breakout = 0;
		if (!returning)
			pc = prog[savepc + 2].ptr;	/* next statement */
	endtask
	
	task whilecode();
		Datum d;
		shortint savepc = pc;	/* loop body */
	
		breakout = 0;
		execute(savepc + 2);	/* condition */
		pop(d);
		while (d.val) begin
			execute(prog[savepc].ptr);	/* body */
			if (returning)
				break;
			if (breakout)
				break;
			execute(savepc + 2);
			pop(d);
		end
		breakout = 0;
		if (!returning)
			pc = prog[savepc + 1].ptr;	/* next statement */
	endtask
	
	task forcode();		/* process FOR */
		Datum d, d1;
		shortint savepc = pc;
	
		execute(savepc+4);              /* precharge */
		pop(d1);
		execute(prog[savepc].ptr);  /* condition */
		pop(d);
		breakout = 0;
		while (d.val) begin
			execute(prog[savepc+2].ptr);        /* body */
			//pop(d1);
			if (returning)
				break;
			if (breakout)
				break;
			execute(prog[savepc+1].ptr);        /* post loop */
			pop(d1);
			execute(prog[savepc].ptr);  /* condition */
			pop(d);
		end
		breakout = 0;
		if (!returning)
			pc = prog[savepc+3].ptr; /* next stmt */
	endtask
	
	task ifcode();
		Datum d;
		shortint savepc = pc;	/* then part */
	
		execute(savepc + 3);	/* condition */
		pop(d);
		if (d.val)
			execute(prog[savepc].ptr);
		else if (prog[prog[savepc + 1].ptr].ins != "STOP") /* else part? */
			execute(prog[savepc + 1].ptr);
		if (!returning)
			pc = prog[savepc + 2].ptr;	 /* next stmt */
	endtask
	
	static task define(Symbol sp, Args f);	/* put func/proc in symbol table */
		Fndefn fd = new();
		int n;
	
		fd.code = progbase;		/* start of code */
		progbase = progp;		/* next code starts here */
	
		fd.formals = f;
		fd.nargs = f.size();
	
		sp.u.defn = fd;
	endtask
	
	task call(); 		/* call a function */
		Args f;
		shortint arg;
		Datum d;
	
		Symbol sp = prog[pc].sym;	/* symbol table entry for function */
	
		fp++;
		frame[fp].sp = sp;
		frame[fp].nargs = prog[pc + 1].nargs;
		frame[fp].retpc = pc + 2;
		frame[fp].argn = stack.size() - 2;	/* last argument, pointer from bottom of stack */
	
		if(frame[fp].nargs != sp.u.defn.nargs)
			execerror(sp.name, "called with wrong number of arguments");
	
		/* bind formals */
		f = sp.u.defn.formals;
		arg = frame[fp].nargs;
		for (int i = 0; i < f.size(); i++) begin
			Saveval s = new();
	
			arg--;
			s.u.val = f[i].sym.u.val;
			s.type_ = f[i].sym.type_;
			f[i].save.push_front(s);
			f[i].sym.u.val = stack[arg].val;
			f[i].sym.type_ = `VAR;
		end
		if(arg != 0)
			execerror(sp.name, $psprintf("expected arg = 0, got = %0d", arg));
	
		for (int i = 0; i < frame[fp].nargs; i++)
			pop(d);  /* pop arguments; no longer needed */
	
		execute(sp.u.defn.code);
		returning = 0;
	endtask
	
	task restore(Symbol sp);	/* restore formals associated with symbol */
		Args f;
	
		f = sp.u.defn.formals;
		for (int i = 0; i < f.size(); i++) begin
			Saveval s;
	
			if(f[i].save.size() == 0)      /* more actuals than formals */
				break;
			s = f[i].save.pop_front();
			f[i].sym.u.val = s.u.val;
			f[i].sym.type_ = s.type_;
		end
	endtask
	
	task ret();		/* common return from func or proc */
		/* restore formals */
		restore(frame[fp].sp);
		pc = frame[fp].retpc;
		--fp;
		returning = 1;
	endtask
	
	task funcret();	/* return from a function */
		Datum d;
	
		if (frame[fp].sp.type_ == `PROCEDURE)
			execerror(frame[fp].sp.name, "(proc) returns value");
		pop(d);	/* preserve function return value */
		ret();
		push(d);
	endtask
	
	task procret();	/* return from a procedure */
		if (frame[fp].sp.type_ == `FUNCTION)
			execerror(frame[fp].sp.name,
				"(func) returns no value");
		ret();
	endtask
	
	task brkout();	/* break out of while, etc. */
		breakout = 1;
	endtask
	
	task bltin();		/* evaluate built-in on top of stack */
		Datum d;
	
		pop(d);
		d.val = exec_bltin(prog[pc++].sym, d.val) ;
		push(d);
	endtask
	
	task eval();		/* evaluate variable on stack */
		Datum d, d1;
		shortint index, dptr;
	
		pop(d);
	
		if (d.sym.type_ != `VAR && d.sym.type_ != `VEC && d.sym.type_ != `UNDEF)
			execerror("attempt to evaluate non-variable", d.sym.name);
		if (d.sym.type_ == `UNDEF)
			execerror("undefined variable", d.sym.name);
	
		if (d.sym.type_ == `VEC) begin
			pop(d1);             /* get subscript */
			index = d1.val;
			dptr = d.sym.u.vec;
			d.val = vecs[dptr][index];
			push(d);
			return;
		end
	
		d.val = d.sym.u.val;
		push(d);
	endtask
	
	task add();		/* add top two elems on stack */
		Datum d1, d2;
	
		pop(d2);
		pop(d1);
		d1.val += d2.val;
		push(d1);
	endtask
	
	task sub();	/* subtract top of stack from next */
		Datum d1, d2;
	
		pop(d2);
		pop(d1);
		d1.val -= d2.val;
		push(d1);
	endtask
	
	task mul();
		Datum d1, d2;
	
		pop(d2);
		pop(d1);
		d1.val *= d2.val;
		push(d1);
	endtask
	
	task div();
		Datum d1, d2;
	
		pop(d2);
		if (d2.val == 0.0)
			execerror("division by zero", "");
		pop(d1);
		d1.val /= d2.val;
		push(d1);
	endtask
	
	task mod();
		Datum d1, d2;
		int x, y, remainder;
		
		pop(d2);
		if ( d2.val == 0.0 )
			execerror("mod: division by zero","");
			
		pop(d1);
		x = d1.val; y = d2.val;
		remainder = x % y;
		d1.val = remainder;
		push(d1);
	endtask
	
	task negate();
		Datum d;
	
		pop(d);
		d.val = -d.val;
		push(d);
	endtask
	
	task gt();
		Datum d1, d2;
	
		pop(d2);
		pop(d1);
		d1.val = real'(d1.val > d2.val);
		push(d1);
	endtask
	
	task lt();
		Datum d1, d2;
	
		pop(d2);
		pop(d1);
		d1.val = real'(d1.val < d2.val);
		push(d1);
	endtask
	
	task ge();
		Datum d1, d2;
	
		pop(d2);
		pop(d1);
		d1.val = real'(d1.val >= d2.val);
		push(d1);
	endtask
	
	task le();
		Datum d1, d2;
	
		pop(d2);
		pop(d1);
		d1.val = real'(d1.val <= d2.val);
		push(d1);
	endtask
	
	task eq();
		Datum d1, d2;
	
		pop(d2);
		pop(d1);
		d1.val = real'(d1.val == d2.val);
		push(d1);
	endtask
	
	task ne();
		Datum d1, d2;
	
		pop(d2);
		pop(d1);
		d1.val = real'(d1.val  !=  d2.val);
		push(d1);
	endtask
	
	task addeq();
		Datum d1, d2;
	
		pop(d1);
	    pop(d2);
		if (d1.sym.type_ != `VAR && d1.sym.type_ != `UNDEF)
			execerror("assignment to non-variable", d1.sym.name);
		d1.sym.u.val += d2.val;
		d2.val = d1.sym.u.val;
		d1.sym.type_ = `VAR;
		push(d2);
	endtask
	
	task subeq();
		Datum d1, d2;
	
		pop(d1);
		pop(d2);
		if (d1.sym.type_ != `VAR && d1.sym.type_ != `UNDEF)
			execerror("assignment to non-variable", d1.sym.name);
		d1.sym.u.val -= d2.val;
		d2.val = d1.sym.u.val;
		d1.sym.type_ = `VAR;
		push(d2);
	endtask
	
	task muleq();
		Datum d1, d2;
	
		pop(d1);
		pop(d2);
		if (d1.sym.type_ != `VAR && d1.sym.type_ != `UNDEF)
			execerror("assignment to non-variable", d1.sym.name);
		d1.sym.u.val *= d2.val;
		d2.val = d1.sym.u.val;
		d1.sym.type_ = `VAR;
		push(d2);
	endtask
	
	task diveq();
		Datum d1, d2;
	
		pop(d1);
		pop(d2);
		if (d1.sym.type_ != `VAR && d1.sym.type_ != `UNDEF)
			execerror("assignment to non-variable", d1.sym.name);
		d1.sym.u.val /= d2.val;
		d2.val = d1.sym.u.val;
		d1.sym.type_ = `VAR;
		push(d2);
	endtask
	
	task modeq();
		Datum d1, d2;
		longint x;
	
		pop(d1);
		pop(d2);
		if (d1.sym.type_ != `VAR && d1.sym.type_ != `UNDEF)
			execerror("assignment to non-variable", d1.sym.name);
		/* d2.val = d1.sym.u.val %= d2.val; */
		x = d1.sym.u.val;
		x %= longint'(d2.val);
		d2.val = x;
		d1.sym.u.val = x;
		d1.sym.type_ = `VAR;
	
		push(d2);
	endtask
	
	task and_();
		Datum d1, d2;
	
		pop(d2);
		pop(d1);
		d1.val = real'(d1.val != 0.0 && d2.val != 0.0);
		push(d1);
	endtask
	
	task or_();
		Datum d1, d2;
	
		pop(d2);
		pop(d1);
		d1.val = real'(d1.val != 0.0 || d2.val != 0.0);
		push(d1);
	endtask
	
	task not_();
		Datum d;
	
		pop(d);
		d.val = real'(d.val == 0.0);
		push(d);
	endtask
	
	task power();
		Datum d1, d2;
	
		pop(d2);
		pop(d1);
		d1.val = pow(d1.val, d2.val);
		push(d1);
	endtask
	
	task verify(Symbol s);
		if (s.type_ != `VAR && s.type_ != `UNDEF)
			execerror("attempt to evaluate non-variable", s.name);
		if (s.type_ == `UNDEF)
			execerror("undefined variable", s.name);
	endtask
	
	task preinc();
		Datum d;
	
		d.sym = prog[pc++].sym;
		verify(d.sym);
		d.sym.u.val += 1.0;
		d.val = d.sym.u.val;
		push(d);
	endtask
	
	task predec();
		Datum d;
	
		d.sym = prog[pc++].sym;
		verify(d.sym);
		d.sym.u.val -= 1.0;
		d.val = d.sym.u.val;
		push(d);
	endtask 
	
	task postinc();
		Datum d;
		real v;
	
		d.sym = prog[pc++].sym;
		verify(d.sym);
		v = d.sym.u.val;
		d.sym.u.val += 1.0;
		d.val = v;
		push(d);
	endtask
	
	task postdec();
		Datum d;
		real v;
	
		d.sym = prog[pc++].sym;
		verify(d.sym);
		v = d.sym.u.val;
		d.sym.u.val -= 1.0;
		d.val = v;
		push(d);
	endtask
	
	task assign_();	/* assign top value to next value */
		Datum d1, d2;
	
		pop(d1);
		pop(d2);
		if (d1.sym.type_ != `VAR && d1.sym.type_ != `UNDEF)
			execerror("assignment to non-variable", d1.sym.name);
		d1.sym.u.val = d2.val;
		d1.sym.type_ = `VAR;
		push(d2);
	endtask
	
	task decvec();	/* declare vector variable */
		Datum d1, d2;
		int i, n;
		shortint dptr = vecs.size();
	
		pop(d1);
		pop(d2);
	
		n = d2.val;	/* number of words to reserve */
		vecs[dptr] = new [n];
		d1.sym.u.vec = dptr;
		d1.sym.type_ = `VEC;
	
		for (int i = 0; i < n; i++) 
			vecs[dptr][i] = 0.0;
	endtask
	
	task vecassign();	/* VAR[subscript] = value */
		Datum d1, d2, d3;
		int index;
		shortint dptr;
	
		pop(d3);	/* value */
		pop(d1);	/* VAR */
		pop(d2);	/* subscript */
	
		if (d1.sym.type_ != `VEC &&
			d1.sym.type_ != `VAR &&
			d1.sym.type_ != `UNDEF)
			execerror("assignment to non-vector",d1.sym.name);
	
		index = d2.val;
		dptr = d1.sym.u.vec;
		vecs[dptr][index] = d3.val;
		d1.sym.type_ = `VEC;
		push(d3);
	endtask
	
	task print();		/* pop top value from stack, print it */
		Datum d;
	
		pop(d);
		$write("\t%0f\n", d.val);
	endtask
	
	task prexpr();	/* print numeric value */
		Datum d;
	
		pop(d);
		$write("%12.12f", d.val);
	endtask
	
	task prstr();		/* print string value */ 
		string val = prog[pc++].sym.u.sval;
		$write("%s", val);
	endtask
	
	task varread();	/* read into variable */
		Datum d;
		Symbol var_ = prog[pc++].sym; /* symbol table entry */
	
		case($fscanf(file_din, "%f", var_.u.val))
			`EOF: begin
				d.val = 0.0;
				var_.u.val = 0.0;
			end
			0: execerror("non-number read into", var_.name);
			default: d.val = 1.0;
		endcase
	
		var_.type_ = `VAR;
		push(d);
	endtask
	
	static function shortint icode(string f);	/* install one instruction */
		shortint oprogp = progp;
	
		prog[progp].ptr = progp;
		prog[progp].type_ = `ICODE;
		prog[progp++].ins = f;
		return oprogp;
	endfunction
	
	static function shortint ocode(Symbol s);	/* install one operand */
		shortint oprogp = progp;
	
		prog[progp].ptr = progp;
		prog[progp].type_ = `OCODE;
		prog[progp++].sym = s;
		return oprogp;
	endfunction
	
	static function void pcode(shortint l, Inst r);	/* install one code pointer */
		prog[l].type_ = `PCODE;
		prog[l].ptr = r.ptr;
	endfunction
	
	static function shortint ncode(int n);	/* install one operand */
		shortint oprogp = progp;
	
		prog[progp].type_ = `NCODE;
		prog[progp].ptr = progp;
		prog[progp++].nargs = n;
		return oprogp;
	endfunction
	
	task execute(shortint p);	/* run the machine */
		int i;
		for (pc = p; prog[pc].ins != "STOP" && !returning && !breakout ; i++) begin
			string cmd = prog[pc++].ins;
			Datum d;
			dump_stack();
			if ( yydebug ) 
				$display ("%12d  command: %s", (pc - 1), cmd);
			case(cmd)
				"print"			: print();	/* pop top value from stack, print it */
				"constpush"		: constpush();	/* push constant onto stack */
				"varpush"		: varpush();	/* push variable onto stack */
				"whilecode"		: whilecode();
				"ifcode"		: ifcode();
				"forcode"		: forcode();
				"casecode"		: casecode();
				"forkcode"		: forkcode();
				"waitcode"		: waitcode();
				"break"			: brkout();
				"call"			: call();
				"funcret"		: funcret();
				"procret"		: procret();
				"bltin"			: bltin();	/* evaluate built-in on top of stack */
				"eval"			: eval();	/* evaluate variable on stack */
				"add"			: add();		/* add top two elems on stack */
				"sub"			: sub();		/* subtract top of stack from next */
				"mul"			: mul();
				"div"			: div();
				"negate"		: negate();
				"mod"			: mod();
				"addeq"			: addeq();
				"subeq"			: subeq();
				"muleq"			: muleq();
				"diveq"			: diveq();
				"modeq"			: modeq();
				"preinc"		: preinc();
				"predec"		: predec();
				"postinc"		: postinc();
				"postdec"		: postdec();
				"gt"			: gt();
				"lt"			: lt();
				"ge"			: ge();
				"le"			: le();
				"eq"			: eq();
				"ne"			: ne();
				"and"			: and_();
				"or"			: or_();
				"not"			: not_();
				"power"			: power();
				"assign"		: assign_();	/* assign top value to next value */
				"pop"			: pop(d);
				"prexpr"		: prexpr();
				"prstr"			: prstr();
				"varread"		: varread();
				"decvec"		: decvec();
				"vecassign"		: vecassign();
				default			: execerror("unknown instruction", cmd);
			endcase
		end
	endtask
endclass
