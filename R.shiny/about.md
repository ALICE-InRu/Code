Random and structured benchmarks in ALICE are obtained using the [generator](http://www.cs.colostate.edu/sched/generator/) by J-P Watson. 
Moreover, problems are solved to optimality using [Gurobi](http://www.gurobi.com/),  a state-of-the-art solver for linear programming, with a free academic licence.

### Dimensions
* **6x5** - 6 jobs, 5 machines
* **10x10** - 10 jobs, 10 machines

### Job Shop Problems
with random machine order are the following, 
* **j.rnd** - random
* **j.rndn** - random narrow

### Flow Shop Problems
with homogeneous machine order are the following, 
* **f.rnd** - random
* **f.rndn** - random narrow
* **f.jc** - job correlation
* **f.mc** - machine correlation
* **f.mxc** - mixed correlation
