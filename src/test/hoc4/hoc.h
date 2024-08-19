typedef struct {	/* symbol table entry */
	string 		name; /* Name */
	shortint	type_;	/* VAR, BLTIN, UNDEF */
	real		val;	/* if VAR */
} Symbol;

typedef struct {	/* Instructions */
	string 		ins; /* Instruction Name */
	Symbol 		sym; /* symbol: var or val*/
} Inst;

typedef struct {   /* interpreter stack type */
	real		val;
	Symbol		sym;
} Datum;

