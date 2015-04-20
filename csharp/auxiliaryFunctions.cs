using System;
using System.Collections.Generic;
using System.Data;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using Scheduling;

enum MyTypes { Double = 1, Int = 2, IntArray = 3, Dispatch = 4, Char = 5, String = 6, Bool = 7, NaN = 0 };

namespace auxiliaryFunctions
{
    public class RandomPastelColorGenerator
    {
        private readonly Random _random;

        public RandomPastelColorGenerator()
        {
            // seed the generator with 2 because
            // this gives a good sequence of colors
            const int RANDOM_SEED = 19850712;
            _random = new Random(RANDOM_SEED);
        }

        /// <summary>
        /// Returns a random pastel brush
        /// </summary>
        /// <returns></returns>
        //public SolidColorBrush GetNextBrush()
        //{
        //    SolidColorBrush brush = new SolidColorBrush(GetNext());
        //    // freeze the brush for efficiency
        //    brush.Freeze();
        //    return brush;
        //}

        /// <summary>
        /// Returns a random pastel color
        /// </summary>
        /// <returns></returns>
        public Color GetNextRandom()
        {
            // to create lighter colours:
            // take a random integer between 0 & 128 (rather than between 0 and 255)
            // and then add 127 to make the colour lighter
            var colorBytes = new byte[3];
            colorBytes[0] = (byte) (_random.Next(128) + 127);
            colorBytes[1] = (byte) (_random.Next(128) + 127);
            colorBytes[2] = (byte) (_random.Next(128) + 127);

            // make the color fully opaque
            return Color.FromArgb(255, colorBytes[0], colorBytes[1], colorBytes[2]);
        }
    }

    public class AuxFun
    {
        public static Schedule.Dispatch String2Dispatch(string disp)
        {
            var split = Regex.Split(disp, @"\.");
            return split.Length == 3
                ? new Schedule.Dispatch(Convert.ToInt32(split[0]), Convert.ToInt32(split[1]), Convert.ToInt32(split[2]))
                : new Schedule.Dispatch(Convert.ToInt32(disp), -1, -1);
        }

        public static string PatSciNr = @"[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?";

        public static int ReadScientificNumber(string number)
        {
            number = number.ToLower();
            var split = Regex.Split(number, "[.]+|e[+-]+");
            if (split.Length == 1)
                return Convert.ToInt32(split[0]);
            if (Regex.IsMatch(number, @"e\+"))
            {
                var idx = Convert.ToInt32(split[2]);
                return Convert.ToInt32(split[0] + split[1].Substring(0, idx)) +
                       (Convert.ToInt32(split[1].Substring(idx, 1)) > 5 ? 1 : 0);
            }
            if (Regex.IsMatch(number, "e-00"))
                return Convert.ToInt32(split[0]) + (Convert.ToInt32(split[1][0]) > 5 ? 1 : 0);
            if (Regex.IsMatch(split[2], "01"))
                return (Convert.ToInt32(split[0][0]) > 5 ? 1 : 0);
            return 0;
        }


        public static double Mean(int[] values)
        {
            double mean = 0;
            var n = values.Length;
            for (var i = 0; i < n; i++)
                mean += values[i];
            return mean/n;
        }

        public static double StandardDev(int[] values, double mean)
        {
            return Math.Sqrt(Variance(values, mean));
        }

        private static double Variance(IList<int> values, double mean)
        {
            double variance = 0;
            var n = values.Count;
            for (var i = 0; i < n; i++)
                variance += Math.Pow((values[i] - mean), 2);

            return variance/n;
        }

