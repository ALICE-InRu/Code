using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;

public enum RankingScheme
{
    fullPareto = 'f',
    partialPareto = 'p',
    basic = 'b',
    all = 'a'
};

public class FullData : DataTable
{
    public string WorkingDirectory;

    public Data Distribution;
    public int NumInstances;
    public int NumFeatures;

    public int Dimension;
    public List<Preference>[][] Data;
    public FeatureType FeatureType;
    public readonly Random Random = new Random();

    public void SetFullData(string workingDirectory, Data distribution)
    {
        Distribution = distribution;
        int numJobs, numMachines;
        AuxFun.Dimension2Info(distribution.Dimension, out numJobs, out numMachines);
        Dimension = numJobs * numMachines;
        NumInstances = distribution.NumInstances;

        WorkingDirectory = workingDirectory;
        if (!Directory.Exists(WorkingDirectory))
            Directory.CreateDirectory(WorkingDirectory);

        Data = new List<Preference>[NumInstances][];
        for (int pid = 0; pid < NumInstances; pid++)
        {
            Data[pid] = new List<Preference>[Dimension];
            for (int dim = 0; dim < Dimension; dim++)
                Data[pid][dim] = new List<Preference>();
        }

        Columns.Add("Name", typeof(string));
        PrimaryKey = new[] { Columns["Name"] };

        Columns.Add("Shop", typeof(char));
        Columns.Add("Distribution", typeof(string));
        Columns.Add("Problem", typeof(ProblemInstance));
        Columns.Add("Dimension", typeof(int));
        Columns.Add("Set", typeof(string)); // should always be train !
        Columns.Add("PID", typeof(int)); // problem instance id
        Columns.Add("Step", typeof(int));
        Columns.Add("NumJobs", typeof(int));
        Columns.Add("NumMachines", typeof(int));
        Columns.Add("Track", typeof(string));
        Columns.Add("Rho", typeof(double));
        Columns.Add("Note", typeof(string));
        Columns.Add("Features", typeof(Features));
        Columns.Add("Dispatch", typeof(Schedule.Dispatch));
        Columns.Add("Followed", typeof(bool));
        Columns.Add("Rank", typeof(int));

        NumFeatures = 0;
    }

    public class Preference : DiffPreference
    {
        public string Name;
        public Schedule.Dispatch Dispatch;
        public int SimplexIterations;

        public DiffPreference Difference(Preference other)
        {
            DiffPreference diff = new DiffPreference
            {
                Rank = Rank - other.Rank,
                ResultingMakespan = ResultingMakespan - other.ResultingMakespan,
                Feature = Feature.Difference(other.Feature),
                Followed = Followed | other.Followed
                //Rho = Rho - other.Rho
            };
            //(this.Rank == other.Rank ? 0 : (this.Rank < other.Rank) ? 1 : -1);
            //diff.SimplexIterations = this.SimplexIterations - other.SimplexIterations;
            return diff;
        }
    }

    public class DiffPreference
    {
        public Features Feature;
        //public int SimplexIterations;
        public int ResultingMakespan;
        public int Rank;
        public bool Followed;
    }

    public bool ValidateDispatches(ref List<Preference> prefs, Schedule jssp)
    {
        if (prefs.FindIndex(p => p.Dispatch.Mac < 0) == -1) return true;
        foreach (Preference pref in prefs)
        {
            jssp.FindDispatch(pref.Dispatch.Job, out pref.Dispatch);
            Rows.Find(pref.Name)["Dispatch"] = pref.Dispatch;
        }
        return false;
    }

}

public class TestingData : FullData
{
    public readonly LinearModel Model;
    public string Filename;

    public TestingData(Data data, LinearModel model, string workingDirectory)
    {
        SetFullData(workingDirectory, data);
        Model = model;
        string set = (string)data.Rows[0]["Set"];
        Filename = WorkingDirectory + data.Name + "." + data.Dimension + "." + set + "." + model.Name + ".csv";

        Columns.Add("FinalPrefMakespan", typeof(int));
        Columns.Add("ResultingPrefMakespan", typeof(int));
        Columns.Add("OptDispatch", typeof(bool));
        Columns.Add("BestDispatch", typeof(bool));
        Columns.Add("Model", typeof(string));
    }

    public string ApplyModel(DataRow instance, Track track, LinearModel model, int optimumMakespan)
    {
        return TrackTrajectoryWithModel(instance, track, model, optimumMakespan);
    }

