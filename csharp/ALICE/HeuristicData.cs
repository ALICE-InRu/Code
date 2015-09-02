using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Security.AccessControl;

namespace ALICE
{
    public class HeuristicData : RawData
    {
        public readonly string HeuristicValue;
        public readonly string HeuristicName;
        private Features.Mode _featureMode;

        internal HeuristicData(string distribution, string dimension, DataSet set, bool extended, string heuristicName,
            string heuristicValue, DirectoryInfo data, Features.Mode featureMode) : base(distribution, dimension, set, extended, data)
        {
            HeuristicName = heuristicName;
            HeuristicValue = heuristicValue;
            _featureMode = featureMode;
            Data.Columns.Add("Makespan", typeof(int));
            Data.Columns.Add("BestFoundMakespan", typeof(int));
            Data.Columns.Add(heuristicName, typeof(string));
        }

        internal HeuristicData(string heuristicName, string heuristicValue, RawData clone, Features.Mode featureMode)
            : base(clone)
        {
            HeuristicName = heuristicName;
            HeuristicValue = heuristicValue;
            _featureMode = featureMode;
            Data.Columns.Add("Makespan", typeof (int));
            Data.Columns.Add("BestFoundMakespan", typeof(int));
            Data.Columns.Add(heuristicName, typeof (string));
        }

        internal void AddMakespan(string name, int makespan, int bestFoundMakespan = int.MaxValue)
        {
            var row = Data.Rows.Find(name);
            row.SetField(HeuristicName, HeuristicValue);
            row.SetField("Makespan", makespan);
            if (bestFoundMakespan < int.MaxValue)
                row.SetField("BestFoundMakespan", bestFoundMakespan);
        }

        internal bool Read(bool all)
        {
            List<string> header;
            List<string[]> content = CSV.Read(FileInfo, out header);
            if (content == null || content.Count == 0) return false;

            foreach (var line in content)
            {
                var row = Data.Rows.Find(line[0]);
                if (row == null) continue;
                if (!all && HeuristicValue != line[1]) continue;
                row[HeuristicName] = line[1];
                row["Makespan"] = Convert.ToInt32(line[2]);
                AlreadySavedPID = (int) row["PID"];
            }
            return true;
        }

        public void Write()
        {
            if (FileInfo.Directory != null && !FileInfo.Directory.Exists)
                Directory.CreateDirectory(FileInfo.Directory.FullName);

            var fs = new FileStream(FileInfo.FullName, FileMode.Append, FileAccess.Write);
            using (var st = new StreamWriter(fs))
            {
                if (fs.Length == 0) // header is missing 
                {
                    string header = string.Format("Name,{0},Makespan", HeuristicName);
                    if (_featureMode == Features.Mode.Global)
                        header += String.Format(",BestFoundMakespan");
                    st.WriteLine(header);
                }

                foreach(DataRow row in Data.Rows)
                {
                    int pid = (int) row["PID"];
                    if (pid <= AlreadySavedPID) continue;
                    if (row.IsNull("Makespan"))
                    {
                        AlreadySavedPID = pid - 1;
                        break;
                    }
                    string info = String.Format("{0},{1},{2}", row["Name"], HeuristicValue, row["Makespan"]);
                    if (_featureMode == Features.Mode.Global)
                        info += String.Format(",{0}", row["BestFoundMakespan"]);
                    st.WriteLine(info);
                }
                st.Close();
            }
            fs.Close();
        }

        internal void ApplyAll(Func<int, Schedule> apply1, Func<int> overwriteWriteFunc = null)
        {
            for (int pid = AlreadySavedPID + 1; pid <= NumInstances; pid++)
                apply1(pid);

            if (overwriteWriteFunc != null)
                overwriteWriteFunc();
            else
                Write();
        }
    }
}