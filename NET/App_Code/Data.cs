using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

/// <summary>
/// Parent class for all JobShop data
/// </summary>
public class RawData : DataTable
{
    public FileInfo FileInfo;
    public readonly string Distribution;
    public readonly int NumDimension;
    public readonly string Dimension;
    public readonly string Set; // test or train
    public int NumInstances;

    internal int AlreadyAutoSavedPID = -1;

    public RawData(string distribution, string dimension, string set)
    {
        Distribution = distribution;
        Dimension = dimension;
        NumDimension = DimString2Num(dimension);
        Set = set.ToLower();

        Columns.Add("Name", typeof (string)); // unique!
        Columns.Add("Set", typeof (string)); // test or train
        Columns.Add("PID", typeof (int)); // problem instance Index
        Columns.Add("Problem", typeof (ProblemInstance));

        PrimaryKey = new[] {Columns["Name"]};
    }

    protected RawData()
    {
        throw new NotImplementedException();
    }

    public static int DimString2Num(string dim)
    {
        var jobxmac = Regex.Split(dim, "x");
        var numJobs = Convert.ToInt32(jobxmac[0]);
        var numMachines = Convert.ToInt32(jobxmac[1]);
        return numJobs*numMachines;
    }

    public void AddProblem(ProblemInstance prob, string distribution, char shopProblem, string note = "")
    {
        var pid = NumInstances;
        var row = NewRow();
        row["Name"] = GetName(pid);
        row["Set"] = Set;
        row["PID"] = pid;
        row["Problem"] = prob;
        NumInstances++;
        Rows.Add(row);
    }

    internal string GetName(int pid)
    {
        return String.Format("{0}.{1}.{2}.{3}", Distribution, Dimension, Set, pid + 1).ToLower();
            // pid is otherwise starting from 0 - we want proper pid starting from 1 on R-side
    }
    
    internal List<string[]> ReadCSV()
    {
        if (!FileInfo.Exists) return null;
        var content = new List<string[]>();

        var fs = new FileStream(FileInfo.FullName, FileMode.Open, FileAccess.Read);
        using (var st = new StreamReader(fs))
        {
            while (st.Peek() != -1) // stops when it reachs the end of the file
            {
                var line = st.ReadLine();
                if (line == null) continue;
                var row = Regex.Split(line, ",");
                content.Add(row);
            }
            st.Close();
        }
        fs.Close();
        return content;
    }
}

/// <summary>
/// Optimum for RawData
/// </summary>
public class OPTData : RawData
{
    public OPTData()
    {
        FileInfo =
            new FileInfo(string.Format("C://Users//helga//Alice//Code//OPT//{0}.{1}.{2}.csv", Distribution, Dimension,
                Set));

        Columns.Add("Solved", typeof(string)); 
        Columns.Add("Optimum", typeof(int));
        Columns.Add("Solution", typeof (int[,]));
        Columns.Add("Solver", typeof (string));
        Columns.Add("Simplex", typeof (int));
    }

    public void AddOptMakespan(string name, int makespan, bool solved, int[,] xTimeJob, int simplexIterations,
        string solver)
    {
        var row = Rows.Find(name);
        row.SetField("Solved", solved ? "opt" : "bks"); 
        row.SetField("Optimum", makespan);
        row.SetField("Solution", xTimeJob);
        row.SetField("Solver", solver);
        row.SetField("Simplex", simplexIterations);
    }

    public bool Read()
    {
        var contents = ReadCSV();
        if (contents == null) return false;
        contents.RemoveAt(0); // HEADER

        foreach (var content in contents)
        {
            var row = Rows.Find(content[0]);
            if (row == null) continue;
            row["Optimum"] = content[1];
            row["Solved"] = content[2];

            AlreadyAutoSavedPID = (int) row["PID"];
        }

        return true;
    }

