﻿using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Globalization;
using System.IO;
using System.Linq;

// ReSharper disable once InconsistentNaming
[SuppressMessage("ReSharper", "InconsistentNaming")]
public class CMAES
{
    private const int NUM_FEATURES = (int)Features.Local.Count;
    private readonly int _dimension;
    private readonly int N; // number of objective variables (here: N = problem dimension * NumFeatures)

    private readonly ProblemInstance[] _trainingData;
    private readonly int[] _optMakespans;

    private readonly int _numInstances;
    private readonly Func<double[], double> _objFun;

    public bool OptimistationComplete { get; private set; }

    public int Generation { get; private set; }
    private int _alreadyAutoSavedGeneration = -1;

    public int CountEval { get; private set; }
    public int StopEval { get; private set; } // stop after stopeval number of function evaluations
    private double sigma; // coordinate wise standard deviation (step size)
    private readonly double _stopFitness; // stop if fitness < stopfitness (minimization)
    private readonly int lambda; // population size, offspring number
    private readonly int mu; // number of parents/points for recombination
    private readonly double mueff; // variance-effectiveness of sum w_i x_i
    private readonly double[] weights; // muXone array for weighted recombination
    private readonly double cc; // time constant for cumulation for C
    private readonly double cs; // t-const for cumulation for sigma control
    private readonly double c1; // learning rate for rank-one update of C
    private readonly double cmu; // and for rank-mu update
    private readonly double damps; // damping for sigma usually close to 1
    private double[] pc; // evolution paths for C 
    private double[] D; // diagonal D defines the scaling
    private double[] ps; // evolution paths for sigma
    private double[,] B; // B defines the coordinate system
    private double[,] C; // C covariance matrix 
    private double[,] invsqrtC;
    private readonly double chiN; // expectation of ||N(0,I)|| == norm(randn(N,1))
    private double _eigenEval; // track update of B and D

    private readonly string _fileNameFinalResults;
    private readonly string _fileNameResults;
    private readonly string _directory;
    private Offspring[] _population;

    private readonly List<SummaryCMA> _output = new List<SummaryCMA>();

    private double[] xmean, xold;

    public string Step { get; private set; }

    private class Offspring
    {
        public double[] Variable;
        public double Fitness;
    }

    public class SummaryCMA
    {
        public double[] DistributionMeanVector;
        public double Fitness;
        public int CountEval;
        public int Generation;
    }

    public CMAES(RawData trainingData, string strObjFun, bool dependentModel, string cmaDirectory)
    {
        _directory = cmaDirectory;
        _fileNameFinalResults = String.Format("full.{0}.{1}.{2}.weights.{3}.csv", trainingData.Distribution,
            trainingData.Dimension, strObjFun, dependentModel ? "timedependent" : "timeindependent");
        _fileNameResults = String.Format(@"results\output.{0}.{1}.{2}.weights.{3}.csv", trainingData.Distribution,
            trainingData.Dimension, strObjFun, dependentModel ? "timedependent" : "timeindependent");

        FileInfo file = new FileInfo(String.Format(@"{0}\{1}", _directory, _fileNameFinalResults));
        if (file.Exists)
        {
            Step = String.Format("Optimistation already completed, see results in {0}", file.Name);
            OptimistationComplete = true;
            return;
        }

        file = new FileInfo(String.Format(@"{0}\{1}", _directory, _fileNameResults));
        if (file.Directory != null && !file.Directory.Exists)
            Directory.CreateDirectory(file.Directory.FullName);

        if (file.Exists)
        {
            // need to read last run here - until then, start from scratch
            // _alreadyAutoSavedGeneration = Generation;
            file.Delete();
        }

        ProblemInstance prob = (ProblemInstance)trainingData.Rows[0]["Problem"];
        int maxInstances = prob.Dimension >= 100 ? 300 : 500;
        _numInstances = Math.Min(maxInstances, trainingData.NumInstances);
        _dimension = prob.Dimension;

        _trainingData = new ProblemInstance[_numInstances];
        for (int pid = 0; pid < _numInstances; pid++)
            _trainingData[pid] = (ProblemInstance)trainingData.Rows[pid]["Problem"];

        //Get the method information using the method info class
        if (strObjFun.ToLower().Contains("makespan"))
            _objFun = MinimumMakespan;
        else
        {
            _optMakespans = new int[_numInstances];
            for (int pid = 0; pid < _numInstances; pid++)
                _optMakespans[pid] = (int)trainingData.Rows[pid]["Makespan"];

            _objFun = MinimumRho;
        }

        N = NUM_FEATURES;
        if (dependentModel)
            N *= _dimension;

        #region --------------------  Initialization --------------------------------

        xmean = LinearAlgebra.RandomValues(N); // objective variables initial point

        sigma = 0.5;
        _stopFitness = 1e-10;
        StopEval = 50000; // 1e3*N^2;   

        #region Strategy parameter setting: Selection

        lambda = 4 + (int)Math.Floor(3 * Math.Log(N));
        // ReSharper disable once LocalVariableHidesMember
        double mu = lambda / 2.0;
        this.mu = (int)Math.Floor(mu);
        _population = new Offspring[lambda];

        weights = new double[this.mu];
        for (int i = 0; i < this.mu; i++)
            weights[i] = Math.Log(mu + 0.5) - Math.Log(i + 1);

        // normalize recombination weights array
        double tmpSum = weights.Sum();
        for (int i = 0; i < weights.Length; i++)
            weights[i] /= tmpSum;

        mueff = Math.Pow(weights.Sum(), 2) / weights.Sum(w => Math.Pow(w, 2));

        #endregion

        #region Strategy parameter setting: Adaptation

        cc = (4 + mueff / N) / (N + 4 + 2 * mueff / N);
        cs = (mueff + 2) / (N + mueff + 5);
        c1 = 2 / (Math.Pow(N + 1.3, 2) + mueff);
        cmu = Math.Min(1 - c1, 2 * (mueff - 2 + 1 / mueff) / (Math.Pow(N + 2, 2) + mueff));
        damps = 1 + 2 * Math.Max(0, Math.Sqrt((mueff - 1) / (N + 1)) - 1) + cs;

        #endregion

        #region Initialize dynamic (internal) strategy parameters and constants

        pc = LinearAlgebra.Zeros(N);
        ps = LinearAlgebra.Zeros(N);
        B = LinearAlgebra.Eye(N);
        D = LinearAlgebra.Ones(N);

        // C = B * diag(D.^2) * B'; 
        C = LinearAlgebra.Multiply(B, LinearAlgebra.Diag(LinearAlgebra.Power(D, 2)), B, true);

        invsqrtC = LinearAlgebra.InvertSqrtMatrix(B, D);

        chiN = Math.Sqrt(N) * (1 - 1 / (4.0 * N) + 1 / (21 * Math.Pow(N, 2)));

        #endregion

        #endregion
    }

