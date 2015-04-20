using System;
using System.Collections.Generic;
using System.Data;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Interop;
using System.Windows.Media.Imaging;
using auxiliaryFunctions;
using Gurobi;

// for glpk

namespace Scheduling
{
    

    public enum FeatureType
    {
        None = 0,
        Local = 1,
        Global = 2
    };

    public class Data : DataTable
    {
        public readonly char ShopProblem; // jsp or fsp
        public readonly string Name;
        public readonly string Dimension;
        public readonly string Set; // test or train
        public int NumInstances;

        public Data(string name, char shopProblem, string dimension, string set)
        {
            Name = name;
            ShopProblem = shopProblem;
            Dimension = dimension;
            Set = set.ToLower();

            Columns.Add("Name", typeof (string)); // unique!
            Columns.Add("Shop", typeof (char));
            Columns.Add("Distribution", typeof (string));
            Columns.Add("Problem", typeof (ProblemInstance));
            Columns.Add("Dimension", typeof (int));
            Columns.Add("Set", typeof (string)); // test or train
            Columns.Add("PID", typeof (int)); // problem instance Index
            Columns.Add("NumJobs", typeof (int));
            Columns.Add("NumMachines", typeof (int));
            Columns.Add("Makespan", typeof (int));
            Columns.Add("SDR", typeof (string));
            Columns.Add("Heuristic", typeof (string));
            Columns.Add("Solver", typeof (string));
            Columns.Add("Solved", typeof (string)); // either Opt (optimum) or BKS (best known solution)
            Columns.Add("Solution", typeof (int[][])); // solution of schedule corresponding to makespan
            Columns.Add("Simplex", typeof (int)); // number of simplex iterations
            Columns.Add("Rho", typeof (double));
            Columns.Add("Note", typeof (string));
            PrimaryKey = new[] {Columns["Name"]};
        }

        public void AddProblem(ProblemInstance prob, string distribution, char shopProblem, string note = "",
            int id = -1)
        {
            NumInstances++;
            if (id < 0) id = NumInstances;

            string dim = String.Format("{0}x{1}", prob.NumJobs, prob.NumMachines);
            string name = String.Format("{0}.{1}.{2}.{3}.{4}", shopProblem, distribution, dim, Set, id);
            DataRow row = NewRow();
            row["Name"] = name.ToLower();
            row["Shop"] = shopProblem;
            row["PID"] = id;
            row["Distribution"] = distribution;
            row["Problem"] = prob;
            row["Dimension"] = prob.NumJobs*prob.NumMachines;
            row["Set"] = Set;
            row["NumJobs"] = prob.NumJobs;
            row["NumMachines"] = prob.NumMachines;
            row["Note"] = note;
            row["Solver"] = string.Empty;
            row["Solved"] = string.Empty;
            row["Simplex"] = int.MinValue;
            row["Makespan"] = int.MinValue;
            row["Rho"] = double.MinValue;
            Rows.Add(row);
        }

        public void AddHeuristicMakespan(string name, int makespan, int optMakespan, string heuristic,
            string columnName = "Heuristic")
        {
            DataRow row = Rows.Find(name);

            row.SetField("Makespan", makespan);
            row.SetField(columnName, heuristic);

            double rho = AuxFun.RhoMeasure(optMakespan, makespan);

            row.SetField("Rho", rho);
        }

        public void AddOptMakespan(string name, int makespan, bool optimum, int[,] xTimeJob, int simplexIterations,
            string solver)
        {
            DataRow row = Rows.Find(name);
            row.SetField("Makespan", makespan);
            row.SetField("Solved", optimum ? "opt" : "bks");
            row.SetField("Solution", xTimeJob);
            row.SetField("Solver", solver);
            row.SetField("Simplex", simplexIterations);
        }

        public void WriteCsvHeuristic(FileInfo file)
        {
            List<string> write = new List<string>()
            {
                "Name",
                "Shop",
                "Distribution",
                "Set",
                "PID",
                "NumJobs",
                "NumMachines",
                "Dimension",
                "Makespan"
            }; //, "Heuristic", "Rho"};
            AuxFun.WriteDataTable2Csv(file, this, write, FileMode.Create, FeatureType.None);
        }

        public void WriteCsvSDR(string sdr, string directory)
        {
            FileInfo file = new FileInfo(String.Format("{0}{1}.{2}.csv", directory, Name, sdr));
            List<string> write = new List<string>()
            {
                "Name",
                "Shop",
                "Distribution",
                "Set",
                "PID",
                "NumJobs",
                "NumMachines",
                "Dimension",
                "Makespan",
                "SDR",
                "Rho"
            };
            AuxFun.WriteDataTable2Csv(file, this, write, FileMode.Append, FeatureType.None);
        }

        public void WriteCsvOpt(string directory)
        {
            FileInfo file = new FileInfo(String.Format("{0}opt.{1}.csv", directory, Name));
            List<string> write = new List<string>()
            {
                "Name",
                "Shop",
                "Distribution",
                "Set",
                "PID",
                "NumJobs",
                "NumMachines",
                "Dimension",
                "Makespan",
                "Solved",
                "Solver",
                "Simplex"
            };
            AuxFun.WriteDataTable2Csv(file, this, write, FileMode.Append, FeatureType.None);
        }

        public bool ReadCsvOpt(string directory)
        {
            string fname = String.Format("opt.{0}.csv", Name);
            List<string[]> contents = AuxFun.ReadCsv2DataTable(directory + fname);
            if (contents == null)
            {
                return false;
            }

            List<string> header = contents[0].ToList();
            contents.RemoveAt(0);
            int name = header.FindIndex(x => x == "Name");
            int ms = header.FindIndex(x => x == "Makespan");
            int solved = header.FindIndex(x => x == "Solved");
            int solver = header.FindIndex(x => x == "Solver");
            int simplex = header.FindIndex(x => x == "Simplex");

            foreach (string[] content in contents)
            {
                DataRow row = Rows.Find(content[name]);
                if (row == null) continue;
                row["Makespan"] = content[ms];
                row["Solved"] = content[solved];
                row["Solver"] = content[solver];
                row["Simplex"] = content[simplex];
            }

            return true;
        }