    public void Write()
    {
        var fs = new FileStream(FileInfo.FullName, FileMode.Append, FileAccess.Write);
        using (var st = new StreamWriter(fs))
        {
            if (fs.Length == 0) // header is missing 
            {
                const string HEADER = "Name,Optimum,Solved";
                st.WriteLine(HEADER);
            }

            foreach (var info in from DataRow row in Rows
                let pid = (int) row["PID"]
                where pid > AlreadyAutoSavedPID
                select String.Format("{0},{1},{2}", row["Name"], row["Optimum"], row["Solved"]))
            {
                st.WriteLine(info);
            }
            st.Close();
        }
        fs.Close();
    }
}

/// <summary>
/// SDR applied on RawData
/// </summary>
public class SDRData : RawData
{
    private readonly string _strSDR ; 
    public SDRData(SDR sdr)
    {
        FileInfo =
            new FileInfo(string.Format("C://Users//helga//Alice//Code//SDR//{0}.{1}.{2}.csv", Distribution, Dimension,
                Set));

        Columns.Add("Makespan", typeof(int));

        _strSDR = String.Format("{0}", sdr);
    }

    public bool Read()
    {
        var contents = ReadCSV();
        if (contents == null) return false;
        contents.RemoveAt(0); // HEADER
        foreach (var content in contents)
        {
            var row = Rows.Find(content[0]);
            if (row == null) continue;
            if (_strSDR != content[1]) continue;
            row["SDR"] = content[1];
            row["Makespan"] = Convert.ToInt32(content[2]);
            AlreadyAutoSavedPID = (int) row["PID"];
        }
        return true;
    }

    public void Write()
    {
        var fs = new FileStream(FileInfo.FullName, FileMode.Append, FileAccess.Write);
        using (var st = new StreamWriter(fs))
        {
            if (fs.Length == 0) // header is missing 
            {
                const string HEADER = "Name,SDR,Makespan";
                st.WriteLine(HEADER);
            }

            foreach (var info in from DataRow row in Rows
                                    let pid = (int)row["PID"]
                                    where pid > AlreadyAutoSavedPID
                                    select String.Format("{0},{1},{2}", row["Name"], row["SDR"], row["Makespan"]))
            {
                st.WriteLine(info);
            }
            st.Close();
        }
        fs.Close();
    }

}

/// <summary>
/// CDR applied on RawData
/// </summary>
public class CDRData : RawData
{
    public CDRData(string model, int nrFeat, int nrModel)
    {
        FileInfo =
            new FileInfo(string.Format(
                "C://Users//helga//Alice//Code//PREF//CDR//{0}//F{1}.Model{2}.on.{3}.{4}.{5}.csv",
                model, nrFeat, nrModel,
                Distribution, Dimension, Set));

        Columns.Add("Makespan", typeof(int));

    }
    
    public void Write()
    {
        var fs = new FileStream(FileInfo.FullName, FileMode.Append, FileAccess.Write);
        using (var st = new StreamWriter(fs))
        {
            if (fs.Length == 0) // header is missing 
            {
                const string HEADER = "Name,Makespan";
                st.WriteLine(HEADER);
            }

            foreach (var info in from DataRow row in Rows
                let pid = (int) row["PID"]
                where pid > AlreadyAutoSavedPID
                select String.Format("{0},{1}", row["Name"], row["Makespan"]))
            {
                st.WriteLine(info);
            }
            st.Close();
        }
        fs.Close();
    }

}

/// <summary>
/// Training set from RawData
/// </summary>
public class TrainingSet : RawData
{
    public enum Track
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
    private readonly bool _extended;

    private readonly Func<Schedule, TrSet[], LinearModel, int> _trajectory;
    private readonly Track _track;
    internal string StrTrack;

    public int NumFeatures;
    public readonly TrSet[,][] TrData;
    internal Random Random = new Random();

    public int NumTrain
    {
        get
        {
            return (Dimension == "10x10")
                ? (_extended ? 1000 : 300)
                : (_extended ? 5000 : 500);
        }
    }

