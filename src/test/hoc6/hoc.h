`define PRINT_MACHINE 1

class Symbol; 	/* symbol table entry */
	string 		name = ""; /* Name */
	shortint	type_;	/* VAR, BLTIN, UNDEF */
	shortint	defn = 0;
	real		val = 0.0;	/* if VAR */
	string		sval = "";	/* if VAR */
endclass

typedef struct {	/* Instructions */
	string 		ins; /* Instruction Name */
	Symbol 		sym; /* symbol: var or val*/
	shortint	ptr; /* location in stack */
	shortint	nargs; /* number of arguments */
	shortint	type_;	/* ICODE, OCODE, PCODE, NCODE */
} Inst;

typedef struct {   /* interpreter stack type */
	real		val;
	Symbol		sym;
} Datum;

