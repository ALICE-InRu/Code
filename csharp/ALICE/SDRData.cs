using System.IO;

namespace ALICE
{
    /// <summary>
    /// SDR applied on RawData
    /// </summary>
    public class SDRData : HeuristicData
    {
        private readonly SDR _sdr ; 

        public SDRData(string distribution, string dimension, string set, SDR sdr)
            : base(distribution, dimension, set, "SDR", sdr.ToString())
        {
            _sdr = sdr; 
            FileInfo =
                new FileInfo(string.Format("C://Users//helga//Alice//Code//SDR//{0}.{1}.{2}.csv", Distribution,
                    Dimension, Set));
        }

        public void Apply()
        {
            for (int pid = AlreadyAutoSavedPID + 1; pid < NumInstances; pid++)
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