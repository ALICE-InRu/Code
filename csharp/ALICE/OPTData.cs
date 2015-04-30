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
        public OPTData(string distribution, string dimension, string set) : base(distribution, dimension, set)
        {
            FileInfo =
                new FileInfo(string.Format("C://Users//helga//Alice//Code//OPT//{0}.{1}.{2}.csv", Distribution, Dimension,
                    Set));

            Columns.Add("Solved", typeof(string));
            Columns.Add("Optimum", typeof(int));
            Columns.Add("Solution", typeof(int[,]));
            Columns.Add("Solver", typeof(string));
            Columns.Add("Simplex", typeof(int));
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

                AlreadyAutoSavedPID = (int)row["PID"];
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
                    let pid = (int)row["PID"]
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
}