    private LinearModel ConvertToLinearModel(double[] x)
    {
        double[][] xArray = new double[(int)Features.Local.Count][];

        if (N == NUM_FEATURES)
        {
            for (var iFeat = 0; iFeat < (int)Features.Local.Count; iFeat++)
                xArray[iFeat] = new[] { x[iFeat] };
        }
        else
        {
            for (var iFeat = 0; iFeat < (int)Features.Local.Count; iFeat++)
                xArray[iFeat] = new double[_dimension];

            for (int i = 0; i < N; i++)
            {
                int ifeat = i % NUM_FEATURES;
                int step = (i - ifeat) / NUM_FEATURES;
                xArray[ifeat][step] = x[i];
            }
        }

        return new LinearModel(xArray, "CMA-ES");
    }

    private int[] ApplyWeights(double[] x)
    {
        LinearModel linear = ConvertToLinearModel(x);

        int[] makespans = new int[_numInstances];
        for (int pid = 0; pid < _numInstances; pid++)
        {
            Schedule jssp = new Schedule(_trainingData[pid]);
            jssp.ApplyCDR(linear);
            makespans[pid] = jssp.Makespan;
        }
        return makespans;
    }

    private double MinimumMakespan(double[] x)
    {
        int[] makespans = ApplyWeights(x);
        return makespans.Average();
    }

    private double MinimumRho(double[] x)
    {
        if (_optMakespans == null) return double.NaN;

        int[] makespans = ApplyWeights(x);
        double[] rho = new double[_numInstances];
        for (int i = 0; i < _numInstances; i++)
            rho[i] = Schedule.RhoMeasure(_optMakespans[i], makespans[i]);

        return rho.Average();
    }

