a = 42;                                 // variable a defined with assignment of a value of the number 42.

b = "mystring";                         // variable b defined with assignment of a value of the string "mystring".

 

vector Array[10];                       // array declaration of size limited to 10 elements

Array[9] = 33;                          // assign the value of 33 to the 10th element of the array declared above.

vector Array1[10] = { 12, 34, 78, 90};   // declaration and assignment of values to elements

vector Array2[] = {0, 1, 2, 3};          // Array size implicitly declared using the assignment

 

dict c;                                   // declaration of a dictionary

dict d = { "a":1, "b":2, "c":3, "d":44 }; // assignment of (key : value) pair elements to the dictionary 

 

dict p = { 12 : 12, 13: {"a" : {10 : 2}}}; // assigning compound values in dictionary

x = p[13]["a"][10];                        // accessing values from compound elements using the subscript notation []

 

vector Array3[] = { 122, {1223, {1:4526}, 2111}, "myvector"}; // assigning compound values as elements of an array

 
for (Count = 1; Count <= 10; Count++) {

      Array[Count-1] = Count * Count;

}

myvar = 2;

case (myvar) { 

         1: print 1, "\n";

         2: { print 2, "\n"; }

         3: { print "hello "; }

         default: print "default\n";

}

 

a = 1;

while (a < 100) {

      print a, "\n";

      a++;

 }

 

if (a) {

      print "a is true\n";

} else {

      print "a is false\n";

}

func factorial(i) {

   if (i < 2) {

      return i;

   } else {

      return factorial(i - 1) * i;

   } 

}

func main() {
   factorial(100);

   return 0;
}

vector v[] = {0, 1, 2, 3};

 

func f2(k) {return k * k;}

 

func map(f, t) { // map takes the parameters: a function and an array of numbers.
    vector w[4];
    for (i=0; i< length(t); i++) { w[i] = f(t[i]); }
    return w;
}

 

w1 = map(f2, v);

 


 

event w;

fork {

      print "fork 0\n";

      { @10; print "fork 1 \n"; } // #10 means wait for 10 units of simulation time

      { @140;  ->w; }             // trigger the event w

      { @w; print "fork 4\n";}    // wait for event w to be triggered

}