        public bool ReadCsvSDR(SDR track, string directory)
        {
            string fname = String.Format("{0}.{1}.csv", Name, track);
            List<string[]> content = AuxFun.ReadCsv2DataTable(directory + fname);
            if (content == null)
            {
                return false;
            }
            List<string> header = content[0].ToList();
            content.RemoveAt(0);
            int name = header.FindIndex(x => x == "Name");
            List<string> names = content.Select(x => x[name]).ToList();

            return Rows.Cast<DataRow>().All(row => names.Exists(x => x == (string) row["Name"]));
        }
    }

    public class ProblemInstance
    {
        public readonly char ShopProblem;
        public readonly int NumJobs;
        public readonly int NumMachines;
        public readonly int[,] PermutationMatrix;
        public readonly int[,] ProcessingTimes;
        public readonly int Dimension;
        private string _contentsDat = "";
        public readonly bool WagnerModelActive = false;


        public ProblemInstance(char shopProblem, int numJobs, int numMachines, int[] processingTimes,
            int[] permutationMatrix)
        {
            ShopProblem = shopProblem;
            NumJobs = numJobs;
            NumMachines = numMachines;
            Dimension = numJobs*numMachines;
            ProcessingTimes = Array2Matrix(processingTimes);
            PermutationMatrix = Array2Matrix(permutationMatrix);
        }

        public int[,] Array2Matrix(int[] array)
        {
            int[,] matrix = new int[NumJobs, NumMachines];
            for (int job = 0; job < NumJobs; job++)
            {
                for (int mac = 0; mac < NumMachines; mac++)
                    matrix[job, mac] = array[job*NumMachines + mac];
            }
            return matrix;
        }

        private void WriteModFile(string modFile, List<Schedule.Dispatch> constraints)
        {
            string pre, post;
            string lpDir = AuxFun.GetCurrentDirectory() + @"lp\";

            if (ShopProblem == 'j' | !WagnerModelActive)
            {
                pre = "jssp-pre.mod";
                post = "jssp-post.mod";
            }
            else
            {
                pre = "fssp-pre.mod";
                post = "fssp-post.mod";
            }
            string contentsPre = File.ReadAllText(lpDir + pre);
            string addConstraints = "";
            string contentsPost = File.ReadAllText(lpDir + post);

            #region add additional constraints

            if (constraints != null)
            {
                addConstraints += "/* Applying already dispatched jobs to the schedule: equal constraints */\n";
                for (int step = 0; step < constraints.Count(); step++)
                    addConstraints += String.Format("s.t. constrEqual{0}: x[{1},{2}] = {3};\n", step,
                        constraints[step].Job + 1, constraints[step].Mac + 1, constraints[step].StartTime);
            }
            else addConstraints += "/* No initial equal contstraints */\n";

            #endregion

            WriteDatFile();
            File.WriteAllText(modFile,
                String.Format("{0}{1}{2}{3}\n", contentsPre, addConstraints, contentsPost, _contentsDat));
        }

        private void WriteDatFile()
        {
            if (_contentsDat != "")
            {
                return;
            }

            _contentsDat = "data;\n";
            _contentsDat += String.Format("param n := {0}\n;", NumJobs);
            _contentsDat += String.Format("param m := {0};\n", NumMachines);

            string macs = "";
            for (int m = 0; m < NumMachines; m++) macs += (m + 1).ToString() + " ";

            if (ShopProblem == 'j' | !WagnerModelActive) // add permutation matrix info
            {
                _contentsDat += String.Format("\nparam sigma : {0}:=", macs);
                for (int n = 0; n < NumJobs; n++)
                {
                    _contentsDat += String.Format("\n{0}", n + 1);
                    for (int m = 0; m < NumMachines; m++)
                        _contentsDat += String.Format(" {0}", (PermutationMatrix[n, m] + 1));
                }
                _contentsDat += ";\n";
            }

            _contentsDat += String.Format("\nparam p : {0}:=", macs);
            for (int n = 0; n < NumJobs; n++)
            {
                _contentsDat += String.Format("\n{0}", n + 1);
                for (int m = 0; m < NumMachines; m++)
                    _contentsDat += String.Format(" {0}", ProcessingTimes[n, m]);
            }
            _contentsDat += ";\n\nend;\n";
        }

        private bool ReadGurobiLog(string logFile, out int simplexIterations)
        {
            simplexIterations = -1;
            if (!File.Exists(logFile))
            {
                return false;
            }
            try
            {
                var content = File.ReadAllText(logFile);

                // Explored 127 nodes (3813 simplex iterations) in 0.16 seconds
                Regex simplex = new Regex(@"[0-9]+ simplex iterations");

                Match match = simplex.Match(content);
                simplexIterations = match.Success ? Convert.ToInt32(Regex.Match(match.Value, @"\d+").Value) : -1;

                // Optimal solution found (tolerance 1.00e-04)
                // Best objective 5.520000000000e+02, best bound 5.520000000000e+02, gap 0.0%
                if (Regex.IsMatch(content, "Optimal solution found|INTEGER OPTIMAL SOLUTION FOUND"))
                    return true;
                else if (Regex.IsMatch(content, "Time limit reached|TIME LIMIT EXCEEDED; SEARCH TERMINATED"))
                    return false;
                else return false;
            }
            catch
            {
                return false;
            }
        }

        private int[,] ReadGurobiSolution(string solFile, out int optMakespan, string varName = "x")
        {
            optMakespan = -1;
            if (!File.Exists(solFile))
            {
                return null;
            }

            int[,] xTimeOpt = new int[NumJobs, NumMachines];

            string contentsSol = File.ReadAllText(solFile);
            string[] lines = Regex.Split(contentsSol, @"\r\n");
            Regex regNumber = new Regex(AuxFun.PatSciNr); // new Regex(@"(\d+)");
            Regex regVar = new Regex("^" + varName);
            foreach (string fullLine in lines)
            {
                if (Regex.IsMatch(fullLine, "# Objective value = "))
                    optMakespan = AuxFun.ReadScientificNumber(regNumber.Match(fullLine).Groups[0].Value);
                Match m = regVar.Match(fullLine);
                if (m.Success)
                {
                    string[] nums = Regex.Split(fullLine, "[ ,]");
                    if (nums.Length == 3)
                    {
                        int job = Convert.ToInt32(regNumber.Match(nums[0]).Groups[0].Value) - 1;
                        int mac = Convert.ToInt32(regNumber.Match(nums[1]).Groups[0].Value) - 1;
                        int time = AuxFun.ReadScientificNumber(nums[2]);
                        xTimeOpt[job, mac] = time;
                    }
                }
            }
            return xTimeOpt;
        }

