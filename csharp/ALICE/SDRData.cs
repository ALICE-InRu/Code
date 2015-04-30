using System;
using System.Data;
using System.IO;
using System.Linq;

namespace ALICE
{
    /// <summary>
    /// SDR applied on RawData
    /// </summary>
    public class SDRData : RawData
    {
        private readonly string _strSDR;
        public SDRData(SDR sdr)
        {
            FileInfo =
                new FileInfo(string.Format("C://Users//helga//Alice//Code//SDR//{0}.{1}.{2}.csv", Distribution, Dimension,
                    Set));

            Columns.Add("Makespan", typeof(int));

            _strSDR = String.Format("{0}", sdr);
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
                if (_strSDR != content[1]) continue;
                row["SDR"] = content[1];
                row["Makespan"] = Convert.ToInt32(content[2]);
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
                    const string HEADER = "Name,SDR,Makespan";
                    st.WriteLine(HEADER);
                }

                foreach (var info in from DataRow row in Rows
                    let pid = (int)row["PID"]
                    where pid > AlreadyAutoSavedPID
                    select String.Format("{0},{1},{2}", row["Name"], row["SDR"], row["Makespan"]))
                {
                    st.WriteLine(info);
                }
                st.Close();
            }
            fs.Close();
        }

    }
}