    public class TrSet : PreferenceSet.PrefSet
    {
        public string Name;
        public Schedule.Dispatch Dispatch;
        public int SimplexIterations; 

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
    
    protected TrainingSet(Track track, bool extended)
    {
        _track = track;
        _extended = extended;
        StrTrack = String.Format("{0}{1}", track, extended ? "EXT" : "");

        FileInfo =
            new FileInfo(string.Format(
                "C://Users//helga//Alice//Code//trainingData//trdat.{0}.{1}.{2}.Local.csv",
                Distribution, Dimension, StrTrack));

        Columns.Add("Step", typeof(int));
        Columns.Add("Dispatch", typeof(Schedule.Dispatch));
        Columns.Add("Followed", typeof(bool));
        Columns.Add("ResultingOptMakespan", typeof(int));
        Columns.Add("Features", typeof(Features));

        TrData = new TrSet[NumInstances, NumDimension][];

        switch (track)
        {
            case Track.CMA:
            case Track.ILUNSUP:
                _trajectory = ChooseWeightedJob;
                break;
            case Track.OPT:
                _trajectory = ChooseOptJob;
                break;
            case Track.ILSUP:
            case Track.ILFIX:
                _trajectory = UseImitationLearning;
                break;
            default:
                _trajectory = ChooseSDRJob;
                break;
        }
    }
    
    public void Write()
    {
        var fs = new FileStream(FileInfo.FullName, FileMode.Append, FileAccess.Write);
        using (var st = new StreamWriter(fs))
        {
            if (fs.Length == 0) // header is missing 
            {
                var header = "PID,Step,Dispatch,Followed,ResultingOptMakespan";
                for (var i = 0; i < (int) Features.Local.Count; i++)
                    header += string.Format(",phi.{0}", (Features.Local) i);
                st.WriteLine(header);
            }

            foreach (var info in from DataRow row in Rows
                                    let pid = (int)row["PID"]
                                    where pid > AlreadyAutoSavedPID
                                    select String.Format("{0},{1}", row["Name"], row["Makespan"]))
            {
                st.WriteLine(info);
            }
            st.Close();
        }
        fs.Close();
    }

    internal void Retrace(int pid, Features.Mode featureMode)
    {
        var name = GetName(pid);
        var instance = Rows.Find(name);
        var prob = (ProblemInstance)instance["Problem"];

        var jssp = new Schedule(prob);
        for (var step = 0; step < prob.Dimension; step++)
        {
            #region find features of possible jobs

            var prefs = TrData[pid, step];
            if (!ValidDispatches(prefs, jssp))
                throw new Exception("Retracing gave an invalid dispatch");

            int dispatchedJob;
            if (prefs.Length > 0)
            {
                foreach (var p in prefs)
                {
                    var lookahead = jssp.Clone();
                    p.Feature = lookahead.Dispatch1(p.Dispatch.Job, featureMode);
                    var row = Rows.Find(p.Name);
                    row["Features"] = p.Feature;
                }

                var followed = prefs.ToList().Find(p => p.Followed);
                dispatchedJob = followed == null ? jssp.JobChosenBySDR((SDR) _track) : followed.Dispatch.Job;
            }
            else
            {
                dispatchedJob = jssp.ReadyJobs.Count > 1 ? jssp.JobChosenBySDR((SDR) _track) : jssp.ReadyJobs[0];
            }

            #endregion

            jssp.Dispatch1(dispatchedJob, Features.Mode.None);
        }
    }

    private bool ValidDispatches(TrSet[] prefs, Schedule jssp)
    {
        if (prefs.ToList().FindIndex(p => p.Dispatch.Mac < 0) == -1) return true;
        foreach (TrSet pref in prefs)
        {
            jssp.FindDispatch(pref.Dispatch.Job, out pref.Dispatch);
            Rows.Find(pref.Name)["Dispatch"] = pref.Dispatch;
        }
        return false;
    }

    const int TMLIM_OPT = 60 * 10; // max 10 min for optimum
    const int TMLIM_STEP = 60 * 2; // max 2 min per step/possible dispatch