        private int[,] ReadLog(string logFile, out int makespan, out bool success)
        {
            makespan = -1;
            success = false;
            var xTimeJob = new int[NumJobs, NumMachines];

            string contentsSol = File.ReadAllText(logFile);
            string[] lines = Regex.Split(contentsSol, @"\r\n");
            int job = 0;
            Regex p = new Regex("# (.*)");
            foreach (string fullLine in lines)
            {
                Match m = p.Match(fullLine);
                if (m.Success)
                {
                    string line = m.Groups[1].Value;
                    if (Regex.IsMatch(line, "^solution:"))
                    {
                        string opt = Regex.Match(line, @"(\d+)$").Groups[0].Value;
                        makespan = Convert.ToInt32(opt);
                        break;
                    }

                    int[] ints = AuxFun.GetIntValuesFromLine(line);
                    if (ints.Length == NumMachines)
                        for (int mac = 0; mac < NumMachines; mac++)
                            xTimeJob[job, mac] = ints[mac];

                    job++;
                }
                else if (Regex.IsMatch(fullLine, "INTEGER OPTIMAL SOLUTION FOUND"))
                    success = true;
            }
            return (makespan != -1 ? xTimeJob : null);
        }

        private int[,] OptimiseOutsideCsharp(string folder, string solver, string name, out int optMakespan,
            out bool success,
            out int simplexIterations, int tmlim, List<Schedule.Dispatch> constraints)
        {
            const int INF = 6000;
            if (tmlim < 1) tmlim = INF; // "100 min == no time limit"
            simplexIterations = 0;

            DateTime start = DateTime.Now;

            #region files

            solver = solver.ToUpper();
            string modFile = folder + name + ".mod";
            string solFile = folder + name + ".sol";
            string logFile = folder + name + ".log";
            string mpsFile = folder + name + ".mps";

            bool readSolFile = solver == "GUROBI";
            WriteModFile(modFile, constraints);

            #endregion

            #region solve linear programming problem

            int[,] xTimeJob = null;
            optMakespan = -1;
            success = false;

            ProcessStartInfo glpk = new ProcessStartInfo();
            if (tmlim < 5 | tmlim == INF | constraints != null)
            {
                //glpk.UseShellExecute = false;
                glpk.WindowStyle = ProcessWindowStyle.Hidden;
                glpk.CreateNoWindow = true;
            }
            glpk.FileName = "glpsol";
            glpk.WorkingDirectory = AuxFun.GetCurrentDirectory() + "lp"; // location of glpsol

            Process mProcess;
            switch (solver)
            {
                case "GLPK":
                    glpk.Arguments = "-m " + modFile + " --log " + logFile + " --tmlim " + tmlim;
                    mProcess = new Process {StartInfo = glpk, EnableRaisingEvents = true};
                    mProcess.Start();
                    mProcess.Close();
                    break;
                case "GUROBI":
                    /* Convert glpk to gurobi format: */
                    glpk.Arguments = "--check -m " + modFile + " --wmps " + mpsFile;
                    mProcess = new Process {StartInfo = glpk, EnableRaisingEvents = true};

                    // Start process
                    mProcess.Start();
                    mProcess.Close();

                    /* run mpsFile with Gurobi: 
                     * GUROBI_HOME=/opt/gurobi/gurobi500/linux64  
                     * PATH=$GUROBI_HOME/bin:$PATH  
                     * LD_LIBRARY_PATH=$GUROBI_HOME/lib:$LD_LIBRARY_PATH  
                     * GRB_LICENSE_FILE=$GUROBI_HOME/bin/gurobi.lic  
                     * gurobi_cl Threads=4 ResultFile=solFile mpsFile
                     */

                    ProcessStartInfo gurobi = new ProcessStartInfo();
                    if (tmlim < 5 | tmlim == INF)
                    {
                        gurobi.RedirectStandardOutput = true;
                        gurobi.RedirectStandardError = true;
                        gurobi.UseShellExecute = false;
                        gurobi.CreateNoWindow = true;
                    }
                    gurobi.FileName = "gurobi_cl";
                    gurobi.WorkingDirectory = AuxFun.GetCurrentDirectory() + "lp"; // location of gurobi
                    gurobi.Arguments = String.Format("Threads=8 ResultFile={0} LogFile={1} TIME_LIMIT={2} {3}", solFile,
                        logFile, tmlim, mpsFile);

                    while ((DateTime.Now - start).TotalSeconds < tmlim)
                    {
                        if (AuxFun.FileAccessible(mpsFile)) break;
                    }

                    // Setup the process
                    mProcess = new Process {StartInfo = gurobi, EnableRaisingEvents = true};

                    // Register event
                    //mProcess.OutputDataReceived += OnOutputDataReceived;

                    // Start process
                    mProcess.Start();
                    mProcess.Close();

                    break;
            }

            #endregion

            tmlim++; // give some time for post processing

            do
            {
                if (AuxFun.FileAccessible(logFile)) break;
            } while ((DateTime.Now - start).TotalSeconds < tmlim); // wait for optimization to finish/timeout 

            if (readSolFile)
            {
                switch (solver)
                {
                    case "GUROBI":
                        success = ReadGurobiLog(logFile, out simplexIterations);
                        do
                        {
                            if (AuxFun.FileAccessible(solFile)) break;
                        } while ((DateTime.Now - start).TotalSeconds < tmlim);
                        // wait for optimization to finish/timeout 
                        xTimeJob = ReadGurobiSolution(solFile, out optMakespan);
                        break;
                }
            }
            else xTimeJob = ReadLog(logFile, out optMakespan, out success);

            if (!success) return xTimeJob;
            try
            {
                foreach (string file in new List<string> {mpsFile, modFile, logFile, solFile})
                    if (File.Exists(file)) File.Delete(file);
            }
            catch
            {
                // ignored
            }
            return xTimeJob;
        }

        private void OptimiseLookAhead(GurobiJspModel model, Schedule.Dispatch lookaheadConstraint, out int optMakespan,
            out bool success, out int simplexIterations)
        {
            model.Lookahead(lookaheadConstraint, out optMakespan);
            simplexIterations = model.SimplexIterations;
            success = optMakespan > 0;
        }

