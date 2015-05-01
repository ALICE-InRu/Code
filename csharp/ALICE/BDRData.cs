using System;

namespace ALICE
{
    /// <summary>
    /// BDR applied on RawData
    /// </summary>
    public class BDRData : SDRData
    {
        private readonly SDR _sdr1;
        private readonly SDR _sdr2;
        private readonly int _split;

        public BDRData(string distribution, string dimension, DataSet set, bool extended, SDR sdr1, SDR sdr2,
            int split)
            : base(distribution, dimension, set, extended, "BDR", String.Format("{0}.{1}.{2}", sdr1, sdr2, split))
        {
            _sdr1 = sdr1;
            _sdr2 = sdr2;
            _split = (int) Math.Round(split/100.0*NumDimension, 0);
        }

        public new void Apply()
        {
            ApplyAll(Apply);
        }

        public new Schedule Apply(int pid)
        {
            string name = GetName(pid);
            Schedule jssp = GetEmptySchedule(name);
            jssp.ApplyBDR(_sdr1, _sdr2, _split);
            AddMakespan(name, jssp.Makespan);
            return jssp;
        }
    }
}