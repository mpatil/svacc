func main() {

   vector Array0[20];
   vector Array[10] = { 12, 34, 56, 78, 90, 123, 456, 789, 8642, 9753 };
   vector Array1[] = { 122, 324, 256, {782, 290, {1223, {1 : 4526}}, 2111}, "myvector", 28642, 92753, 121, 222, 3113, 4432, 3223 };

   for (Count = 0; Count < 10; Count++) {
      Array0[Count] = Array[Count];
      print Count, ": ", Array[Count], "\n";
   }

   vector Array2[10] = { 12, 34, 56, 78, 90, 123, 456, 789, 8642, 9753 };

   for (Count = 0; Count < 10; Count++) {
      Array0[Count + 10] = Array1[Count];
      print Count, ": ", Array2[Count], "\n";
   }

   for (Count = 0; Count < 20; Count++) {
      print Count, ": ", Array0[Count], "\n";
   }

   print "Array0[2:3] ", Array0[2:3], "\nlength Array0 ", length(Array0), "\n";

   return 0;
}

/* vim: set expandtab ts=4 sw=3 sts=3 tw=80 :*/

main();
