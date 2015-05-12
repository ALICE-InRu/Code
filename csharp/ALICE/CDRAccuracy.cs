using System;
using System.IO;

namespace ALICE
{
    public class CDRAccuracy : CDRData
    {
        public CDRAccuracy(RawData data, LinearModel model)
            : base(data, model)
        {
            FileInfo =
                new FileInfo(String.Format(@"{0}\acc\{1}", FileInfo.Directory, FileInfo.Name));
        }

        public new void Apply()
        {
            ApplyAll(Apply, Write);
        }
        
        private Schedule Apply(int pid)
        {
            throw new NotImplementedException();
            string name = GetName(pid);
            Schedule jssp = GetEmptySchedule(name);
            jssp.ApplyCDR(Model);
            AddMakespan(name, jssp.Makespan);
            return jssp;
        }

        public new int Write()
        {
            throw new NotImplementedException();
            return AlreadySavedPID;
        }
    }
}