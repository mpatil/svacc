typedef struct {	/* symbol table entry */
	string 		name; /* Name */
	shortint	type_;	/* VAR, BLTIN, UNDEF */
	real		val;	/* if VAR */
} Symbol;

