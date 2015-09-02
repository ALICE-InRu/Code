using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Net.NetworkInformation;

namespace ALICE
{
    /// <summary>
    /// Optimum for RawData
    /// </summary>
    public class OPTData : RawData
    {
        public readonly int TimeLimit; // in minutes

        internal OPTData(string distribution, string dimension, DataSet set, bool extended, bool readAll,
            DirectoryInfo data)
            : base(distribution, dimension, set, extended, data)
        {
            FileInfo =
                new FileInfo(string.Format(@"{0}\OPT\{1}.{2}.{3}.csv", data.FullName,
                    Distribution, Dimension, Set));

            CommonBase(readAll);
        }

        private void CommonBase(bool readAll)
        {
            SetAlreadySavedPID();

            Data.Columns.Add("Solved", typeof (string));
            Data.Columns.Add("Optimum", typeof (int));
            Data.Columns.Add("Solution", typeof (int[,]));
            Data.Columns.Add("Simplex", typeof (int));

            if (readAll)
                Read();
        }

        public OPTData(string distribution, string dimension, DataSet set, bool extended, int timeLimit_min,
            DirectoryInfo data)
            : this(distribution, dimension, set, extended, false, data)
        {
            TimeLimit = timeLimit_min;
            FileInfo =
                new FileInfo(string.Format(@"{0}\OPT\{1}.{2}.{3}.csv", data.FullName,
                    Distribution, Dimension, Set));
        }

        public OPTData(string orlib, int timeLimit_min, DirectoryInfo data)
            : base(orlib, data)
        {
            TimeLimit = timeLimit_min;
            FileInfo =
                new FileInfo(string.Format(@"{0}\OPT\{1}.{2}.{3}.csv", data.FullName,
                    Distribution, Dimension, Set));

            CommonBase(false);
        }

        public void Optimise()
        {
            for (int pid = AlreadySavedPID + 1; pid <= NumInstances; pid++)
                Optimise(pid);
            Write();
        }

        public string Optimise(int pid)
        {
            int opt;
            bool solved;
            int simplexIterations;
            string name = GetName(pid);
            ProblemInstance prob = GetProblem(name);
            if (prob == null)
                return String.Format("{0}:{1} doen't exist!", FileInfo.Name, pid);

            // INTENSE WORK
            int[,] xTimeJob = prob.Optimize(name, out opt, out solved, out simplexIterations, TimeLimit);

            Schedule jssp = new Schedule(prob);
            jssp.SetCompleteSchedule(xTimeJob, opt);

            string errorMsg;
            if (!jssp.Validate(out errorMsg, true))
            {
                return String.Format("Error {0}", errorMsg);
            }

            AddOptMakespan(name, opt, solved, xTimeJob, simplexIterations);
            return String.Format("{0}:{1} {2}{3}", FileInfo.Name, pid, opt, (solved ? "" : "*"));
        }

        private void AddOptMakespan(string name, int makespan, bool solved, int[,] xTimeJob, int simplexIterations)
        {
            var row = Data.Rows.Find(name);
            if (row == null) return;
            row.SetField("Solved", solved ? "opt" : "bks");
            row.SetField("Optimum", makespan);
            row.SetField("Solution", xTimeJob);
            row.SetField("Simplex", simplexIterations);
        }

        internal int[] OptimumArray()
        {
            int[] opts = new int[Data.Rows.Count];
            for (int i = 0; i < Data.Rows.Count; i++)
            {
                opts[i] = (int) Data.Rows[i]["Optimum"];
            }
            return opts;
        }

        public void Read()
        {
            List<string> header;
            List<string[]> content = CSV.Read(FileInfo, out header);

            foreach (var line in content)
            {
                AddOptMakespan(line[0], Convert.ToInt32(line[1]), line[2] == "opt", null, 0);
            }
        }

        public void Write()
        {
            bool orlib = Dimension == "ORLIB";

            var fs = new FileStream(FileInfo.FullName, FileMode.Append, FileAccess.Write);
            using (var st = new StreamWriter(fs))
            {
                if (fs.Length == 0) // header is missing 
                {
                    string header = String.Format("Name,Optimum,Solved{0}", orlib ? ",GivenName,Dimension" : "");
                    st.WriteLine(header);
                }

                foreach (
                    DataRow row in
                        from DataRow row in Data.Rows let pid = (int) row["PID"] where pid > AlreadySavedPID select row)
                {
                    if (row["Optimum"].ToString() == "")
                    {
                        AlreadySavedPID = (int) row["PID"] - 1;
                        break;
                    }
                    string info = String.Format("{0},{1},{2}", row["Name"], row["Optimum"], row["Solved"]);
                    if (orlib)
                    {
                        ProblemInstance prob = (ProblemInstance) row["Problem"];
                        info += String.Format(",{0},{1}", row["GivenName"],
                            String.Format("{0}x{1}", prob.NumJobs, prob.NumMachines));
                    }
                    st.WriteLine(info);
                }
                st.Close();
            }
            fs.Close();
        }
    }
}