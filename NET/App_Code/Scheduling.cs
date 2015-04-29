using System;
using System.Collections.Generic;
using System.Data;
using System.Diagnostics.CodeAnalysis;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using Gurobi;

public enum FeatureType
{
    None = 0,
    Local = 1,
    Global = 2
};

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
    RND
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

        Columns.Add("Name", typeof(string)); // unique!
        Columns.Add("Shop", typeof(char));
        Columns.Add("Distribution", typeof(string));
        Columns.Add("Problem", typeof(ProblemInstance));
        Columns.Add("Dimension", typeof(int));
        Columns.Add("Set", typeof(string)); // test or train
        Columns.Add("PID", typeof(int)); // problem instance Index
        Columns.Add("NumJobs", typeof(int));
        Columns.Add("NumMachines", typeof(int));
        Columns.Add("Makespan", typeof(int));
        Columns.Add("Heuristic", typeof(string));
        Columns.Add("Solver", typeof(string));
        Columns.Add("Solved", typeof(string)); // either Opt (optimum) or BKS (best known solution)
        Columns.Add("Solution", typeof(int[][])); // solution of schedule corresponding to makespan
        Columns.Add("Simplex", typeof(int)); // number of simplex iterations
        Columns.Add("Note", typeof(string));
        PrimaryKey = new[] { Columns["Name"] };
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
        row["Dimension"] = prob.NumJobs * prob.NumMachines;
        row["Set"] = Set;
        row["NumJobs"] = prob.NumJobs;
        row["NumMachines"] = prob.NumMachines;
        row["Note"] = note;
        row["Solver"] = string.Empty;
        row["Solved"] = string.Empty;
        row["Simplex"] = int.MinValue;
        row["Makespan"] = int.MinValue;
        Rows.Add(row);
    }

    public void AddHeuristicMakespan(string name, int makespan, int optMakespan, string heuristic,
        string columnName = "Heuristic")
    {
        DataRow row = Rows.Find(name);
        row.SetField("Makespan", makespan);
        row.SetField(columnName, heuristic);
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
        List<string> write = new List<string>
        {
            "Name",
            "Heuristic",
            "Makespan"
        }; 
        AuxFun.WriteDataTable2Csv(file, this, write, FileMode.Create, FeatureType.None);
    }

    public void WriteCsvSDR(string sdr, string directory)
    {
        FileInfo file = new FileInfo(String.Format("{0}{1}.{2}.csv", directory, Name, sdr));
        List<string> write = new List<string>
        {
            "Name",
            "SDR",
            "Makespan"
        };
        AuxFun.WriteDataTable2Csv(file, this, write, FileMode.Append, FeatureType.None);
    }

    public void WriteCsvOpt(string directory)
    {
        FileInfo file = new FileInfo(String.Format("{0}opt.{1}.csv", directory, Name));
        List<string> write = new List<string>
        {
            "Name",
            "Makespan",
            "Solved",
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

        return Rows.Cast<DataRow>().All(row => names.Exists(x => x == (string)row["Name"]));
    }
}


public class LinearWeight
{
    public double[][] Local = new double[(int)LocalFeature.Count][];
    public double[][] Global = new double[(int)GlobalFeature.Count][];
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

        if (modelIndex != -1 & nrFeat != (int)LocalFeature.Count)
        {
            Name = String.Format("{0}//F{1}.Model{2}", fileName, nrFeat, modelIndex);
        }

        TimeIndependent = timeDependentSteps == 1;

        for (int i = 0; i < (int)LocalFeature.Count; i++)
            Local[i] = new double[timeDependentSteps];

