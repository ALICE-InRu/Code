using System;
using System.Linq;

namespace ALICE
{
    public class RetraceSet : TrainingSet
    {

        private readonly Features.Mode _featureMode;

        public RetraceSet(string distribution, string dimension, Trajectory track, bool extended, Features.Mode featureMode)
            : base(distribution, dimension, track, extended)
        {
            _featureMode = featureMode;


        }

        public void Retrace(int pid)
        {
            string name = GetName(pid);
            var jssp = GetEmptySchedule(name);
            for (var step = 0; step < NumDimension; step++)
            {
                #region find features of possible jobs

                var prefs = TrData[pid, step];
                if (!ValidDispatches(prefs, jssp))
                    throw new Exception("Retracing gave an invalid dispatch");

                int dispatchedJob;
                if (prefs.Length > 0)
                {
                    foreach (var p in prefs)
                    {
                        var lookahead = jssp.Clone();
                        p.Feature = lookahead.Dispatch1(p.Dispatch.Job, _featureMode);
                    }

                    var followed = prefs.ToList().Find(p => p.Followed);
                    dispatchedJob = followed == null ? jssp.JobChosenBySDR((SDRData.SDR)Track) : followed.Dispatch.Job;
                }
                else
                {
                    dispatchedJob = jssp.ReadyJobs.Count > 1 ? jssp.JobChosenBySDR((SDRData.SDR)Track) : jssp.ReadyJobs[0];
                }

                #endregion
                jssp.Dispatch1(dispatchedJob, Features.Mode.None);
            }
        }

        private bool ValidDispatches(TrSet[] prefs, Schedule jssp)
        {
            if (prefs.ToList().FindIndex(p => p.Dispatch.Mac < 0) == -1) return true;
            foreach (TrSet pref in prefs)
            {
                jssp.FindDispatch(pref.Dispatch.Job, out pref.Dispatch);
            }
            return false;
        }
    }
}