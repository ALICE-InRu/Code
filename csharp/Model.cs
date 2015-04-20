using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using auxiliaryFunctions;

namespace Scheduling
{
    public class LinearModel
    {
        public readonly string Classifer; // liblin or libsvm 
        public readonly string Param;
        public readonly string Name;
        public readonly LinearWeight Weights;
        public int NumInstances = 0;
        public readonly string PathTrainingData;
        public readonly string PathModel;
        public readonly FeatureType FeatureType = FeatureType.Local;
        public readonly double Beta; // odds of doing optimal trajectory 

        #region PREF model

        public LinearModel(string classifer, string param, string path2TrainingData, string dir, FeatureType featureType)
        {
            var file = new FileInfo(path2TrainingData);
            var m = Regex.Match(file.Name, "^trdat(.+?).csv");
            var trdat = m.Success ? m.Groups[1].ToString() : "";

            Name = "model" + trdat + "." + classifer;
            Classifer = classifer;
            Param = param;
            PathTrainingData = path2TrainingData;
            PathModel = dir + Name + ".txt";

            FeatureType = featureType;
        }

        public void TrainModel()
        {
            var r = new ProcessStartInfo
            {
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true,
                FileName = @"C:\Program Files\R\R-3.0.2\bin\Rscript",
                WorkingDirectory = AuxFun.GetCurrentDirectory() + @"trainingData\"
            };

            var mType = Regex.Match(Param, @"(?<=-t )(\d*)");
            var mCost = Regex.Match(Param, @"(?<=-C )(\d*)");
            switch (Classifer)
            {
                case "LIBLINEAR":
                    r.Arguments = String.Format("cmdLiblinear.R {0} {1} {2} > {3}", PathTrainingData, mType.Value,
                        mCost.Value, PathModel);
                    break;
                case "LIBSVM":
                    var mCoef0 = Regex.Match(Param, @"(?<=-coef0 )(\d*)");
                    var mGamma = Regex.Match(Param, @"(?<=-g )(\d*)");
                    var mDegree = Regex.Match(Param, @"(?<=-d )(\d*)");
                    r.Arguments = String.Format("cmdLibsvm.R {0} {1} {2} {3} {4} {5} > {6}", PathTrainingData,
                        mCoef0.Value, mGamma.Value, mDegree.Value, mType.Value, mCost.Value, PathModel);
                    break;
            }

            // Setup the process
            var mProcess = new Process {StartInfo = r, EnableRaisingEvents = true};

            // Register event
            //mProcess.OutputDataReceived += OnOutputDataReceived;

            // Start process
            mProcess.Start();
            mProcess.Close();
        }

        public double PriorityIndex(Features phi)
        {
            var step = Weights.TimeIndependent ? 0 : phi.Local[(int) LocalFeature.step] - 1;
            double index = 0;

            for (var i = 0; i < (int) LocalFeature.Count; i++)
                index += Weights.Local[i][step]*phi.Local[i];

            for (var i = 0; i < (int) GlobalFeature.Count; i++)
                index += Weights.Global[i][step]*phi.Global[i];

            return index;
        }

        public LinearModel(double[][] localWeights, string name)
        {
            Name = name;
            PathModel = "User input";
            Weights = new LinearWeight(localWeights[0].Length, name) {Local = localWeights};
            FeatureType = FeatureType.Local;
        }

        public LinearModel(FileInfo file)
        {
            Name = file.Name.Substring(0, file.Name.Length - file.Extension.Length);
            PathModel = file.FullName;

            if (Regex.IsMatch(Name, "LIBLINEAR", RegexOptions.IgnoreCase))
                Classifer = "LIBLINEAR";
            else if (Regex.IsMatch(Name, "CMA[-]*ES", RegexOptions.IgnoreCase))
                Classifer = "CMA-ES";
            else // not supported
                return;

            Weights.ReadLinearWeights(PathModel, out FeatureType);
        }

        #endregion


        public LinearModel(SDR sdr)
        {
            Name = String.Format("model{0}", sdr);
            FeatureType = FeatureType.None;
            Weights = EquivalentSDR(sdr);
        }

        private LinearWeight EquivalentSDR(SDR sdr)
        {
            var w = new LinearWeight(1, sdr.ToString());
            switch (sdr)
            {
                case SDR.MWR:
                    w.Local[(int) LocalFeature.wrmJob][0] = +1;
                    return w;
                case SDR.LWR:
                    w.Local[(int) LocalFeature.wrmJob][0] = -1;
                    return w;
                case SDR.SPT:
                    w.Local[(int) LocalFeature.proc][0] = -1;
                    return w;
                case SDR.LPT:
                    w.Local[(int) LocalFeature.proc][0] = +1;
                    return w;
                default:
                    return w; // do nothing
            }
        }

        public LinearModel(Data distribution)
        {
            Name = "CMA" + distribution.Name;
            FeatureType = FeatureType.Local;
            Weights = SetCMAWeight(distribution.Name);
            Classifer = "CMA-ES";
        }

        public LinearModel(object[] imitationLearning)
        {
            var logFile = new FileInfo(String.Format("{0}", imitationLearning[0]));
            var nrFeat = (int) imitationLearning[1];
            var model = (int) imitationLearning[2];
            var iter = (int) imitationLearning[4];
            
            switch (imitationLearning[5].ToString())
            {
                case "SUP":
                    Beta = Math.Pow(0.5, iter);
                    break;
                case "FIXSUP":
                    Beta = 0.5;
                    break;
                case "UNSUP":
                    Beta = 0;
                    break;
            }
            
            var loggedWeights = AuxFun.ReadLoggedLinearWeights(logFile);
            if (loggedWeights == null)
                return; // error

            foreach (var w in loggedWeights.Where(w => w.NrFeat == nrFeat && w.ModelIndex == model))
            {
                PathModel = logFile.Name;
                Weights = new LinearWeight(w.Local[0].Length, Name) {Local = w.Local};
                Name = w.Name;
                break;
            }
            FeatureType = FeatureType.Local;
            Classifer = "PREF";
        }

        private LinearWeight SetCMAWeight(string distribution, string objFun = "Cmax")
        {
            FeatureType featureType;
            var path = String.Format("CMAES\\model.{0}.CMAES.min_{1}", distribution, objFun);
            var weights = new LinearWeight(1, path);
            if (File.Exists(path))
                weights.ReadLinearWeights(path, out featureType);

            return weights;
        }
    }
}