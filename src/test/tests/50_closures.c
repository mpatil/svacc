// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab

func main(a, b) {
	print "\n<----a = ", a, "---->\n";
	print "\n<----b = ", b, "---->\n";
	f = 2;
	func fn(x, j) {
		print "\n<----f = ", f, "---->\n";
		print "\n<----x = ", x, "---->\n";
		func f1(u) { print f, " ", x, " ", a, " ", j, "\n";  return f * x * a * u(j); }
		return f1;
	}
	c = fn(3, a);
	f = 5;
	print "\nX----f = ", f, "----X\n";
	aa = fn(b, f);
	return aa;
}

func f2(k) {return k * k;}

a = 10;
d = main(a, 2);
p = d(f2);
print p, " ";
p%a;
