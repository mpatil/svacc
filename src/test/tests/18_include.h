event w;
vector a[5];
dict b;
dict c = { "a": 12 , "b": {"a" : {"c" : 2}}}  ;
dict d = { "a":1, "b": 2, "c":  3, "d" : 44 }  ;
b[1200] = "s"  ;
e = &d  ;


print "d[\"c\"] = ", d["c"], "\n"  ;
print "c[\"a\"] = ", c["a"], "\n"  ;
print "e[\"b\"] = ", e["b"], "\n"  ;
print "e = ", e, "\n"  ;
print "b = ", b, "\n"  ;
print "c[\"b\"] = ", c["b"], "\n"  ;
print "c = ", c["b"]["a"]["c"], "\n"  ;

proc pp(k, l) {
	for (i = 0; i < k; i++) {
		a[i] = -1   ;// this is a comment	
	}
	for (j = k; j < l; j++) {
		a[j] = j	  ;
	}
	for (m = l; m < 5; m++) {
		a[m] = 10	  ;
	}
}

print "my_opt = ", my_opt, "\n"  ;
my_opt = 2  ;

->w;

pp(1 * 1 /1, 3 / 1 * 1)  ;

for (j = 0; j < length(a); j++) {
	print  "a[",j, "]   ", j * a[j],  "\n"  ;
}

