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
            arrival, // arrival time of job
            wait, // wait for job

            #endregion

            #region mac-related

            macOps, // number of macs
            macFree, // current makespan for mac 
            makespan, // current makespan for schedule

            #endregion

            #region slack related

            slotReduced, // slack reduced from job assignment 
            slots, // total slack on mac
            slotsTotal, // total slacks for schedule
            //slotCreated, // true if slotReduced < 0

            #endregion

            #region work remaining

            wrmMac, // work remaining for mac
            wrmJob, // work remaining for job
            wrmTotal // work remaining for total

            #endregion

        }

        public enum Explanatory
        {
            mac,
            step, // current step 
            totProcTime, // total processing times
            macTotProcTime, // total processing times for mac
            jobTotProcTime, // total processing times for job            
        }

        public static int LocalCount
        {
            get { return Enum.GetNames(typeof (Local)).Length; }
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
            RNDmin

            #endregion

        }

        public static int GlobalCount
        {
            get { return Enum.GetNames(typeof (Global)).Length; }
        }

        public static int ExplanatoryCount
        {
            get { return Enum.GetNames(typeof(Explanatory)).Length; }            
        }


        // ReSharper disable once InconsistentNaming
        private int[] RND = new int[100];
        public int[] PhiExplanatory = new int[ExplanatoryCount];
        public int[] PhiLocal = new int[LocalCount];
        public double[] PhiGlobal = new double[GlobalCount];
        public bool[] Equiv = new bool[SDRData.SDRCount];

        public Features Difference(Features other)
        {
            Features diff = new Features();

            for (int i = 0; i < LocalCount; i++)
                diff.PhiLocal[i] = PhiLocal[i] - other.PhiLocal[i];

            for (int i = 0; i < GlobalCount; i++)
                diff.PhiGlobal[i] = PhiGlobal[i] - other.PhiGlobal[i];

            for (int i = 0; i < SDRData.SDRCount; i++)
                diff.Equiv[i] = Equiv[i] == other.Equiv[i];

            diff.RND = null;
            return diff;
        }

        public void GetLocalPhi(Schedule.Jobs job, Schedule.Macs mac, int proc, int wrmTotal, int slotsTotal,
            int makespan, int step, int startTime, int arrivalTime, int reduced, int totProcTime)
        {
            #region job related

            PhiLocal[(int)Local.proc] = proc;
            PhiLocal[(int)Local.startTime] = startTime;
            PhiLocal[(int)Local.endTime] = startTime + proc;
            PhiLocal[(int)Local.jobOps] = job.MacCount;
            PhiLocal[(int)Local.arrival] = arrivalTime;
            PhiLocal[(int)Local.wait] = startTime - arrivalTime;

            #endregion

            #region machine related

            PhiLocal[(int)Local.macFree] = mac.Makespan;
            PhiLocal[(int)Local.macOps] = mac.JobCount;

            #endregion

            #region explanatory for features, static per step

            PhiExplanatory[(int)Explanatory.mac] = mac.Index;
            PhiExplanatory[(int)Explanatory.totProcTime] = totProcTime;
            PhiExplanatory[(int)Explanatory.macTotProcTime] = mac.TotProcTime;
            PhiExplanatory[(int)Explanatory.jobTotProcTime] = job.TotProcTime;
            PhiExplanatory[(int)Explanatory.step] = step;
            
            #endregion 

            #region schedule related

            PhiLocal[(int)Local.makespan] = makespan;
            
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

            for (int i = 0; i < SDRData.SDRCount; i++)
            {
                SDRData.SDR sdr = (SDRData.SDR)i;
                lookahead = current.Clone();
                lookahead.ApplySDR(sdr, Mode.None);
                PhiGlobal[(int)(Global)(sdr)] = lookahead.Makespan;
            }

            for (int i = 0; i < RND.Length; i++)
            {
                lookahead = current.Clone();
                lookahead.ApplySDR(SDRData.SDR.RND, Mode.None);
                RND[i] = lookahead.Makespan;
            }

            PhiGlobal[(int)Global.RNDmin] = RND.Min();
            PhiGlobal[(int)Global.RNDmax] = RND.Max();
            PhiGlobal[(int)Global.RNDmean] = RND.Average();
            PhiGlobal[(int)Global.RNDstd] = StandardDev(RND, PhiGlobal[(int)Global.RNDmean]);
        }

        public void GetEquivPhi(int job, Schedule current)
        {
            for (int i = 0; i < SDRData.SDRCount; i++)
                Equiv[i] = job == current.JobChosenBySDR((SDRData.SDR)i);
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