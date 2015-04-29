using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using Gurobi;
using JobShop;

/// <summary>
/// Summary description for JobShop
/// </summary>
public class ProblemInstance
{
    public readonly int NumJobs;
    public readonly int NumMachines;
    public readonly int[,] Sigma;
    public readonly int[,] Procs;
    public readonly int Dimension;

    public ProblemInstance(int numJobs, int numMachines, int[] processingTimes, int[] permutationMatrix)
    {
        NumJobs = numJobs;
        NumMachines = numMachines;
        Dimension = numJobs*numMachines;
        Procs = Array2Matrix(processingTimes);
        Sigma = Array2Matrix(permutationMatrix);
    }

    public int[,] Array2Matrix(int[] array)
    {
        int[,] matrix = new int[NumJobs, NumMachines];
        for (int job = 0; job < NumJobs; job++)
        {
            for (int mac = 0; mac < NumMachines; mac++)
                matrix[job, mac] = array[job*NumMachines + mac];
        }
        return matrix;
    }

    // sequence is a list of <job,mac,starttime>        
    public int[,] Optimize(string folder, string solver, string name, out int optMakespan, out bool success,
        out int simplexIterations, int tmlim = 6000, List<Schedule.Dispatch> constraints = null)
    {
        GurobiJspModel model = new GurobiJspModel(this, name, tmlim);
        var xTimeJob = constraints != null
            ? model.Lookahead(constraints, out optMakespan)
            : model.Optimise(out optMakespan);
        simplexIterations = model.SimplexIterations;
        success = model.Status == GRB.Status.OPTIMAL;
        model.Dispose();
        return xTimeJob;
    }
}

public class Schedule
{
    private readonly Func<int[], int, int, int> _slotAllocation;

    public List<Dispatch> Sequence;
    public List<int> ReadyJobs;
    private readonly Jobs[] _jobs;
    private readonly Macs[] _macs;

    public int Makespan;
    private readonly ProblemInstance _prob;
    private readonly Random _random;

    public Schedule(ProblemInstance prob, Random rnd = null, string slotAllocation = "FirstSlotChosen")
    {
        _prob = prob;

        Sequence = new List<Dispatch>(prob.Dimension);

        _jobs = new Jobs[_prob.NumJobs];
        _macs = new Macs[_prob.NumMachines];

        ReadyJobs = new List<int>(_prob.NumJobs);

        for (int job = 0; job < _prob.NumJobs; job++)
        {
            ReadyJobs.Add(job);
            int totalWork = 0;
            for (int a = 0; a < _prob.NumMachines; a++)
                totalWork += _prob.Procs[job, a];
            _jobs[job] = new Jobs(job, totalWork, _prob.NumMachines);
        }

        for (int mac = 0; mac < _prob.NumMachines; mac++)
        {
            int wrm = 0;
            for (int j = 0; j < _prob.NumJobs; j++)
                wrm += _prob.Procs[j, mac];
            _macs[mac] = new Macs(mac, wrm);
        }

        _slotAllocation = slotAllocation.Equals("First")
            ? (Func<int[], int, int, int>) FirstSlotChosen
            : SmallestSlotChosen;

        if (rnd == null)
        {
            int seed = (int) DateTime.Now.Ticks;
            _random = new Random(seed);
        }
        else
            _random = rnd;
    }

    public class Dispatch
    {
        public int Job, Mac, StartTime;

        public string Name
        {
            get { return String.Format("{0}.{1}.{2}", Job, Mac, StartTime); }
        }

        public Dispatch(int job, int mac, int startTime)
        {
            Job = job;
            Mac = mac;
            StartTime = startTime;
        }

        public Dispatch Clone()
        {
            return new Dispatch(Job, Mac, StartTime);
        }
    }

    public class Jobs
    {
        public readonly int Index;
        public int TotProcTime;
        public int WorkRemaining;
        public int MacCount;
        public int Free;
        public int[] XTime;

        public Jobs(int index, int totProcTime, int numMachines)
        {
            Index = index;
            TotProcTime = totProcTime;
            WorkRemaining = totProcTime;
            XTime = new int[numMachines];
        }

