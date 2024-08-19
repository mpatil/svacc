// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab

typedef struct {		/* Keywords */
	string	name;
	int		kval;
} keywords_;

static keywords_ keywords[] = {
	'{"proc",		`PROC},
	'{"func",		`FUNC},
	'{"return",		`RETURN},
	'{"if",			`IF},
	'{"for",		`FOR},
	'{"else",		`ELSE},
	'{"while",		`WHILE},
	'{"break",		`BREAK},
	'{"vector",		`VECTOR},
	'{"case",		`CASE},
	'{"fork",		`FORK},
	'{"default",	`DEFAULT},
	'{"print",		`PRINT},
	'{"read",		`READ},
	'{"",			0}
};

typedef struct {		/* Constants */
	string	name;
	real	cval;
} const_;

static const_ consts[] = {
	'{"PI",	 3.14159265358979323846},
	'{"E",	 2.71828182845904523536},
	'{"GAMMA", 0.57721566490153286060},  /* Euler */
	'{"DEG",  57.29577951308232087680},  /* deg/radian */
	'{"PHI",  1.61803398874989484820},  /* golden ratio */
	'{"",  0.0}  
};

static string builtins[] = {
	"sin",
	"cos",
	"tan",
	"asin",
	"acos",
	"atan",
	"sinh",
	"cosh",
	"tanh",
	"log",
	"log10",
	"exp",
	"sqrt",
	"abs",
	"fabs",
	"round",
	"ceil",
	"floor",
	""
};

function void init();	/* install constants and built-ins in table */
	int i;
	Symbol s;

	for (i = 0; keywords[i].name != ""; i++) begin
		s = new();
		s.name = keywords[i].name;
		s.type_ = keywords[i].kval;
		s.u.val = 0.0;
		Process::symlist[keywords[i].name] = s;
	end
	for (i = 0; consts[i].name != ""; i++) begin
		s = new();
		s.name = consts[i].name;
		s.type_ = `VAR;
		s.u.val = consts[i].cval;
		Process::symlist[consts[i].name] = s;
	end
	for (i = 0; builtins[i] != ""; i++) begin
		s = new();
		s.name = builtins[i];
		s.type_ = `BLTIN;
		s.u.val = 0.0;
		Process::symlist[builtins[i]] = s;
	end
endfunction

static function real exec_bltin(Symbol fname, real val);
	case(fname.name)
		"sin"   : return sin(val);
		"cos"   : return cos(val);
		"tan"   : return tan(val);
		"asin"  : return asin(val);
		"acos"  : return acos(val);
		"atan"  : return atan(val);
		"sinh"  : return sinh(val);
		"cosh"  : return cosh(val);
		"tanh"  : return tanh(val);
		"exp"   : return exp(val);
		"abs"   : return abs(val);
		"fabs"  : return fabs(val);
		"log"   : return log(val);
		"log10" : return log10(val);
		"sqrt"  : return sqrt(val);
		"round" : return round(val);
		"ceil"  : return ceil(val);
		"floor" : return floor(val);
	endcase
endfunction

