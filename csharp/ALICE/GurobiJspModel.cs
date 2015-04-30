/* Copyleft 2015, Helga Ingimundardottir. */

/* Optimise job shop scheduling problem, 
 * where you can add (and remove) lookahead constraints 
 * and commit constraints to the existing model
 * meant for correct 'labelling' when following 
 * a certain trajectory through the state space */

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Gurobi;

namespace ALICE
{
    public class GurobiJspModel
    {
        public readonly int TrueOptimum;
        public readonly int[,] TrueOptimumDecVars;
        public int SimplexIterations { get; private set; }
        public int Status { get; private set; }
        public string Info { get; private set; }
        private readonly GRBEnv _env;
        private readonly GRBModel _model;
        private readonly string _fileName;
        private readonly int _n; // num jobs
        private readonly int _m; // num machines
        private GRBVar[,] _x; // starting time of job j on machine a 

        public int NumConstraints
        {
            get { return _model.GetConstrs().Count(); }
        }

        public GurobiJspModel(ProblemInstance prob, string name, int tmlim = -1,
            bool optimise = false)
        {
            _n = prob.NumJobs;
            _m = prob.NumMachines;
            Info = "Starting gurobi optimisation";
            TrueOptimum = -1;
            _fileName = String.Format("jssp.{0}.log", name);

            // Model
            _env = new GRBEnv(_fileName);
            if (tmlim > 0)
                _env.Set(GRB.DoubleParam.TimeLimit, tmlim);
            _env.Set(GRB.IntParam.LogToConsole, 0);

            _model = new GRBModel(_env);
            _model.Set(GRB.StringAttr.ModelName, "jsp");

            DecisionVariables();
            ProcessingOrder(prob.Procs, prob.Sigma);
            DisjunctiveCondition(prob.Procs);
            Objective(prob.Procs, prob.Sigma);

            if (!optimise) return;
            TrueOptimumDecVars = Optimise(out TrueOptimum);
            //if (TrueOptimum > 0) // Objective cutoff
            //    _model.GetEnv().Set(GRB.DoubleParam.Cutoff, TrueOptimum + 0.5);
            /* Indicates that you aren't interested in solutions whose objective values 
                 * are worse than the specified value. If the objective value for the optimal 
                 * solution is better than the specified cutoff, the solver will return the 
                 * optimal solution. Otherwise, it will terminate with a CUTOFF status.
                 */
            // seems to be only for LP relaxation, not MIP objective
        }

        public void UpdateTimeLimit(int sec)
        {
            _env.Set(GRB.DoubleParam.TimeLimit, sec);
        }

        public int[,] Optimise(out int optimum)
        {
            SimplexIterations = -1;

            // Optimize
            _model.Optimize();
            Status = _model.Get(GRB.IntAttr.Status);

            switch (Status)
            {
                case GRB.Status.UNBOUNDED:
                    Info = "The model cannot be solved because it is unbounded";
                    optimum = -1;
                    return null;
                case GRB.Status.OPTIMAL:
                case GRB.Status.TIME_LIMIT:
                case GRB.Status.CUTOFF:
                    double doubleOptimum = _model.Get(GRB.DoubleAttr.ObjVal);
                    Info = "The optimal objective is " + doubleOptimum;
                    SimplexIterations = GRB.Callback.MIP_ITRCNT; // Current simplex iteration count.
                    int[,] vars = new int[_n, _m];
                    for (int j = 0; j < _n; j++)
                    {
                        for (int a = 0; a < _m; a++)
                            vars[j, a] =
                                (int) _model.GetVarByName(String.Format("x[{0},{1}]", j, a)).Get(GRB.DoubleAttr.X);
                    }
                    optimum = (int) Math.Round(doubleOptimum, 0);
                    return vars;
                default:
                    if ((Status != GRB.Status.INF_OR_UNBD) &&
                        (Status != GRB.Status.INFEASIBLE))
                    {
                        Info = "Optimization was stopped with status " + Status;
                    }
                    else
                    {
                        // Do IIS
                        _model.ComputeIIS();
                        Info =
                            _model.GetConstrs()
                                .Where(c => c.Get(GRB.IntAttr.IISConstr) == 1)
                                .Aggregate(
                                    "The model is infeasible;\nThe following constraint(s) cannot be satisfied:",
                                    (current, c) => current + c.Get(GRB.StringAttr.ConstrName));
                    }
                    optimum = -1;
                    return null;
            }
        }

        private void DecisionVariables()
        {
            /* Since an assignment model always produces integer
                 * solutions, we use continuous variables and solve as an LP. */
            _x = new GRBVar[_n, _m];
            for (int j = 0; j < _n; ++j)
            {
                for (int a = 0; a < _m; ++a)
                {
                    _x[j, a] =
                        _model.AddVar(0, GRB.INFINITY, 0, GRB.CONTINUOUS,
                            String.Format("x[{0},{1}]", j, a));
                }
            }
            // Update model to integrate new variables
            _model.Update();
        }