        public Jobs Clone()
        {
            Jobs clone = new Jobs(Index, WorkRemaining, XTime.Length)
            {
                TotProcTime = TotProcTime,
                WorkRemaining = WorkRemaining,
                MacCount = MacCount,
                Free = Free
            };
            Array.Copy(XTime, clone.XTime, XTime.Length);
            return clone;
        }

        public void Update(int start, int time, int mac, out int arrivalTime)
        {
            arrivalTime = Free;
            WorkRemaining -= time;
            MacCount++;
            Free = start + time;
            XTime[mac] = start;
        }
    }

    public class Macs
    {
        public readonly int Index;
        public int JobCount;
        public int WorkRemaining;
        public int Makespan;
        public int TotSlack;
        public int[] ETime = new int[0];
        public int[] STime = new int[0];
        public int[] Slacks = new int[0];

        public Macs(int index, int workRemaining)
        {
            Index = index;
            WorkRemaining = workRemaining;
        }

        public Macs Clone()
        {
            Macs clone = new Macs(Index, WorkRemaining)
            {
                JobCount = JobCount,
                Makespan = Makespan,
                TotSlack = TotSlack,
                ETime = new int[JobCount],
                STime = new int[JobCount],
                Slacks = new int[JobCount]
            };
            Array.Copy(ETime, clone.ETime, JobCount);
            Array.Copy(STime, clone.STime, JobCount);
            Array.Copy(Slacks, clone.Slacks, JobCount);
            return clone;
        }

        public void Update(int start, int time, int slot, out int slotReduced)
        {
            JobCount++;
            Array.Resize(ref ETime, JobCount);
            Array.Resize(ref STime, JobCount);
            Array.Resize(ref Slacks, JobCount);

            if (slot < JobCount - 1)
            {
                Array.Copy(ETime, slot, ETime, slot + 1, JobCount - slot - 1);
                Array.Copy(STime, slot, STime, slot + 1, JobCount - slot - 1);
                Array.Copy(Slacks, slot, Slacks, slot + 1, JobCount - slot - 1);
            }

            STime[slot] = start;
            ETime[slot] = start + time;

            Makespan = Math.Max(Makespan, start + time);
            WorkRemaining -= time;

            Slacks[0] = STime[0];
            for (int job = 1; job < JobCount; job++)
                Slacks[job] = STime[job] - ETime[job - 1];

            slotReduced = TotSlack;
            TotSlack = Slacks.Sum();
            slotReduced -= TotSlack;
        }
    }

    public Schedule Clone()
    {
        Schedule clone = new Schedule(_prob, _random);

        foreach (Dispatch disp in Sequence)
            clone.Sequence.Add(disp);

        clone.ReadyJobs = ReadyJobs.ToList();

        clone.Makespan = Makespan;

        for (int job = 0; job < _prob.NumJobs; job++)
            clone._jobs[job] = _jobs[job].Clone();

        for (int mac = 0; mac < _prob.NumMachines; mac++)
            clone._macs[mac] = _macs[mac].Clone();

        return clone;
    }

    public int FindDispatch(int job, out Dispatch dispatch)
    {
        int mac = _prob.Sigma[job, _jobs[job].MacCount];
        int time = _prob.Procs[job, mac];

 
        #region find available slot
        int slot;
        int startTime;
        if (_macs[mac].JobCount == 0) // never been assigned a job before, no need to check for slotsizes
        {
            startTime = _jobs[job].Free;
            slot = 0;
        }
        else // possibility of slots
        {
            var slotSizes = new int[_macs[mac].JobCount + 1];
            slotSizes[0] = _macs[mac].STime[0] - _jobs[job].Free;
            slotSizes[_macs[mac].JobCount] = int.MaxValue; // inf 
            for (int jobPrime = 1; jobPrime < _macs[mac].JobCount; jobPrime++)
                slotSizes[jobPrime] = Math.Max(0,
                    _macs[mac].STime[jobPrime] - Math.Max(_macs[mac].ETime[jobPrime - 1], _jobs[job].Free));
            slot = _slotAllocation(slotSizes, mac, time);
            startTime = slot == 0 ? _jobs[job].Free : Math.Max(_macs[mac].ETime[slot - 1], _jobs[job].Free);
        }

        #endregion

        dispatch = new Dispatch(job, mac, startTime);

        return slot;
    }

