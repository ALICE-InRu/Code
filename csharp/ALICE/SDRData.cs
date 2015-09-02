using System;
using System.IO;

namespace ALICE
{
    /// <summary>
    /// SDR applied on RawData
    /// </summary>
    public class SDRData : HeuristicData
    {
        public enum SDR
        {
            SPT,
            LPT,
            MWR,
            LWR,
            RND // must be last 
        }

        public static int SDRCount
        {
            get { return Enum.GetNames(typeof (SDR)).Length - 1; }
        }

        private readonly SDR _sdr;

        public SDRData(string distribution, string dimension, DataSet set, bool extended, SDR sdr, DirectoryInfo data)
            : base(distribution, dimension, set, extended, "SDR", sdr.ToString(), data, Features.Mode.Local)
        {
            _sdr = sdr;
            FileInfo =
                new FileInfo(string.Format(@"{0}\{1}\{2}.{3}.{4}.csv", data.FullName, "SDR",
                    Distribution, Dimension, Set));

            Read(false);
        }

        protected SDRData(string distribution, string dimension, DataSet set, bool extended, string heuristicName,
            string heuristicValue, DirectoryInfo data)
            : base(distribution, dimension, set, extended, heuristicName, heuristicValue, data, Features.Mode.Local)
        {
            FileInfo =
                new FileInfo(string.Format(@"{0}\{1}\{2}.{3}.{4}.csv", data.FullName, HeuristicName,
                    Distribution, Dimension, Set));

            Read(false);
        }

        public void Apply()
        {
            ApplyAll(Apply);
        }

        public Schedule Apply(int pid)
        {
            string name = GetName(pid);
            Schedule jssp = GetEmptySchedule(name);
            jssp.ApplySDR(_sdr);
            AddMakespan(name, jssp.Makespan);
            return jssp;
        }
    }
}