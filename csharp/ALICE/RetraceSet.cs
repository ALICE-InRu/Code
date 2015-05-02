using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace ALICE
{
    public class RetraceSet : TrainingSet
    {
        private int _numRetraced;

        public RetraceSet(string distribution, string dimension, Trajectory track, bool extended,
            Features.Mode featureMode)
            : base(distribution, dimension, track, extended)
        {
            Read();
            FeatureMode = featureMode;

            if (FeatureMode != Features.Mode.Local)
                FileInfo =
                    new FileInfo(FileInfo.FullName.Replace(Features.Mode.Local.ToString(), FeatureMode.ToString()));
        }

        private void Read()
        {
            List<string> header;
            List<string[]> content = CSV.Read(FileInfo, out header);
            if (content == null || content.Count == 0) return;

            int iPID = header.FindIndex(x => x.Equals("PID"));
            int iStep = header.FindIndex(x => x.Equals("Step"));
            int iDispatch = header.FindIndex(x => x.Equals("Dispatch"));
            int iFollowed = header.FindIndex(x => x.Equals("Followed"));
            int iResultingOptMakespan = header.FindIndex(x => x.Equals("ResultingOptMakespan"));
            int iRank = header.FindIndex(x => x.Equals("Rank"));

            int minStep = Convert.ToInt32(content[0][iStep]);

            int pid, step;
            for (pid = 0; pid < AlreadySavedPID; pid++)
                for (step = 0; step < NumDimension; step++)
                    TrData[pid, step] = new List<TrSet>();

            foreach (var line in content)
            {
                pid = Convert.ToInt32(line[iPID]);
                if (pid > AlreadySavedPID) return;

                step = Convert.ToInt32(line[iStep]);
                bool followed = Convert.ToInt32(line[iFollowed]) == 1;
                int resultingOptMakespan = Convert.ToInt32(line[iResultingOptMakespan]);
                int rank = iRank >= 0 ? Convert.ToInt32(line[iRank]) : 0;

                Schedule.Dispatch dispatch = new Schedule.Dispatch(line[iDispatch]);
                TrData[pid - 1, step - minStep].Add(new TrSet(dispatch, followed, resultingOptMakespan, rank));
            }

            if (iRank >= 0) return;
            for (pid = 1; pid < AlreadySavedPID; pid++)
                RankPreferences(pid);
        }

        public new void Write()
        {
            if (_numRetraced == AlreadySavedPID)
                Write(FileMode.Create);
        }

        public void Retrace()
        {
            for (int pid = 1; pid <= AlreadySavedPID; pid++)
                Retrace(pid);
            Write();
        }

        public string Retrace(int pid)
        {
            if (pid > AlreadySavedPID)
                return String.Format("PID {0} exeeds what has already been created. Cannot retrace!", pid);

            _numRetraced++;

            if (TrData[pid - 1, 0].Count == 0)
            {
                return FeatureMode == Features.Mode.Local
                    ? String.Format("{0} - from scratch!", CollectAndLabel(pid))
                    : String.Format("PID {0} doesn't exist!", pid);
            }

            string name = GetName(pid);
            var jssp = GetEmptySchedule(name);
            int currentNumFeatures = 0;
            for (var step = 0; step < NumDimension; step++)
            {
                var prefs = TrData[pid - 1, step];
                currentNumFeatures += prefs.Count;

                if (!ValidDispatches(ref prefs, jssp))
                    throw new Exception("Retracing gave an invalid dispatch!");

                #region update features of possible jobs

                int dispatchedJob;
                if (prefs.Count > 0)
                {
                    foreach (var p in prefs)
                    {
                        var lookahead = jssp.Clone();
                        p.Feature = lookahead.Dispatch1(p.Dispatch.Job, FeatureMode);
                    }
                    var followed = prefs.Find(p => p.Followed);
                    dispatchedJob = followed == null ? jssp.JobChosenBySDR((SDRData.SDR) Track) : followed.Dispatch.Job;
                }
                else
                {
                    dispatchedJob = jssp.ReadyJobs.Count > 1
                        ? jssp.JobChosenBySDR((SDRData.SDR) Track)
                        : jssp.ReadyJobs[0];
                }

                #endregion

                jssp.Dispatch1(dispatchedJob, Features.Mode.None);
            }
            return String.Format("{0}:{1} #{2} phi", FileInfo.Name, pid, currentNumFeatures);
        }

        private bool ValidDispatches(ref List<TrSet> prefs, Schedule jssp)
        {
            if (prefs.Count > jssp.ReadyJobs.Count)
            {
                prefs = prefs
                    .GroupBy(x => x.Dispatch.Name)
                    .Select(group => group.First()).ToList();
            }

            if (prefs.Count == 0 && jssp.Sequence.Count >= NumDimension - 1) return true; 

            if (prefs.FindIndex(p => p.Dispatch.Mac < 0) == -1 &&
                prefs.Count(p => p.Followed) == 1)
                return true;

            foreach (TrSet pref in prefs)
            {
                jssp.FindDispatch(pref.Dispatch.Job, out pref.Dispatch);
            }
            return false;
        }
    }
}