using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;

namespace ALICE
{
    public class HeuristicData : RawData
    {
        public readonly string HeuristicValue;
        public readonly string HeuristicName;

        public HeuristicData(string distribution, string dimension, DataSet set, bool extended, string heuristicName,
            string heuristicValue) : base(distribution, dimension, set, extended)
        {
            HeuristicName = heuristicName;
            HeuristicValue = heuristicValue;
            Columns.Add("Makespan", typeof (int));
            Columns.Add(heuristicName, typeof (string));
        }

        internal void AddMakespan(string name, int makespan)
        {
            var row = Rows.Find(name);
            row.SetField(HeuristicName, HeuristicValue);
            row.SetField("Makespan", makespan);
        }

        internal bool Read(bool all)
        {
            List<string> header;
            List<string[]> content = CSV.Read(FileInfo, out header);
            if (content == null || content.Count == 0) return false;

            foreach (var line in content)
            {
                var row = Rows.Find(line[0]);
                if (row == null) continue;
                if (!all && HeuristicValue != line[1]) continue;
                row[HeuristicName] = line[1];
                row["Makespan"] = Convert.ToInt32(line[2]);
                AlreadySavedPID = (int) row["PID"];
            }
            return true;
        }

        internal void Write()
        {
            var fs = new FileStream(FileInfo.FullName, FileMode.Append, FileAccess.Write);
            using (var st = new StreamWriter(fs))
            {
                if (fs.Length == 0) // header is missing 
                {
                    string header = string.Format("Name,{0},Makespan", HeuristicName);
                    st.WriteLine(header);
                }

                foreach (var info in from DataRow row in Rows
                    let pid = (int) row["PID"]
                    where pid > AlreadySavedPID
                    select String.Format("{0},{1},{2}", row["Name"], HeuristicValue, row["Makespan"]))
                {
                    st.WriteLine(info);
                }
                st.Close();
            }
            fs.Close();
        }
    }
}