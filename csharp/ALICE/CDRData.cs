using System.IO;

namespace ALICE
{
    /// <summary>
    /// CDR applied on RawData
    /// </summary>
    public class CDRData : HeuristicData
    {
        public CDRData(string distribution, string dimension, string set, string model, int nrFeat, int nrModel)
            : base(distribution, dimension, set, "CDR", string.Format("{0}.{1}", nrFeat, nrModel))
        {
            FileInfo =
                new FileInfo(string.Format(
                    "C://Users//helga//Alice//Code//PREF//CDR//{0}//F{1}.Model{2}.on.{3}.{4}.{5}.csv",
                    model, nrFeat, nrModel,
                    Distribution, Dimension, Set));
        }
    }
}