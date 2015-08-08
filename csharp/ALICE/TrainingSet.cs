using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;

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
            CMAESMINCMAX,
            CMAESMINRHO,
            RND,
            ILUNSUP,
            ILSUP,
            ILFIXSUP,
            LOCOPT,
            ALL
        }

        private readonly Func<Schedule, List<Preference>, int> _trajectory;
        internal readonly Trajectory Track;

        public readonly int NumTraining;
        public int NumFeatures { get; internal set; }
        private const int TMLIM_STEP = 2; // max 2 min per step/possible dispatch

        internal Features.Mode FeatureMode = Features.Mode.Local;

        internal readonly List<Preference>[,] Preferences;
        internal Random Random = new Random();

        internal LinearModel Model;
        private readonly double _beta; // only used in imitation learning 

        internal class Preference
        {
            public Features Feature;
            public int ResultingOptMakespan;
            public int Rank;
            public bool Followed;

            public Schedule.Dispatch Dispatch;
            public int SimplexIterations;

            public double Priority; 

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

        public TrainingSet(string distribution, string dimension, Trajectory track, bool extended, DirectoryInfo data)
            : this(distribution, dimension, track, -1, extended, data)
        {

        }

        internal TrainingSet(string distribution, string dimension, Trajectory track, int iter, bool extended, DirectoryInfo data)
            : base(distribution, dimension, DataSet.train, extended, data)
        {
            Track = track;
            string strTrack = track.ToString();
            NumInstances = ResetNumInstances(extended);
            NumTraining = ResetNumInstances(false);
            
            switch (Track)
            {
                case Trajectory.ILFIXSUP:
                case Trajectory.ILSUP:
                case Trajectory.ILUNSUP:
                    strTrack = GetImitationModel(out Model, out _beta, ref iter, extended);
                    if (Track == Trajectory.ILUNSUP)
                        _trajectory = ChooseWeightedJob;
                    else
                        _trajectory = UseImitationLearning;

                    if (extended)
                    {
                        AlreadySavedPID = Math.Max(AlreadySavedPID, NumTraining*iter);
                        NumInstances = Math.Min(Data.Rows.Count, NumTraining*(iter + 1));
                    }

                    break;
                case Trajectory.CMAESMINCMAX:
                    GetCMAESModel(out Model, CMAESData.ObjectiveFunction.MinimumMakespan);
                    _trajectory = ChooseWeightedJob;
                    break;
                case Trajectory.CMAESMINRHO:
                    GetCMAESModel(out Model, CMAESData.ObjectiveFunction.MinimumRho);
                    _trajectory = ChooseWeightedJob;
                    break;
                case Trajectory.OPT:
                    Model = null;
                    _trajectory = ChooseOptJob;
                    break;
                case Trajectory.LOCOPT:
                    Model = null;
                    _trajectory = ChooseLocalOptJob;
                    break;
                default: // SDR  
                    Model = new LinearModel((SDRData.SDR) Track, distribution, Dimension);
                    _trajectory = ChooseSDRJob;
                    break;
            }
            if (extended) strTrack += "EXT";


            FileInfo =
                new FileInfo(string.Format(
                    @"{0}\Training\trdat.{1}.{2}.{3}.{4}.csv", data.FullName,
                    Distribution, Dimension, strTrack, FeatureMode));

            Data.Columns.Add("Step", typeof (int));
            Data.Columns.Add("Dispatch", typeof (Schedule.Dispatch));
            Data.Columns.Add("Followed", typeof (bool));
            Data.Columns.Add("ResultingOptMakespan", typeof (int));
            Data.Columns.Add("Features", typeof (Features));

            SetAlreadySavedPID();

            Preferences = new List<Preference>[NumInstances, NumDimension];
        }

        private string GetImitationModel(out LinearModel model, out double beta, ref int currentIter, bool extended)
        {
            model = new LinearModel(Distribution, Dimension, Track, extended, PreferenceSet.Ranking.PartialPareto, false,
                new DirectoryInfo(String.Format(@"{0}\..", FileInfo.DirectoryName)));

            if (currentIter < 0) // use latest iteration
                currentIter = model.Iteration + 1;

            switch (Track)
            {
                case Trajectory.ILFIXSUP:
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

            return String.Format("IL{0}{1}", currentIter, Track.ToString().Substring(2));
        }

        private void GetCMAESModel(out LinearModel model, CMAESData.ObjectiveFunction objFun)
        {
            model = new LinearModel(Distribution, Dimension, objFun, false,
                new DirectoryInfo(String.Format(@"{0}\..", FileInfo.DirectoryName)));
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
                    var header = String.Format("PID,Step{0},Followed,ResultingOptMakespan,Rank",
                        dispatch ? ",Dispatch" : "");
                    switch (FeatureMode)
                    {
                        case Features.Mode.Global:
                            for (var i = 0; i < Features.GlobalCount; i++)
                                header += string.Format(",phi.{0}", (Features.Global) i);
                            break;
                        case Features.Mode.Local:
                            for (var i = 0; i < Features.LocalCount; i++)
                                header += string.Format(",phi.{0}", (Features.Local) i);

                            if (dispatch)
                            {
                                for (var i = 0; i < Features.ExplanatoryCount; i++)
                                    header += string.Format(",xi.{0}", (Features.Explanatory) i);
                            }
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
                                    for (var i = 0; i < Features.GlobalCount; i++)
                                        info += string.Format(",{0:0}", pref.Feature.PhiGlobal[i]);
                                    break;
                                case Features.Mode.Local:
                                    for (var i = 0; i < Features.LocalCount; i++)
                                        info += string.Format(",{0:0}", pref.Feature.PhiLocal[i]);

                                    if (!dispatch) break;
                             
                                    for (var i = 0; i < Features.ExplanatoryCount; i++)
                                        info += string.Format(",{0:0}", pref.Feature.XiExplanatory[i]);
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

        internal string CollectAndLabel(int pid)
        {
            string name = GetName(pid);
            DataRow instance = Data.Rows.Find(name);
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
            return optimums.Count == 1
                ? optimums[0].Dispatch.Job
                : optimums[Random.Next(0, optimums.Count)].Dispatch.Job;
        }

        private int ChooseLocalOptJob(Schedule jssp, List<Preference> prefs)
        {
            const double EPSILON = 0.1;
            if (Random.NextDouble() > EPSILON)
                return ChooseOptJob(jssp, prefs);

            int minMakespan = prefs.Min(p => p.ResultingOptMakespan);
            List<Preference> epsGreedy = prefs.Where(p => p.ResultingOptMakespan > minMakespan).ToList();
            if (epsGreedy.Count == 0)
                return ChooseOptJob(jssp, prefs);

            int nextBest = epsGreedy.Min(p => p.ResultingOptMakespan);
            epsGreedy = epsGreedy.Where(p => p.ResultingOptMakespan == nextBest).ToList();
            return epsGreedy.Count == 1
                ? epsGreedy[0].Dispatch.Job
                : epsGreedy[Random.Next(0, epsGreedy.Count)].Dispatch.Job;
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