        private int[,] OptimiseWithGurobiFromScratch(string name, out int optMakespan, out bool success,
            out int simplexIterations, int tmlim, List<Schedule.Dispatch> constraints)
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

        // sequence is a list of <job,mac,starttime>        
        public int[,] Optimize(string folder, string solver, string name, out int optMakespan, out bool success,
            out int simplexIterations, int tmlim = 6000, List<Schedule.Dispatch> constraints = null)
        {
            int[,] xTimeJob;
            if (solver.ToUpper() == "GUROBI")
                xTimeJob = OptimiseWithGurobiFromScratch(name, out optMakespan, out success, out simplexIterations, tmlim,
                    constraints);
            else
                xTimeJob = OptimiseOutsideCsharp(folder, solver, name, out optMakespan, out success,
                    out simplexIterations, tmlim, constraints);

            return xTimeJob;
        }
    }

    public enum LocalFeature
    {
        #region job related

        proc = 0, // processing time
        startTime, // start time 
        endTime, // end time 
        jobOps, // number of jobs 
        arrivalTime, // arrival time of job
        //wrm, // work remaining for job
        //mwrm, // most work remaining for schedule (could be other job)
        totProc, // total processing times
        wait, // wait for job

        #endregion

        #region mac-related

        mac,
        macOps, // number of macs
        macFree, // current makespan for mac 
        makespan, // current makespan for schedule

        #endregion

        #region slack related

        step, // current step 
        slotReduced, // slack reduced from job assignment 
        slots, // total slack on mac
        slotsTotal, // total slacks for schedule
        //slotCreated, // true if slotReduced < 0

        #endregion

        #region work remaining

        wrmMac, // work remaining for mac
        wrmJob, // work remaining for job
        wrmTotal, // work remaining for total

        #endregion

        Count
    }

    public enum GlobalFeature
    {
        #region makespan related

        MWR,
        LWR,
        SPT,
        LPT,
        RNDmean,
        RNDstd,
        RNDmax,
        RNDmin,

        #endregion

        Count
    }

    public enum SDR
    {
        MWR,
        LWR,
        SPT,
        LPT,
        Count,
        RND,
    }

    public enum Track
    {
        MWR,
        LWR,
        SPT,
        LPT,
        OPT,
        CMA,
        RND,
        PREF,
        Count
    }

    public class Features
    {
        public int[] RND = new int[100];
        public int[] Local = new int[(int) LocalFeature.Count];
        public double[] Global = new double[(int) GlobalFeature.Count];
        public bool[] Equiv = new bool[(int) SDR.Count];

        public Features Difference(Features other)
        {
            Features diff = new Features();

            for (int i = 0; i < (int) LocalFeature.Count; i++)
                diff.Local[i] = Local[i] - other.Local[i];

            for (int i = 0; i < (int) GlobalFeature.Count; i++)
                diff.Global[i] = Global[i] - other.Global[i];

            for (int i = 0; i < (int) SDR.Count; i++)
                diff.Equiv[i] = Equiv[i] == other.Equiv[i];

            diff.RND = null;
            return diff;
        }


        public void GetLocalFeatures(Schedule.Jobs job, Schedule.Macs mac, int proc, int wrmTotal, int slotsTotal,
            int makespan, int step, int startTime, int arrivalTime, int reduced)
        {
            #region job related

            Local[(int) LocalFeature.proc] = proc;
            Local[(int) LocalFeature.startTime] = startTime;
            Local[(int) LocalFeature.endTime] = startTime + proc;
            Local[(int) LocalFeature.jobOps] = job.MacCount;
            Local[(int) LocalFeature.arrivalTime] = arrivalTime;
            Local[(int) LocalFeature.wait] = startTime - arrivalTime;

            #endregion

            #region machine related

            Local[(int) LocalFeature.mac] = mac.Index;
            Local[(int) LocalFeature.macFree] = mac.Makespan;
            Local[(int) LocalFeature.macOps] = mac.JobCount;

            #endregion

            #region schedule related

            Local[(int) LocalFeature.totProc] = job.TotProcTime;
            Local[(int) LocalFeature.makespan] = makespan;
            Local[(int) LocalFeature.step] = step;

            #endregion

            #region work remaining

            /* add current processing time in order for <w,phi> can be equivalent to MWR/LWR 
            * (otherwise it would find the job with most/least work remaining in the next step,
            * i.e. after the one-step lookahead */
            Local[(int) LocalFeature.wrmMac] = mac.WorkRemaining + proc;
            Local[(int) LocalFeature.wrmJob] = job.WorkRemaining + proc;
            Local[(int) LocalFeature.wrmTotal] = wrmTotal + proc;

            #endregion

            #region flow related

            Local[(int) LocalFeature.slotReduced] = reduced;
            Local[(int) LocalFeature.slots] = mac.TotSlack;
            Local[(int) LocalFeature.slotsTotal] = slotsTotal;
            //local[(int)LocalFeature.slotCreated] = reduced > 0 ? 0 : 1;

            #endregion

        }

        public void GetGlobalFeatures(Schedule current)
        {
            Schedule lookahead;

            for (int i = 0; i < (int) SDR.Count; i++)
            {
                SDR sdr = (SDR) i;
                lookahead = current.Clone();
                lookahead.ApplyMethod(sdr, FeatureType.None);
                Global[(int) (GlobalFeature) (sdr)] = lookahead.Makespan;
            }

            //double maxPossibilities = Math.Pow(ReadyJobs.Count, (Dimension - Sequence.Count));
            //int plays = (int)Math.Min(phi.RND.Length, maxPossibilities);

            for (int i = 0; i < RND.Length; i++)
            {
                lookahead = current.Clone();
                lookahead.ApplyMethod(SDR.RND, FeatureType.None);
                RND[i] = lookahead.Makespan;
            }

            //int[] rnd = new int[plays];
            //Array.Copy(phi.RND, rnd, plays);

            Global[(int) GlobalFeature.RNDmin] = RND.Min();
            Global[(int) GlobalFeature.RNDmax] = RND.Max();
            Global[(int) GlobalFeature.RNDmean] = AuxFun.Mean(RND);
            Global[(int) GlobalFeature.RNDstd] = AuxFun.StandardDev(RND, Global[(int) GlobalFeature.RNDmean]);

        }

        public void GetEquivFeatures(int job, Schedule current)
        {
            for (int i = 0; i < (int) SDR.Count; i++)
                Equiv[i] = job == current.JobChosenBySDR((SDR) i);
        }
    }

