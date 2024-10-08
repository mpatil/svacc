// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab

typedef struct {		/* Keywords */
	string	name;
	int		kval;
} keywords_;

static keywords_ keywords[] = {
	keywords_'{"proc",	`PROC},
	keywords_'{"func",	`FUNC},
	keywords_'{"return",	`RETURN},
	keywords_'{"if",		`IF},
	keywords_'{"else",	`ELSE},
	keywords_'{"while",	`WHILE},
	keywords_'{"print",	`PRINT},
	keywords_'{"read",	`READ},
	keywords_'{"",		0}
};

typedef struct {		/* Constants */
	string	name;
	real	cval;
} const_;

static const_ consts[] = {
	const_'{"PI",	 3.14159265358979323846},
	const_'{"E",	 2.71828182845904523536},
	const_'{"GAMMA", 0.57721566490153286060},  /* Euler */
	const_'{"DEG",  57.29577951308232087680},  /* deg/radian */
	const_'{"PHI",  1.61803398874989484820},  /* golden ratio */
	const_'{"",  0.0}
};

static string builtins[] = {
	"sin",
	"cos",
	"atan",
	"log",
	"log10",
	"exp",
	"sqrt",
	"abs",
	"pow",
	""
};

function void init();	/* install constants and built-ins in table */
	int i;
	Symbol s;

	for (i = 0; keywords[i].name != ""; i++) begin
		s = new();
		s.name = keywords[i].name;
		s.type_ = keywords[i].kval;
		s.val = 0.0;
		symlist[keywords[i].name] = s;
	end
	for (i = 0; consts[i].name != ""; i++) begin
		s = new();
		s.name = consts[i].name;
		s.type_ = `VAR;
		s.val = consts[i].cval;
		symlist[consts[i].name] = s;
	end
	for (i = 0; builtins[i] != ""; i++) begin
		s = new();
		s.name = builtins[i];
		s.type_ = `BLTIN;
		s.val = 0.0;
		symlist[builtins[i]] = s;
	end
endfunction

function real exec_bltin(Symbol fname, real val);
	case(fname.name)
		"sin"   : return sin(val);
		"cos"   : return cos(val);
		"atan"  : return atan(val);
		"log"   : return log(val);
		"log10" : return log10(val);
		"exp"   : return exp(val);
		"sqrt"  : return sqrt(val);
		"abs"   : return abs(val);
	endcase
endfunction

