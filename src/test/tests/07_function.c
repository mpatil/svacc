func myfunc(x) {
   print "x= ", x, "\n";
   return x * x;
}

proc vfunc(a) {
   print "a= ", a, "\n";
}

proc qfunc() {
   print "qfunc()\n";
}

func main() {
   print myfunc(3), "\n";
   print myfunc(4), "\n";

   vfunc(1234);

   qfunc();

   return 0;
}

// vim: set expandtab ts=4 sw=3 sts=3 tw=80 :

main();
