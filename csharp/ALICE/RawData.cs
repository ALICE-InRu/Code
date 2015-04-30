using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

namespace ALICE
{
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

            Columns.Add("Name", typeof(string)); // unique!
            Columns.Add("PID", typeof(int)); // problem instance Index
            Columns.Add("Problem", typeof(ProblemInstance));

            PrimaryKey = new[] { Columns["Name"] };

            ReadProblemText();

        }
        
        public static int DimString2Num(string dim)
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
            var instance = Rows.Find(name);
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

            string workDir = String.Format("{0}//generator//{1}", FileInfo.Directory.FullName,
                Distribution.Substring(2, Distribution.Length));

            if (!Directory.Exists(workDir)) return;

            var files = Directory.GetFiles(workDir);

            int start = 0, finish = files.Length;
            string setInfo;
            if (Set == "test")
            {
                start = files.Length / 2;
                setInfo = "TEST";
            }
            else
            {
                finish = files.Length / 2;
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
}