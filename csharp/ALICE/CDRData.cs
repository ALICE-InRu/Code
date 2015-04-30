using System;
using System.Data;
using System.IO;
using System.Linq;

namespace ALICE
{
    /// <summary>
    /// CDR applied on RawData
    /// </summary>
    public class CDRData : RawData
    {
        public CDRData(string model, int nrFeat, int nrModel)
        {
            FileInfo =
                new FileInfo(string.Format(
                    "C://Users//helga//Alice//Code//PREF//CDR//{0}//F{1}.Model{2}.on.{3}.{4}.{5}.csv",
                    model, nrFeat, nrModel,
                    Distribution, Dimension, Set));

            Columns.Add("Makespan", typeof(int));

        }

        public void Write()
        {
            var fs = new FileStream(FileInfo.FullName, FileMode.Append, FileAccess.Write);
            using (var st = new StreamWriter(fs))
            {
                if (fs.Length == 0) // header is missing 
                {
                    const string HEADER = "Name,Makespan";
                    st.WriteLine(HEADER);
                }

                foreach (var info in from DataRow row in Rows
                    let pid = (int)row["PID"]
                    where pid > AlreadyAutoSavedPID
                    select String.Format("{0},{1}", row["Name"], row["Makespan"]))
                {
                    st.WriteLine(info);
                }
                st.Close();
            }
            fs.Close();
        }

    }
}