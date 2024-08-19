typedef class Fndefn;

typedef struct { /* value of a symbol */
	real		val = 0.0;	/* VAR */
	Fndefn		defn;		/* FUNCTION, PROCEDURE */
	string		sval = "";	/* STRING */
	shortint	vec = -1;	/* VECTOR */
} Symval;

function string symval_nice_string (Symval s, string prefix = "", string prefix_ = "");
	symval_nice_string = {prefix_, prefix};
	if (s.defn != null)
		symval_nice_string = {symval_nice_string, prefix_, s.defn.nice_string ("Function Definition\n", prefix_)};
	if (s.sval != "")
		symval_nice_string = {symval_nice_string, prefix_, $psprintf ("String Val: %s\n", s.sval)};
	if (s.val != 0.0)
		symval_nice_string = {symval_nice_string, prefix_, $psprintf ("Real Val: %f\n", s.val)};
	if (s.vec != -1)
		symval_nice_string = {symval_nice_string, prefix_, $psprintf ("Vector: @%0d\n", s.vec)};
endfunction

class Symbol; 	/* symbol table entry */
	string 		name = ""; /* Name */
	shortint	type_;	/* VAR, BLTIN, UNDEF */
	Symval		u;

	function string nice_string (string prefix = "", string prefix_ = "");
		nice_string = {prefix_, prefix};
		nice_string = {nice_string, prefix_, $psprintf("name: %s\n", name)};
		nice_string = {nice_string, prefix_, $psprintf("type: %0d\n", type_)};
		nice_string = {nice_string, prefix_, symval_nice_string(u, "Symbol Value:\n", prefix_)};
	endfunction : nice_string

	task copy (ref Symbol s);
		s.name = name; 
		s.type_ = type_;
		s.u = u;
	endtask	
endclass

class Saveval;        /* saved value of variable */
	Symval   u;
	shortint type_;

	function string nice_string (string prefix = "", string prefix_ = "");
		nice_string = {prefix_, prefix};
		nice_string = {nice_string, prefix_, $psprintf("type: %0d\n", type_)};
		nice_string = {nice_string, prefix_, symval_nice_string(u, "Symbol Value:\n", prefix_)};
	endfunction : nice_string
endclass

class Formal; /* formal parameter */
	Symbol  sym;
	Saveval save[$];

	function string nice_string (string prefix = "", string prefix_ = "");
		nice_string = {prefix_, prefix};
		nice_string = {nice_string, prefix_, sym.nice_string("Symbol:\n", prefix_)};
		if (save.size()) begin
			nice_string = {nice_string, prefix_, $psprintf("Saved Values: \n", prefix_)};
			foreach (save[i]) begin
				nice_string = {nice_string, prefix_, save[i].nice_string($psprintf("\t[%0d] ", i), prefix_)};
		end
		end
	endfunction : nice_string
endclass 

typedef struct {	/* Instructions */
	string 		ins; /* Instruction Name */
	Symbol 		sym; /* symbol: var or val*/
	shortint	ptr; /* location in stack */
	shortint	nargs; /* number of arguments */
	shortint	type_;	/* ICODE, OCODE, PCODE, NCODE */
} Inst;

typedef Formal  Args[$];

class Fndefn; /* formal parameters */
	shortint	code;
	Args		formals;
	int		nargs;

	function string nice_string (string prefix = "", string prefix_ = "");
		nice_string = {prefix_, prefix};
		nice_string = {nice_string, prefix_, $psprintf("code: %0d\n", code)};
		nice_string = {nice_string, prefix_, $psprintf("nargs: %0d\n", nargs)};
		if (formals.size()) begin
			nice_string = {nice_string, prefix_, $psprintf("Formals: \n")};
			foreach (formals[i]) begin
				nice_string = {nice_string, prefix_, formals[i].nice_string($psprintf("\t[%0d] ", i, prefix_))};
			end
		end
	endfunction : nice_string

endclass 

typedef struct {		/* proc/func call stack frame */
	Symbol		sp;		/* symbol table entry */
	shortint	retpc;	/* where to resume after return */
	shortint	argn;	/* n-th argument on stack */
	shortint	nargs;	/* number of arguments */
} Frame;

typedef struct {   /* interpreter stack type */
	real		val;
	Symbol		sym;
} Datum;

