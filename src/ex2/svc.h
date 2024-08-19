// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab

`ifndef SVC__H
`define SVC__H

virtual class Val; /* value */
	virtual function string get_type ();
		get_type = "Bad Type";
	endfunction : get_type

endclass

class RealVal extends Val;
	real	val = 0.0;

	function string get_type ();
		get_type = "real";
	endfunction : get_type

endclass 

class StringVal extends Val;
	string	val = "";	/* STRING */

	function string get_type ();
		get_type = "string";
	endfunction : get_type
endclass 

class VectorVal extends Val;
	Val	vecs[$];	/* VECTOR */

	function string get_type ();
		get_type = "vector";
	endfunction : get_type
endclass 

class DictVal extends Val;
	Val	dict[string];	/* HASH */

	function string get_type ();
		get_type = "dict";
	endfunction : get_type
endclass 

`endif