    public class LinearWeight
    {
        public double[][] Local = new double[(int) LocalFeature.Count][];
        public double[][] Global = new double[(int) GlobalFeature.Count][];
        public readonly string Name;
        public readonly int NrFeat;
        public readonly int ModelIndex;
        public readonly bool TimeIndependent;

        public LinearWeight(int timeDependentSteps, string fileName, int nrFeat = (int) LocalFeature.Count,
            int modelIndex = -1)
        {
            Name = fileName;
            ModelIndex = modelIndex;
            NrFeat = nrFeat;

            if (modelIndex != -1 & nrFeat != (int) LocalFeature.Count)
            {
                Name = String.Format("{0}//F{1}.Model{2}", fileName, nrFeat, modelIndex);
            }

            TimeIndependent = timeDependentSteps == 1;

            for (int i = 0; i < (int) LocalFeature.Count; i++)
                Local[i] = new double[timeDependentSteps];

            for (int i = 0; i < (int) GlobalFeature.Count; i++)
                Global[i] = new double[timeDependentSteps];

        }

        public LinearWeight EquivalentSDR(SDR sdr)
        {
            LinearWeight w = new LinearWeight(1, sdr.ToString());
            switch (sdr)
            {
                case SDR.MWR:
                    w.Local[(int) LocalFeature.wrmJob][0] = +1;
                    return w;
                case SDR.LWR:
                    w.Local[(int) LocalFeature.wrmJob][0] = -1;
                    return w;
                case SDR.SPT:
                    w.Local[(int) LocalFeature.proc][0] = -1;
                    return w;
                case SDR.LPT:
                    w.Local[(int) LocalFeature.proc][0] = +1;
                    return w;
                default:
                    return w; // do nothing
            }
        }

        public void ReadLinearWeights(string path, out FeatureType featureType)
        {
            string[] content;
            AuxFun.ReadTextFile(path, out content, "\r\n");

            bool foundLocal = false;
            bool foundGlobal = false;

            foreach (string line in content)
            {
                string pattern;
                for (int i = 0; i < (int) LocalFeature.Count; i++)
                {
                    pattern = String.Format("phi.{0}", (LocalFeature) i);
                    Match phi = Regex.Match(line, String.Format(@"(?<={0} (-?[0-9.]*)", pattern));
                    if (phi.Success)
                    {
                        double value = Convert.ToDouble(phi.Groups[2].ToString(),
                            CultureInfo.InvariantCulture);
                        Local[i][0] = value;
                        foundLocal = true;
                    }
                }

                for (int i = 0; i < (int) GlobalFeature.Count; i++)
                {
                    pattern = String.Format("phi.{0}", (GlobalFeature) i);
                    Match phi = Regex.Match(line, String.Format(@"(?<={0} (-?[0-9.]*)", pattern));
                    if (phi.Success)
                    {
                        double value = Convert.ToDouble(phi.Groups[2].ToString(),
                            CultureInfo.InvariantCulture);
                        Global[i][0] = value;
                        foundGlobal = true;
                    }
                }
            }

            featureType = foundGlobal ? FeatureType.Global : foundLocal ? FeatureType.Local : FeatureType.None;

            //foreach (string line in content)
            //{
            //    Match phi = Regex.Match(line, @"(?<=phi.)(\w+) (-?[0-9.]*)");
            //    if (phi.Success)
            //    {

            //        string field = phi.Groups[1].ToString();
            //        FieldInfo myFieldInfo = myType.GetField(field);
            //        if (myFieldInfo != null)
            //            myFieldInfo.SetValue(weights, value);
            //        else
            //        {
            //            FieldInfo[] fields = myType.BaseType.GetFields(BindingFlags.NonPublic | BindingFlags.Instance);
            //            foreach (FieldInfo info in fields)
            //            {
            //                if (Regex.IsMatch(info.Name, field))
            //                {
            //                    info.SetValue(weights, value);
            //                    break;
            //                }
            //            }
            //        }
            //    }
            //}            
        }
    }

    internal enum SlotType
    {
        First = 0,
        Smallest
    };

    public class Schedule
    {
        private const SlotType SLOT_TYPE = SlotType.First;
        public readonly int NumJobs;
        public readonly int NumMachines;
        private readonly int[,] _sigma;
        private readonly int[,] _procs;
        public readonly int Dimension;
        public List<Dispatch> Sequence;
        public int Makespan;
        private readonly ProblemInstance _problemInstance;

        public List<int> ReadyJobs;
        private readonly Jobs[] _jobs;
        private readonly Macs[] _macs;

        private readonly Random _random;


        public Schedule Clone()
        {
            Schedule clone = new Schedule(_problemInstance, _random);

            foreach (Dispatch disp in Sequence)
                clone.Sequence.Add(disp);

            clone.ReadyJobs = ReadyJobs.ToList();

            clone.Makespan = Makespan;

            for (int job = 0; job < NumJobs; job++)
                clone._jobs[job] = _jobs[job].Clone();

            for (int mac = 0; mac < NumMachines; mac++)
                clone._macs[mac] = _macs[mac].Clone();

            return clone;
        }

        public class Dispatch
        {
            public int Job, Mac, StartTime;

            public string Name
            {
                get { return String.Format("{0}.{1}.{2}", Job, Mac, StartTime); }
            }

            public Dispatch(int job, int mac, int startTime)
            {
                Job = job;
                Mac = mac;
                StartTime = startTime;
            }

            public Dispatch Clone()
            {
                return new Dispatch(Job, Mac, StartTime);
            }
        }

        public class Jobs
        {
            public readonly int Index;
            public int TotProcTime;
            public int WorkRemaining;
            public int MacCount;
            public int Free;
            public int[] XTime;

            public Jobs(int index, int totProcTime, int numMachines)
            {
                Index = index;
                TotProcTime = totProcTime;
                WorkRemaining = totProcTime;
                XTime = new int[numMachines];
            }

            public Jobs Clone()
            {
                Jobs clone = new Jobs(Index, WorkRemaining, XTime.Length)
                {
                    TotProcTime = TotProcTime,
                    WorkRemaining = WorkRemaining,
                    MacCount = MacCount,
                    Free = Free
                };
                Array.Copy(XTime, clone.XTime, XTime.Length);
                return clone;
            }

