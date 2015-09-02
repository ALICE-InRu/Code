using System;
using System.IO;
using System.Reflection;

namespace ALICE
{
    /// <summary>
    /// CDR applied on RawData
    /// </summary>
    public class CDRData : HeuristicData
    {
        public readonly LinearModel Model;

        public CDRData(RawData data, LinearModel model)
            : base("CDR", model.Name, data, model.FeatureMode)
        {
            Model = model;
            FileInfo =
                new FileInfo(string.Format(
                    @"{0}\..\CDR\{1}\{2}.{3}.{4}.csv", Model.FileInfo.Directory,
                    Model.FileInfo.Name.Substring(0, Model.FileInfo.Name.Length - Model.FileInfo.Extension.Length),
                    Distribution, Dimension, Set));
            Read(false);
        }

        public void Apply()
        {
            ApplyAll(Apply1);
        }

        public string Apply(int pid)
        {
            Schedule jssp = Apply1(pid);
            return String.Format("{0}:{1} {2}", FileInfo.Name, pid, jssp.Makespan);
        }

        private Schedule Apply1(int pid)
        {
            string name = GetName(pid);
            Schedule jssp = GetEmptySchedule(name);
            int bestFoundMakespan = jssp.ApplyCDR(Model);
            AddMakespan(name, jssp.Makespan, bestFoundMakespan);
            return jssp;
        }
    }
}