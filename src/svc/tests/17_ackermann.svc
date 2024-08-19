
n=0;

func ack(a, b) {
	n = n + 1;
	if(a == 0) { return (b + 1); }
	if(b == 0) { return (ack(a - 1, 1)); }
	return (ack(a - 1, ack(a, b - 1)));
}


print ack(2,1), "\n";
print ack(3,3), "\n";
print ack(3,5), "\n";

i = 0;

print n, "\tcalls\n";
