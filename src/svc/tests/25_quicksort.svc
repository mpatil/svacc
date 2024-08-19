vector array[16];

//Swap integer values by array indexes
proc swap(a, b) {
   tmp  = array[a];
   array[a] = array[b];
   array[b] = tmp;
}

//Partition the array into two halves and return the
//index about which the array is partitioned
func  partition(left, right) {
   pivotIndex = left;
   pivotValue = array[pivotIndex];
   index = left;

   swap(pivotIndex, right);
   for(i = left; i < right; i++) {
      if(array[i] < pivotValue) {
         swap(i, index);
         index += 1;
      }
   }
   swap(right, index);

   return index;
}

//Quicksort the array
proc  quicksort(left, right) {
   if(left >= right) {
      return;
   }

   index = partition(left, right);
   quicksort(left, index - 1);
   quicksort(index + 1, right);
}

func  main() {

   array[0] = 62;
   array[1] = 83;
   array[2] = 4;
   array[3] = 89;
   array[4] = 36;
   array[5] = 21;
   array[6] = 74;
   array[7] = 37;
   array[8] = 65;
   array[9] = 33;
   array[10] = 96;
   array[11] = 38;
   array[12] = 53;
   array[13] = 16;
   array[14] = 74;
   array[15] = 55;

   for (i = 0; i < 16; i++) {
      print array[i], " ";
   }

   print "\n";

   quicksort(0, 15);

   for (i = 0; i < 16; i++) {
      print array[i], " ";
   }

   print "\n";

   return 0;
}

/* vim: set expandtab ts=4 sw=3 sts=3 tw=80 :*/

main();
