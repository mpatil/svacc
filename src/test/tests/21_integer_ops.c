func main() {
   // variables
   print "a=1", "\t\t\t\t\t";
   a = 1;
   print a, "\n";

   print "a+=1", "\t\t\t\t\t";
   a+=1;
   print a, "\n";

   print "a-=1", "\t\t\t\t\t";
   a-=1;
   print a, "\n";

   print "a*=2", "\t\t\t\t\t";
   a*=2;
   print a, "\n";

   print "a/=2", "\t\t\t\t\t";
   a/=2;
   print a, "\n";

   print "a|=0xaaaa5555", "\t\t\t\t";
   a|=0xaaaa5555;
   print a, "\n";

   print "a&=0x5555aaaa", "\t\t\t\t";
   a&=0x5555aaaa;
   print a, "\n";

   print "a^=0x5a5a5a5a", "\t\t\t\t";
   a^=0x5a5a5a5a;
   print a, "\n";

   print "a<<=4", "\t\t\t\t\t";
   a<<=4;
   print a, "\n";

   print "a>>=4", "\t\t\t\t\t";
   a>>=4;
   print a, "\n";

   print "a < 2 ? a + 10 : a - 1 =", "\t\t", a < 2 ? a + 10 : a - 1, "\n";
   print "a > 2 ? a + 10 : a - 1 =", "\t\t", a > 2 ? a + 10 : a - 1, "\n";

   // infix operators
   print "8 << 2", "\t\t\t\t\t", 8 << 2, "\n";
   print "8 >> 2", "\t\t\t\t\t", 8 >> 2, "\n";

   // comparison operators

   // assignment operators

   // prefix operators

   return 0;
}

/* vim: set expandtab ts=4 sw=3 sts=3 tw=80 :*/

main();
