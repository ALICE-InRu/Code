using System;
using System.Data;
using System.IO;
using System.Linq;

namespace ALICE
{
    public class HeuristicData : RawData
    {
        private readonly string _heuristicValue;
        private readonly string _heuristicName;

        public HeuristicData(string distribution, string dimension, string set, string heuristicName,
            string heuristicValue) : base(distribution, dimension, set)
        {
            _heuristicName = heuristicName;
            _heuristicValue = heuristicValue;
            Columns.Add("Makespan", typeof (int));
            Columns.Add("Makespan", typeof (int));
        }

        internal bool Read(bool all)
        {
            var contents = ReadCSV();
            if (contents == null) return false;
            //string[] header = contents[0]; 
            contents.RemoveAt(0); // remove header
            foreach (var content in contents)
            {
                var row = Rows.Find(content[0]);
                if (row == null) continue;
                if (!all && _heuristicValue != content[1]) continue;
                row["SDR"] = content[1];
                row["Makespan"] = Convert.ToInt32(content[2]);
                AlreadyAutoSavedPID = (int) row["PID"];
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
                    string header = string.Format("Name,{0},Makespan", _heuristicName);
                    st.WriteLine(header);
                }

                foreach (var info in from DataRow row in Rows
                    let pid = (int) row["PID"]
                    where pid > AlreadyAutoSavedPID
                    select String.Format("{0},{1},{2}", row["Name"], row[_heuristicValue], row["Makespan"]))
                {
                    st.WriteLine(info);
                }
                st.Close();
            }
            fs.Close();
        }
    }
}