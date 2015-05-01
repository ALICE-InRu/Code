using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

namespace ALICE
{
    /// <summary>
    /// Training set from RawData
    /// </summary>
    public class TrainingSet : RawData
    {
        public enum Trajectory
        {
            MWR,
            LWR,
            SPT,
            LPT,
            OPT,
            CMA,
            RND,
            ILUNSUP,
            ILSUP,
            ILFIX,
            Count
        }

        private readonly Func<Schedule, List<TrSet>, LinearModel, int> _trajectory;
        internal readonly Trajectory Track;

        public int NumFeatures;
        internal Features.Mode FeatureMode = Features.Mode.Local; 
        
        public readonly List<TrSet>[,] TrData;
        internal Random Random = new Random();

        internal readonly LinearModel Model;
        

        public class TrSet : PreferenceSet.PrefSet
        {
            public Schedule.Dispatch Dispatch;
            public int SimplexIterations;

            public TrSet(Schedule.Dispatch dispatch, Features features)
            {
                Dispatch = dispatch;
                Feature = features;
            }

            public TrSet(Schedule.Dispatch dispatch, bool followed, int resultingOptMakespan, int rank)
            {
                Dispatch = dispatch;
                Followed = followed;
                ResultingOptMakespan = resultingOptMakespan;
                Rank = rank;
            }

            public PreferenceSet.PrefSet Difference(TrSet other)
            {
                var diff = new PreferenceSet.PrefSet
                {
                    Rank = Rank - other.Rank,
                    ResultingOptMakespan = ResultingOptMakespan - other.ResultingOptMakespan,
                    Feature = Feature.Difference(other.Feature),
                    Followed = Followed | other.Followed
                    //Rho = Rho - other.Rho
                };
                //(this.Rank == other.Rank ? 0 : (this.Rank < other.Rank) ? 1 : -1);
                return diff;
            }
        }

        public TrainingSet(string distribution, string dimension, Trajectory track, bool extended)
            : base(distribution, dimension, DataSet.train, extended)
        {
            Track = track;
            switch (Track)
            {
                case Trajectory.ILFIX:
                case Trajectory.ILSUP:
                case Trajectory.ILUNSUP:
                    throw new NotImplementedException();
                case Trajectory.CMA:
                    throw new NotImplementedException();
                default:
                    Model = null;
                    break;
            }

            FileInfo =
                new FileInfo(string.Format(
                    "C://Users//helga//Alice//Code//trainingData//trdat.{0}.{1}.{2}{3}.{4}.csv",
                    Distribution, Dimension, track, extended ? "EXT" : "", FeatureMode));

            Columns.Add("Step", typeof (int));
            Columns.Add("Dispatch", typeof (Schedule.Dispatch));
            Columns.Add("Followed", typeof (bool));
            Columns.Add("ResultingOptMakespan", typeof (int));
            Columns.Add("Features", typeof (Features));

            SetAlreadySavedPID();

            TrData = new List<TrSet>[NumInstances,NumDimension];

            switch (Track)
            {
                case Trajectory.CMA:
                case Trajectory.ILUNSUP:
                    _trajectory = ChooseWeightedJob;
                    break;
                case Trajectory.OPT:
                    _trajectory = ChooseOptJob;
                    break;
                case Trajectory.ILSUP:
                case Trajectory.ILFIX:
                    _trajectory = UseImitationLearning;
                    break;
                default:
                    _trajectory = ChooseSDRJob;
                    break;
            }
        }

        public void Write()
        {
            Write(FileMode.Append);
        }

        internal void Write(FileMode fileMode)
        {
            var fs = new FileStream(FileInfo.FullName, fileMode, FileAccess.Write);
            using (var st = new StreamWriter(fs))
            {
                if (fs.Length == 0) // header is missing 
                {
                    var header = "PID,Step,Dispatch,Followed,ResultingOptMakespan";
                    switch (FeatureMode)
                    {
                        case Features.Mode.Global:
                            for (var i = 0; i < (int) Features.Global.Count; i++)
                                header += string.Format(",phi.{0}", (Features.Global) i);
                            break;
                        case Features.Mode.Local:
                            for (var i = 0; i < (int) Features.Local.Count; i++)
                                header += string.Format(",phi.{0}", (Features.Local) i);
                            break;
                    }
                    header += ",Rank";
                    st.WriteLine(header);
                }

                for (int pid = fileMode == FileMode.Append ? AlreadySavedPID + 1 : 1; pid < NumInstances; pid++)
                {
                    for (int step = 0; step < NumDimension; step++)
                    {
                        var prefs = TrData[pid - 1, step];
                        if (prefs == null)
                        {
                            AlreadySavedPID = pid - 1;
                            return;
                        }
                        foreach (var pref in prefs)
                        {
                            string info = String.Format("{0},{1},{2},{3},{4}", pid, step, pref.Dispatch.Name,
                                pref.Followed ? 1 : 0, pref.ResultingOptMakespan);
                            switch (FeatureMode)
                            {
                                case Features.Mode.Global:
                                    for (var i = 0; i < (int)Features.Global.Count; i++)
                                        info += string.Format(",{0:0}", pref.Feature.PhiGlobal[i]);
                                    break;
                                case Features.Mode.Local:
                                    for (var i = 0; i < (int) Features.Local.Count; i++)
                                        info += string.Format(",{0:0}", pref.Feature.PhiLocal[i]);
                                    break;
                            }
                            info += String.Format(",{0}", pref.Rank);
                            st.WriteLine(info);
                        }
                    }
                }

                foreach (var info in from DataRow row in Rows
                    let pid = (int)row["PID"]
                    where pid > AlreadySavedPID
                    select String.Format("{0},{1}", row["Name"], row["Makespan"]))
                {
                    st.WriteLine(info);
                }
                st.Close();
            }
            fs.Close();
        }

