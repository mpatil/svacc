func factorial(i) {
   if (i < 2) {
      return i;
   } else {
      return factorial(i - 1) * i;
   }
}

func main() {
   for (Count = 1.0; Count <= 171.0; Count++) {
      print Count, " ", factorial(Count), "\n";
   }

   return 0;
}

/* vim: set expandtab ts=4 sw=3 sts=3 tw=80 :*/

main();