    // finds optimal weights for linear (local) model w.r.t. minimum either makespan or rho values
    public double[] Optimize(out double minimum, bool tryOnce = false)
    {
        #region -------------------- Generation Loop --------------------------------

        while (CountEval < StopEval)
        {
            Generation++;
            GenerationLoop();

            #region save temporal solution

            Step = String.Format(CultureInfo.InvariantCulture, "#{0}: z*={1:F2}", Generation, _population[0].Fitness);

            _output.Add(new SummaryCMA
            {
                Fitness = _population[0].Fitness,
                DistributionMeanVector = xmean,
                CountEval = CountEval,
                Generation = Generation
            });

            #endregion

            // Break, if fitness is good enough or condition exceeds 1e14, better termination methods are advisable 
            if (_population[0].Fitness <= _stopFitness || D.Max() > 1e7 * D.Min())
                break;

            if (!tryOnce) continue;
            minimum = _population[0].Fitness;
            return null;
        }

        #endregion

        OptimistationComplete = true;

        #region ------------- Final Message and Plotting Figures --------------------

        // Notice that xmean is expected to be even better.
        var xmin = _population[0].Variable;
        minimum = _population[0].Fitness;
        Step = String.Format("#{0} evals have {1} fitness", CountEval, minimum);

        //figure(1); hold off; semilogy(abs(out.dat)); hold on;  % abs for negative fitness
        //semilogy(out.dat(:,1) - min(out.dat(:,1)), 'k-');  % difference to best ever fitness, zero is not displayed
        //title('fitness, sigma, sqrt(eigenvalues)'); grid on; xlabel('iteration');  
        //figure(2); hold off; plot(out.datx); 
        //title('Distribution Mean'); grid on; xlabel('iteration')

        #endregion

        return xmin;
    }

    private void GenerationLoop()
    {
        #region Generate and evaluate lambda offspring

        for (int k = 0; k < lambda; k++)
        {
            _population[k] = new Offspring
            {
                // arx(:,k) = xmean + sigma * B * (D .* randn(N,1)); % m + sig * Normal(0,C) 
                Variable =
                    LinearAlgebra.Addition(xmean,
                        LinearAlgebra.Multiply(B,
                            LinearAlgebra.ArrayPiecewiseMultiplication(D, LinearAlgebra.Randn(N)), sigma))
            };

            LinearAlgebra.Normalize(ref _population[k].Variable);

            //Invoke the objective function call and the array of decision variables...
            _population[k].Fitness = _objFun(_population[k].Variable);

            CountEval++;
        }

        #endregion

        #region Sort by fitness and compute weighted mean into xmean

        _population = _population.ToList().OrderBy(p => p.Fitness).ToArray(); // minimization

        xold = xmean;

        double[,] arx = new double[N, mu];
        for (int i = 0; i < N; i++)
            for (int j = 0; j < mu; j++)
                arx[i, j] = _population[j].Variable[i];
        xmean = LinearAlgebra.Multiply(arx, weights);
        //xmean = arx(:,arindex(1:mu)) * weights;  // recombination, new mean value

        #endregion

        #region Cumulation: Update evolution paths

        double[] xdiff = LinearAlgebra.Minus(xmean, xold);
        // ps = (1-cs) * ps + sqrt(cs*(2-cs)*mueff) * invsqrtC * (xmean-xold) / sigma;            
        ps = LinearAlgebra.Addition(LinearAlgebra.Scalar(1 - cs, ps),
            LinearAlgebra.Multiply(invsqrtC, xdiff, Math.Sqrt(cs * (2 - cs) * mueff) / sigma));

        //hsig = sum(ps.^2)/(1-(1-cs)^(2*CountEval/lambda))/N < 2 + 4/(N+1);
        bool hsig = LinearAlgebra.Power(ps, 2).Sum() / (1 - Math.Pow(1 - cs, 2.0 * CountEval / lambda)) / N <
                    2 + 4.0 / (N + 1);

        // pc = (1-cc) * pc + hsig * sqrt(cc*(2-cc)*mueff) * (xmean-xold) / sigma; 
        pc = LinearAlgebra.Scalar(1 - cc, pc);
        if (hsig)
            pc = LinearAlgebra.Addition(pc,
                LinearAlgebra.Scalar(Math.Sqrt(cc * (2 - cc) * mueff) / sigma, xdiff));

        #endregion

        #region Adapt covariance matrix C

        //artmp = (1/sigma) * (arx(:,arindex(1:mu)) - repmat(xold,1,mu));  % mu difference vectors
        double[,] artmp = new double[N, mu];
        for (int i = 0; i < N; i++)
            for (int j = 0; j < mu; j++)
                artmp[i, j] = (_population[j].Variable[i] - xold[i]) / sigma;

        // C = (1-c1-cmu) * C ...                      % regard old matrix  
        //     + c1 * (pc * pc' ...                    % plus rank one update
        //             + (1-hsig) * cc*(2-cc) * C) ... % minor correction if hsig==0
        //     + cmu * artmp * diag(weights) * artmp'; % plus rank mu update 

        var regardOldMatrix = LinearAlgebra.Scalar(1 - c1 - cmu, C);

        double[,] rank1Update = LinearAlgebra.Multiply(pc, pc, c1);
        if (!hsig) // minor correction if hsig==0
            rank1Update = LinearAlgebra.Addition(rank1Update, LinearAlgebra.Scalar(c1 * cc * (2 - cc), C));

        var rankMuUpdate = LinearAlgebra.Multiply(artmp, LinearAlgebra.Diag(weights), artmp, true, cmu);

        C = LinearAlgebra.Addition(regardOldMatrix, LinearAlgebra.Addition(rank1Update, rankMuUpdate));

        #endregion

        #region Adapt step size sigma

        sigma = sigma * Math.Exp((cs / damps) * (LinearAlgebra.Norm2(ps) / chiN - 1));

        #endregion

        #region Update B and D from C

        // to achieve O(N^2)
        if (!(CountEval - _eigenEval > lambda / (c1 + cmu) / N / 10)) return;

        _eigenEval = CountEval;
        LinearAlgebra.EnforceSymmestry(ref C);

        //[B,D] = eig(C); // eigen decomposition, B==normalized eigenvectors
        alglib.smatrixevd(C, N, 1, true, out D, out B);

        D = LinearAlgebra.Power(D, 0.5); //D = sqrt(diag(D)); 
        // D contains standard deviations now

        invsqrtC = LinearAlgebra.InvertSqrtMatrix(B, D);

        #endregion
    }