            public void Update(int start, int time, int mac, out int arrivalTime)
            {
                arrivalTime = Free;
                WorkRemaining -= time;
                MacCount++;
                Free = start + time;
                XTime[mac] = start;
            }
        }

        public class Macs
        {
            public readonly int Index;
            public int JobCount;
            public int WorkRemaining;
            public int Makespan;
            public int TotSlack;
            public int[] ETime = new int[0];
            public int[] STime = new int[0];
            public int[] Slacks = new int[0];

            public Macs(int index, int workRemaining)
            {
                Index = index;
                WorkRemaining = workRemaining;
            }

            public Macs Clone()
            {
                Macs clone = new Macs(Index, WorkRemaining)
                {
                    JobCount = JobCount,
                    Makespan = Makespan,
                    TotSlack = TotSlack,
                    ETime = new int[JobCount],
                    STime = new int[JobCount],
                    Slacks = new int[JobCount]
                };
                Array.Copy(ETime, clone.ETime, JobCount);
                Array.Copy(STime, clone.STime, JobCount);
                Array.Copy(Slacks, clone.Slacks, JobCount);
                return clone;
            }

            public void Update(int start, int time, int slot, out int slotReduced)
            {
                JobCount++;
                Array.Resize(ref ETime, JobCount);
                Array.Resize(ref STime, JobCount);
                Array.Resize(ref Slacks, JobCount);

                if (slot < JobCount - 1)
                {
                    Array.Copy(ETime, slot, ETime, slot + 1, JobCount - slot - 1);
                    Array.Copy(STime, slot, STime, slot + 1, JobCount - slot - 1);
                    Array.Copy(Slacks, slot, Slacks, slot + 1, JobCount - slot - 1);
                }

                STime[slot] = start;
                ETime[slot] = start + time;

                Makespan = Math.Max(Makespan, start + time);
                WorkRemaining -= time;

                Slacks[0] = STime[0];
                for (int job = 1; job < JobCount; job++)
                    Slacks[job] = STime[job] - ETime[job - 1];

                slotReduced = TotSlack;
                TotSlack = Slacks.Sum();
                slotReduced -= TotSlack;
            }
        }

        public Schedule(ProblemInstance prob, Random rnd = null)
        {
            _problemInstance = prob;

            _procs = prob.ProcessingTimes;
            _sigma = prob.PermutationMatrix;

            NumJobs = prob.NumJobs;
            NumMachines = prob.NumMachines;
            Dimension = prob.Dimension;
            Sequence = new List<Dispatch>(Dimension);

            _jobs = new Jobs[NumJobs];
            _macs = new Macs[NumMachines];

            ReadyJobs = new List<int>(NumJobs);

            for (int job = 0; job < NumJobs; job++)
            {
                ReadyJobs.Add(job);
                int totalWork = 0;
                for (int a = 0; a < NumMachines; a++)
                    totalWork += _procs[job, a];
                _jobs[job] = new Jobs(job, totalWork, NumMachines);
            }

            for (int mac = 0; mac < NumMachines; mac++)
            {
                int wrm = 0;
                for (int j = 0; j < NumJobs; j++)
                    wrm += _procs[j, mac];
                _macs[mac] = new Macs(mac, wrm);
            }

            if (rnd == null)
            {
                int seed = (int) DateTime.Now.Ticks;
                _random = new Random(seed);
            }
            else
                _random = rnd;
        }




        public int FindDispatch(int job, out Dispatch dispatch)
        {
            int mac = _sigma[job, _jobs[job].MacCount];
            int time = _procs[job, mac];

            #region find available slot

            int slot = -1;
            int startTime;
            if (_macs[mac].JobCount == 0) // never been assigned a job before, no need to check for slotsizes
            {
                startTime = _jobs[job].Free;
                slot = 0;
            }
            else // possibility of slots
            {
                var slotsizes = new int[_macs[mac].JobCount + 1];
                slotsizes[0] = _macs[mac].STime[0] - _jobs[job].Free;
                slotsizes[_macs[mac].JobCount] = int.MaxValue; // inf 
                for (int jobPrime = 1; jobPrime < _macs[mac].JobCount; jobPrime++)
                    slotsizes[jobPrime] = Math.Max(0,
                        _macs[mac].STime[jobPrime] - Math.Max(_macs[mac].ETime[jobPrime - 1], _jobs[job].Free));

                switch (SLOT_TYPE)
                {
                    case SlotType.Smallest:
                        int minSlot = _macs[mac].Makespan;
                        for (int jobPrime = 0; jobPrime <= _macs[mac].JobCount; jobPrime++)
                            if (slotsizes[jobPrime] >= time & slotsizes[jobPrime] < minSlot)
                                // fits, and smaller than last slot
                            {
                                slot = jobPrime;
                            }
                        break;
                    //case SlotType.First:
                    default:
                        for (int jobPrime = 0; jobPrime <= _macs[mac].JobCount; jobPrime++)
                            if (slotsizes[jobPrime] >= time) // fits
                            {
                                slot = jobPrime;
                                break;
                            }
                        break;

                }

                startTime = slot == 0 ? _jobs[job].Free : Math.Max(_macs[mac].ETime[slot - 1], _jobs[job].Free);
            }

            #endregion

            dispatch = new Dispatch(job, mac, startTime);

            return slot;
        }

        public Features Dispatch1(int job, FeatureType featureMode) // commits dispatch! 
        {
            Dispatch dispatch;
            int slot = FindDispatch(job, out dispatch);

            int time = _procs[job, dispatch.Mac];

            int arrivalTime, slotReduced;

            Features phi = new Features();

            switch (featureMode)
            {
                case FeatureType.Global:
                    phi.GetEquivFeatures(job, this);
                    break;
            }

            _macs[dispatch.Mac].Update(dispatch.StartTime, time, slot, out slotReduced);
            _jobs[job].Update(dispatch.StartTime, time, dispatch.Mac, out arrivalTime);

            Sequence.Add(dispatch);

            if (_jobs[job].MacCount == NumMachines)
                ReadyJobs.Remove(job);
            Makespan = _macs.Max(x => x.Makespan);

            switch (featureMode)
            {
                case FeatureType.Global:
                    //phi.getLocalFeatures(jobs[job], macs[dispatch.Mac], procs[job][dispatch.Mac], jobs.Sum(p => p.workRemaining), macs.Sum(p => p.totSlack), makespan, sequence.Count, dispatch.StartTime, arrivalTime, slotReduced);
                    phi.GetGlobalFeatures(this);
                    return phi;
                case FeatureType.Local:
                    phi.GetLocalFeatures(_jobs[job], _macs[dispatch.Mac], _procs[job, dispatch.Mac],
                        _jobs.Sum(p => p.WorkRemaining), _macs.Sum(p => p.TotSlack), Makespan, Sequence.Count,
                        dispatch.StartTime, arrivalTime, slotReduced);
                    return phi;
                //case FeatureType.None:
                default:
                    return null;
            }
        }