    private string TrackTrajectoryWithModel(DataRow instance, Track track, LinearModel model, int optimumMakespan)
    {
        string distribution = (string)instance["Distribution"];
        ProblemInstance prob = (ProblemInstance)instance["Problem"];
        string name = (string)instance["Name"];

        Schedule jssp = new Schedule(prob);
        int currentNumFeatures = 0;

        for (int step = 0; step < prob.Dimension; step++)
        {
            #region find features of possible jobs
            Preference[] preferences = new Preference[jssp.ReadyJobs.Count];
            for (int r = 0; r < jssp.ReadyJobs.Count; r++)
            {
                Schedule lookahead = jssp.Clone();

                preferences[r] = new Preference
                {
                    Feature = lookahead.Dispatch1(jssp.ReadyJobs[r], model.FeatureType),
                    Dispatch = lookahead.Sequence[lookahead.Sequence.Count - 1],
                    Name = name + "." + step + "_" + jssp.ReadyJobs[r]
                };

                switch (track)
                {
                    case Track.CMA:
                    case Track.PREF:
                        lookahead.ApplyCDR(model);
                        break;
                    default:
                        lookahead.ApplySDR((SDR)track, model.FeatureType);
                        break;
                }

                preferences[r].ResultingMakespan = lookahead.Makespan;
                // preferences[r].Rho = Schedule.RhoMeasure(optimumMakespan, lookahead.Makespan);
            }
            #endregion

            #region commit job chosen by tracjectory specified
            int dispatchedJob;
            switch (track)
            {
                case Track.PREF: // linear weights!
                case Track.CMA:
                    List<double> priority = new List<double>(jssp.ReadyJobs.Count);
                    for (int r = 0; r < jssp.ReadyJobs.Count; r++)
                        priority.Add(model.PriorityIndex(preferences[r].Feature));

                    dispatchedJob = jssp.ReadyJobs[priority.FindIndex(p => Math.Abs(p - priority.Max()) < 0.001)];
                    break;
                default:
                    dispatchedJob = jssp.JobChosenBySDR((SDR)track);
                    break;
            }
            jssp.Dispatch1(dispatchedJob, FeatureType.None);
            #endregion

            var bestFinalMakespan = preferences.Min(p => p.ResultingMakespan);
            var finalPrefMakespan =
                preferences.ToList().Find(p => p.Dispatch.Job == dispatchedJob).ResultingMakespan;

            #region report preference to outer loop
            if (jssp.Sequence.Count != prob.Dimension) continue;
            foreach (Preference preference in preferences)
            {
                DataRow rowFeature = NewRow();
                rowFeature["Model"] = model.Name;
                rowFeature["Shop"] = prob.ShopProblem;
                rowFeature["Distribution"] = distribution;
                rowFeature["Problem"] = prob;
                rowFeature["Dimension"] = prob.Dimension;
                rowFeature["Set"] = (string)instance["Set"];
                rowFeature["PID"] = (int)instance["PID"];
                rowFeature["NumJobs"] = prob.NumJobs;
                rowFeature["NumMachines"] = prob.NumMachines;
                rowFeature["Track"] = track;
                rowFeature["Step"] = step;
                rowFeature["Note"] = string.Empty;
                rowFeature["FinalPrefMakespan"] = finalPrefMakespan;
                rowFeature["Name"] = preference.Name;
                rowFeature["Dispatch"] = preference.Dispatch;
                rowFeature["Features"] = preference.Feature;
                rowFeature["ResultingPrefMakespan"] = preference.ResultingMakespan;
                rowFeature["Followed"] = dispatchedJob == preference.Dispatch.Job;
                rowFeature["OptDispatch"] = preference.ResultingMakespan == optimumMakespan;
                rowFeature["BestDispatch"] = preference.ResultingMakespan == bestFinalMakespan;
                //rowFeature["Simplex"] = pref[r].SimplexIterations;
                Rows.Add(rowFeature);
                NumFeatures++;
                currentNumFeatures++;
            }
            #endregion
        }
        return prob.ShopProblem + "." + distribution + '.' + track + "." + (int)instance["PID"] + ": " +
               currentNumFeatures + " features";
    }

