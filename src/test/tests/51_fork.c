func main() {
   event w;
   i = 0;
   func f1(x, y) {
      print "\ncalled f1 : x ", x, " y ", y, " i  " , i, "\n";
      return x + i + y;
   }
   fork {
      print "fork 0";
      { @10; print "fork 1 : ", f1(i++, 1), " 1\n"; }
      { @140; print "fork 2 : ", f1(i++, 2), " 2   --->2\n"; ->w; }
      {
         a=1;
         if (a == 1) { print " 3\n"; }
         @2;
         print "fork 3 : ", f1(i++, 3), " 4\n";
         @3;
         print a, " 5\n";
         for (Count = 1; Count < 6; Count++) {
            case (Count) { 
               1: print 1, "\n";
               2: { print 2, "\n"; } 
               3: {  
                     print "hello "; 
                     @4;
                     case (1 == 1) { 
                        0: { print 22, " hello 1 \n";  @5 ; a = 0; a++ ; }
                        1: { print 33, " hello 2 \n";  @6; b = 1; b++ ; }
                        default: {d = 10; @7; print " ", 44, "\n"; d = d + 2; }
                     }
                  }
               4: print "return 1";
               5: print 1, "\n";
            }
         }
      }
      { @2; @w; print "fork 4 : ", f1(i++, 4), " 6   --->4\n";}
   }
   return 0;
}

// vim: set expandtab ts=4 sw=3 sts=3 tw=80 :
//
main();
