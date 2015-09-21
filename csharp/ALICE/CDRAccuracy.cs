using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;

namespace ALICE
{
    public class CDRAccuracy : RetraceSet
    {
        private int[] _isOptimal;

        public CDRAccuracy(LinearModel model, DirectoryInfo data)
            : base(
                model.Distribution, model.Dimension, Trajectory.OPT, 0, false, Features.LocalCount, 1, "equal",
                Features.Mode.Local, data)
        {
            Model = model;

            FileInfo =
                new FileInfo(String.Format(@"{0}\Stepwise\accuracy\{1}", data.FullName, Model.FileInfo.Name));

            _isOptimal = new int[NumDimension];

            Read();
        }

        public CDRAccuracy Clone(LinearModel model, DirectoryInfo data)
        {
            CDRAccuracy clone = (CDRAccuracy) MemberwiseClone();
            clone.Model = model;
            clone._isOptimal = new int[NumDimension];
            clone.Read();
            return clone;
        }

        public new string Apply()
        {
            ApplyAll(Retrace, Accuracy, null, Write);
            return Model.Name;
        }

        public new string Apply(int pid)
        {
            NumApplied++;
            return Retrace(pid, Accuracy);
        }

        private int Accuracy(int pid, int step, Schedule jssp)
        {
            foreach (var p in Preferences[pid - 1, step])
                p.Priority = Model.PriorityIndex(p.Feature);     
     
            Preference best = Preferences[pid - 1, step].Find(p => p.Followed);
            Preference chosen =
                Preferences[pid - 1, step].Find(
                    p => Math.Abs(p.Priority - Preferences[pid - 1, step].Max(q => q.Priority)) < 0.001);
            
            if (best.ResultingOptMakespan == chosen.ResultingOptMakespan)
                _isOptimal[step]++;

            return Preferences[pid - 1, step].Count;
        }

        private void Read()
        {
            if (!FileInfo.Exists) return;
            List<string> header;
            List<string[]> content = CSV.Read(FileInfo, out header);
            int iHeader = header.FindIndex(p => p.Equals("CDR"));
            NumApplied = content.Any(line => line[iHeader].Equals(Model.Name)) ? NumInstances : 0;
        }

        public new int Write()
        {
            if (NumApplied != AlreadySavedPID) return -1; 

            if (FileInfo.Directory != null && !FileInfo.Directory.Exists)
                FileInfo.Directory.Create();

            var fs = new FileStream(FileInfo.FullName, FileMode.Append, FileAccess.Write);
            using (var st = new StreamWriter(fs))
            {
                if (fs.Length == 0) // header is missing 
                {
                    var header = "CDR";
                    for (int step = 0; step < NumDimension; step++)
                        header += String.Format(",Step.{0}", step + 1);
                    st.WriteLine(header);
                }

                string info = String.Format("{0}", Model.Name);
                for (int step = 0; step < NumDimension; step++)
                    info += String.Format(CultureInfo.InvariantCulture, ",{0:0.00}",
                        _isOptimal[step]/(double) NumInstances);

                st.WriteLine(info);
                st.Close();
            }
            fs.Close();
            return AlreadySavedPID = NumInstances;
        }
    }
}