    public void WriteCsv(bool overwrite)
    {
        List<string> write = new List<string>
        {
            "Shop",
            "Distribution",
            "Set",
            "PID",
            "Track",
            "Model",
            "Step",
            "Dispatch",
            "Followed",
            "Features",
            "ResultingPrefMakespan",
            "Rho",
            "OptDispatch",
            "BestDispatch"
        };
        FileInfo file = new FileInfo(Filename);
        if (overwrite | !file.Exists)
            AuxFun.WriteDataTable2Csv(file, this, write, FileMode.Create, FeatureType.Local);
    }
}

public class TrainingData : FullData
{
    public readonly string Problem;
    public readonly string FileName;

    public RankingScheme[] RankingSchemes;
    public readonly Track Track;
    public bool Ranked;
    public string Error { get; private set; }

    public TrainingData(Data distribution, Track track, string trackName, FeatureType featureType,
        string trainingDirectory, string workingDirectory, string error, RankingScheme[] rankingSchemes = null)
    {
        Problem = distribution.Name.Substring(2);
        FeatureType = featureType;

        SetFullData(workingDirectory, distribution);

        RankingSchemes = rankingSchemes;
        Track = track;
        Error = error;

        FileName = String.Format("{0}trdat.{1}.{2}.{3}{4}.{5}.csv", trainingDirectory, Distribution.Name,
            Distribution.Dimension, trackName, distribution.Rows.Count == 5000 ? "EXT" : "", FeatureType);

        //Columns.Add("Solver", typeof(string));
        Columns.Add("Simplex", typeof(int)); // number of simplex iterations
        Columns.Add("TrueOptMakespan", typeof(int));
        Columns.Add("ResultingOptMakespan", typeof(int));
    }

    public void RankPreferences(int pid)
    {
        for (int step = 0; step < Dimension; step++)
        {
            List<Preference> prefs = Data[pid][step];
            List<int> cmax = prefs.Select(p => p.ResultingMakespan).Distinct().OrderBy(x => x).ToList();
            foreach (Preference pref in prefs)
            {
                int rank = cmax.FindIndex(ms => ms == pref.ResultingMakespan);
                pref.Rank = rank;
                Rows.Find(pref.Name)["Rank"] = rank;
            }
        }
        Ranked = true;
    }

    public int CountPreferencePairs(List<DiffPreference>[][] diffData)
    {
        int pairs = 0;
        for (int pid = 0; pid < NumInstances; pid++)
            for (int step = 0; step < Dimension; step++)
                pairs += diffData[pid][step].Count;
        return pairs;
    }

    private void BasicRanking(List<Preference> prefs, ref List<DiffPreference> diffData)
    {
        for (int opt = 0; opt < prefs.Count; opt++)
        {
            if (prefs[opt].Rank > 0)
            {
                break;
            }

            for (int sub = opt + 1; sub < prefs.Count; sub++)
            {
                if (prefs[opt].Rank != prefs[sub].Rank)
                {
                    diffData.Add(prefs[opt].Difference(prefs[sub]));
                    diffData.Add(prefs[sub].Difference(prefs[opt]));
                }
            }
        }
    }

    private void FullParetoRanking(List<Preference> prefs, ref List<DiffPreference> diffData)
    {
        diffData.AddRange(from pi in prefs
            from pj in prefs
            where /* subsequent ranking */ Math.Abs(pi.Rank - pj.Rank) == 1
            select pi.Difference(pj));
    }

    private void PartialParetoRanking(List<Preference> prefs, ref List<DiffPreference> diffData)
    {
        // subsequent ranking
        // partial, yet sufficient, pareto ranking
        bool[] inTrainingSet = new bool[prefs.Count];
        for (int i = 0; i < prefs.Count; i++)
            for (int j = 0; j < prefs.Count; j++)
                if (Math.Abs(prefs[i].Rank - prefs[j].Rank) == 1) // subsequent ranking
                    // partial, yet sufficient, pareto ranking
                    if (!inTrainingSet[i] | !inTrainingSet[j])
                    {
                        DiffPreference ijDiff = prefs[i].Difference(prefs[j]);
                        diffData.Add(ijDiff);

                        DiffPreference jiDiff = prefs[j].Difference(prefs[i]);
                        diffData.Add(jiDiff);

                        inTrainingSet[i] = true;
                        inTrainingSet[j] = true;
                    }
    }

    private void AllRankings(List<Preference> prefs, ref List<DiffPreference> diffData)
    {
        diffData.AddRange(from pi in prefs
            from pj in prefs
            where /* full ranking */ pi.Rank != pj.Rank
            select pi.Difference(pj));
    }

