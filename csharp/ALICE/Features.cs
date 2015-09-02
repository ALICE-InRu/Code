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
            arrival, // arrival time of job
            wait, // wait for job

            #endregion

            #region mac-related

            macFree, // current makespan for mac 
            makespan, // current makespan for schedule

            #endregion

            #region slack related

            reducedSlack, // slack reduced from job assignment 
            macSlack, // total slack on mac
            allSlack, // total slacks for schedule

            #endregion

            #region mac / job counterparts

            jobOps, // number of jobs 
            macOps, // number of macs

            jobWrm, // work remaining for job
            macWrm, // work remaining for mac

            jobTotProcTime, // total processing times for job            
            macTotProcTime, // total processing times for mac

            #endregion

        }

        public enum Explanatory
        {
            step, // current step 
            totProcTime, // total processing times for schedule
            totWrm // work remaining for schedule
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
            get { return Enum.GetNames(typeof (Explanatory)).Length; }
        }


        // ReSharper disable once InconsistentNaming
        private int[] RND = new int[100];
        public int[] XiExplanatory = new int[ExplanatoryCount];
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

            PhiLocal[(int) Local.proc] = proc;
            PhiLocal[(int) Local.startTime] = startTime;
            PhiLocal[(int) Local.endTime] = startTime + proc;
            PhiLocal[(int) Local.jobOps] = job.MacCount;
            PhiLocal[(int) Local.arrival] = arrivalTime;
            PhiLocal[(int) Local.wait] = startTime - arrivalTime;

            #endregion

            #region machine related

            PhiLocal[(int) Local.macFree] = mac.Makespan;
            PhiLocal[(int) Local.macOps] = mac.JobCount;

            #endregion

            #region explanatory for features, static per step

            XiExplanatory[(int) Explanatory.totProcTime] = totProcTime;
            PhiLocal[(int) Local.macTotProcTime] = mac.TotProcTime;
            PhiLocal[(int) Local.jobTotProcTime] = job.TotProcTime;
            XiExplanatory[(int) Explanatory.step] = step;

            #endregion

            #region schedule related

            PhiLocal[(int) Local.makespan] = makespan;

            #endregion

            #region work remaining

            /* add current processing time in order for <w,phi> can be equivalent to MWR/LWR 
            * (otherwise it would find the job with most/least work remaining in the next step,
            * i.e. after the one-step lookahead */
            PhiLocal[(int) Local.macWrm] = mac.WorkRemaining + proc;
            PhiLocal[(int) Local.jobWrm] = job.WorkRemaining + proc;
            XiExplanatory[(int) Explanatory.totWrm] = wrmTotal + proc;

            #endregion

            #region flow related

            PhiLocal[(int) Local.reducedSlack] = reduced;
            PhiLocal[(int) Local.macSlack] = mac.TotSlack;
            PhiLocal[(int) Local.allSlack] = slotsTotal;

            #endregion

        }

        public void GetGlobalPhi(Schedule current, LinearModel model)
        {
            Schedule lookahead;

            for (int i = 0; i < SDRData.SDRCount; i++)
            {
                SDRData.SDR sdr = (SDRData.SDR) i;
                if (!(Math.Abs(model.GlobalWeights[(int) sdr][0]) > LinearModel.WEIGHT_TOLERANCE)) continue;
                lookahead = current.Clone();
                lookahead.ApplySDR(sdr);
                PhiGlobal[(int) (Global) (sdr)] = lookahead.Makespan;
            }
            
            if ((Math.Abs(model.GlobalWeights[(int) Global.RNDmin][0]) < LinearModel.WEIGHT_TOLERANCE) &&
                (Math.Abs(model.GlobalWeights[(int) Global.RNDmax][0]) < LinearModel.WEIGHT_TOLERANCE) &&
                (Math.Abs(model.GlobalWeights[(int) Global.RNDstd][0]) < LinearModel.WEIGHT_TOLERANCE) &&
                (Math.Abs(model.GlobalWeights[(int) Global.RNDmean][0]) < LinearModel.WEIGHT_TOLERANCE)) return;
         
            for (int i = 0; i < RND.Length; i++)
            {
                lookahead = current.Clone();
                lookahead.ApplySDR(SDRData.SDR.RND);
                RND[i] = lookahead.Makespan;
            }

            PhiGlobal[(int) Global.RNDmin] = RND.Min();
            PhiGlobal[(int) Global.RNDmax] = RND.Max();
            PhiGlobal[(int) Global.RNDmean] = RND.Average();
            PhiGlobal[(int) Global.RNDstd] = StandardDev(RND, PhiGlobal[(int) Global.RNDmean]);
        }

        public void GetEquivPhi(int job, Schedule current)
        {
            for (int i = 0; i < SDRData.SDRCount; i++)
                Equiv[i] = job == current.JobChosenBySDR((SDRData.SDR) i);
        }

        private static double StandardDev(IList<int> values, double mean)
        {
            double variance = 0;
            var n = values.Count;
            for (var i = 0; i < n; i++)
                variance += Math.Pow((values[i] - mean), 2);

            return Math.Sqrt(variance/n);
        }
    }
}