    private int SmallestSlotChosen(int[] slotSizes, int mac, int time)
    {
        int slot = -1;
        int minSlot = _macs[mac].Makespan;
        for (int jobPrime = 0; jobPrime <= _macs[mac].JobCount; jobPrime++)
            if (slotSizes[jobPrime] >= time & slotSizes[jobPrime] < minSlot)
            // fits, and smaller than last slot
            {
                slot = jobPrime;
            }
        return slot;
    }

    private int FirstSlotChosen(int[] slotSizes, int mac, int time)
    {
        int slot = -1;
        for (int jobPrime = 0; jobPrime <= _macs[mac].JobCount; jobPrime++)
            if (slotSizes[jobPrime] >= time) // fits
            {
                slot = jobPrime;
                break;
            }
        return slot;
    }

    public Features Dispatch1(int job, Features.Mode mode) // commits dispatch! 
    {
        Dispatch dispatch;
        int slot = FindDispatch(job, out dispatch);

        int time = _prob.Procs[job, dispatch.Mac];

        int arrivalTime, slotReduced;

        Features phi = new Features();

        switch (mode)
        {
            case Features.Mode.Equiv:
                phi.GetEquivPhi(job, this);
                break;
        }

        _macs[dispatch.Mac].Update(dispatch.StartTime, time, slot, out slotReduced);
        _jobs[job].Update(dispatch.StartTime, time, dispatch.Mac, out arrivalTime);

        Sequence.Add(dispatch);

        if (_jobs[job].MacCount == _prob.NumMachines)
            ReadyJobs.Remove(job);
        Makespan = _macs.Max(x => x.Makespan);

        switch (mode)
        {
            case Features.Mode.Global:
                phi.GetGlobalPhi(this);
                return phi;
            case Features.Mode.Local:
                phi.GetLocalPhi(_jobs[job], _macs[dispatch.Mac], _prob.Procs[job, dispatch.Mac],
                    _jobs.Sum(p => p.WorkRemaining), _macs.Sum(p => p.TotSlack), Makespan, Sequence.Count,
                    dispatch.StartTime, arrivalTime, slotReduced);
                return phi;
            //case FeatureType.None:
            default:
                return null;
        }
    }

    public void ApplySDR(SDR sdr, Features.Mode mode)
    {
        for (int step = Sequence.Count; step < _prob.Dimension; step++)
        {
            var job = JobChosenBySDR(sdr);
            Dispatch1(job, mode);
        }
    }

    public void ApplyBDR(SDR sdrFirst, SDR sdrSecond, int stepSplitProc)
    {
        int stepSplit = (int)(stepSplitProc / 100.0 * _prob.Dimension);

        for (int step = Sequence.Count; step < _prob.Dimension; step++)
        {
            var sdr = step < stepSplit ? sdrFirst : sdrSecond;
            var job = JobChosenBySDR(sdr);
            Dispatch1(job, Features.Mode.None);
        }
    }
   
    public void ApplyCDR(LinearModel linModel)
    {
        for (int step = Sequence.Count; step < _prob.Dimension; step++)
        {
            List<double> priority = new List<double>(ReadyJobs.Count);
            priority.AddRange(from j in ReadyJobs
                              let lookahead = Clone()
                              select lookahead.Dispatch1(j, linModel.FeatureMode)
                                  into feat
                                  select linModel.PriorityIndex(feat));
            var job = ReadyJobs[priority.FindIndex(p => Math.Abs(p - priority.Max()) < 0.001)];
            Dispatch1(job, Features.Mode.None);
        }
    }