        public bool Validate(out string error, bool fullSchedule, Dispatch newDispatch = null)
        {
            int reportedMakespan = -1;
            for (int mac = 0; mac < NumMachines; mac++)
                reportedMakespan = Math.Max(Makespan, _macs[mac].Makespan);
            if (reportedMakespan != Makespan)
            {
                error = "Makespan doesn't match end time of machines";
                return false;
            }

            if (fullSchedule)
            {
                for (int job = 0; job < NumJobs; job++)
                    if (_jobs[job].MacCount != NumMachines)
                    {
                        error = "Mac count for job " + job + " doesn't match";
                        return false;
                    }
                for (int mac = 0; mac < NumMachines; mac++)
                    if (_macs[mac].JobCount != NumJobs)
                    {
                        error = "Jobcount for mac " + mac + " doesn't match";
                        return false;
                    }
            }

            for (int job = 0; job < NumJobs; job++)
                for (int order = _jobs[job].MacCount; order < NumMachines; order++)
                {
                    int mac = _sigma[job, order];
                    if (_jobs[job].XTime[mac] <= 0) continue;
                    error = "Dispatch committed that hasn't been reported";
                    return false;
                }

            if (Sequence.Any(o => _jobs[o.Job].XTime[o.Mac] != o.StartTime & o.StartTime != -1))
            {
                error = "Dispatch was not reported correctly";
                return false;
            }

            // job finishes their previous machine before it starts its next, w.r.t. its permutation
            for (int job = 0; job < NumJobs; job++)
                for (int mac = 1; mac < _jobs[job].MacCount; mac++)
                {
                    int macnow = _sigma[job, mac];
                    int macpre = _sigma[job, mac - 1];
                    if (_jobs[job].XTime[macnow] < _jobs[job].XTime[macpre] + _procs[job, macpre])
                    {
                        error = "job starts too early";
                        return false;
                    }
                }

            // only one job at a time per machine
            for (int mac = 0; mac < NumMachines; mac++)
                for (int job = 1; job < _macs[mac].JobCount; job++)
                {
                    if (_macs[mac].STime[job] < _macs[mac].ETime[job - 1])
                    {
                        error = "machine occupied";
                        return false;
                    }
                }
            error = "";
            return true;
        }

        public void ApplySplitSDR(SDR sdrFirst, SDR sdrSecond, int stepSplitProc)
        {
            int stepSplit = (int) (stepSplitProc/100.0*Dimension);

            for (int step = Sequence.Count; step < Dimension; step++)
            {
                var sdr = step < stepSplit ? sdrFirst : sdrSecond;
                var job = JobChosenBySDR(sdr);
                Dispatch1(job, FeatureType.None);
            }
        }

        public void ApplyMethod(SDR sdr, FeatureType featureMode)
        {
            for (int step = Sequence.Count; step < Dimension; step++)
            {
                var job = JobChosenBySDR(sdr);
                Dispatch1(job, featureMode);
            }
        }

        public void ApplyMethod(LinearModel linModel, FeatureType featureMode)
        {
            for (int step = Sequence.Count; step < Dimension; step++)
            {
                List<double> priority = new List<double>(ReadyJobs.Count);
                priority.AddRange(from j in ReadyJobs
                    let lookahead = Clone()
                    select lookahead.Dispatch1(j, linModel.FeatureType)
                    into feat
                    select linModel.PriorityIndex(feat));
                var job = ReadyJobs[priority.FindIndex(p => Math.Abs(p - priority.Max()) < 0.001)];
                Dispatch1(job, FeatureType.None);
            }
        }

        public int JobChosenBySDR(SDR sdr)
        {
            switch (sdr)
            {
                case SDR.LWR:
                case SDR.MWR:
                    List<int> wrm = new List<int>(ReadyJobs.Count);
                    wrm.AddRange(ReadyJobs.Select(job => _jobs[job].WorkRemaining));

                    return sdr == SDR.LWR
                        ? ReadyJobs[wrm.FindIndex(w => w == wrm.Min())]
                        : ReadyJobs[wrm.FindIndex(w => w == wrm.Max())];

                case SDR.LPT:
                case SDR.SPT:
                    List<int> times = new List<int>(ReadyJobs.Count);
                    times.AddRange(from job in ReadyJobs
                        let mac = _sigma[job, _jobs[job].MacCount]
                        select _procs[job, mac]);
                    return sdr == SDR.SPT
                        ? ReadyJobs[times.FindIndex(w => w == times.Min())]
                        : ReadyJobs[times.FindIndex(w => w == times.Max())];

                default: // unknown, choose at random 
                    return ReadyJobs[_random.Next(0, ReadyJobs.Count())];
            }
        }

        public void SetCompleteSchedule(int[,] times, int ms)
        {
            if (times == null)
            {
                return;
            }
            Makespan = ms;

            for (int j = 0; j < NumJobs; j++)
            {
                _jobs[j].MacCount = NumMachines;
                for (int a = 0; a < NumMachines; a++)
                    times[j, a] = _jobs[j].XTime[a];
            }

            for (int m = 0; m < NumMachines; m++)
            {
                Array.Resize(ref _macs[m].STime, NumJobs);
                Array.Resize(ref _macs[m].ETime, NumJobs);
                for (int j = 0; j < NumJobs; j++)
                {
                    Sequence.Add(new Dispatch(j, m, -1));
                    _macs[m].STime[j] = _jobs[j].XTime[m];
                    _macs[m].ETime[j] = _jobs[j].XTime[m] + _procs[j, m];
                }
                _macs[m].JobCount = NumJobs;
                Array.Sort(_macs[m].STime);
                Array.Sort(_macs[m].ETime);
            }
        }

