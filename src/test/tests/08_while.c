func main() {
   a = 1;
   p = 0;
   t = 0;

   while (a < 100) {
      print a, "\n";
      t = a;
      a = t + p;
      p = t;
   }

   return 0;
}

// vim: set expandtab ts=4 sw=3 sts=3 tw=80 :
//
//

main();