    public int JobChosenBySDR(SDR sdr)
    {
        switch (sdr)
        {
            case SDR.LWR:
            case SDR.MWR:
                List<int> wrm = new List<int>(ReadyJobs.Count);
                wrm.AddRange(ReadyJobs.Select(job => _jobs[job].WorkRemaining));

                return sdr == SDR.LWR
                    ? ReadyJobs[wrm.FindIndex(w => w == wrm.Min())]
                    : ReadyJobs[wrm.FindIndex(w => w == wrm.Max())];

            case SDR.LPT:
            case SDR.SPT:
                List<int> times = new List<int>(ReadyJobs.Count);
                times.AddRange(from job in ReadyJobs
                               let mac = _prob.Sigma[job, _jobs[job].MacCount]
                               select _prob.Procs[job, mac]);
                return sdr == SDR.SPT
                    ? ReadyJobs[times.FindIndex(w => w == times.Min())]
                    : ReadyJobs[times.FindIndex(w => w == times.Max())];

            default: // unknown, choose at random 
                return ReadyJobs[_random.Next(0, ReadyJobs.Count())];
        }
    }

    public static double RhoMeasure(int trueMakespan, int resultingMakespan)
    {
        if (resultingMakespan < trueMakespan | trueMakespan == int.MinValue)
            return double.NaN;
        return 100.0 * (resultingMakespan - trueMakespan) / trueMakespan;
    }

    public bool Validate(out string error, bool fullSchedule, Dispatch newDispatch = null)
    {
        int reportedMakespan = -1;
        for (int mac = 0; mac < _prob.NumMachines; mac++)
            reportedMakespan = Math.Max(Makespan, _macs[mac].Makespan);
        if (reportedMakespan != Makespan)
        {
            error = "Makespan doesn't match end time of machines";
            return false;
        }

        if (fullSchedule)
        {
            for (int job = 0; job < _prob.NumJobs; job++)
                if (_jobs[job].MacCount != _prob.NumMachines)
                {
                    error = "Mac count for job " + job + " doesn't match";
                    return false;
                }
            for (int mac = 0; mac < _prob.NumMachines; mac++)
                if (_macs[mac].JobCount != _prob.NumJobs)
                {
                    error = "Jobcount for mac " + mac + " doesn't match";
                    return false;
                }
        }

        for (int job = 0; job < _prob.NumJobs; job++)
            for (int order = _jobs[job].MacCount; order < _prob.NumMachines; order++)
            {
                int mac = _prob.Sigma[job, order];
                if (_jobs[job].XTime[mac] <= 0) continue;
                error = "Dispatch committed that hasn't been reported";
                return false;
            }

        if (Sequence.Any(o => _jobs[o.Job].XTime[o.Mac] != o.StartTime & o.StartTime != -1))
        {
            error = "Dispatch was not reported correctly";
            return false;
        }

        // job finishes their previous machine before it starts its next, w.r.t. its permutation
        for (int job = 0; job < _prob.NumJobs; job++)
            for (int mac = 1; mac < _jobs[job].MacCount; mac++)
            {
                int macnow = _prob.Sigma[job, mac];
                int macpre = _prob.Sigma[job, mac - 1];
                if (_jobs[job].XTime[macnow] < _jobs[job].XTime[macpre] + _prob.Procs[job, macpre])
                {
                    error = "job starts too early";
                    return false;
                }
            }

        // only one job at a time per machine
        for (int mac = 0; mac < _prob.NumMachines; mac++)
            for (int job = 1; job < _macs[mac].JobCount; job++)
            {
                if (_macs[mac].STime[job] < _macs[mac].ETime[job - 1])
                {
                    error = "machine occupied";
                    return false;
                }
            }
        error = "";
        return true;
    }

    public void SetCompleteSchedule(int[,] times, int ms)
    {
        if (times == null)
        {
            return;
        }
        Makespan = ms;

        for (int j = 0; j < _prob.NumJobs; j++)
        {
            _jobs[j].MacCount = _prob.NumMachines;
            for (int a = 0; a < _prob.NumMachines; a++)
                times[j, a] = _jobs[j].XTime[a];
        }

        for (int m = 0; m < _prob.NumMachines; m++)
        {
            Array.Resize(ref _macs[m].STime, _prob.NumJobs);
            Array.Resize(ref _macs[m].ETime, _prob.NumJobs);
            for (int j = 0; j < _prob.NumJobs; j++)
            {
                Sequence.Add(new Dispatch(j, m, -1));
                _macs[m].STime[j] = _jobs[j].XTime[m];
                _macs[m].ETime[j] = _jobs[j].XTime[m] + _prob.Procs[j, m];
            }
            _macs[m].JobCount = _prob.NumJobs;
            Array.Sort(_macs[m].STime);
            Array.Sort(_macs[m].ETime);
        }
    }