        public static string GetCurrentDirectory()
        {
            var match = Regex.Match(Directory.GetCurrentDirectory(), "[A-z:]*csharp");
            return String.Format(@"{0}\", match.Groups[0].Value);
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

        public static bool FileAccessible(string path)
        {
            try
            {
                if (!File.Exists(path)) return false;
                return !FileInUse(path) & !IsFileLocked(path);
            }
            catch
            {
                return false;
            }
        }

        protected static bool FileInUse(string path)
        {
            try
            {
                using (var fs = new FileStream(path, FileMode.OpenOrCreate))
                {
                    //fs.CanWrite
                }
                return false;
            }
            catch // (IOException ex)
            {

                return true;
            }
        }

        protected static bool IsFileLocked(string path)
        {
            var file = new FileInfo(path);
            FileStream stream = null;

            try
            {
                stream = file.Open(FileMode.Open, FileAccess.ReadWrite, FileShare.None);
            }
            catch (IOException)
            {
                //the file is unavailable because it is:
                //still being written to
                //or being processed by another thread
                //or does not exist (has already been processed)
                return true;
            }
            finally
            {
                if (stream != null)
                    stream.Close();
            }

            //file is not locked
            return false;
        }

        public static void Dimension2Info(string dim, out int numJobs, out int numMachines)
        {
            var jobxmac = Regex.Split(dim, "x");
            numJobs = Convert.ToInt32(jobxmac[0]);
            numMachines = Convert.ToInt32(jobxmac[1]);
        }

        public enum ManipulateProcs
        {
            None = 0,
            Job1,
            Machine1
        };


        public static void WriteGeneratedData(string fname, string dir, string subfolder, ManipulateProcs manipulate)
        {
            const string SEP = "+++";
            string dim, distr, set;
            char shopProblem;
            int macs, jobs;
            Filename2Info(fname, out shopProblem, out distr, out dim, out set);
            Dimension2Info(dim, out jobs, out macs);

            const int SEED = 19850712;
            var rnd = (shopProblem == 'j' ? new Random(SEED) : null);

            var workdir = dir + @"generator\" + subfolder;
            if (!Directory.Exists(workdir))
            {
                return;
            }

            var files = Directory.GetFiles(workdir);

            int start = 0, finish = files.Length;
            string setInfo;
            if (set == "test")
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
            using (
                var writer =
                    new StreamWriter(dir + string.Format("{0}.{1}.{2}.{3}.txt", shopProblem, distr, dim, set.ToLower()))
                )
            {
                setInfo += " SET problems from subfolder generator/" + subfolder +
                           (rnd != null ? " with random machine order (seed=" + SEED + ")" : "") +
                           String.Format("\n\n{0}", LONG_SEP);
                writer.WriteLine(setInfo);
                for (var id = start; id < finish; id++)
                {
                    var content = File.ReadAllText(sorted[id].OriginalString);

                    var prob = ReadSingleProblem(content, shopProblem, rnd);
                    if (prob == null)
                        continue;

                    switch (manipulate)
                    {
                        case ManipulateProcs.Job1:
                            for (var a = 0; a < prob.NumMachines; a++)
                                prob.ProcessingTimes[1, a] *= 2;
                            break;
                        case ManipulateProcs.Machine1:
                            for (var j = 0; j < prob.NumJobs; j++)
                                prob.ProcessingTimes[j, 1] *= 2;
                            break;
                    }

                    content = Problem2String(prob);
                    writer.WriteLine("instance problem.{0}\n{1}\n{2}{1}", id + 1, LONG_SEP, content);
                }
                writer.WriteLine("\n{0}\nEND OF DATA\n{0}", SEP);
            }
        }

        public static double RhoMeasure(object trueMakespan, object resultingMakespan)
        {
            return RhoMeasure((int) trueMakespan, (int) resultingMakespan);
        }

        public static double RhoMeasure(int trueMakespan, int resultingMakespan)
        {
            if (resultingMakespan < trueMakespan | trueMakespan == int.MinValue)
                return double.NaN;
            return 100.0*(resultingMakespan - trueMakespan)/trueMakespan;
        }

        private static string Problem2String(ProblemInstance prob)
        {
            var thisProblem = prob.NumJobs + " " + prob.NumMachines + "\n";
            for (var j = 0; j < prob.NumJobs; j++)
            {
                for (var m = 0; m < prob.NumMachines; m++)
                {
                    thisProblem += prob.PermutationMatrix[j, m] + " " + prob.ProcessingTimes[j, m] + " ";
                }
                thisProblem += "\n";
            }
            return thisProblem;
        }

        private static ProblemInstance ReadSingleProblem(string content, char shopProblem, Random rnd = null)
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
                    var dim = macs*jobs;
                    sigma = new int[dim];
                    procs = new int[dim];
                    job = 0;
                }
                else if (ints.Length == 2*macs) // jsp
                {
                    for (var mac = 0; mac < macs; mac++)
                    {
                        var ii = job*macs + mac;
                        if (sigma != null) sigma[ii] = ints[mac*2];
                        if (procs != null) procs[ii] = ints[mac*2 + 1];
                    }
                    job++;
                }
            }

