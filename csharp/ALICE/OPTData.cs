using System;
using System.Data;
using System.IO;
using System.Linq;

namespace ALICE
{
    /// <summary>
    /// Optimum for RawData
    /// </summary>
    public class OPTData : RawData
    {
        public readonly int TimeLimit; // in minutes

        public OPTData(string distribution, string dimension, DataSet set, bool extended, int timeLimit_min = -1)
            : base(distribution, dimension, set, extended)
        {
            TimeLimit = timeLimit_min;
            FileInfo =
                new FileInfo(string.Format("C://Users//helga//Alice//Code//OPT//{0}.{1}.{2}.csv",
                    Distribution, Dimension, Set));

            SetAlreadySavedPID(false);

            Columns.Add("Solved", typeof (string));
            Columns.Add("Optimum", typeof (int));
            Columns.Add("Solution", typeof (int[,]));
            Columns.Add("Simplex", typeof (int));
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

        public void AddOptMakespan(string name, int makespan, bool solved, int[,] xTimeJob, int simplexIterations)
        {
            var row = Rows.Find(name);
            row.SetField("Solved", solved ? "opt" : "bks");
            row.SetField("Optimum", makespan);
            row.SetField("Solution", xTimeJob);
            row.SetField("Simplex", simplexIterations);
        }

        internal int[] OptimumArray()
        {
            int[] opts = new int[Rows.Count];
            for (int i = 0; i < Rows.Count; i++)
            {
                opts[i] = (int) Rows[i]["Optimum"];
            }
            return opts;
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
                    where pid > AlreadySavedPID
                    select String.Format("{0},{1},{2}", row["Name"], row["Optimum"], row["Solved"]))
                {
                    st.WriteLine(info);
                }
                st.Close();
            }
            fs.Close();
        }
    }
}