// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
static integer keywords[string] = { /* Keywords */
	"proc":		`PROC,
	"func":		`FUNC,
	"return":	`RETURN,
	"if":		`IF,
	"for":		`FOR,
	"else":		`ELSE,
	"while":	`WHILE,
	"break":	`BREAK,
	"vector":	`VECTOR,
	"dict":		`DICTIONARY,
	"event":	`EVENT,
	"case":		`CASE,
	"fork":		`FORK,
	"default":	`DEFAULT,
	"print":	`PRINT,
	"read":		`READ
};

static real consts[string] = { /* Constants */
	"PI":	  3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679,
	"E":	  2.7182818284590452353602874713526624977572470936999595749669676277240766303535475945713821785251664274,
	"GAMMA":0.5772156649015328606065120900824024310421593359399235988057672348848677267776646709369470632917467495,  /* Euler */
	"PHI":  1.6180339887498948482045868343656381177203091798057628621354486227052604628189024497072072041893911374  /* golden ratio */
};

static shortint builtin_tsks[string] = { /* Builtins */
	"rx": 2
};

static shortint builtin_fns[string] = { /* Builtins */
	"sin": 1,
	"cos": 1,
	"tan": 1,
	"asin": 1,
	"acos": 1,
	"atan": 1,
	"sinh": 1,
	"cosh": 1,
	"tanh": 1,
	"log": 1,
	"log10": 1,
	"exp": 1,
	"sqrt": 1,
	"abs": 1,
	"fabs": 1,
	"round": 1,
	"ceil": 1,
	"floor": 1,
	"length": 1,
	"pow": 2
};

function void init();	/* install constants and built-ins in table */
	int i;
	Symbol s;
	string s_;

	if ( keywords.first(s_) )
	do begin
		s = new();
		s.name = s_;
		s.type_ = keywords[s_];
		Process::globals[s_] = s;
	end while ( keywords.next(s_) );

	if ( consts.first(s_) )
	do begin
		RealVal u = new();
		s = new();
		s.name = s_;
		s.type_ = `CONST;
		u.val = consts[s_];
		s.u = u;
		Process::globals[s_] = s;
	end while ( consts.next(s_) );

	if ( builtin_fns.first(s_) )
	do begin
		FnDefn fn = new(); 
		s = new();
		s.name = s_;
		fn.nargs = builtin_fns[s_];
		s.type_ = `BLTINFN;
		s.u = fn;
		Process::globals[s_] = s;
	end while ( builtin_fns.next(s_) );

	if ( builtin_tsks.first(s_) )
	do begin
		FnDefn fn = new(); 
		s = new();
		s.name = s_;
		fn.nargs = builtin_tsks[s_];
		s.type_ = `BLTINTSK;
		s.u = fn;
		Process::globals[s_] = s;
	end while ( builtin_tsks.next(s_) );

endfunction

static task register_builtin_fn(string name, shortint nargs);
		FnDefn fn; 
		Symbol s;

		if (Process::globals.exists(name)) begin
			execerror(name, " already exists!!");
			return;
		end

		s = new();
		fn = new();
		s.name = name;
		fn.nargs = nargs;
		s.type_ = `BLTINFN;
		s.u = fn;
		Process::globals[name] = s;
endtask

static task register_var(string name, real val = 0.0);
		Symbol s;
		RealVal u = new();

		if (Process::globals.exists(name)) begin
			execerror(name, " already exists!!");
			return;
		end

		s = new();
		s.name = name;
		s.type_ = `VAR;
		u.val = val;
		s.u = u;
		Process::globals[name] = s;
endtask

function real get_val(string name);
		Symbol s = Process::globals[name];
		RealVal u;
		if (!$cast(u, s.u))
			execerror("get_val", "not a real type");
		get_val = u.val;
endfunction

function set_val(string name, real val);
		Symbol s = Process::globals[name];
		RealVal u;
		if (!$cast(u, s.u))
			execerror("set_val", "not a real type");
		u.val = val;
endfunction

static function Symval  exec_bltin_fn(Symbol fname, Symval val[]);
	FnDefn u;
	`cast(u, fname.u, fname.name, "not a function");
	case (u.nargs) 
		1:	begin
				case (val[0].get_type())
					"real": begin
								RealVal u, u1 = new();
								`cast(u, val[0], fname.name, "argument not a number");

								case(fname.name)
									"sin"   : u1.val = sin(u.val);
									"cos"   : u1.val = cos(u.val);
									"tan"   : u1.val = tan(u.val);
									"asin"  : u1.val = asin(u.val);
									"acos"  : u1.val = acos(u.val);
									"atan"  : u1.val = atan(u.val);
									"sinh"  : u1.val = sinh(u.val);
									"cosh"  : u1.val = cosh(u.val);
									"tanh"  : u1.val = tanh(u.val);
									"exp"   : u1.val = exp(u.val);
									"abs"   : u1.val = abs(u.val);
									"fabs"  : u1.val = fabs(u.val);
									"log"   : u1.val = log(u.val);
									"log10" : u1.val = log10(u.val);
									"sqrt"  : u1.val = sqrt(u.val);
									"round" : u1.val = round(u.val);
									"ceil"  : u1.val = ceil(u.val);
									"floor" : u1.val = floor(u.val);
								endcase
								return u1;
							end
					"vector": begin
								RealVal u1 = new();
								VectorVal u;
								`cast(u, val[0], fname.name, "arg not a vector");
								case(fname.name)
									"length"   : u1.val = u.vecs.size();
								endcase
								return u1;
							end
				endcase
			end
		2:	begin
				RealVal u1, u2, u3 = new();

				`cast(u1, val[0], fname.name, "arg 1 not a number");
				`cast(u2, val[1], fname.name, "arg 2 not a number");

				case(fname.name)
					"pow"	: u3.val = pow (u1.val, u2.val);
				endcase
				return u3;
			end
	endcase
endfunction

static task exec_bltin_task(Symbol fname, Symval val[]);
	FnDefn u;
	`cast(u, fname.u, fname.name, "not a function");
	case (u.nargs) 
		2:	begin
				RealVal u1, u2, u3 = new();

				`cast(u1, val[0], fname.name, "arg 1 not a number");
				`cast(u2, val[1], fname.name, "arg 2 not a number");

				case(fname.name)
					"rx"	: u3.val = pow (u1.val, u2.val);
				endcase
			end
	endcase
     /* no bultin tasks */
endtask
