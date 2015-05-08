using System.IO;

namespace ALICE
{
    /// <summary>
    /// CDR applied on RawData
    /// </summary>
    public class CDRData : HeuristicData
    {
        public readonly LinearModel Model;

        public CDRData(string distribution, string dimension, DataSet set, bool extended,
            LinearModel model, DirectoryInfo data)
            : base(distribution, dimension, set, extended, "CDR", model.Name, data)
        {
            Model = model;
            FileInfo =
                new FileInfo(string.Format(
                    @"{0}\..\CDR\{1}\{2}.{3}.{4}.csv", Model.FileInfo.Directory,
                    Model.FileInfo.Name.Substring(0, Model.FileInfo.Name.Length - Model.FileInfo.Extension.Length),
                    Distribution, Dimension, Set));
        }

        public CDRData(RawData data, LinearModel model)
            : base("CDR", model.Name, data)
        {
            Model = model;
            FileInfo =
                new FileInfo(string.Format(
                    @"{0}\..\CDR\{1}\{2}.{3}.{4}.csv", Model.FileInfo.Directory,
                    Model.FileInfo.Name.Substring(0, Model.FileInfo.Name.Length - Model.FileInfo.Extension.Length),
                    Distribution, Dimension, Set));
        }

        public void Apply()
        {
            ApplyAll(Apply);
        }

        private Schedule Apply(int pid)
        {
            string name = GetName(pid);
            Schedule jssp = GetEmptySchedule(name);
            jssp.ApplyCDR(Model);
            AddMakespan(name, jssp.Makespan);
            return jssp;
        }
    }
}