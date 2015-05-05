using System.IO;

namespace ALICE
{
    /// <summary>
    /// CDR applied on RawData
    /// </summary>
    public class CDRData : HeuristicData
    {
        public CDRData(string distribution, string dimension, DataSet set, bool extended,
            string model, int nrFeat, int nrModel, DirectoryInfo data)
            : base(distribution, dimension, set, extended, "CDR", string.Format("{0}.{1}", nrFeat, nrModel), data)
        {
            FileInfo =
                new FileInfo(string.Format(
                    "{0}//PREF//CDR//{1}//F{2}.Model{3}.on.{4}.{5}.{6}.csv", data.FullName,
                    model, nrFeat, nrModel,
                    Distribution, Dimension, Set));
        }
    }
}