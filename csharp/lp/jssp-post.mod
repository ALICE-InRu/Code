

minimize obj: z; 
/* the objective is to make z as small as possible */ 

solve; 

for {j in J}
{	
	printf("# "); 
	for {a in M} printf " %d", x[j,a]; 
	printf("\n"); 
} 
printf "# solution: %d\n", z;

