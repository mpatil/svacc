func main() {

   a = 42;
   print a, "\n";
   print " a = ", a, "\n";

   b = 64;
   print b, "\n";
   print " b = ", b, "\n";
   a = b++;
   print " b = ", b, " a = ", a, "\n";
   b += 33;
   print " b = ", b, "\n";
   b *= 33;
   print " b = ", b, "\n";

   c = 12; d = 34;
   print c, " ", d, "\n";

   return 0;
}

// vim: set expandtab ts=4 sw=3 sts=3 tw=80 :

main();
