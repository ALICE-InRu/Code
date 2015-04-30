using System.Collections.Generic;
using Gurobi;

namespace ALICE
{
    /// <summary>
    /// Summary description for JobShop
    /// </summary>
    public class ProblemInstance
    {
        public readonly int NumJobs;
        public readonly int NumMachines;
        public readonly int[,] Sigma;
        public readonly int[,] Procs;
        public readonly int Dimension;

        public ProblemInstance(int numJobs, int numMachines, int[] processingTimes, int[] permutationMatrix)
        {
            NumJobs = numJobs;
            NumMachines = numMachines;
            Dimension = numJobs * numMachines;
            Procs = Array2Matrix(processingTimes);
            Sigma = Array2Matrix(permutationMatrix);
        }

        public int[,] Array2Matrix(int[] array)
        {
            int[,] matrix = new int[NumJobs, NumMachines];
            for (int job = 0; job < NumJobs; job++)
            {
                for (int mac = 0; mac < NumMachines; mac++)
                    matrix[job, mac] = array[job * NumMachines + mac];
            }
            return matrix;
        }

        // sequence is a list of <job,mac,starttime>        
        public int[,] Optimize(string folder, string solver, string name, out int optMakespan, out bool success,
            out int simplexIterations, int tmlim = 6000, List<Schedule.Dispatch> constraints = null)
        {
            GurobiJspModel model = new GurobiJspModel(this, name, tmlim);
            var xTimeJob = constraints != null
                ? model.Lookahead(constraints, out optMakespan)
                : model.Optimise(out optMakespan);
            simplexIterations = model.SimplexIterations;
            success = model.Status == GRB.Status.OPTIMAL;
            model.Dispose();
            return xTimeJob;
        }
    }
}