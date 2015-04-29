using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Reflection.Emit;
using System.Text.RegularExpressions;
using System.Web.UI.WebControls;

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

    public int AlreadyAutoSavedPID;

    public RawData(string distribution, string dimension, string set)
    {
        Distribution = distribution;
        Dimension = dimension;
        NumDimension = DimString2Num(dimension);
        Set = set.ToLower();

        FileInfo =
            new FileInfo(String.Format("C://Users//helga//Alice//Code//rawData//{0}.{1}.{2}.txt",
                Distribution, Dimension, Set));

        if (!FileInfo.Exists)
            WriteGeneratedData();
        
        Columns.Add("Name", typeof (string)); // unique!
        Columns.Add("PID", typeof (int)); // problem instance Index
        Columns.Add("Problem", typeof (ProblemInstance));

        PrimaryKey = new[] {Columns["Name"]};

        ReadProblemText();
        
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

    internal string GetName(int pid)
    {
        return String.Format("{0}.{1}.{2}.{3}", Distribution, Dimension, Set, pid).ToLower();
    }

    private void WriteGeneratedData()
    {
        if (FileInfo == null || FileInfo.Directory == null) return;

        ManipulateProcs manipulate;
        switch (Distribution)
        {
            case "j.rnd_p1mdoubled":
                manipulate = ManipulateProcs.Job1;
                break;
            case "j.rnd_pj1doubled":
                manipulate = ManipulateProcs.Machine1;
                break;
            default:
                manipulate = ManipulateProcs.None;
                break;
        }

        const string SEP = "+++";
       
        const int SEED = 19850712;
        var rnd = (Distribution[0] == 'j' ? new Random(SEED) : null);

        string workDir = String.Format("{0}//generator//{1}", FileInfo.Directory.FullName,
            Distribution.Substring(2, Distribution.Length));

        if (!Directory.Exists(workDir)) return;

        var files = Directory.GetFiles(workDir);

        int start = 0, finish = files.Length;
        string setInfo;
        if (Set == "test")
        {
            start = files.Length/2;
            setInfo = "TEST";
        }
        else
        {
            finish = files.Length/2;
            setInfo = "TRAIN";
        }

        var sorted = files.ToList().Select(str => new NameAndNumber(str))
            .OrderBy(n => n.Name)
            .ThenBy(n => n.Number).ToList();

        //Data problems = new Data(shopProblem + "." + distr, shopProblem);
        const string LONG_SEP = SEP + SEP + SEP;
        using (var writer = new StreamWriter(FileInfo.FullName))
        {
            setInfo += " SET problems from subfolder " + workDir +
                       (rnd != null ? " with random machine order (seed=" + SEED + ")" : "") +
                       String.Format("\n\n{0}", LONG_SEP);
            writer.WriteLine(setInfo);

            for (var id = start; id < finish; id++)
            {
                var content = File.ReadAllText(sorted[id].OriginalString);

                var prob = ReadSingleProblem(content, rnd);
                if (prob == null)
                    continue;

                switch (manipulate)
                {
                    case ManipulateProcs.Job1:
                        for (var a = 0; a < prob.NumMachines; a++)
                            prob.Procs[1, a] *= 2;
                        break;
                    case ManipulateProcs.Machine1:
                        for (var j = 0; j < prob.NumJobs; j++)
                            prob.Procs[j, 1] *= 2;
                        break;
                }

                content = Problem2String(prob);
                writer.WriteLine("instance problem.{0}\n{1}\n{2}{1}", id + 1, LONG_SEP, content);
            }
            writer.WriteLine("\n{0}\nEND OF DATA\n{0}", SEP);
        }

        FileInfo = new FileInfo(FileInfo.FullName);
    }

    private enum ManipulateProcs
    {
        None,
        Job1,
        Machine1
    };

    private static string Problem2String(ProblemInstance prob)
    {
        var thisProblem = prob.NumJobs + " " + prob.NumMachines + "\n";
        for (var j = 0; j < prob.NumJobs; j++)
        {
            for (var m = 0; m < prob.NumMachines; m++)
            {
                thisProblem += prob.Sigma[j, m] + " " + prob.Procs[j, m] + " ";
            }
            thisProblem += "\n";
        }
        return thisProblem;
    }

    private class NameAndNumber
    {
        public NameAndNumber(string s)
        {
            OriginalString = s;
            var match = Regex.Match(s, @"^(.*?)(\d*)$");
            Name = match.Groups[1].Value;
            int number;
            int.TryParse(match.Groups[2].Value, out number);
            Number = number; //will get default value when blank
        }

        public string OriginalString { get; private set; }
        public string Name { get; private set; }
        public int Number { get; private set; }
    }

    private void ReadProblemText(int maxTrain = 500, int onlyReadPID = -1)
    {
        if (!FileInfo.Exists) return;

        var fullContent = File.ReadAllText(FileInfo.FullName);
        var allContent = Regex.Split(fullContent, "[\r\n ]*[+]+[\r\n ]*");
        
        var shortName = string.Empty;
        var regShortName = new Regex("^instance ([a-zA-Z0-9. ]*)");
        var id = 0;
        foreach (var content in allContent)
        {
            var m = regShortName.Match(content);
            if (m.Success)
            {
                id++;
                shortName = m.Groups[1].Value;
            }
            else if (shortName != string.Empty)
            {
                if (id == onlyReadPID | onlyReadPID < 0)
                {
                    var prob = ReadSingleProblem(content);
                    AddProblem(prob);
                }
                shortName = string.Empty;
            }
            if (Rows.Count >= maxTrain)
                return;
        }
        //AuxFun.writeRawDataCsv(fname, dir, data); 
    }

    private ProblemInstance ReadSingleProblem(string content, Random rnd = null)
    {
        var lines = Regex.Split(content, @"[\r\n]+[ ]*");

        int jobs = -1, macs = -1;
        int[] sigma = null, procs = null;
        var job = 0;

        foreach (
            var ints in from line in lines where !Regex.IsMatch(line, "^[+]*$") select GetIntValuesFromLine(line))
        {
            if (ints.Length == 2)
            {
                jobs = ints[0];
                macs = ints[1];
                var dim = macs * jobs;
                sigma = new int[dim];
                procs = new int[dim];
                job = 0;
            }
            else if (ints.Length == 2 * macs) // jsp
            {
                for (var mac = 0; mac < macs; mac++)
                {
                    var ii = job * macs + mac;
                    if (sigma != null) sigma[ii] = ints[mac * 2];
                    if (procs != null) procs[ii] = ints[mac * 2 + 1];
                }
                job++;
            }
        }

        if (job != jobs) return null;
        if (rnd == null) return new ProblemInstance(jobs, macs, procs, sigma);
        var machineOrder = new int[macs];
        for (var m = 0; m < macs; m++)
        {
            machineOrder[m] = m;
        }

        for (var j = 0; j < jobs; j++)
        {
            var randomOrder = machineOrder.OrderBy(x => rnd.Next()).ToArray();
            if (sigma != null) Array.Copy(randomOrder, 0, sigma, j * macs, macs);
        }

        return new ProblemInstance(jobs, macs, procs, sigma);
    }

    private void AddProblem(ProblemInstance prob)
    {
        if (prob == null) return;

        var pid = ++NumInstances;
        var row = NewRow();
        row["Name"] = GetName(pid);
        row["PID"] = pid;
        row["Problem"] = prob;
        Rows.Add(row);
    }

    public static int[] GetIntValuesFromLine(string line)
    {
        line = Regex.Replace(line, "\r", string.Empty);
        if (Regex.IsMatch(line, "[A-Za-z]+") | line == string.Empty)
        {
            return new int[0];
        }

        line = Regex.Replace(line, " +( |$)", "$1"); //Substitute two or more spaces for one space
        line = Regex.Replace(line, "^[ ]", ""); // remove first white space in line
        var substrs = Regex.Split(line, "[ ]");

        var ints = new int[substrs.Length];
        for (var i = 0; i < ints.Count(); i++)
            ints[i] = Convert.ToInt32(substrs[i]);
        return ints;
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
    private Track LookupTrack(String track)
    {
        for(int i=0; i< (int)Track.Count; i++)
            if (track.Equals(String.Format("{0}", (Track) i)))
                return (Track) i;
        return Track.RND;
    }

    private readonly bool _extended;

    private readonly Func<Schedule, TrSet[], LinearModel, int> _trajectory;
    private readonly Track _track;
    internal string StrTrack;

    public int NumFeatures;
    public readonly TrSet[,][] TrData;
    internal Random Random = new Random();

    internal readonly LinearModel Model;

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
    
    public TrainingSet(string distribution, string dim, string track, bool extended) : base(distribution, dim, "train")
    {
        _track = LookupTrack(track);
        _extended = extended;
        Model = null; // fix me
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

        if (FileInfo.Exists)
        {
            var firstLine = File.ReadLines(FileInfo.FullName).First();
            var lastLine = File.ReadLines(FileInfo.FullName).Last();
            if (firstLine != lastLine)
            {
                string[] splitFirst = firstLine.Split(',');
                string[] splitLast = lastLine.Split(',');
                AlreadyAutoSavedPID =
                    Convert.ToInt32(splitLast[splitFirst.ToList().FindIndex(x => x == "PID")]);
            }
        }

        TrData = new TrSet[NumInstances, NumDimension][];
        
        switch (_track)
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

    public string CollectTrainingSet(int pid)
    {
        string name = GetName(pid);
        DataRow instance = Rows.Find(name);
        ProblemInstance prob = (ProblemInstance) instance["Problem"];

        GurobiJspModel gurobiModel = new GurobiJspModel(prob, name, TMLIM_OPT, true);
        gurobiModel.SetTimeLimit(TMLIM_STEP);

        Schedule jssp = new Schedule(prob);
        int currentNumFeatures = 0;
        for (int step = 0; step < prob.Dimension; step++)
        {
            TrData[pid, step] = FindFeaturesForAllJobs(jssp, gurobiModel);
            int dispatchedJob = _trajectory(jssp, TrData[pid, step], Model);
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

    public PreferenceSet(string problem, string dim, string track, bool extended, char rank) : base(problem, dim, track, extended)
    {
        FileInfo =
            new FileInfo(string.Format(
                "C://Users//helga//Alice//Code//trainingData//trdat.{0}.{1}.{2}.Local.diff.{3}.csv",
                Distribution, Dimension, StrTrack, rank));
        
        Columns.Add("Rank", typeof (int));

        switch ((Ranking) rank)
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
