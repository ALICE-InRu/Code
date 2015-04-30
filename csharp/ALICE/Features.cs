using System;
using System.Collections.Generic;
using System.Linq;

namespace ALICE
{
    public class Features
    {
        public enum Mode
        {
            None = 0,
            Local,
            Global,
            Equiv
        };

        public enum Local
        {
            #region job related

            proc = 0, // processing time
            startTime, // start time 
            endTime, // end time 
            jobOps, // number of jobs 
            arrivalTime, // arrival time of job
            //wrm, // work remaining for job
            //mwrm, // most work remaining for schedule (could be other job)
            totProc, // total processing times
            wait, // wait for job

            #endregion

            #region mac-related

            mac,
            macOps, // number of macs
            macFree, // current makespan for mac 
            makespan, // current makespan for schedule

            #endregion

            #region slack related

            step, // current step 
            slotReduced, // slack reduced from job assignment 
            slots, // total slack on mac
            slotsTotal, // total slacks for schedule
            //slotCreated, // true if slotReduced < 0

            #endregion

            #region work remaining

            wrmMac, // work remaining for mac
            wrmJob, // work remaining for job
            wrmTotal, // work remaining for total

            #endregion

            Count
        }

        public enum Global
        {
            #region makespan related

            MWR,
            LWR,
            SPT,
            LPT,
            // ReSharper disable once InconsistentNaming
            RNDmean,
            // ReSharper disable once InconsistentNaming
            RNDstd,
            // ReSharper disable once InconsistentNaming
            RNDmax,
            // ReSharper disable once InconsistentNaming
            RNDmin,

            #endregion

            Count
        }

        // ReSharper disable once InconsistentNaming
        private int[] RND = new int[100];
        public int[] PhiLocal = new int[(int)Local.Count];
        public double[] PhiGlobal = new double[(int)Global.Count];
        public bool[] Equiv = new bool[(int)SDR.Count];

        public Features Difference(Features other)
        {
            Features diff = new Features();

            for (int i = 0; i < (int)Local.Count; i++)
                diff.PhiLocal[i] = PhiLocal[i] - other.PhiLocal[i];

            for (int i = 0; i < (int)Global.Count; i++)
                diff.PhiGlobal[i] = PhiGlobal[i] - other.PhiGlobal[i];

            for (int i = 0; i < (int)SDR.Count; i++)
                diff.Equiv[i] = Equiv[i] == other.Equiv[i];

            diff.RND = null;
            return diff;
        }

        public void GetLocalPhi(Schedule.Jobs job, Schedule.Macs mac, int proc, int wrmTotal, int slotsTotal,
            int makespan, int step, int startTime, int arrivalTime, int reduced)
        {
            #region job related

            PhiLocal[(int)Local.proc] = proc;
            PhiLocal[(int)Local.startTime] = startTime;
            PhiLocal[(int)Local.endTime] = startTime + proc;
            PhiLocal[(int)Local.jobOps] = job.MacCount;
            PhiLocal[(int)Local.arrivalTime] = arrivalTime;
            PhiLocal[(int)Local.wait] = startTime - arrivalTime;

            #endregion

            #region machine related

            PhiLocal[(int)Local.mac] = mac.Index;
            PhiLocal[(int)Local.macFree] = mac.Makespan;
            PhiLocal[(int)Local.macOps] = mac.JobCount;

            #endregion

            #region schedule related

            PhiLocal[(int)Local.totProc] = job.TotProcTime;
            PhiLocal[(int)Local.makespan] = makespan;
            PhiLocal[(int)Local.step] = step;

            #endregion

            #region work remaining

            /* add current processing time in order for <w,phi> can be equivalent to MWR/LWR 
            * (otherwise it would find the job with most/least work remaining in the next step,
            * i.e. after the one-step lookahead */
            PhiLocal[(int)Local.wrmMac] = mac.WorkRemaining + proc;
            PhiLocal[(int)Local.wrmJob] = job.WorkRemaining + proc;
            PhiLocal[(int)Local.wrmTotal] = wrmTotal + proc;

            #endregion

            #region flow related

            PhiLocal[(int)Local.slotReduced] = reduced;
            PhiLocal[(int)Local.slots] = mac.TotSlack;
            PhiLocal[(int)Local.slotsTotal] = slotsTotal;
            //local[(int)LocalFeature.slotCreated] = reduced > 0 ? 0 : 1;

            #endregion

        }

        public void GetGlobalPhi(Schedule current)
        {
            Schedule lookahead;

            for (int i = 0; i < (int)SDR.Count; i++)
            {
                SDR sdr = (SDR)i;
                lookahead = current.Clone();
                lookahead.ApplySDR(sdr, Mode.None);
                PhiGlobal[(int)(Global)(sdr)] = lookahead.Makespan;
            }

            for (int i = 0; i < RND.Length; i++)
            {
                lookahead = current.Clone();
                lookahead.ApplySDR(SDR.RND, Mode.None);
                RND[i] = lookahead.Makespan;
            }

            PhiGlobal[(int)Global.RNDmin] = RND.Min();
            PhiGlobal[(int)Global.RNDmax] = RND.Max();
            PhiGlobal[(int)Global.RNDmean] = RND.Average();
            PhiGlobal[(int)Global.RNDstd] = StandardDev(RND, PhiGlobal[(int)Global.RNDmean]);
        }

        public void GetEquivPhi(int job, Schedule current)
        {
            for (int i = 0; i < (int)SDR.Count; i++)
                Equiv[i] = job == current.JobChosenBySDR((SDR)i);
        }

        private static double StandardDev(IList<int> values, double mean)
        {
            double variance = 0;
            var n = values.Count;
            for (var i = 0; i < n; i++)
                variance += Math.Pow((values[i] - mean), 2);

            return Math.Sqrt(variance / n);
        }

    }
}