        for (int i = 0; i < (int)GlobalFeature.Count; i++)
            Global[i] = new double[timeDependentSteps];

    }

    public LinearWeight EquivalentSDR(SDR sdr)
    {
        LinearWeight w = new LinearWeight(1, sdr.ToString());
        switch (sdr)
        {
            case SDR.MWR:
                w.Local[(int)LocalFeature.wrmJob][0] = +1;
                return w;
            case SDR.LWR:
                w.Local[(int)LocalFeature.wrmJob][0] = -1;
                return w;
            case SDR.SPT:
                w.Local[(int)LocalFeature.proc][0] = -1;
                return w;
            case SDR.LPT:
                w.Local[(int)LocalFeature.proc][0] = +1;
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
            for (int i = 0; i < (int)LocalFeature.Count; i++)
            {
                pattern = String.Format("phi.{0}", (LocalFeature)i);
                Match phi = Regex.Match(line, String.Format(@"(?<={0} (-?[0-9.]*)", pattern));
                if (phi.Success)
                {
                    double value = Convert.ToDouble(phi.Groups[2].ToString(),
                        CultureInfo.InvariantCulture);
                    Local[i][0] = value;
                    foundLocal = true;
                }
            }

            for (int i = 0; i < (int)GlobalFeature.Count; i++)
            {
                pattern = String.Format("phi.{0}", (GlobalFeature)i);
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

public class LinearModel
{
    public readonly string Classifer; // liblin or libsvm 
    public readonly string Param;
    public readonly string Name;
    public readonly LinearWeight Weights;
    public int NumInstances = 0;
    public readonly string PathTrainingData;
    public readonly string PathModel;
    public readonly FeatureType FeatureType = FeatureType.Local;
    public readonly double Beta; // odds of doing optimal trajectory 

    #region PREF model

    public LinearModel(string classifer, string param, string path2TrainingData, string dir, FeatureType featureType)
    {
        var file = new FileInfo(path2TrainingData);
        var m = Regex.Match(file.Name, "^trdat(.+?).csv");
        var trdat = m.Success ? m.Groups[1].ToString() : "";

        Name = "model" + trdat + "." + classifer;
        Classifer = classifer;
        Param = param;
        PathTrainingData = path2TrainingData;
        PathModel = dir + Name + ".txt";

        FeatureType = featureType;
    }

    public double PriorityIndex(Features phi)
    {
        var step = Weights.TimeIndependent ? 0 : phi.Local[(int)LocalFeature.step] - 1;
        double index = 0;

        for (var i = 0; i < (int)LocalFeature.Count; i++)
            index += Weights.Local[i][step] * phi.Local[i];

        for (var i = 0; i < (int)GlobalFeature.Count; i++)
            index += Weights.Global[i][step] * phi.Global[i];

        return index;
    }

    public LinearModel(double[][] localWeights, string name)
    {
        Name = name;
        PathModel = "User input";
        Weights = new LinearWeight(localWeights[0].Length, name) { Local = localWeights };
        FeatureType = FeatureType.Local;
    }

    public LinearModel(FileInfo file)
    {
        Name = file.Name.Substring(0, file.Name.Length - file.Extension.Length);
        PathModel = file.FullName;

        if (Regex.IsMatch(Name, "LIBLINEAR", RegexOptions.IgnoreCase))
            Classifer = "LIBLINEAR";
        else if (Regex.IsMatch(Name, "CMA[-]*ES", RegexOptions.IgnoreCase))
            Classifer = "CMA-ES";
        else // not supported
            return;

        Weights.ReadLinearWeights(PathModel, out FeatureType);
    }

    #endregion


    public LinearModel(SDR sdr)
    {
        Name = String.Format("model{0}", sdr);
        FeatureType = FeatureType.None;
        Weights = EquivalentSDR(sdr);
    }

    private LinearWeight EquivalentSDR(SDR sdr)
    {
        var w = new LinearWeight(1, sdr.ToString());
        switch (sdr)
        {
            case SDR.MWR:
                w.Local[(int)LocalFeature.wrmJob][0] = +1;
                return w;
            case SDR.LWR:
                w.Local[(int)LocalFeature.wrmJob][0] = -1;
                return w;
            case SDR.SPT:
                w.Local[(int)LocalFeature.proc][0] = -1;
                return w;
            case SDR.LPT:
                w.Local[(int)LocalFeature.proc][0] = +1;
                return w;
            default:
                return w; // do nothing
        }
    }

    public LinearModel(Data distribution)
    {
        Name = "CMA" + distribution.Name;
        FeatureType = FeatureType.Local;
        Weights = SetCMAWeight(distribution.Name);
        Classifer = "CMA-ES";
    }

    public LinearModel(object[] imitationLearning)
    {
        var logFile = new FileInfo(String.Format("{0}", imitationLearning[0]));
        var nrFeat = (int)imitationLearning[1];
        var model = (int)imitationLearning[2];
        var iter = (int)imitationLearning[4];

        switch (imitationLearning[5].ToString())
        {
            case "SUP":
                Beta = Math.Pow(0.5, iter);
                break;
            case "FIXSUP":
                Beta = 0.5;
                break;
            case "UNSUP":
                Beta = 0;
                break;
        }

        var loggedWeights = AuxFun.ReadLoggedLinearWeights(logFile);
        if (loggedWeights == null)
            return; // error

        foreach (var w in loggedWeights.Where(w => w.NrFeat == nrFeat && w.ModelIndex == model))
        {
            PathModel = logFile.Name;
            Weights = new LinearWeight(w.Local[0].Length, Name) { Local = w.Local };
            Name = w.Name;
            break;
        }
        FeatureType = FeatureType.Local;
        Classifer = "PREF";
    }

    private LinearWeight SetCMAWeight(string distribution, string objFun = "Cmax")
    {
        FeatureType featureType;
        var path = String.Format("CMAES\\model.{0}.CMAES.min_{1}", distribution, objFun);
        var weights = new LinearWeight(1, path);
        if (File.Exists(path))
            weights.ReadLinearWeights(path, out featureType);

        return weights;
    }
}


