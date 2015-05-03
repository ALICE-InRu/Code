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

        private readonly Func<Schedule, List<Preference>, int> _trajectory;
        internal readonly Trajectory Track;

        public int NumFeatures { get; internal set; }
        private const int TMLIM_STEP = 2; // max 2 min per step/possible dispatch

        internal Features.Mode FeatureMode = Features.Mode.Local;

        internal readonly List<Preference>[,] Preferences;
        internal Random Random = new Random();

        internal readonly LinearModel Model;
        private readonly double _beta; // only used in imitation learning 

        internal class Preference 
        {
            public Features Feature;
            public int ResultingOptMakespan;
            public int Rank;
            public bool Followed;

            public Schedule.Dispatch Dispatch;
            public int SimplexIterations;

            public Preference(Schedule.Dispatch dispatch, Features features)
            {
                Dispatch = dispatch;
                Feature = features;
            }

            public Preference(Schedule.Dispatch dispatch, bool followed, int resultingOptMakespan, int rank)
            {
                Dispatch = dispatch;
                Followed = followed;
                ResultingOptMakespan = resultingOptMakespan;
                Rank = rank;
            }

            public Preference Difference(Preference other)
            {
                var diff = new Preference(null, Feature.Difference(other.Feature))
                {
                    Rank = Rank - other.Rank,
                    ResultingOptMakespan = ResultingOptMakespan - other.ResultingOptMakespan,
                    Followed = Followed | other.Followed
                };
                return diff;
            }
        }

        private int ResetNumInstances(bool extended)
        {
            return Math.Min(NumInstances, NumDimension < 100 ? (extended ? 5000 : 500) : (extended ? 1000 : 300));
        }

        public TrainingSet(string distribution, string dimension, Trajectory track, bool extended)
            : base(distribution, dimension, DataSet.train, extended)
        {
            Track = track;
            string strTrack = track.ToString();
            NumInstances = ResetNumInstances(extended);

            switch (Track)
            {
                case Trajectory.ILFIX:
                case Trajectory.ILSUP:
                case Trajectory.ILUNSUP:
                    int iter;
                    strTrack = GetImitationModel(out Model, out _beta, out iter, extended);
                    if (Track == Trajectory.ILUNSUP)
                        _trajectory = ChooseWeightedJob;
                    else
                        _trajectory = UseImitationLearning;

                    if (extended)
                    {
                        int numTraining = ResetNumInstances(false);
                        AlreadySavedPID = Math.Max(AlreadySavedPID, numTraining*iter);
                        NumInstances = Math.Min(Rows.Count, numTraining*(iter + 1));
                    }

                    break;
                case Trajectory.CMA:
                    Model = null;
                    _trajectory = ChooseWeightedJob;
                    throw new NotImplementedException();
                case Trajectory.OPT:
                    Model = null;
                    _trajectory = ChooseOptJob;
                    break;
                default: // SDR  
                    Model = new LinearModel((SDRData.SDR) Track);
                    _trajectory = ChooseSDRJob;
                    break;
            }
            if (extended) strTrack += "EXT";


            FileInfo =
                new FileInfo(string.Format(
                    "C://Users//helga//Alice//Code//trainingData//trdat.{0}.{1}.{2}.{3}.csv",
                    Distribution, Dimension, strTrack, FeatureMode));

            Columns.Add("Step", typeof (int));
            Columns.Add("Dispatch", typeof (Schedule.Dispatch));
            Columns.Add("Followed", typeof (bool));
            Columns.Add("ResultingOptMakespan", typeof (int));
            Columns.Add("Features", typeof (Features));

            SetAlreadySavedPID();

            Preferences = new List<Preference>[NumInstances, NumDimension];
        }

        private string GetImitationModel(out LinearModel model, out double beta, out int currentIter, bool extended,
            string probability = "equal", bool timedependent = false, int numFeatures = 16, int modelID = 1)
        {
            const string DIR = @"C:\users\helga\Alice\Code\PREF\weights";

            string pat = String.Format("\\b(exhaust|full)\\.{0}.{1}.{2}.(OPT|IL([0-9]+){3}{4}).{5}.weights.{6}",
                Distribution, Dimension, (char) PreferenceSet.Ranking.PartialPareto, Track.ToString().Substring(2),
                extended ? "EXT" : "", probability, timedependent ? "timedependent" : "timeindependent");

            Regex reg = new Regex(pat);

            var files = Directory.GetFiles(DIR, "*.csv")
                .Where(path => reg.IsMatch(path))
                .ToList();

            if (files.Count <= 0)
                throw new Exception(String.Format("Cannot find any weights belonging to {0}. Start with optimal!", Track));

            int[] iters = new int[files.Count];
            for (int i = 0; i < iters.Length; i++)
            {
                Match m = reg.Match(files[i]);
                if (m.Groups[2].Value == "OPT")
                    iters[i] = 0;
                else
                    iters[i] = Convert.ToInt32(m.Groups[3].Value);
            }

            currentIter = iters.Max() + 1;
            switch (Track)
            {
                case Trajectory.ILFIX:
                    beta = 0.5;
                    break;
                case Trajectory.ILSUP:
                    beta = Math.Pow(0.5, currentIter);
                    break;
                case Trajectory.ILUNSUP:
                    beta = 0;
                    break;
                default:
                    throw new Exception(String.Format("{0} is not supported as imitation learning!", Track));
            }

            string weightFile = files[Array.FindIndex(iters, x => x == iters.Max())];
            model = new LinearModel(new FileInfo(weightFile), numFeatures, modelID);
            return String.Format("IL{0}{1}", currentIter, Track.ToString().Substring(2));
        }

        public void Write()
        {
            Write(FileMode.Append, Preferences);
        }

        internal void Write(FileMode fileMode, List<Preference>[,] data)
        {
            bool dispatch = data == Preferences; 

            var fs = new FileStream(FileInfo.FullName, fileMode, FileAccess.Write);
            using (var st = new StreamWriter(fs))
            {
                if (fs.Length == 0) // header is missing 
                {
                    var header = String.Format("PID,Step{0},Followed,ResultingOptMakespan,Rank", dispatch ? ",Dispatch" : "");
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
                    st.WriteLine(header);
                }

                for (int pid = fileMode == FileMode.Append ? AlreadySavedPID + 1 : 1; pid <= NumInstances; pid++)
                {
                    for (int step = 0; step < NumDimension; step++)
                    {
                        var prefs = data[pid - 1, step];
                        if (prefs == null)
                        {
                            AlreadySavedPID = pid - 1;
                            st.Close();
                            fs.Close();
                            return;
                        }
                        foreach (var pref in prefs)
                        {
                            string info = String.Format("{0},{1}{2},{3},{4},{5}", pid, step,
                                dispatch ? String.Format(",{0}", pref.Dispatch.Name) : "",
                                pref.Followed ? 1 : 0, pref.ResultingOptMakespan, pref.Rank);
                            switch (FeatureMode)
                            {
                                case Features.Mode.Global:
                                    for (var i = 0; i < (int) Features.Global.Count; i++)
                                        info += string.Format(",{0:0}", pref.Feature.PhiGlobal[i]);
                                    break;
                                case Features.Mode.Local:
                                    for (var i = 0; i < (int) Features.Local.Count; i++)
                                        info += string.Format(",{0:0}", pref.Feature.PhiLocal[i]);
                                    break;
                            }
                            st.WriteLine(info);
                        }
                    }
                }
                st.Close();
            }
            fs.Close();
        }

        public void Apply()
        {
            for (int pid = AlreadySavedPID + 1; pid <= NumInstances; pid++)
                CollectAndLabel(pid);
            Write();
        }

        public string Apply(int pid)
        {
            return CollectAndLabel(pid);
        }

        protected string CollectAndLabel(int pid)
        {
            string name = GetName(pid);
            DataRow instance = Rows.Find(name);
            ProblemInstance prob = (ProblemInstance) instance["Problem"];

            GurobiJspModel gurobiModel = new GurobiJspModel(prob, name, TMLIM_STEP);

            Schedule jssp = new Schedule(prob);
            int currentNumFeatures = 0;
            for (int step = 0; step < prob.Dimension; step++)
            {
                Preferences[pid - 1, step] = FindFeaturesForAllJobs(jssp, gurobiModel);
                int dispatchedJob = _trajectory(jssp, Preferences[pid - 1, step]);
                jssp.Dispatch1(dispatchedJob, Features.Mode.None);
                gurobiModel.CommitConstraint(jssp.Sequence[step], step);
                Preferences[pid - 1, step].Find(x => x.Dispatch.Job == dispatchedJob).Followed = true;
                currentNumFeatures += Preferences[pid - 1, step].Count;
            }
            NumFeatures += currentNumFeatures;
            gurobiModel.Dispose();
            RankPreferences(pid);
            return String.Format("{0}:{1} #{2} phi", FileInfo.Name, pid, currentNumFeatures);
        }

        protected void RankPreferences(int pid)
        {
            for (var step = 0; step < NumDimension; step++)
            {
                var prefs = Preferences[pid - 1, step];
                var cmax = prefs.Select(p => p.ResultingOptMakespan).Distinct().OrderBy(x => x).ToList();
                foreach (var pref in prefs)
                {
                    var rank = cmax.FindIndex(ms => ms == pref.ResultingOptMakespan);
                    pref.Rank = rank;
                }
            }
        }

        private List<Preference> FindFeaturesForAllJobs(Schedule jssp, GurobiJspModel gurobiModel)
        {
            Preference[] prefs = new Preference[jssp.ReadyJobs.Count];
            for (int r = 0; r < jssp.ReadyJobs.Count; r++)
            {
                Schedule lookahead = jssp.Clone();
                Features phi = lookahead.Dispatch1(jssp.ReadyJobs[r], FeatureMode); // commit the lookahead
                prefs[r] = new Preference(lookahead.Sequence[lookahead.Sequence.Count - 1], phi);
                // need to optimize to label featuers correctly -- this is computationally intensive
                gurobiModel.Lookahead(prefs[r].Dispatch, out prefs[r].ResultingOptMakespan);
                prefs[r].SimplexIterations = gurobiModel.SimplexIterations;
            }
            return prefs.ToList();
        }

        private int ChooseOptJob(Schedule jssp, List<Preference> prefs)
        {
            int minMakespan = prefs.Min(p => p.ResultingOptMakespan);
            List<Preference> optimums = prefs.Where(p => p.ResultingOptMakespan == minMakespan).ToList();
            return optimums.Count == 1 ? optimums[0].Dispatch.Job : optimums[Random.Next(0, optimums.Count)].Dispatch.Job;
        }

        private int ChooseWeightedJob(Schedule jssp, List<Preference> prefs)
        {
            List<double> priority = new List<double>(jssp.ReadyJobs.Count);
            for (int r = 0; r < jssp.ReadyJobs.Count; r++)
                priority.Add(Model.PriorityIndex(prefs[r].Feature));
            return jssp.ReadyJobs[priority.FindIndex(p => Math.Abs(p - priority.Max()) < 0.001)];
        }

        private int UseImitationLearning(Schedule jssp, List<Preference> prefs)
        {
            // pi_i = beta_i*pi_star + (1-beta_i)*pi_i^hat
            // i: ith iteration of imitation learning
            // pi_star is expert policy (i.e. optimal)
            // pi_i^hat: is pref model from prev. iteration
            double pr = Random.NextDouble();
            return Model != null && pr >= _beta
                ? ChooseWeightedJob(jssp, prefs)
                : ChooseOptJob(jssp, prefs);
        }

        private int ChooseSDRJob(Schedule jssp, List<Preference> prefs = null)
        {
            return jssp.JobChosenBySDR((SDRData.SDR) Track);
        }
    }
}