            if (job != jobs) return null;
            if (rnd == null) return new ProblemInstance(shopProblem, jobs, macs, procs, sigma);
            var machineOrder = new int[macs];
            for (var m = 0; m < macs; m++)
            {
                machineOrder[m] = m;
            }

            for (var j = 0; j < jobs; j++)
            {
                var randomOrder = machineOrder.OrderBy(x => rnd.Next()).ToArray();
                if (sigma != null) Array.Copy(randomOrder, 0, sigma, j*macs, macs);
            }

            return new ProblemInstance(shopProblem, jobs, macs, procs, sigma);
        }

        public static LinearWeight[] ReadLoggedLinearWeights(FileInfo file)
        {
            string[] allContent;
            ReadTextFile(file.FullName, out allContent, "\r\n");
            var models = new List<LinearWeight>();

            // 	Weight,NrFeat,Model,Feature,NA,values
            var regModel = new Regex(String.Format("Weight,([0-9]+),([0-9]+),phi.([a-zA-Z]*),NA,({0})", PatSciNr));
            var regWeight = new Regex(PatSciNr);

            var strLocalFeature = new string[(int) LocalFeature.Count];
            for (var i = 0; i < (int) LocalFeature.Count; i++)
                strLocalFeature[i] = String.Format("{0}", (LocalFeature) i);

            LinearWeight weights = null;
            var timeindependent = Regex.Match(file.Name, "timeindependent").Success;

            var dim = Regex.Match(file.Name, "([0-9]+x[0-9]+)");
            var dimension = dim.Groups[0].Value;
            int numJobs, numMachines;
            Dimension2Info(dimension, out numJobs, out numMachines);
            var timeindependentSteps = timeindependent ? 1 : numJobs*numMachines;

            int nrFeat = -1, featFound = -1;
            foreach (var line in allContent)
            {
                var m = regModel.Match(line);
                if (!m.Success) continue;
                if (featFound == nrFeat | featFound == -1)
                {
                    if (weights != null) models.Add(weights);
                    nrFeat = Convert.ToInt32(m.Groups[1].Value);
                    var idModel = Convert.ToInt32(m.Groups[2].Value);
                    weights = new LinearWeight(timeindependentSteps, file.Name.Substring(0, file.Name.Length - 4),
                        nrFeat, idModel);
                    featFound = 0;
                }

                var local = m.Groups[3].Value;
                if (timeindependent) // global model 
                {
                    var value = Convert.ToDouble(m.Groups[4].Value, CultureInfo.InvariantCulture);
                    for (var i = 0; i < (int) LocalFeature.Count; i++)
                    {
                        if (String.Compare(local, strLocalFeature[i], StringComparison.InvariantCultureIgnoreCase) != 0)
                            continue;
                        if (weights != null) weights.Local[i][0] = value;
                        featFound++;
                        break;
                    }
                }
                else
                {
                    for (var i = 0; i < (int) LocalFeature.Count; i++)
                    {
                        if (String.Compare(local, strLocalFeature[i], StringComparison.InvariantCultureIgnoreCase) != 0)
                            continue;
                        var wMatches = regWeight.Matches(line);
                        for (var step = 0; step < wMatches.Count; step++) // first two captures include NrFeat + Model 
                        {
                            var value = Convert.ToDouble(wMatches[step].Groups[1].Value,
                                CultureInfo.InvariantCulture);
                            if (weights != null) weights.Local[i][step] = value;
                        }
                        featFound++;
                        break;
                    }
                }
            }
            if (weights != null) models.Add(weights);
            //if (models.Count == 697)
            return models.ToArray();
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

        private static void Filename2Info(string fname, out char shopProblem, out string distr, out string dim,
            out string set)
        {
            shopProblem = fname[0];
            if (Regex.IsMatch(fname, "1.txt")) // flowshop1.txt or jobshop1.txt are from ORLIB
            {
                distr = "ORLIB";
                dim = "mixed";
                set = "Test";
            }
            else
            {
                //distr = fname.Substring(1, fname.Length - 4); // remove .txt as well
                var info = Regex.Split(fname, "[.]");
                //shopProblem = info[0][0]; 
                distr = info[1];
                dim = info[2];
                set = info[3];
            }
        }

        public static void WriteRawDataCsv(string fname, string dir, Data data)
        {
            char shopProblem;
            string distr, dim, set;
            Filename2Info(fname, out shopProblem, out distr, out dim, out set);
            fname = "sortedProcs." + shopProblem + "." + distr + "." + dim + "." + set + ".csv";
            //if (File.Exists(dir + fname)) { return; }

            int numJobs, numMachines;
            Dimension2Info(dim, out numJobs, out numMachines);

            var fs = new FileStream(dir + fname, FileMode.Create, FileAccess.Write);
            using (var st = new StreamWriter(fs))
            {
                //string header = "Name";
                //for (int i = 0; i < dimension; i++)
                //    header += ",p" + i;
                //st.WriteLine(header)
                for (var I = 0; I < data.Rows.Count; I++)
                {
                    var row = data.Rows[I];
                    var info = String.Format("{0},{1}", I, row["Name"]);
                    var prob = (ProblemInstance) row["Problem"];
                    for (var job = 0; job < prob.NumJobs; job++)
                        for (var mac = 0; mac < prob.NumMachines; mac++)
                            info += "," + prob.ProcessingTimes[job, prob.PermutationMatrix[job, mac]];
                    st.WriteLine(info);
                }
                st.Close();
            }
            fs.Close();
        }

        public static bool ReadTextFile(string path2File, out string[] allContent, string sep)
        {
            allContent = null;
            if (!File.Exists(path2File))
                return false;

            while (!FileAccessible(path2File))
            {
                /* wait */
            }
            var fullContent = File.ReadAllText(path2File);
            allContent = sep != ""
                ? Regex.Split(fullContent, "[\r\n ]*" + sep + "[\r\n ]*")
                : Regex.Split(fullContent, "[\r\n]+");
            return true;
        }

        public static void ReadRawData(string fname, string dir, out Data data, int single = -1, int maxTrain = 500)
        {
            char shopProblem;
            string distr, dim, set;
            Filename2Info(fname, out shopProblem, out distr, out dim, out set);
            data = new Data(String.Format("{0}.{1}", shopProblem, distr), shopProblem, dim, set);

            string[] allContent;
            if (!ReadTextFile(dir + fname, out allContent, "[+]+"))
            {
                return;
            }

            var shortName = string.Empty;
            //Regex regShortName = new Regex("^instance ([a-zA-Z0-9]{4})");

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
                    if (id == single | single < 0)
                    {
                        var prob = ReadSingleProblem(content, shopProblem);
                        if (prob != null)
                            data.AddProblem(prob, distr, shopProblem, shortName, id);
                    }
                    shortName = string.Empty;
                }
                if (data.Rows.Count >= maxTrain)
                    return;
            }
            //AuxFun.writeRawDataCsv(fname, dir, data); 
        }

        public static List<string[]> ReadCsv2DataTable(string fname)
        {
            var content = new List<string[]>();

            if (!File.Exists(fname))
            {
                return null;
            }
            while (FileInUse(fname))
            {
                /* wait */
            }

            var fs = new FileStream(fname, FileMode.Open, FileAccess.Read);
            using (var st = new StreamReader(fs))
            {
                while (st.Peek() != -1) // stops when it reachs the end of the file
                {
                    var row = Regex.Split(st.ReadLine(), ",");
                    content.Add(row);
                }
                st.Close();
            }
            fs.Close();
            return content;
        }

        public static void WriteCMAFinalResults(FileInfo file, LinearModel linearModel)
        {
            if (file.Extension != ".csv")
                file = new FileInfo(file.FullName + ".csv");

            while (File.Exists(file.FullName) & FileInUse(file.FullName))
            {
                /* wait */
            }

            var fs = new FileStream(file.FullName, FileMode.Create, FileAccess.Write);
            using (var st = new StreamWriter(fs))
            {
                string header = "Type,NrFeat,Model,Feature,mean";
                int numSteps = linearModel.Weights.Local[0].Length;
                for (int step = 1; step <= numSteps; step++)
                    header += String.Format(CultureInfo.InvariantCulture, ",Step.{0}", step);
                st.WriteLine(header);

                const int NUM_FEATURES = (int) LocalFeature.Count - 2; 
                
                for (int iFeat = 0; iFeat < (int) LocalFeature.Count; iFeat++)
                {
                    LocalFeature feat = (LocalFeature) iFeat;
                    switch (feat)
                    {
                        case LocalFeature.step:
                        case LocalFeature.totProc:
                            continue;
                    }

                    string info = String.Format("Weight,{0},1,phi.{1},NA", NUM_FEATURES, feat);

                    for (int step = 0; step < numSteps; step++)
                        info += String.Format(CultureInfo.InvariantCulture, ",{0:R9}",
                            linearModel.Weights.Local[iFeat][step]);

                    st.WriteLine(info);
                }

                st.Close();
            }
            fs.Close();
        }

        public static void WriteCMAResults(FileInfo file, FileMode fileMode, List<CMAES.SummaryCMA> output,
            int numDecsVariables, int numFeatures)
        {
            if (file.Extension != ".csv")
                file = new FileInfo(file.FullName + ".csv");

            while (File.Exists(file.FullName) & FileInUse(file.FullName))
            {
                /* wait */
            }

            var fs = new FileStream(file.FullName, fileMode, FileAccess.Write);
            using (var st = new StreamWriter(fs))
            {
                if (fs.Length == 0) // header is missing 
                {
                    string header = "Generation,CountEval,Fitness"; // for plotting output
                    for (int i = 0; i < numDecsVariables; i++)
                    {
                        int ifeat = i%numFeatures;
                        int step = (i - ifeat)/numFeatures + 1;
                        LocalFeature feat = (LocalFeature) ifeat;
                        header += String.Format(CultureInfo.InvariantCulture, ",phi.{0}.{1}", feat, step);
                    }
                    st.WriteLine(header);
                }

                foreach (string info in from summary in output
                    let info = String.Format(CultureInfo.InvariantCulture, "{0},{1},{2:F4}", summary.Generation,
                        summary.CountEval, summary.Fitness)
                    select summary.DistributionMeanVector.Aggregate(info,
                        (current, x) => current + String.Format(CultureInfo.InvariantCulture, ",{0:R9}", x)))
                {
                    st.WriteLine(info);
                }

                st.Close();
            }
            fs.Close();
        }

        public static void WriteDifference2Csv(FileInfo file, List<FullData.DiffPreference>[][] diffData,
            FileMode fileMode, string problem, Track track, FeatureType featType)
        {
            if (file.Extension != ".csv")
                file = new FileInfo(file.FullName + ".csv");

            while (File.Exists(file.FullName) & FileInUse(file.FullName))
            {
                /* wait */
            }

            var fs = new FileStream(file.FullName, fileMode, FileAccess.Write);
            using (var st = new StreamWriter(fs))
            {
                if (fs.Length == 0) // header is missing 
                {
                    var header = "PID,Step,Rank,ResultingOptMakespan,Followed";

                    switch (featType)
                    {
                        case FeatureType.Local:
                            for (var j = 0; j < (int) LocalFeature.Count; j++)
                                header += "," + String.Format("phi.{0}", (LocalFeature) j);
                            break;
                        case FeatureType.Global:
                            for (var j = 0; j < (int) GlobalFeature.Count; j++)
                                header += "," + String.Format("phi.{0}", (GlobalFeature) j);

                            for (var j = 0; j < (int) SDR.Count; j++)
                                header += "," + String.Format("sdr.{0}", (SDR) j);
                            break;
                    }
                    st.WriteLine(header);
                }

                for (var pid = 0; pid < diffData.Length; pid++)
                {
                    for (var step = 0; step < diffData[pid].Length; step++)
                    {
                        foreach (var diff in diffData[pid][step])
                        {
                            var info = String.Format("{0},{1},{2},{3},{4}", pid, step, diff.Rank, diff.ResultingMakespan,
                                diff.Followed ? '1' : '0');

                            switch (featType)
                            {
                                case FeatureType.Local:
                                    for (var j = 0; j < (int) LocalFeature.Count; j++)
                                        info += "," + diff.Feature.Local[j];
                                    break;
                                case FeatureType.Global:
                                    for (var j = 0; j < (int) GlobalFeature.Count; j++)
                                        info += "," + (int) diff.Feature.Global[j];

                                    for (var j = 0; j < (int) SDR.Count; j++)
                                        info += String.Format(",{0}", diff.Feature.Equiv[j] ? 1 : .0);
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


        public static void WriteDataTable2Csv(FileInfo file, DataTable data, List<string> write, FileMode fileMode,
            FeatureType featType, bool writeRND = false, int alreadyAutoSavedPid = -1)
        {
            if (file.Directory != null && !file.Directory.Exists)
                Directory.CreateDirectory(file.Directory.FullName);

            if (file.Extension != ".csv")
                file = new FileInfo(file.FullName + ".csv");

            while (File.Exists(file.FullName) & FileInUse(file.FullName))
            {
                /* wait */
            }

            var fs = new FileStream(file.FullName, fileMode, FileAccess.Write);
            using (var st = new StreamWriter(fs))
            {
                if (fs.Length == 0) // header is missing 
                {
                    var header = string.Empty;
                    for (var i = 0; i < write.Count; i++)
                    {
                        if (write[i] == "Features")
                        {
                            switch (featType)
                            {
                                case FeatureType.Local:
                                    for (var j = 0; j < (int) LocalFeature.Count; j++)
                                        header += String.Format("phi.{0}", (LocalFeature) j) + ",";
                                    header = header.Substring(0, header.Length - 1);
                                    break;

                                case FeatureType.Global:
                                    for (var j = 0; j < (int) SDR.Count; j++)
                                        header += String.Format("sdr.{0}", (SDR) j) + ",";

                                    for (var j = 0; j < (int) GlobalFeature.Count; j++)
                                        header += String.Format("phi.{0}", (GlobalFeature) j) + ",";

                                    if (writeRND)
                                        header += "phi.RND";
                                    else
                                        header = header.Substring(0, header.Length - 1);

                                    break;
                            }
                        }
                        else
                            header += write[i];
                        header += (i == write.Count - 1 ? string.Empty : ",");
                    }
                    if (header == "")
                    {
                        return;
                    }
                    st.WriteLine(header);
                }

                foreach (DataRow row in data.Rows)
                {
                    int pid = (int) row["PID"];
                    if (pid <= alreadyAutoSavedPid) continue;

                    var info = string.Empty;
                    for (var i = 0; i < write.Count; i++)
                    {
                        var type = row[write[i]].GetType();
                        if (type == typeof (string))
                            info += row[write[i]];
                        else if (type == typeof (int))
                            info += row[write[i]].ToString();
                        else if (type == typeof (double))
                        {
                            var num = (double) (row[write[i]]);
                            if (!double.IsNaN(num))
                                info += num.ToString("F3").Replace(',', '.');
                        }
                        else if (type == typeof (bool))
                            info += ((bool) row[write[i]] ? 1 : 0); // TRUE vs. FALSE
                        else if (type == typeof (char))
                            info += (char) row[write[i]];
                        else if (type == typeof (Schedule.Dispatch))
                        {
                            var disp = (Schedule.Dispatch) row[write[i]];
                            info += disp.Job + "." + disp.Mac + "." + disp.StartTime;
                        }
                        else if (type == typeof (Features))
                        {
                            var feat = (Features) row[write[i]];
                            switch (featType)
                            {
                                case FeatureType.Local:

                                    for (var j = 0; j < (int) LocalFeature.Count; j++)
                                        info += feat.Local[j] + ",";
                                    info = info.Substring(0, info.Length - 1);
                                    break;
                                case FeatureType.Global:
                                    for (var j = 0; j < (int) SDR.Count; j++)
                                        info += String.Format("{0},", feat.Equiv[j] ? 1 : 0);

                                    for (var j = 0; j < (int) GlobalFeature.Count; j++)
                                        info += (int) feat.Global[j] + ",";

                                    if (writeRND)
                                    {
                                        if (feat.RND != null)
                                        {
                                            for (var k = 0; k < feat.RND.Length; k++)
                                                info += (k > 0 ? ";" : "") + feat.RND[k];
                                        }
                                    }
                                    else info = info.Substring(0, info.Length - 1);
                                    break;
                            }
                        }
                        info += (i == write.Count - 1 ? string.Empty : ",");
                    }
                    st.WriteLine(info);
                }
                st.Close();
            }
            fs.Close();
        }
    }
}