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
            MWR,
            LWR,
            SPT,
            LPT,
            Count,
            RND
        }

        private readonly SDR _sdr;

        public SDRData(string distribution, string dimension, DataSet set, bool extended, SDR sdr)
            : base(distribution, dimension, set, extended, "SDR", sdr.ToString())
        {
            _sdr = sdr;
            FileInfo =
                new FileInfo(string.Format("C://Users//helga//Alice//Code//SDR//{0}.{1}.{2}.csv", Distribution,
                    Dimension, Set));

            Read(false);
        }

        public void Apply()
        {
            for (int pid = AlreadySavedPID + 1; pid <= NumInstances; pid++)
                Apply(pid);
            Write();
        }

        public Schedule Apply(int pid)
        {
            string name = GetName(pid);
            Schedule jssp = GetEmptySchedule(name);
            jssp.ApplySDR(_sdr, Features.Mode.None);
            AddMakespan(name, jssp.Makespan);
            return jssp;
        }
    }
}