    public void CreatePreferencePairs(int pid, RankingScheme ranking, List<DiffPreference>[][] diffData)
    {
        for (int step = 0; step < Dimension; step++)
        {
            List<Preference> prefs = Data[pid][step];
            prefs = prefs.OrderBy(p => p.Rank).ToList();

            switch (ranking)
            {
                case RankingScheme.fullPareto:
                    FullParetoRanking(prefs, ref diffData[pid][step]);
                    break;
                case RankingScheme.partialPareto:
                    PartialParetoRanking(prefs, ref diffData[pid][step]);
                    break;
                case RankingScheme.basic:
                    BasicRanking(prefs, ref diffData[pid][step]);
                    break;
                case RankingScheme.all:
                    AllRankings(prefs, ref diffData[pid][step]);
                    break;
            }
        }
    }

    public string CreateTrainingData(DataRow instance, Track track, LinearModel linearModel2Follow)
    {   
        FeatureType featType=FeatureType.Local;

        string distribution = (string)instance["Distribution"];
        ProblemInstance prob = (ProblemInstance)instance["Problem"];

        string name = (string)instance["Name"];

        const int TMLIM_OPT = 60 * 10; // max 10 min for optimum
        const int TMLIM_STEP = 60 * 2; // max 2 min per step/possible dispatch

        GurobiJspModel gurobiModel = new GurobiJspModel(prob, name, TMLIM_OPT, true);
        var trueOptimumMakespan = gurobiModel.TrueOptimum;
        gurobiModel.SetTimeLimit(TMLIM_STEP);
        
        int currentNumFeatures = 0;

        if (linearModel2Follow != null)
            if (linearModel2Follow.FeatureType > featType)
                featType = linearModel2Follow.FeatureType;

        Schedule jssp = new Schedule(prob);
        for (int step = 0; step < prob.Dimension; step++)
        {
            #region find features of possible jobs

            Preference[] prefs = new Preference[jssp.ReadyJobs.Count];
            for (int r = 0; r < jssp.ReadyJobs.Count; r++)
            {
                Schedule lookahead = jssp.Clone();

                prefs[r] = new Preference
                {
                    Feature = lookahead.Dispatch1(jssp.ReadyJobs[r], featType),
                    Dispatch = lookahead.Sequence[lookahead.Sequence.Count - 1],
                    Name = name + "." + step + "_" + jssp.ReadyJobs[r]
                };

                // need to optimize to label featuers correctly 
                // INTENSE WORK
                gurobiModel.Lookahead(prefs[r].Dispatch, out prefs[r].ResultingMakespan);
                prefs[r].SimplexIterations = gurobiModel.SimplexIterations;
            }

            #endregion

            #region commit job chosen by tracjectory specified

            int dispatchedJob;
            switch (track)
            {
                case Track.OPT:
                    dispatchedJob = ChooseOptJob(prefs);
                    break;
                case Track.PREF:
                    // pi_i = beta_i*pi_star + (1-beta_i)*pi_i^hat
                    // i: ith iteration of imitation learning
                    // pi_star is expert policy (i.e. optimal)
                    // pi_i^hat: is pref model from prev. iteration
                    double pr = Random.NextDouble();
                    dispatchedJob = linearModel2Follow != null && pr >= linearModel2Follow.Beta
                        ? ChooseWeightedJob(prefs, jssp, linearModel2Follow)
                        : ChooseOptJob(prefs);
                    break;
                case Track.CMA:
                    dispatchedJob = ChooseWeightedJob(prefs, jssp, linearModel2Follow);
                    break;
                default:
                    dispatchedJob = jssp.JobChosenBySDR((SDR)track);
                    break;
            }
            jssp.Dispatch1(dispatchedJob, FeatureType.None);
            gurobiModel.CommitConstraint(jssp.Sequence[step], step);

            #endregion

            #region report preference to outer loop

            foreach (Preference pref in prefs)
            {
                DataRow rowFeature = NewRow();
                rowFeature["Shop"] = prob.ShopProblem;
                rowFeature["Distribution"] = distribution;
                rowFeature["Problem"] = prob;
                rowFeature["Dimension"] = prob.Dimension;
                rowFeature["Set"] = (string)instance["Set"];
                rowFeature["PID"] = (int)instance["PID"];
                rowFeature["NumJobs"] = prob.NumJobs;
                rowFeature["NumMachines"] = prob.NumMachines;
                rowFeature["Track"] = track;
                rowFeature["Step"] = step;
                rowFeature["Note"] = string.Empty;
                rowFeature["TrueOptMakespan"] = trueOptimumMakespan;
                rowFeature["Name"] = pref.Name;
                rowFeature["Dispatch"] = pref.Dispatch;
                rowFeature["Features"] = pref.Feature;
                rowFeature["ResultingOptMakespan"] = pref.ResultingMakespan;
                rowFeature["Followed"] = dispatchedJob == pref.Dispatch.Job;
                rowFeature["Simplex"] = pref.SimplexIterations;
                Rows.Add(rowFeature);
                NumFeatures++;
                currentNumFeatures++;
            }

            #endregion
        }

        if (gurobiModel != null)
            gurobiModel.Dispose();

        return prob.ShopProblem + "." + distribution + '.' + track + "." + (int)instance["PID"] + ": " +
               currentNumFeatures + " features";
    }

