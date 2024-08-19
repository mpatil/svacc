func main() {
   for (Count = 0; Count < 6; Count++) {
      print "Count: ", Count, "\n";
      case (Count) { 
         1: print 1, "\n";
         2: { print 2, "\n"; } 
         3: { print "hello "; 
              case (1 == 0) { 
                0: { print 22, " hello 1 \n";  a = 0; a++ ; }
                1: { print 33, " hello 2 \n";  b = 1; b++ ; }
                default: {d = 10; print " ", 44, "\n"; d = d + 2; }
              }
            }
         4: return 1;
         5: print 1, "\n";
      }
   }
   return 0;
}
// vim: set expandtab ts=4 sw=3 sts=3 tw=80 :

main();
