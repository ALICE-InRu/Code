using System;
using System.ComponentModel;
using System.Data;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

namespace ALICE
{
    /// <summary>
    /// Parent class for all JobShop data
    /// </summary>
    public class RawData 
    {
        public FileInfo FileInfo;
        public readonly string Distribution;
        public readonly int NumDimension;
        public readonly string Dimension;
        public readonly DataSet Set;
        public int NumInstances { get; internal set; }
        public int AlreadySavedPID { get; internal set; }
        internal readonly DataTable Data; 

        public enum DataSet
        {
            train,
            test
        };

        internal RawData(string distribution, string dimension, DataSet set)
        {
            Distribution = distribution;
            Dimension = dimension;
            NumDimension = DimString2Num(dimension);
            Set = set;
        }

        internal RawData(RawData clone) : this(clone.Distribution, clone.Dimension, clone.Set)
        {
            FileInfo = clone.FileInfo;
            NumInstances = clone.NumInstances;
            AlreadySavedPID = clone.AlreadySavedPID;
            Data = clone.Data.Copy();
        }

        public RawData(string distribution, string dimension, DataSet set, bool extended, DirectoryInfo data)
            : this(distribution, dimension, set)
        {
            FileInfo =
                new FileInfo(String.Format(@"{0}\Raw\{1}.{2}.{3}.txt",
                    data.FullName, Distribution, Dimension, Set));

            if (!FileInfo.Exists)
            {
                WriteGeneratedData();
                FileInfo = new FileInfo(FileInfo.FullName);
                if (!FileInfo.Exists)
                    throw new Exception(
                        String.Format("Failed generating problem instances! Check if they are located in {0}",
                            FileInfo.DirectoryName));
            }

            Data = new DataTable("Problem");

            Data.Columns.Add("Name", typeof (string)); // unique!
            Data.Columns.Add("PID", typeof (int)); // problem instance Index
            Data.Columns.Add("Problem", typeof (ProblemInstance));

            Data.PrimaryKey = new[] {Data.Columns["Name"]};

            ReadProblemText(extended);
        }

        internal void SetAlreadySavedPID(bool warn = true)
        {
            if (!FileInfo.Exists) return;
            var firstLine = File.ReadLines(FileInfo.FullName).First();
            var lastLine = File.ReadLines(FileInfo.FullName).Last();
            if (lastLine == firstLine || lastLine == null) return;

            var firstSplit = Regex.Split(firstLine, ",").ToList();
            var lastSplit = Regex.Split(lastLine, ",").ToArray();

            int iPID = firstSplit.FindIndex(x => x == "PID");
            if (iPID == -1)
            {
                int iName = firstSplit.FindIndex(x => x == "Name");
                string[] name = Regex.Split(lastSplit[iName], "\\.").ToArray();
                AlreadySavedPID = Convert.ToInt32(name[4]);
            }
            else
            {
                AlreadySavedPID = Convert.ToInt32(lastSplit[iPID]);
            }

            if (AlreadySavedPID <= NumInstances) return;
            if (warn)
                throw new WarningException(
                    String.Format("Use extended data set, otherwise you will lose information on {0} instances!",
                        AlreadySavedPID - NumInstances));
            AlreadySavedPID = NumInstances;
        }

        internal static int DimString2Num(string dim)
        {
            var jobxmac = Regex.Split(dim, "x");
            var numJobs = Convert.ToInt32(jobxmac[0]);
            var numMachines = Convert.ToInt32(jobxmac[1]);
            return numJobs * numMachines;
        }

        internal string GetName(int pid)
        {
            return String.Format("{0}.{1}.{2}.{3}", Distribution, Dimension, Set, pid).ToLower();
        }

        internal ProblemInstance GetProblem(string name)
        {
            var instance = Data.Rows.Find(name);
            return instance == null ? null : (ProblemInstance) instance["Problem"];
        }

        internal Schedule GetEmptySchedule(string name)
        {
            ProblemInstance prob = GetProblem(name);
            return prob == null ? null : new Schedule(prob);
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

            string workDir = String.Format(@"{0}\generator\{1}", FileInfo.Directory.FullName,
                Distribution.Substring(2));

            if (!Directory.Exists(workDir)) return;
            var files = Directory.GetFiles(workDir);
            if (files.Length <= 0) return;

            int start, finish;
            if (Set == DataSet.test)
            {
                start = files.Length / 2;
                finish = files.Length;
            }
            else
            {
                start = 0;
                finish = files.Length / 2;
            }

            var sorted = files.ToList().Select(str => new NameAndNumber(str))
                .OrderBy(n => n.Name)
                .ThenBy(n => n.Number).ToList();

            const string LONG_SEP = SEP + SEP + SEP;
            using (var writer = new StreamWriter(FileInfo.FullName))
            {
                writer.WriteLine("{0} SET problems from subfolder {1}{2}\n\n{3}", Set.ToString().ToUpper(), workDir,
                    (rnd != null ? String.Format(" with random machine order (seed={0})", SEED) : ""), LONG_SEP);

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

        private void ReadProblemText(bool extended)
        {
            if (!FileInfo.Exists) return;
            int maxNumInstances = extended ? 5000 : 500; 

            var fullContent = File.ReadAllText(FileInfo.FullName);
            var allContent = Regex.Split(fullContent, "[\r\n ]*[+]+[\r\n ]*");

            var shortName = string.Empty;
            var regShortName = new Regex("^instance ([a-zA-Z0-9. ]*)");
            foreach (var content in allContent)
            {
                var m = regShortName.Match(content);
                if (m.Success)
                {
                    shortName = m.Groups[1].Value;
                }
                else if (shortName != string.Empty)
                {
                    var prob = ReadSingleProblem(content);
                    AddProblem(prob);
                    shortName = string.Empty;
                }
                if (Data.Rows.Count >= maxNumInstances)
                    break;
            }
            NumInstances = Data.Rows.Count;
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
            var row = Data.NewRow();
            row["Name"] = GetName(pid);
            row["PID"] = pid;
            row["Problem"] = prob;
            Data.Rows.Add(row);
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

    }
}