    private int ChooseWeightedJob(Preference[] pref, Schedule jssp, LinearModel linearModel2Follow)
    {
        List<double> priority = new List<double>(jssp.ReadyJobs.Count);
        for (int r = 0; r < jssp.ReadyJobs.Count; r++)
            priority.Add(linearModel2Follow.PriorityIndex(pref[r].Feature));
        return jssp.ReadyJobs[priority.FindIndex(p => Math.Abs(p - priority.Max()) < 0.001)];
    }

    private int ChooseOptJob(Preference[] pref)
    {
        int minMakespan = pref.Min(p => p.ResultingMakespan);
        List<Preference> optimums = pref.ToList().Where(p => p.ResultingMakespan == minMakespan).ToList();
        return optimums.Count == 1 ? optimums[0].Dispatch.Job : optimums[Random.Next(0, optimums.Count)].Dispatch.Job;
    }

    public enum CSVType
    {
        Gen,
        Rank,
        Diff
    };

    public void WriteCSV(CSVType type, FileInfo file, List<DiffPreference>[][] diffData = null,
        int alreadyAutoSavedPid = -1)
    {
        List<string> write = new List<string>
        {
            "PID",
            "Step",
            "Dispatch",
            "Followed",
            "ResultingOptMakespan",
            "Features" /*,"Rho"*/
        };

        if (FeatureType == FeatureType.Local) write.Add("Simplex");

        switch (type)
        {
            case CSVType.Gen:
            case CSVType.Rank:

                if (type == CSVType.Rank) write.Add("Rank");
                AuxFun.WriteDataTable2Csv(file, this, write, FileMode.Append, FeatureType, false,
                    alreadyAutoSavedPid);
                break;
            case CSVType.Diff:
                AuxFun.WriteDifference2Csv(file, diffData, FileMode.Create, Distribution.Name, Track, FeatureType);
                break;
        }
    }


    public void Retrace(int pid)
    {
        string name = Distribution.Name + "." + Distribution.Dimension + "." + Distribution.Set + "." +
                      (pid + 1);

        DataRow instance = Distribution.Rows.Find(name);
        ProblemInstance prob = (ProblemInstance)instance["Problem"];

        Schedule jssp = new Schedule(prob);
        for (int step = 0; step < prob.Dimension; step++)
        {
            #region find features of possible jobs

            List<Preference> prefs = Data[pid][step];
            ValidateDispatches(ref prefs, jssp);
            int dispatchedJob;
            if (prefs.Count > 0)
            {
                foreach (Preference p in prefs)
                {
                    Schedule lookahead = jssp.Clone();
                    p.Feature = lookahead.Dispatch1(p.Dispatch.Job, FeatureType);
                    DataRow row = Rows.Find(p.Name);
                    row["Features"] = p.Feature;
                }

                Preference followed = prefs.Find(p => p.Followed);
                dispatchedJob = followed == null ? jssp.JobChosenBySDR((SDR)Track) : followed.Dispatch.Job;
            }
            else
            {
                dispatchedJob = jssp.ReadyJobs.Count > 1 ? jssp.JobChosenBySDR((SDR)Track) : jssp.ReadyJobs[0];
            }

            #endregion

            jssp.Dispatch1(dispatchedJob, FeatureType.None);
        }
    }

}