        public Image PlotSchedule(int width, int height, string filePath, bool printJobIndex = true)
        {
            string probName = Regex.Match(filePath, "(?<=\\\\)[a-z0-9.]*(?=_)").Value;
            string method = Regex.Match(filePath, "(?<=_)(.*)").Value;
            RandomPastelColorGenerator colors = new RandomPastelColorGenerator();

            Font font = new Font("courier new", 8);

            const int x0 = 25; // margin left
            const int x1 = 10; // margin right
            int y0 = (int) (font.Size*3); // top margin
            int y1 = (int) (font.Size*2); // bottom margin

            double widthConvert = (width - x0 - x1)/(double) (Makespan);
            int macheight = (height - y0 - y1)/NumMachines;
            int space = (int) (macheight - font.Size*2); // space between machines

            Brush blackBrush = new SolidBrush(Color.Black);
            Brush whiteBrush = new SolidBrush(Color.White);

            Schedule fromScratch = new Schedule(_problemInstance);

            SolidBrush[] colorBrushes = new SolidBrush[NumJobs];
            for (int job = 0; job < NumJobs; job++)
                colorBrushes[job] = new SolidBrush(colors.GetNextRandom());

            List<Bitmap> images = new List<Bitmap>();
            Bitmap imgSchedule = new Bitmap(width, height);
            using (Graphics g = Graphics.FromImage(imgSchedule))
            {
                g.Clear(Color.White);
                for (int mac = 0; mac < NumMachines; mac++)
                    g.DrawString(String.Format("{0}:", mac), font, blackBrush, new PointF(0, y0 + mac*macheight));
                if (method != string.Empty)
                    g.DrawString("Method " + method + " applied:", font, blackBrush, new PointF(0, 0));
            }

            #region gif image

            if (!File.Exists(filePath + ".gif"))
            {
                Pen blackPen = new Pen(blackBrush);
                for (int step = 0; step < Sequence.Count; step++)
                {
                    #region Check next possile jobs

                    Bitmap img = new Bitmap(imgSchedule);
                    using (Graphics g = Graphics.FromImage(img))
                    {
                        foreach (int job in fromScratch.ReadyJobs)
                        {
                            Schedule lookahead = fromScratch.Clone();
                            lookahead.Dispatch1(job, FeatureType.None);
                            Dispatch dispatch = lookahead.Sequence[lookahead.Sequence.Count - 1];
                            int mac = dispatch.Mac;
                            int start = dispatch.StartTime;
                            int end = start + _procs[job, mac];

                            start = (int) (start*widthConvert) + x0;
                            end = (int) (end*widthConvert) + x0;

                            g.DrawRectangle(blackPen,
                                new Rectangle(start, y0 + mac*macheight, end - start, macheight - space));
                            g.DrawString(job.ToString(), font, blackBrush, new PointF(start, y0 + mac*macheight));
                        }
                        g.Dispose();
                    }
                    images.Add(img);

                    #endregion

                    #region Commit dispatch

                    using (Graphics g = Graphics.FromImage(imgSchedule))
                    {
                        int mac = Sequence[step].Mac;
                        int job = Sequence[step].Job;
                        int start = Sequence[step].StartTime;
                        int end = start + _procs[job, mac];
                        fromScratch.Dispatch1(job, FeatureType.None);

                        start = (int) (start*widthConvert) + x0;
                        end = (int) (end*widthConvert) + x0;

                        g.FillRectangle(colorBrushes[job],
                            new Rectangle(start, y0 + mac*macheight, end - start, macheight - space));
                        if (printJobIndex)
                            g.DrawString(job.ToString(), font, blackBrush, new PointF(start, y0 + mac*macheight));

                        g.FillRectangle(whiteBrush, new Rectangle(0, height - y1, width, y1));
                        g.DrawString(
                            (step == Sequence.Count - 1 ? "Final" : "Current") + " Cmax: " +
                            fromScratch.Makespan.ToString() + (probName != "" ? "  (" + probName + ")" : ""),
                            font, blackBrush, new PointF(0, height - y1));

                        g.Dispose();
                    }

                    #endregion
                }
                images.Add(imgSchedule);

                GifBitmapEncoder gEnc = new GifBitmapEncoder();
                foreach (Bitmap bmp in images)
                {
                    var src = Imaging.CreateBitmapSourceFromHBitmap(
                        bmp.GetHbitmap(),
                        IntPtr.Zero,
                        Int32Rect.Empty,
                        BitmapSizeOptions.FromEmptyOptions());
                    gEnc.Frames.Add(BitmapFrame.Create(src));
                }
                if (!File.Exists(filePath + ".gif"))
                    gEnc.Save(new FileStream(filePath + ".gif", FileMode.Create));
            }

            #endregion

            #region plot final resulting image

            if (!images.Any())
                using (Graphics g = Graphics.FromImage(imgSchedule))
                {
                    g.DrawString(
                        String.Format("{0} Cmax: {1}{2}", Sequence.Count() == Dimension ? "Final" : "Current", Makespan,
                            probName != "" ? "  (" + probName + ")" : ""), font, blackBrush, new PointF(0, height - y1));

                    for (int job = 0; job < NumJobs; job++)
                    {
                        for (int a = 0; a < _jobs[job].MacCount; a++)
                        {
                            int mac = _sigma[job, a];
                            int start = _jobs[job].XTime[mac];
                            int end = start + _procs[job, mac];

                            start = (int) (start*widthConvert) + x0;
                            end = (int) (end*widthConvert) + x0;

                            g.FillRectangle(colorBrushes[job],
                                new Rectangle(start, y0 + mac*macheight, end - start, macheight - space));
                            if (printJobIndex)
                                g.DrawString(job.ToString(), font, blackBrush, new PointF(start, y0 + mac*macheight));
                        }
                    }
                    g.Dispose();
                }

            #endregion

            imgSchedule.Save(filePath + ".jpg", ImageFormat.Jpeg);
            return imgSchedule;
        }

        public string PrintSchedule()
        {
            string info = String.Format("Solution has {0} Cmax: {1}\n\nStart times for {2} jobs on {3} machines:\n",
                Sequence.Count() == Dimension ? "final" : "partial", Makespan, NumJobs, NumMachines);

            for (int job = 0; job < NumJobs; job++)
            {
                for (int mac = 0; mac < NumMachines; mac++)
                    info += _jobs[job].XTime[mac] + " ";
                info += "\n";
            }
            return info + "\n";
        }
    }
}