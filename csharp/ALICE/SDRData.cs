using System.IO;

namespace ALICE
{
    /// <summary>
    /// SDR applied on RawData
    /// </summary>
    public class SDRData : HeuristicData
    {
        public SDRData(string distribution, string dimension, string set, SDR sdr)
            : base(distribution, dimension, set, "SDR", sdr.ToString())
        {
            FileInfo =
                new FileInfo(string.Format("C://Users//helga//Alice//Code//SDR//{0}.{1}.{2}.csv", Distribution,
                    Dimension, Set));
        }
    }
}