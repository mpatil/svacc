// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
`define ICODE 0
`define OCODE 1
`define NCODE 2
`define PCODE 3

class Process;
	static Inst			prog[*];	/* the machine */
	static shortint		progp;		/* next free spot for code generation */
	static shortint		progbase = 0; /* start of current subprogram */
	static Symlist		symlist[$];	/* symbol table: linked list */
	static Symlist		globals;	/* globals symbol table: linked list */
	static int			pid = 0 ;
	static bit			yydebug = 0;

	Datum				stack[$];	/* the stack */
	shortint			pc;			/* program counter during execution */
	Frame				frame[*];	/* contexts */
	shortint			fp;			/* frame pointer */
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

	task push(Datum d);		/* push d onto stack */
		#0;
		stack.push_front(d);
	endtask

	task pop(ref Datum d);	/* pop and return top elem from stack */
		if (stack.size())
			d = stack.pop_front();
		else
			execerror("FATAL ERROR", "pop on an empty stack");
		#0;
	endtask

	task constpush(string mode);	/* push constant onto stack */
		Datum d;
		Symbol sym = prog[pc++].sym;
		if (mode == "slice") begin
			Datum d1, d2;
			VectorVal v;
			RealVal u1, u2;

			pop(d1);
			`cast(u1, d1.u.real_(), "slice range: right", "not a number");

			pop(d2);
			`cast(u2, d2.u.real_(), "slice range: left", "not a number");

			`cast(v, sym.u, sym.name, "not a vector");

			d.u = v.get_slice(u2.val, u1.val);
		end
		else
		begin
			d.u = sym.u;
			if(mode == "ref") d.u.isref = 1;
		end
		push(d);
	endtask

	task varpush(string mode = "");	/* push variable onto stack */
		if (mode != "sub") begin 
			Datum d;
			d.sym = prog[pc++].sym;
			if(d.sym.u && mode == "ref") d.sym.u.isref = 1;
			push(d);
		end else begin /* subscript */
			Datum d1, d2;
		    pop(d1);
		    pop(d2);
			d2.sym = new();
			d2.sym.name = "_anon__121__";
			case(d2.u.get_type())
				"vector":	d2.sym.type_ = `VEC;
				"dict":		d2.sym.type_ = `DICT;
				default :	execerror("subscript -- []", "on bad type");
			endcase
			d2.sym.u = d2.u; 		
			d2.u = null;
		    push(d1);
		    push(d2);
		end
	endtask

	task forkcode();	/* fork { stmts } */
		shortint savepc = prog[pc++].ptr;
		shortint forkpc = pc++;
		shortint dpc = forkpc;
		shortint i = 0;

		if(savepc == forkpc + 1) return;

		while (1) begin
			Process p = new(i + 1);
			
			forkpc = prog[dpc].ptr - 1;	

			fork
				automatic int epc = dpc + 1;
				automatic Process q = p;
				begin
					q.execute(epc);	/* fork body */
				end
			join_none

			if ((prog[dpc].ptr) >= savepc) break;
			dpc = forkpc;

			i++;
		end 

		wait fork ; // wait for all jobs to end

		if (returning)
			execerror("fork", "Illegal return from within a fork");
		if (!returning)
			pc = savepc;	/* next statement */
	endtask

	task triggercode();	
		Symbol  sym = prog[pc++].sym;	/* VAR */
		EventVal u;
		`cast(u, sym.u, "->: ev", "not an event");
		-> u.ev;
	endtask

	task waitcode(string mode = "");		/* # N, @event */
		Symbol sym;
		if (mode == "event") begin
			EventVal u;
			sym = prog[pc++].sym;	/* VAR */
			`cast(u, sym.u, "@: ev", "not an event");
			@u.ev;
		end else begin
			RealVal u;
			Datum d;
			pop(d);
			`cast(u, d.u.real_(), "wait: arg ", "not a number");
			# (u.val);
		end
	endtask

	task casecode();	/* case (n) { m: stmt ..} */
		Datum d1;
		RealVal u1;

		shortint savepc = pc;	/* first case condition expression */
		shortint cpc = prog[savepc].ptr - 1;
		int do_def = 1;

		breakout = 0;
		execute(savepc + 3);	/* switch condition */
		pop(d1);
		`cast(u1, d1.u.real_(), "case switch condition", "not a number");
		do begin
			Datum d2;
			RealVal u2;
			shortint dpc = cpc + 1;

			cpc = prog[cpc].ptr;

			execute(prog[dpc].ptr);	/* case condition expression*/
			pop(d2);
			`cast(u2, d2.u.real_(), "case condition", "not a number");

			if (u1.val == u2.val) begin
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
		RealVal u;
		shortint savepc = pc;	/* loop body */

		breakout = 0;
		execute(savepc + 2);	/* condition */
		pop(d);
		`cast(u, d.u.real_(), "while condition", "not a number");
		while (u.val) begin
			execute(prog[savepc].ptr);	/* body */
			if (returning)
				break;
			if (breakout)
				break;
			execute(savepc + 2);
			pop(d);
			$cast(u, d.u);
		end
		breakout = 0;
		if (!returning)
			pc = prog[savepc + 1].ptr;	/* next statement */
	endtask

	task forcode();		/* process FOR */
		Datum d, d1;
		shortint savepc = pc;
		RealVal u;

		execute(savepc+4);			/* precharge */
		pop(d1);
		execute(prog[savepc].ptr);	/* condition */
		pop(d);
		`cast(u, d.u.real_(), "for condition", "not a number");
		breakout = 0;
		while (u.val) begin
			execute(prog[savepc+2].ptr);	/* body */
			//pop(d1);
			if (returning)
				break;
			if (breakout)
				break;
			execute(prog[savepc+1].ptr);	/* post loop */
			pop(d1);
			execute(prog[savepc].ptr);	/* condition */
			pop(d);
			$cast(u, d.u.real_());
		end
		breakout = 0;
		if (!returning)
			pc = prog[savepc+3].ptr; /* next stmt */
	endtask

	task ifcode();
		Datum d;
		RealVal u;
		shortint savepc = pc;	/* then part */

		execute(savepc + 3);	/* condition */
		pop(d);
		`cast(u, d.u.real_(), "if condition", "not a number");
		if (u.val)
			execute(prog[savepc].ptr);
		else if (prog[prog[savepc + 1].ptr].ins != "STOP") /* else part? */
			execute(prog[savepc + 1].ptr);
		if (!returning)
			pc = prog[savepc + 2].ptr;	/* next stmt */
	endtask

	task fundef();		/* nested function definition */
		Symbol sp = prog[pc++].sym;
		Symbol up;

		FnDefn u;

		`cast(u, sp.u, sp.name, "not a function");

		up = u.parent; // if this function is nested ie. has parent, then create the closure ...
		while (up) begin /* exec'd only when parent is 'call'ed */
			string s;

			FnDefn v;
			`cast(v, up.u, up.name, "not a function");

			if (v.symlist.first(s))
				do begin // copy parent dynamic values to static chain; sc will have captured environment after this
					Args a = u.formals.find_first(x) with (x.sym.name == v.symlist[s].name);
					if (v.symlist[s].u && (a.size() == 0))
						u.sc[s] = v.symlist[s].copy();
				end while(v.symlist.next(s));

			up = v.parent;
		end

		pc = prog[pc].ptr;
	endtask

	task call();		/* call a function */
		FnDefn u;
		Symbol sp = prog[pc].sym;	/* symbol table entry for function */
		`cast(u, sp.u, sp.name, "not a function");

		if (u.parent) begin
			Symbol up = u.parent; 
			while (up) begin 
				string s;

				FnDefn v;
				`cast(v, up.u, up.name, "not a function");

				if (v.symlist.first(s))
					do begin 
						if (u.sc.exists(s) && u.sc[s].u) begin
							assert(v.symlist[s].name == u.sc[s].name);
							v.symlist[s].u = u.sc[s].u.copy();
						end
					end while(v.symlist.next(s));
				up = v.parent;
			end
		end

		fp++;
		frame[fp].sp = sp;
		frame[fp].nargs = prog[pc + 1].nargs;
		frame[fp].retpc = pc + 2;

		if(frame[fp].nargs != u.nargs)
			execerror(sp.name, "called with wrong number of arguments");

		begin
			/* bind formals */
			Args f = u.formals;
			shortint arg = frame[fp].nargs;
			for (int i = 0; i < f.size(); i++) begin
				arg--;
				case(stack[arg].u.get_type())
					"real":		f[i].sym.type_ = `VAR;
					"vector":	f[i].sym.type_ = `VEC;
					"function":	f[i].sym.type_ = `FUNCTION;
					"string":	f[i].sym.type_ = `STRING;
					"dict":		f[i].sym.type_ = `DICT;
					default : execerror(sp.name, "function args bad type");
				endcase
				begin
					Saveval s = new();
					if (f[i].sym.u) s.u = f[i].sym.u;
					s.type_ = f[i].sym.type_;
					f[i].save.push_front(s);
				end

				f[i].sym.u = stack[arg].u;
			end
			if(arg != 0)
				execerror(sp.name, $psprintf("expected arg = 0, got = %0d", arg));
		end

		begin
			Datum d;
			for (int i = 0; i < frame[fp].nargs; i++) pop(d);	/* pop arguments; no longer needed */
		end

		execute(u.code);
		returning = 0;
	endtask

	task restore(Symbol sp);	/* restore formals associated with symbol */
		Symbol up;
		FnDefn u;
		`cast(u, sp.u, sp.name, "not a function");

		begin
			Args f = u.formals;
			for (int i = 0; i < f.size(); i++) begin
				Saveval s = f[i].save.pop_front();

				f[i].sym.u = s.u;
				f[i].sym.type_ = s.type_;

				if(f[i].save.size() == 0) break;	/* more actuals than formals */
			end
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
			execerror(frame[fp].sp.name, "(func) returns no value");
		ret();
	endtask

	task brkout();	/* break out of while, etc. */
		breakout = 1;
	endtask

	task bltin(string mode = "fn");		/* evaluate built-in on top of stack */
		Symbol sp = prog[pc].sym;	/* symbol table entry for function */
		FnDefn u;
		shortint nargs = prog[pc + 1].nargs;
		shortint arg = nargs;
		Symval args[];
		`cast(u, sp.u, sp.name, "not a function");

		if(nargs != u.nargs)
			execerror(sp.name, "called with wrong number of arguments");

		args = new [nargs];
		for (int i = 0; i < nargs; i++) begin
			Datum d1;

			arg--;
			pop(d1);
			args[arg] = d1.u;
		end

		if (mode == "fn") begin
			Datum d;
			d.u = exec_bltin_fn(sp, args) ;
			push(d);
        end else 
			exec_bltin_task(sp, args) ;

		pc += 2;
	endtask

	task eval(string mode = "");		/* evaluate variable on stack */
		Datum d;

		pop(d);

		verify(d.sym, "eval");
		if (d.sym.u == null)
			execerror(d.sym.name, "eval : undefined variable");

		case (d.sym.type_)
			`VEC: begin
				VectorVal u;

				`cast(u, d.sym.u, d.sym.name, "not a vector");

				if (mode == "vecvar") begin
					Datum d1, d2;
					RealVal u1; 
					shortint index;

					pop(d1);		/* get subscript */
					`cast(u1, d1.u.int_(), d.sym.name, "bad array subscript/index");
					index = u1.val;
					if ((index >= u.vecs.size()) || (index < (-1 * u.vecs.size()))) 
						execerror(d.sym.name, $psprintf(": bad index %0d", index));
					if	((index < 0) && index >= (-1 * u.vecs.size())) index += u.vecs.size();

					if (u.vecs[index]) 
						d2.u = u.vecs[index];
					else
						execerror(d.sym.name, $psprintf("undefined vector element %s[%0d]", d.sym.name,index));
					push(d2);
				end
				else
				begin
					d.u = d.sym.u;
					push(d);
				end
				return;
			end
			`DICT: begin
				DictVal u;

				`cast(u, d.sym.u, d.sym.name, "not a dictionary");
				if (mode == "vecvar") begin
					Datum d1, d2;
					Symval u2;
					pop(d1);		/* get key */
					u2 = u.from_key(d1.u);
					d2.u = u2;
					push(d2);
				end
				else
				begin
					d.u = d.sym.u;
					push(d);
				end
				return;
			end
			default: begin
				d.u = d.sym.u;
				push(d);
			end
		endcase
	endtask

	task checkop(real val);
		if (val == 0)
			execerror("division by zero", "");
	endtask

	task binarithop(string op);
		Datum d1, d2, d3;

		pop(d2);
		if ((d2.u.get_type() != "real"))
			execerror("arithmetic operation", "not a number");
		pop(d1);
		if ((d1.u.get_type() != "real"))
			execerror("arithmetic operation", "not a number");

		begin
			RealVal u1, u2, u3 = new();
			$cast(u1, d1.u.real_());
			$cast(u2, d2.u.real_());
			case(op)
				"+": u3.val = u1.val + u2.val;
				"-": u3.val = u1.val - u2.val;
				"*": u3.val = u1.val * u2.val;
				"&": u3.val = longint'(u1.val) & longint'(u2.val);
				"|": u3.val = longint'(u1.val) | longint'(u2.val);
				"^": u3.val = longint'(u1.val) ^ longint'(u2.val);
				"/": begin checkop(u2.val); u3.val = u1.val / u2.val; end
				"**": u3.val = pow(u1.val, u2.val);
				"<<": u3.val = longint'(u1.val) << longint'(u2.val); 
				">>": u3.val = longint'(u1.val) >> longint'(u2.val); 
			endcase
			d3.u = u3;
		end
		push(d3);
	endtask

	task mod();
		Datum d1, d2, d3;
		int x, y, remainder;

		pop(d2);
		pop(d1);

		case (d1.u.get_type())
			"real": begin
						RealVal u1, u2, u3 = new();
						$cast(u2, d2.u.int_());
						$cast(u1, d1.u.int_());
						if ( u2.val == 0.0 )
							execerror("mod: division by zero","");
						x = u1.val; y = u2.val;
						remainder = x % y;
						u3.val = remainder;
						d3.u = u3;
					end
			default : execerror("modulo operation", "not a number");
		endcase
		push(d3);
	endtask

	task negate();
		Datum d, d1;

		pop(d);
		case (d.u.get_type())
			"real": begin
						RealVal u, u1 = new();
						$cast(u, d.u);
						u1.val = -u.val;
						d1.u = u1;
					end
			default : execerror("negate", "not a number");
		endcase
		push(d1);
	endtask

	task binrelop(string op);
		Datum d1, d2, d3;

		pop(d2);
		pop(d1);

		case (d1.u.get_type())
			"real": begin
						RealVal u1, u2, u3 = new();
						$cast(u1, d1.u);
						$cast(u2, d2.u);
						case (op)
							">":  u3.val = (u1.val > u2.val);
							"<":  u3.val = (u1.val < u2.val);
							">=":  u3.val = (u1.val >= u2.val);
							"<=":  u3.val = (u1.val <= u2.val);
							"==":  u3.val = (u1.val == u2.val);
							"!=":  u3.val = (u1.val != u2.val);
							"&&":  u3.val = (u1.val && u2.val);
							"||":  u3.val = (u1.val || u2.val);
						endcase
						d3.u = u3;
					end
			default : begin
						RealVal u3 = new();
						case (op)
							"==":  u3.val = (d1.u.get_type() == d2.u.get_type()) && (d1.u == d2.u);
							"!=":  u3.val = (d1.u.get_type() != d2.u.get_type()) || (d1.u != d2.u);
							"&&":  u3.val = (d1.u.get_type() == d2.u.get_type()) && (d1.u && d2.u);
							"||":  u3.val = (d1.u.get_type() == d2.u.get_type()) && (d1.u || d2.u);
							default: execerror("relational operation", "not a number");
						endcase
						d3.u = u3;
					end
		endcase
		push(d3);
	endtask

	task sc(string op);
		Datum d;
		shortint scjump = prog[pc - 1].ptr;

		pop(d);

		case (d.u.get_type())
			"real": begin
						RealVal u;
						$cast(u, d.u);
						case (op)
							"&&": begin if (!u.val) pc = scjump + 1; push(d); end
							"||": begin if (u.val) pc = scjump + 1; push(d); end
							"?": if (!u.val) pc = scjump + 1; 
							":": begin pc = scjump; push(d); end
						endcase
					end
			default : execerror("relational operation", "not a number");
		endcase
	endtask

	task vareq(string op);
		Datum d1, d2;

		d1.sym = prog[pc++].sym;	/* VAR */
		pop(d2);
		verify(d1.sym, "binary op");
		case (d1.sym.u.get_type())
			"real" : begin
						RealVal u1, u2;
						`cast(u1, d1.sym.u, d1.sym.name, "not a number");
						`cast(u2, d2.u.real_(), "modulo operation", "not a number");
						case (op)
							"+=": u1.val += u2.val;
							"-=": u1.val -= u2.val;
							"*=": u1.val *= u2.val;
							"/=": u1.val /= u2.val;
							"&=": u1.val  = longint'(u1.val) &  longint'(u2.val);
							"|=": u1.val  = longint'(u1.val) |  longint'(u2.val);
							"^=": u1.val  = longint'(u1.val) ^  longint'(u2.val);
							"<<=": u1.val = longint'(u1.val) << longint'(u2.val);
							">>=": u1.val = longint'(u1.val) >> longint'(u2.val);
						endcase
					end
			default : execerror("modulo operation", "not a number");
		endcase
		push(d1);
	endtask

	task modeq();
		Datum d1, d2;
		RealVal u1, u2;
		longint x, y, remainder;

		d1.sym = prog[pc++].sym;	/* VAR */
		pop(d2);
		verify(d1.sym, "modeq");
		`cast(u1, d1.u, d1.sym.name, "% operands: not the correct type");
		`cast(u2, d2.u, "% operands", "not the correct type");
		/* d2.val = u1.val %= d2.val; */
		x = longint'(u1.val);
		y = longint'(u2.val);
		remainder = x % y;
		u1.val = remainder;
		push(d1);
	endtask

	task not_();
		Datum d, d1;
		RealVal u, u1 = new();

		pop(d);

		$cast(u, d.u.real_());
		u1.val = real'(u.val == 0.0);
		d1.u = u1;
		push(d1);
	endtask

	task verify(Symbol s, string t = "");
		if (s.type_ != `VAR && s.type_ != `VEC && s.type_ != `UNDEF && s.type_ != `FUNCTION && s.type_ != `DICT)
			execerror("non-variable:", s.name);
		if (s.type_ == `UNDEF)
			execerror($psprintf("%s undefined variable", t), s.name);
	endtask

	task preop(string op);
		Datum d;

		d.sym = prog[pc++].sym;
		verify(d.sym, "preinc");
		begin
			case(d.sym.u.get_type())
				"real" : begin
							RealVal u, u1;
							`cast(u, d.sym.u, d.sym.name, "not a number");
							case (op)
								"++": u.val += 1;
								"--": u.val -= 1;
							endcase
							if (d.u)
								$cast(u1, d.u);
							else begin
								u1 = new();
								d.u = u1;
							end
							u1.val = u.val;
						end
				default : execerror(d.sym.name, "not a number");
			endcase
		end
		push(d);
	endtask

	task postop(string op);
		Datum d;

		d.sym = prog[pc++].sym;
		verify(d.sym, "postinc");
		begin
			case(d.sym.u.get_type())
				"real" : begin
							real v;
							RealVal u, u1;
							`cast(u, d.sym.u, d.sym.name, "not a number");
							v = u.val;
							case (op)
								"++": u.val += 1;
								"--": u.val -= 1;
							endcase
							if (d.u)
								$cast(u1, d.u);
							else begin
								u1 = new();
								d.u = u1;
							end
							u1.val = v;
						end
				default : execerror(d.sym.name, "not a number");
			endcase
		end
		push(d);
	endtask

	task assign_();	/* assign top value to next value */
		Symbol sym = prog[pc++].sym;	/* VAR */
		Datum d2;	/* VAR = value */

		pop(d2);	/* value */
		if (sym.type_ != `VAR && sym.type_ != `UNDEF)
			execerror("assignment to non-variable", sym.name);
		assert(d2.u);

		if (d2.u.get_type() == "vector" ) begin
			VectorVal u;
			`cast(u, d2.u, "assign rhs", "not a vector");
			if (u.isref) begin
				sym.u = d2.u;
				u.isref = 0;
			end
			else
				sym.u = d2.u.copy();
		end
		else
			sym.u = d2.u.copy();
		case (d2.u.get_type())
			"real": sym.type_ = `VAR;
			"function" : sym.type_ = `FUNCTION;
			"string" : sym.type_ = `STRING;
			"vector" : sym.type_ = `VEC;
			"dict" : sym.type_ = `DICT;
			default : execerror("assign", "Fatal Error");
		endcase
		push(d2);
	endtask

	task decevent();	/* declare an event*/
		Symbol sym = prog[pc++].sym;	/* VAR */
		EventVal u;

		if (sym.u == null) begin
			u = new();
			sym.u = u;
		end
		else
			`cast(u, sym.u, "decevent", "not an event");
		assert(sym.type_ == `EV);
	endtask

	task decdict(string mode = "");	/* declare dictionary variable */
		Symbol sym;	/* VAR */
		DictVal u;
		Datum d2;
		Symval elems[Symval];

		if (mode != "anon") begin
			sym = prog[pc++].sym;	/* VAR */
			if (sym.type_ != `VAR && sym.type_ != `DICT && sym.type_ != `UNDEF )
				execerror("non-variable:", sym.name);
		end
		case (mode)
			"vd": begin
					shortint n_ = prog[pc++].nargs;

					while (n_) begin
						Datum dk, dv;
						n_--;
						pop(dv);
						pop(dk);
						elems[dk.u] = dv.u;
					end
				end
			"anon": begin
					shortint n_ = prog[pc++].nargs;

					u = new();
					while (n_) begin
						Datum dk, dv;
						n_--;
						pop(dv);
						pop(dk);
						elems[dk.u] = dv.u;
					end
					u.dict = elems;
					d2.u = u;
					push(d2);
				end

		endcase
		if (mode != "anon") begin
			if (sym.u == null) begin
				u = new();
				sym.u = u;
			end
			else
				`cast(u, sym.u, "decdict", "not a dictionary");
			u.dict = elems;
			assert(sym.type_ == `DICT);
		end
	endtask

	task decvec(string mode = "");	/* declare vector variable */
		Symbol sym;
		Datum d2;
		RealVal u2;
		Symval elems[];
		int i, n;

		if (mode != "anon") begin
			sym = prog[pc++].sym;	/* VAR */
			if (sym.type_ != `VAR && sym.type_ != `VEC && sym.type_ != `UNDEF )
				execerror("non-variable:", sym.name);
		end
		case (mode)
			"d": begin
					pop(d2);
					$cast(u2, d2.u.int_());
					n = u2.val;	/* number of words to reserve */
				end
			"dd", "vd": begin
					shortint n_ = prog[pc++].nargs;

					n = n_;
					elems = new [n_];
					while (n_) begin
						Datum d;
						n_--;
						pop(d);
						elems[n_] = d.u;
					end

					if (mode != "vd") begin
						pop(d2);
						$cast(u2, d2.u.int_());
						n = u2.val;	/* number of words to reserve */
					end
				end
			"anon": begin
					shortint n_ = prog[pc++].nargs;
					VectorVal v = new();
					v.vecs = new [n_];
					while (n_) begin
						Datum d;

						n_--;
						pop(d);
						v.vecs[n_] = d.u;
					end

					d2.u = v;
					push(d2);
				end
		endcase
		if (mode != "anon") begin
			VectorVal u;
			if (sym.u == null) begin
				u = new();
				sym.u = u;
			end
			else
				`cast(u, sym.u, "decvec", "not a vector");
			assert(n >= elems.size());
			u.vecs = new[n];
			foreach (elems[i]) u.vecs[i] = elems[i];
			assert(sym.type_ == `VEC);
		end
	endtask

	task vecassign();	/* VAR[subscript] = value */
		Datum d1, d2, d3;

		pop(d3);	/* value */
		pop(d1);	/* VAR */
		pop(d2);	/* subscript */

		if (d1.sym.type_ != `VEC && d1.sym.type_ != `VAR && d1.sym.type_ != `UNDEF && d1.sym.type_ != `DICT)
			execerror("assignment to non-vector",d1.sym.name);

		case(d1.sym.u.get_type())
			"vector": begin
						RealVal u2;
						int index;
						$cast(u2, d2.u.int_());
						index = u2.val;
						begin
							VectorVal u;
							`cast(u, d1.sym.u, d1.sym.name, "not a vector");
							u.vecs[index] = d3.u.copy();
						end
						d1.sym.type_ = `VEC;
					end
			"dict": begin
						DictVal u;
						`cast(u, d1.sym.u, d1.sym.name, "not a dictionary");
						u.set_val(d2.u, d3.u);
					end
		endcase
		push(d3);
	endtask

	task prexpr();	/* print numeric value */
		Datum d;

		pop(d);
		case (d.u.get_type())
			"real": begin
						RealVal u;
						longint unsigned x;
						$cast(u, d.u);
						x = longint'(u.val);
						if(x == u.val)
							$write("%0d", x);
						else
							$write("%g", u.val);
					end
			"string": begin
						StringVal u;
						$cast(u, d.u);
						$write("%s", u.val);
					end
			"vector": begin
						VectorVal u;
						$cast(u, d.u);
						$write("%0d", u.vecs.size());
					end
			"dict": begin
						DictVal u;
						$cast(u, d.u);
						$write("%0d", u.dict.num());
					end
			default : execerror("", "unprintable type");
		endcase
	endtask

	task varread();	/* read into variable */
		Datum d;
		Symbol sym = prog[pc++].sym; /* symbol table entry */
		RealVal u;
		`cast(u, sym.u, "varread", "not a number");

		case($fscanf(file_din, "%f", u.val))
			`EOF: u.val = 0.0;
			0: execerror("non-number read into", sym.name);
		endcase

		sym.type_ = `VAR;
		push(d);
	endtask

	static function shortint icode(string f, string arg1 = "", string arg2 = "");	/* install one instruction */
		shortint oprogp = progp;

		prog[progp].ptr = progp;
		prog[progp].type_ = `ICODE;
		prog[progp].arg1 = arg1;
		prog[progp].arg2 = arg2;
		prog[progp].tokenoff = Parser::tokenoff;
		prog[progp++].ins = f;
		return oprogp;
	endfunction

	static function shortint ocode(Symbol s);	/* install one operand */
		shortint oprogp = progp;

		prog[progp].ptr = progp;
		prog[progp].type_ = `OCODE;
		prog[progp].tokenoff = Parser::tokenoff;
		prog[progp++].sym = s;
		return oprogp;
	endfunction

	static function void pcode(shortint l, Inst r);	/* install one code pointer */
		prog[l].type_ = `PCODE;
		prog[progp].tokenoff = Parser::tokenoff;
		prog[l].ptr = r.ptr;
	endfunction

	static function shortint ncode(int n);	/* install one operand */
		shortint oprogp = progp;

		prog[progp].type_ = `NCODE;
		prog[progp].tokenoff = Parser::tokenoff;
		prog[progp].ptr = progp;
		prog[progp++].nargs = n;
		return oprogp;
	endfunction

	task execute(shortint p);	/* run the machine */
		int i;
		for (pc = p; prog[pc].ins != "STOP" && !returning && !breakout ; i++) begin
			Inst ins = prog[pc++];
			string cmd = ins.ins;
			string arg = ins.arg1;
			Datum d;

			Parser::tokenoff = ins.tokenoff;

			case(cmd)
				"prexpr"		: prexpr();
				"constpush"		: constpush(ins.arg1);	/* push constant onto stack */
				"varpush"		: varpush(ins.arg1);	/* push variable onto stack */
				"whilecode"		: whilecode();
				"ifcode"		: ifcode();
				"forcode"		: forcode();
				"casecode"		: casecode();
				"forkcode"		: forkcode();
				"waitcode"		: waitcode(ins.arg1);
				"triggercode"	: triggercode();
				"break"			: brkout();
				"fundef"		: fundef();
				"call"			: call();
				"funcret"		: funcret();
				"procret"		: procret();
				"bltin"			: bltin(ins.arg1);	/* evaluate built-in on top of stack */
				"eval"			: eval(ins.arg1);	/* evaluate variable on stack */
				"negate"		: negate();
				"mod"			: mod();
				"postop"		: preop(ins.arg1);
				"preop"			: postop(ins.arg1);
				"vareq"			: vareq(ins.arg1);
				"binarithop"	: binarithop(ins.arg1);
				"binrelop"		: binrelop(ins.arg1);
				"sc"			: sc(ins.arg1); /* shortcircuit op */
				"modeq"			: modeq();
				"not"			: not_();
				"assign"		: assign_();	/* assign top value to next value */
				"pop"			: pop(d);
				"varread"		: varread();
				"decvec"		: decvec(ins.arg1);
				"decdict"		: decdict(ins.arg1);
				"decevent"		: decevent();
				"vecassign"		: vecassign();
				default			: execerror("unknown instruction", cmd);
			endcase
		end
	endtask
endclass
