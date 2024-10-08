// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
`ifndef SVC__H
`define SVC__H

`define cast(lhs, rhs, err1, err2) if (!$cast(lhs, rhs)) execerror(err1, err2)
`define LINENOPP begin lineno_ = lineno; lineoff[lineno] = $ftell(file); lineno++; end
`define TOKENOFF begin tokenoff_ = tokenoff; tokenoff = $ftell(file); end
`define icode(x) Process::icode(x)
`define icode2(x, y) Process::icode(x, y)
`define ocode(x) Process::ocode(x)
`define ncode(x) Process::ncode(x)
`define pcode(x, y) Process::pcode((x), (y))
`define progp Process::progp

virtual class Symval; /* value of a symbol */
	bit isref = 0;
	virtual function string get_type ();
		get_type = "Bad Type";
	endfunction : get_type

	virtual function Symval copy ();
		copy = null;
	endfunction : copy

	virtual function Symval int_();
		int_ = null;
	endfunction : int_

	virtual function Symval real_();
		real_ = null;
	endfunction : real_
	
	virtual function bit eq(Symval rhs);
		eq = 0;
	endfunction : eq
endclass

class RealVal extends Symval;
	real	val = 0.0;

	function string get_type ();
		get_type = "real";
	endfunction : get_type

	function Symval copy ();
		RealVal v = new; 
		$cast(copy, v); 
		v.val = val;
	endfunction : copy

	virtual function Symval int_();
		val = integer'(val);   
		int_ = this;
	endfunction : int_

	virtual function Symval real_();
		real_ = this;
	endfunction : real_

	function bit eq(Symval rhs);
		RealVal u; 
		if(!$cast(u, rhs)) return 0; 
		eq = u.val == val;
	endfunction : eq
endclass 

class StringVal extends Symval;
	string	val = "";	/* STRING */

	function string get_type ();
		get_type = "string";
	endfunction : get_type

	function Symval copy ();
		StringVal v = new; 
		$cast(copy, v); 
		v.val = val;
	endfunction : copy

	function bit eq(Symval rhs);
		StringVal u; 
		if(!$cast(u, rhs)) return 0; 
		eq = u.val == val;
	endfunction : eq
endclass 

class VectorVal extends Symval;
	Symval	vecs[];	/* VECTOR */

	function VectorVal get_slice (int beg_ = 0, int end_ = 0);
		get_slice = new; 
		get_slice.vecs = new [end_ - beg_ + 1];
		assert(end_ >= beg_);
		for (int i = beg_; i <= end_; i++)
			get_slice.vecs[i] = vecs[i].copy();
	endfunction : get_slice

	function string get_type ();
		get_type = "vector";
	endfunction : get_type

	function Symval copy ();
		VectorVal v = new; 
		$cast(copy, v); 
		v.vecs = vecs;
	endfunction : copy

	function bit eq(Symval rhs);
		VectorVal u;
		if(!$cast(u, rhs)) return 0; 
		eq = 1;	
		foreach(vecs[i]) if(! vecs[i].eq(u.vecs[i])) return 0;
	endfunction : eq
endclass 

class DictVal extends Symval;
	Symval	dict[Symval];	/* HASH */

	function string get_type ();
		get_type = "dict";
	endfunction : get_type

	function Symval from_key (Symval key);
		Symval u;
		if ( dict.first(u) )
		do 
			if (u.eq(key)) return dict[u];
		while ( dict.next(u) );
	endfunction : from_key

	task set_val (Symval key, Symval val);
		Symval u;
		if ( dict.first(u) )
		do 
			if (u.eq(key)) begin dict[u] = val; return; end
		while ( dict.next(u) );
		dict[key] = val;
	endtask : set_val

	function Symval copy ();
		DictVal v = new; 
		$cast(copy, v); 
		v.dict = dict;
	endfunction : copy
endclass 

class EventVal extends Symval;
	event	ev;

	function string get_type ();
		get_type = "event";
	endfunction : get_type

	function Symval copy ();
		EventVal v = new; 
		$cast(copy, v); 
		v.ev = ev;
	endfunction : copy

	function bit eq(Symval rhs);
		EventVal u; 
		if(!$cast(u, rhs)) return 0; 
		eq = u.ev == ev;
	endfunction : eq
endclass 

class Symbol; 	/* symbol table entry */
	string 		name = ""; /* Name */
	shortint	type_;	/* VAR, BLTINFN, UNDEF, FUNCTION */
	Symval		u;

	function Symbol copy ();
		copy = new();
		copy.name = name;
		copy.type_ = type_;
		copy.u = u.copy();
	endfunction : copy
endclass

typedef Symbol		Symlist[string];

class Saveval;        /* saved value of a variable */
	Symval   u;
	shortint type_;

	function Saveval  copy ();
		copy = new();
		copy.type_ = type_;
		copy.u = u.copy();
	endfunction : copy
endclass

class Formal;	/* formal parameter */
	Symbol  sym;
	Saveval save[$];

	function Formal copy ();
		copy = new();
		copy.sym = sym.copy();
		copy.save = save;
	endfunction : copy
endclass 

typedef struct {	/* Instructions */
	string 		ins; /* Instruction Name */
	Symbol 		sym; /* symbol: var or val*/
	shortint	ptr; /* location in stack */
	shortint	nargs; /* number of arguments */
	shortint	type_;	/* ICODE, OCODE, PCODE, NCODE */
	shortint	tokenoff;
	string		arg1;
	string		arg2;
} Inst;

typedef Formal  Args[$];

class FnDefn extends Symval;
	shortint	code;
	Args		formals;	/* formal parameters */
	Symlist		symlist;	/* list of local vars */
	Symlist		sc;			/* static chain vars */
	Symbol		parent;
	int			nargs;

	function string get_type ();
		get_type = "function";
	endfunction : get_type

	function Symval copy ();
		FnDefn  v = new; 
		$cast(copy, v); 
		v.code = code;
		v.formals = formals;
		v.symlist = symlist;
		v.sc = sc;
		v.parent = parent;
		v.nargs = nargs;
	endfunction : copy
endclass 

typedef struct {		/* proc/func call stack frame */
	Symbol		sp;		/* symbol table entry */
	shortint	retpc;	/* where to resume after return */
	shortint	nargs;	/* number of arguments */
} Frame;

typedef struct {   /* interpreter stack type */
	Symval		u;
	Symbol		sym;
} Datum;

import "DPI-C" pure function real sin (real rTheta);
import "DPI-C" pure function real cos (real rTheta);
import "DPI-C" pure function real tan (real rTheta);
import "DPI-C" pure function real asin (real rTheta);
import "DPI-C" pure function real acos (real rTheta);
import "DPI-C" pure function real atan (real rTheta);
import "DPI-C" pure function real sinh (real rTheta);
import "DPI-C" pure function real cosh (real rTheta);
import "DPI-C" pure function real tanh (real rTheta);
import "DPI-C" pure function real exp (real rVal);
import "DPI-C" pure function real abs (real rVal);
import "DPI-C" pure function real fabs (real rVal);
import "DPI-C" pure function real log (real rVal);
import "DPI-C" pure function real log10 (real rVal);
import "DPI-C" pure function real pow (real rVal1, real rVal2);
import "DPI-C" pure function real sqrt (real rVal);
import "DPI-C" pure function real round (real rVal);
import "DPI-C" pure function real ceil (real rVal);
import "DPI-C" pure function real floor (real rVal);
`endif