        const int TMLIM_STEP = 2; // max 2 min per step/possible dispatch

        public string CollectTrainingSet(int pid)
        {
            string name = GetName(pid);
            DataRow instance = Rows.Find(name);
            ProblemInstance prob = (ProblemInstance) instance["Problem"];

            GurobiJspModel gurobiModel = new GurobiJspModel(prob, name, TMLIM_STEP);

            Schedule jssp = new Schedule(prob);
            int currentNumFeatures = 0;
            for (int step = 0; step < prob.Dimension; step++)
            {
                TrData[pid - 1, step] = FindFeaturesForAllJobs(jssp, gurobiModel);
                int dispatchedJob = _trajectory(jssp, TrData[pid - 1, step], Model);
                jssp.Dispatch1(dispatchedJob, Features.Mode.None);
                gurobiModel.CommitConstraint(jssp.Sequence[step], step);
                currentNumFeatures += TrData[pid - 1, step].Count;
            }
            gurobiModel.Dispose();
            NumFeatures += currentNumFeatures;
            return String.Format("{0}:{1} #{2} phi", FileInfo.Name, pid, currentNumFeatures);
        }

        private List<TrSet> FindFeaturesForAllJobs(Schedule jssp, GurobiJspModel gurobiModel)
        {
            TrSet[] prefs = new TrSet[jssp.ReadyJobs.Count];
            for (int r = 0; r < jssp.ReadyJobs.Count; r++)
            {
                Schedule lookahead = jssp.Clone();
                Features phi = lookahead.Dispatch1(jssp.ReadyJobs[r], FeatureMode); // commit the lookahead
                prefs[r] = new TrSet(lookahead.Sequence[lookahead.Sequence.Count - 1], phi);
                // need to optimize to label featuers correctly -- this is computationally intensive
                gurobiModel.Lookahead(prefs[r].Dispatch, out prefs[r].ResultingOptMakespan);
                prefs[r].SimplexIterations = gurobiModel.SimplexIterations;
            }
            return prefs.ToList();
        }

        private int ChooseOptJob(Schedule jssp, List<TrSet> prefs, LinearModel model = null)
        {
            int minMakespan = prefs.Min(p => p.ResultingOptMakespan);
            List<TrSet> optimums = prefs.Where(p => p.ResultingOptMakespan == minMakespan).ToList();
            return optimums.Count == 1 ? optimums[0].Dispatch.Job : optimums[Random.Next(0, optimums.Count)].Dispatch.Job;
        }

        private int ChooseWeightedJob(Schedule jssp, List<TrSet> prefs, LinearModel model)
        {
            List<double> priority = new List<double>(jssp.ReadyJobs.Count);
            for (int r = 0; r < jssp.ReadyJobs.Count; r++)
                priority.Add(model.PriorityIndex(prefs[r].Feature));
            return jssp.ReadyJobs[priority.FindIndex(p => Math.Abs(p - priority.Max()) < 0.001)];
        }

        private int UseImitationLearning(Schedule jssp, List<TrSet> prefs, LinearModel model)
        {
            // pi_i = beta_i*pi_star + (1-beta_i)*pi_i^hat
            // i: ith iteration of imitation learning
            // pi_star is expert policy (i.e. optimal)
            // pi_i^hat: is pref model from prev. iteration
            double pr = Random.NextDouble();
            return model != null && pr >= model.Beta
                ? ChooseWeightedJob(jssp, prefs, model)
                : ChooseOptJob(jssp, prefs);
        }

        private int ChooseSDRJob(Schedule jssp, List<TrSet> prefs = null, LinearModel mode = null)
        {
            return jssp.JobChosenBySDR((SDRData.SDR) Track);
        }
    }
}