// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab

vector v[] = {0, 1, 2, 3};

func f2(k) {return k * k;}

func map(f, t) {
	vector w[4];
	for (i=0; i< length(w); i++) { w[i] = f(t[i]); }
	return w;
}

print "v=", v, "\n";
q = map(f2, v);
print "q=", q, "\n";

for ( j = 0; j < length(v); j++) { print "q[", j, "] " , q[j], "\n";}