    private string CollectTrainingSet(int pid, LinearModel model)
    {
        string name = GetName(pid);
        DataRow instance = Rows.Find(name);
        ProblemInstance prob = (ProblemInstance) instance["Problem"];

        GurobiJspModel gurobiModel = new GurobiJspModel(prob, name, TMLIM_OPT, true);
        var trueOptimumMakespan = gurobiModel.TrueOptimum;
        gurobiModel.SetTimeLimit(TMLIM_STEP);

        Schedule jssp = new Schedule(prob);
        int currentNumFeatures = 0;
        for (int step = 0; step < prob.Dimension; step++)
        {
            TrData[pid, step] = FindFeaturesForAllJobs(jssp, gurobiModel);
            int dispatchedJob = _trajectory(jssp, TrData[pid, step], model);
            jssp.Dispatch1(dispatchedJob, Features.Mode.None);
            gurobiModel.CommitConstraint(jssp.Sequence[step], step);
            currentNumFeatures = TrData[pid, step].Length;
        }
        gurobiModel.Dispose();
        NumFeatures += currentNumFeatures;
        return String.Format("{0}.{1}.{2} {3} #{4}", Distribution, Dimension, pid, StrTrack, currentNumFeatures);
    }

    private TrSet[] FindFeaturesForAllJobs(Schedule jssp, GurobiJspModel gurobiModel)
    {
        TrSet[] prefs = new TrSet[jssp.ReadyJobs.Count];
        for (int r = 0; r < jssp.ReadyJobs.Count; r++)
        {
            Schedule lookahead = jssp.Clone();
            prefs[r] = new TrSet
            {
                Feature = lookahead.Dispatch1(jssp.ReadyJobs[r], Features.Mode.Local),
                Dispatch = lookahead.Sequence[lookahead.Sequence.Count - 1],
            };
            // need to optimize to label featuers correctly -- this is computationally intensive
            gurobiModel.Lookahead(prefs[r].Dispatch, out prefs[r].ResultingOptMakespan);
            prefs[r].SimplexIterations = gurobiModel.SimplexIterations;
        }
        return prefs;
    }

    private int ChooseOptJob(Schedule jssp, TrSet[] prefs, LinearModel model = null)
    {
        int minMakespan = prefs.Min(p => p.ResultingOptMakespan);
        List<TrSet> optimums = prefs.ToList().Where(p => p.ResultingOptMakespan == minMakespan).ToList();
        return optimums.Count == 1 ? optimums[0].Dispatch.Job : optimums[Random.Next(0, optimums.Count)].Dispatch.Job;
    }

    private int ChooseWeightedJob(Schedule jssp, TrSet[] prefs, LinearModel model)
    {
        List<double> priority = new List<double>(jssp.ReadyJobs.Count);
        for (int r = 0; r < jssp.ReadyJobs.Count; r++)
            priority.Add(model.PriorityIndex(prefs[r].Feature));
        return jssp.ReadyJobs[priority.FindIndex(p => Math.Abs(p - priority.Max()) < 0.001)];
    }

    private int UseImitationLearning(Schedule jssp, TrSet[] prefs, LinearModel model)
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

    private int ChooseSDRJob(Schedule jssp, TrSet[] prefs = null, LinearModel mode = null)
    {
        return jssp.JobChosenBySDR((SDR) _track);
    }
}

/// <summary>
/// Preference set from RawData
/// </summary>
public class PreferenceSet : TrainingSet
{
    public int NumPreferences; 

    private readonly List<PrefSet>[,] _diffData;
    private readonly Func<List<TrSet>, int, int, int> _rankingFunction;

    public enum Ranking
    {
        FullPareto = 'f',
        PartialPareto = 'p',
        Basic = 'b',
        All = 'a'
    };

    public class PrefSet
    {
        public Features Feature;
        public int ResultingOptMakespan;
        public int Rank;
        public bool Followed;
    }

