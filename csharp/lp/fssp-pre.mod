/* Permutation Flow Shop Problem : WAGNER */
param n;
param m;
set M := 1 ..m;
set J := 1 ..n;
param p{j in J,r in M}, >= 0;
var x{j in J, r in M}, >= 0;
var Y{r in M, j in J}, >= 0;
var Z{i in J, j in J}, binary;
s.t. ASSIGN1 {i in J}: sum {j in J} Z[i,j] = 1;
s.t. ASSIGN2 {j in J}: sum {i in J} Z[i,j] = 1;
s.t. JAML1 {r in 1 ..m-1,j in 1 ..n-1}: sum {i in J}p[i,r]*Z[i,j+1] - sum {i in J} p[i,r+1]*Z[i,j] + x[j+1,r] - x[j+1,r+1] + Y[r,j+1] - Y[r,j] = 0;
s.t. JAML2 {r in 1 ..m-1}: sum {i in J}(p[i,r]*Z[i ,1]) + x[1,r] - x[1,r+1] + Y[r ,1] = 0;