        private void ProcessingOrder(int[,] p, int[,] sigma)
        {
            /* s.t. ord{j in J, t in 2..m}: 
                 *      x[j, sigma[j,t]] >= x[j, sigma[j,t-1]] + p[j, sigma[j,t-1]]; 
                 * j can be processed on sigma[j,t] only after it has been completely 
                 * processed on sigma[j,t-1] */
            for (int j = 0; j < _n; j++)
            {
                for (int t = 1; t < _m; t++)
                {
                    _model.AddConstr(_x[j, sigma[j, t]] >= _x[j, sigma[j, t - 1]] + p[j, sigma[j, t - 1]],
                        String.Format("ord[{0},{1}]", j, t));
                }
            }
        }

        private void DisjunctiveCondition(int[,] p)
        {
            /* The disjunctive condition that each machine can handle at most one 
                 * job at a time is the following: 
                 *      x[i,a] >= x[j,a] + p[j,a]  or  x[j,a] >= x[i,a] + p[i,a] 
                 * for all i, j in J, a in M. This condition is modeled through binary variables y 
                 * var y{i in J, j in J, a in M}, binary; 
                 * y[i,j,a] is 1 if i scheduled before j on machine a, and 0 if j is 
                 * scheduled before i */
            GRBVar[,,] y = new GRBVar[_n, _n, _m];
            for (int j = 0; j < _n; j++)
            {
                for (int i = 0; i < _n; i++)
                {
                    for (int a = 0; a < _m; a++)
                    {
                        y[i, j, a] = _model.AddVar(0, 1, 0, GRB.BINARY, String.Format("y[{0},{1},{2}]", i, j, a));
                    }
                }
            }
            // Update model to integrate new variables
            _model.Update();

            int k = 0; /* some large constant */
            for (int j = 0; j < _n; j++) for (int a = 0; a < _m; a++) k += p[j, a];

            /* s.t. phi{i in J, j in J, a in M: i <> j}: 
                 *      x[i,a] >= x[j,a] + p[j,a] - K * y[i,j,a]; 
                 * <=>  x[i,a] >= x[j,a] + p[j,a] iff y[i,j,a] is 0 */
            for (int i = 0; i < _n; i++)
            {
                for (int j = 0; j < _n; j++)
                {
                    if (i == j) continue;
                    for (int a = 0; a < _m; a++)
                    {
                        _model.AddConstr(_x[i, a] >= _x[j, a] + p[j, a] - k*y[i, j, a],
                            String.Format("phi[{0},{1},{2}]", i, j, a));
                    }
                }
            }

            /* s.t. psi{i in J, j in J, a in M: i <> j}: 
                 *      x[j,a] >= x[i,a] + p[i,a] - K * (1 - y[i,j,a]); 
                 * <=>  x[j,a] >= x[i,a] + p[i,a] iff y[i,j,a] is 1 */
            for (int i = 0; i < _n; i++)
            {
                for (int j = 0; j < _n; j++)
                {
                    if (i == j) continue;
                    for (int a = 0; a < _m; a++)
                    {
                        _model.AddConstr(_x[j, a] >= _x[i, a] + p[i, a] - k*(1 - y[i, j, a]),
                            String.Format("psi[{0},{1},{2}]", i, j, a));
                    }
                }
            }
        }

        private void Objective(int[,] p, int[,] sigma)
        {
            /* var z; -- so-called makespan */
            GRBVar z = _model.AddVar(0.0, GRB.INFINITY, 1, GRB.CONTINUOUS, "makespan");
            // Update model to integrate new variables
            _model.Update();

            // The objective is to minimize the total makespan
            GRBQuadExpr obj = z;
            _model.SetObjective(obj);
            _model.Set(GRB.IntAttr.ModelSense, 1);

            /* s.t. fin{j in J}: z >= x[j, sigma[j,m]] + p[j, sigma[j,m]]; 
                 * which is the maximum of the completion times of all the jobs */
            for (int j = 0; j < _n; j++)
            {
                _model.AddConstr(z >= _x[j, sigma[j, _m - 1]] + p[j, sigma[j, _m - 1]],
                    String.Format("fin[{0}]", j));
            }
        }

        public void CommitConstraint(Schedule.Dispatch dispatch, int step)
        {
            _model.AddConstr(_x[dispatch.Job, dispatch.Mac] == dispatch.StartTime,
                String.Format("Step{0}.{1}", step, dispatch.Name));
        }

        public int[,] Lookahead(Schedule.Dispatch dispatch, out int optimum)
        {
            return Lookahead(new List<Schedule.Dispatch> {dispatch}, out optimum);
        }

        public int[,] Lookahead(List<Schedule.Dispatch> dispatchs, out int optimum)
        {
            foreach (var dispatch in dispatchs)
            {
                _model.AddConstr(_x[dispatch.Job, dispatch.Mac] == dispatch.StartTime, dispatch.Name);
            }

            int[,] resultingTimes = Optimise(out optimum);

            foreach (
                GRBConstr c in
                    dispatchs.SelectMany(
                        dispatch => _model.GetConstrs().Where(c => c.Get(GRB.StringAttr.ConstrName) == dispatch.Name)))
                _model.Remove(c);

            return resultingTimes;
        }

        public void Dispose()
        {
            // Dispose of model and env
            _model.Dispose();
            _env.Dispose();

            // Get rid of log file
            FileInfo file = new FileInfo(_fileName);
            if (file.Exists)
                file.Delete();
        }
    }
}