    public PreferenceSet(Track track, bool extended, Ranking rank) : base(track, extended)
    {
        FileInfo =
            new FileInfo(string.Format(
                "C://Users//helga//Alice//Code//trainingData//trdat.{0}.{1}.{2}.Local.diff.{3}.csv",
                Distribution, Dimension, StrTrack, rank));
        
        Columns.Add("Rank", typeof (int));

        switch (rank)
        {
            case Ranking.All:
                _rankingFunction = AllRankings;
                break;
            case Ranking.Basic:
                _rankingFunction = BasicRanking;
                break;
            case Ranking.FullPareto:
                _rankingFunction = FullParetoRanking;
                break;
            //case Ranking.PartialPareto:
            default:
                _rankingFunction = PartialParetoRanking;
                break;
        }

        _diffData = new List<PrefSet>[NumInstances, NumDimension];
    }

    public void CreatePreferencePairs(int pid)
    {
        RankPreferences(pid);
        for (var step = 0; step < NumDimension; step++)
        {
            var prefs = TrData[pid, step].ToList().OrderBy(p => p.Rank).ToList();
            NumPreferences += _rankingFunction(prefs, pid, step);
        }
    }

    private int BasicRanking(List<TrSet> prefs, int pid, int step)
    {
        for (var opt = 0; opt < prefs.Count; opt++)
        {
            if (prefs[opt].Rank > 0)
            {
                break;
            }

            for (var sub = opt + 1; sub < prefs.Count; sub++)
            {
                if (prefs[opt].Rank == prefs[sub].Rank) continue;
                _diffData[pid, step].Add(prefs[opt].Difference(prefs[sub]));
                _diffData[pid, step].Add(prefs[sub].Difference(prefs[opt]));
            }
        }
        return _diffData[pid, step].Count;
    }

    private int FullParetoRanking(List<TrSet> prefs, int pid, int step)
    {
        _diffData[pid, step].AddRange(from pi in prefs
            from pj in prefs
            where /* subsequent ranking */ Math.Abs(pi.Rank - pj.Rank) == 1
            select pi.Difference(pj));
        return _diffData[pid, step].Count;
    }

    private int PartialParetoRanking(List<TrSet> prefs, int pid, int step)
    {
        // subsequent ranking
        // partial, yet sufficient, pareto ranking
        var inTrainingSet = new bool[prefs.Count];
        for (var i = 0; i < prefs.Count; i++)
            for (var j = 0; j < prefs.Count; j++)
                if (Math.Abs(prefs[i].Rank - prefs[j].Rank) == 1) // subsequent ranking
                    // partial, yet sufficient, pareto ranking
                    if (!inTrainingSet[i] | !inTrainingSet[j])
                    {
                        var ijDiff = prefs[i].Difference(prefs[j]);
                        _diffData[pid, step].Add(ijDiff);

                        var jiDiff = prefs[j].Difference(prefs[i]);
                        _diffData[pid, step].Add(jiDiff);

                        inTrainingSet[i] = true;
                        inTrainingSet[j] = true;
                    }
        return _diffData[pid, step].Count;
    }

    private int AllRankings(List<TrSet> prefs, int pid, int step)
    {
        _diffData[pid, step].AddRange(from pi in prefs
            from pj in prefs
            where /* full ranking */ pi.Rank != pj.Rank
            select pi.Difference(pj));
        return _diffData[pid, step].Count;
    }
    
    private void RankPreferences(int pid)
    {
        for (var step = 0; step < NumDimension; step++)
        {
            var prefs = TrData[pid, step];
            var cmax = prefs.Select(p => p.ResultingOptMakespan).Distinct().OrderBy(x => x).ToList();
            foreach (var pref in prefs)
            {
                var rank = cmax.FindIndex(ms => ms == pref.ResultingOptMakespan);
                pref.Rank = rank;
                Rows.Find(pref.Name)["Rank"] = rank;
            }
        }        
    }
    
}
