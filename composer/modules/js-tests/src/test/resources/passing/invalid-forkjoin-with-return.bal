
function invalidJoinResultType() (int) {
    int x = 10;
    fork {
	   worker w1 {
	     int a = 5;
	     int b = a + 1;
	     return 10;
	   }
	   worker w2 {
	     int a = 0;
	     int b = 15;
	   }
	} join (all) (map results) { }
	return x;
}