    public void WriteFinalResultsCSV()
    {
        WriteResultsCSV();

        FileInfo fileinfo = new FileInfo(string.Format(@"{0}\{1}", _directory, _fileNameFinalResults));

        SummaryCMA best = _output.FindLast(x => Math.Abs(x.Fitness - _output.Min(y => y.Fitness)) < 1e-8);
        LinearModel bestWeights = ConvertToLinearModel(best.DistributionMeanVector);

        WriteCMAFinalResults(fileinfo, bestWeights);
    }

    public void WriteResultsCSV()
    {
        FileInfo fileinfo = new FileInfo(string.Format(@"{0}\{1}", _directory, _fileNameResults));

        WriteCMAResults(fileinfo, FileMode.Append,
            _output.Where(x => x.Generation > _alreadyAutoSavedGeneration).ToList(), N, NUM_FEATURES);

        _alreadyAutoSavedGeneration = Generation;
    }

    public static void WriteCMAResults(FileInfo file, FileMode fileMode, List<SummaryCMA> output,
            int numDecsVariables, int numFeatures)
    {
        if (file.Extension != ".csv")
            file = new FileInfo(file.FullName + ".csv");

        var fs = new FileStream(file.FullName, fileMode, FileAccess.Write);
        using (var st = new StreamWriter(fs))
        {
            if (fs.Length == 0) // header is missing 
            {
                string header = "Generation,CountEval,Fitness"; // for plotting output
                for (int i = 0; i < numDecsVariables; i++)
                {
                    int ifeat = i % numFeatures;
                    int step = (i - ifeat) / numFeatures + 1;
                    Features.Local feat = (Features.Local)ifeat;
                    header += String.Format(CultureInfo.InvariantCulture, ",phi.{0}.{1}", feat, step);
                }
                st.WriteLine(header);
            }

            foreach (string info in from summary in output
                                    let info = String.Format(CultureInfo.InvariantCulture, "{0},{1},{2:F4}", summary.Generation,
                                        summary.CountEval, summary.Fitness)
                                    select summary.DistributionMeanVector.Aggregate(info,
                                        (current, x) => current + String.Format(CultureInfo.InvariantCulture, ",{0:R9}", x)))
            {
                st.WriteLine(info);
            }

            st.Close();
        }
        fs.Close();
    }

    public static void WriteCMAFinalResults(FileInfo file, LinearModel linearModel)
    {
        if (file.Extension != ".csv")
            file = new FileInfo(file.FullName + ".csv");

        var fs = new FileStream(file.FullName, FileMode.Create, FileAccess.Write);
        using (var st = new StreamWriter(fs))
        {
            string header = "Type,NrFeat,Model,Feature,mean";
            int numSteps = linearModel.Weights.Local[0].Length;
            for (int step = 1; step <= numSteps; step++)
                header += String.Format(CultureInfo.InvariantCulture, ",Step.{0}", step);
            st.WriteLine(header);

            for (int iFeat = 0; iFeat < (int)Features.Local.Count; iFeat++)
            {
                Features.Local feat = (Features.Local)iFeat;
                switch (feat)
                {
                    case Features.Local.step:
                    case Features.Local.totProc:
                        continue;
                    default:
                        string info = String.Format("Weight,{0},1,phi.{1},NA", NUM_FEATURES - 2, feat);

                        for (int step = 0; step < numSteps; step++)
                            info += String.Format(CultureInfo.InvariantCulture, ",{0:R9}",
                                linearModel.Weights.Local[iFeat][step]);

                        st.WriteLine(info);
                        break;
                }
            }
            st.Close();
        }
        fs.Close();
    }

     
}