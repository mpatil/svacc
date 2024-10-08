// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab

typedef struct {		/* Keywords */
	string	name;
	int		kval;
} keywords_;

static keywords_ keywords[] = {
	keywords_'{"proc",		`PROC},
	keywords_'{"func",		`FUNC},
	keywords_'{"return",		`RETURN},
	keywords_'{"if",			`IF},
	keywords_'{"for",		`FOR},
	keywords_'{"else",		`ELSE},
	keywords_'{"while",		`WHILE},
	keywords_'{"break",		`BREAK},
	keywords_'{"vector",		`VECTOR},
	keywords_'{"dict",		`DICTIONARY},
	keywords_'{"event",		`EVENT},
	keywords_'{"case",		`CASE},
	keywords_'{"fork",		`FORK},
	keywords_'{"default",	`DEFAULT},
	keywords_'{"print",		`PRINT},
	keywords_'{"read",		`READ},
	keywords_'{"",			0}
};

typedef struct {		/* Constants */
	string	name;
	real	cval;
} const_;

static const_ consts[] = {
	const_'{"PI",	  3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679},
	const_'{"E",	  2.7182818284590452353602874713526624977572470936999595749669676277240766303535475945713821785251664274},
	const_'{"GAMMA",0.5772156649015328606065120900824024310421593359399235988057672348848677267776646709369470632917467495},  /* Euler */
	const_'{"PHI",  1.6180339887498948482045868343656381177203091798057628621354486227052604628189024497072072041893911374},  /* golden ratio */
	const_'{"",  0.0}
};

typedef struct {		/* Builtins */
	string		name;
	shortint	nargs;
} bltin_;

static bltin_ builtin_tsks[] = {
	bltin_'{"rx", 2},
	bltin_'{"", 0}
};

static bltin_ builtin_fns[] = {
  bltin_'{"sin", 1},
  bltin_'{"cos", 1},
  bltin_'{"tan", 1},
  bltin_'{"asin", 1},
  bltin_'{"acos", 1},
  bltin_'{"atan", 1},
  bltin_'{"sinh", 1},
  bltin_'{"cosh", 1},
  bltin_'{"tanh", 1},
  bltin_'{"log", 1},
  bltin_'{"log10", 1},
  bltin_'{"exp", 1},
  bltin_'{"sqrt", 1},
  bltin_'{"abs", 1},
  bltin_'{"fabs", 1},
  bltin_'{"round", 1},
  bltin_'{"ceil", 1},
  bltin_'{"floor", 1},
  bltin_'{"length", 1},
  bltin_'{"pow", 2},
  bltin_'{"", 0}
};

function void init();	/* install constants and built-ins in table */
	int i;
	Symbol s;

	for (i = 0; keywords[i].name != ""; i++) begin
		s = new();
		s.name = keywords[i].name;
		s.type_ = keywords[i].kval;
		Process::globals[keywords[i].name] = s;
	end
	for (i = 0; consts[i].name != ""; i++) begin
		RealVal u = new();
		s = new();
		s.name = consts[i].name;
		s.type_ = `CONST;
		u.val = consts[i].cval;
		s.u = u;
		Process::globals[consts[i].name] = s;
	end
	for (i = 0; builtin_fns[i].name != ""; i++) begin
		FnDefn fn = new();
		s = new();
		s.name = builtin_fns[i].name;
		fn.nargs = builtin_fns[i].nargs;
		s.type_ = `BLTINFN;
		s.u = fn;
		Process::globals[builtin_fns[i].name] = s;
	end
	for (i = 0; builtin_tsks[i].name != ""; i++) begin
		FnDefn fn = new();
		s = new();
		s.name = builtin_tsks[i].name;
		fn.nargs = builtin_tsks[i].nargs;
		s.type_ = `BLTINTSK;
		s.u = fn;
		Process::globals[builtin_tsks[i].name] = s;
	end

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