    public string PrintSchedule()
    {
        string info = String.Format("Solution has {0} Cmax: {1}\n\nStart times for {2} jobs on {3} machines:\n",
            Sequence.Count() == _prob.Dimension ? "final" : "partial", Makespan, _prob.NumJobs, _prob.NumMachines);

        for (int job = 0; job < _prob.NumJobs; job++)
        {
            for (int mac = 0; mac < _prob.NumMachines; mac++)
                info += _jobs[job].XTime[mac] + " ";
            info += "\n";
        }
        return info + "\n";
    }

    public Image PlotSchedule(int width, int height, string filePath, bool printJobIndex = true)
    {
        RandomPastelColorGenerator colors = new RandomPastelColorGenerator();

        Font font = new Font("courier new", 8);

        const int X0 = 25; // margin left
        const int X1 = 10; // margin right
        int y0 = (int)(font.Size * 3); // top margin
        int y1 = (int)(font.Size * 2); // bottom margin

        double widthConvert = (width - X0 - X1) / (double)(Makespan);
        int macheight = (height - y0 - y1) / _prob.NumMachines;
        int space = (int)(macheight - font.Size * 2); // space between machines

        Brush blackBrush = new SolidBrush(Color.Black);

        SolidBrush[] colorBrushes = new SolidBrush[_prob.NumJobs];
        for (int job = 0; job < _prob.NumJobs; job++)
            colorBrushes[job] = new SolidBrush(colors.GetNextRandom());

        Bitmap imgSchedule = new Bitmap(width, height);
        #region plot final resulting image
        using (Graphics g = Graphics.FromImage(imgSchedule))
        {
            g.Clear(Color.White);
            for (int mac = 0; mac < _prob.NumMachines; mac++)
                g.DrawString(String.Format("{0}:", mac), font, blackBrush, new PointF(0, y0 + mac * macheight));

            g.DrawString(String.Format("Cmax: {0}", Makespan), font, blackBrush, new PointF(0, height - y1));

            for (int job = 0; job < _prob.NumJobs; job++)
            {
                for (int a = 0; a < _jobs[job].MacCount; a++)
                {
                    int mac = _prob.Sigma[job, a];
                    int start = _jobs[job].XTime[mac];
                    int end = start + _prob.Procs[job, mac];

                    start = (int)(start * widthConvert) + X0;
                    end = (int)(end * widthConvert) + X0;

                    g.FillRectangle(colorBrushes[job],
                        new Rectangle(start, y0 + mac * macheight, end - start, macheight - space));
                    if (printJobIndex)
                        g.DrawString(job.ToString(), font, blackBrush, new PointF(start, y0 + mac * macheight));
                }
            }
            g.Dispose();
        }
        #endregion
        return imgSchedule;
    }

    private class RandomPastelColorGenerator
    {
        private readonly Random _random;

        public RandomPastelColorGenerator()
        {
            // seed the generator with 2 because
            // this gives a good sequence of colors
            const int RANDOM_SEED = 19850712;
            _random = new Random(RANDOM_SEED);
        }

        public Color GetNextRandom()
        {
            // to create lighter colours:
            // take a random integer between 0 & 128 (rather than between 0 and 255)
            // and then add 127 to make the colour lighter
            var colorBytes = new byte[3];
            colorBytes[0] = (byte)(_random.Next(128) + 127);
            colorBytes[1] = (byte)(_random.Next(128) + 127);
            colorBytes[2] = (byte)(_random.Next(128) + 127);

            // make the color fully opaque
            return Color.FromArgb(255, colorBytes[0], colorBytes[1], colorBytes[2]);
        }
    }

}

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