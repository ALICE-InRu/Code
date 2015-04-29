using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

namespace JobShop
{
    public enum SDR
    {
        MWR,
        LWR,
        SPT,
        LPT,
        Count,
        RND
    }


    public class LinearWeight
    {
        public double[][] Local = new double[(int)Features.Local.Count][];
        public double[][] Global = new double[(int)Features.Global.Count][];
        public readonly string Name;
        public readonly int NrFeat;
        public readonly int ModelIndex;
        public readonly bool TimeIndependent;

        public LinearWeight(int timeDependentSteps, string fileName, int nrFeat = (int) Features.Local.Count,
            int modelIndex = -1)
        {
            Name = fileName;
            ModelIndex = modelIndex;
            NrFeat = nrFeat;

            if (modelIndex != -1 & nrFeat != (int)Features.Local.Count)
            {
                Name = String.Format("{0}//F{1}.Model{2}", fileName, nrFeat, modelIndex);
            }

            TimeIndependent = timeDependentSteps == 1;

            for (int i = 0; i < (int)Features.Local.Count; i++)
                Local[i] = new double[timeDependentSteps];

            for (int i = 0; i < (int)Features.Global.Count; i++)
                Global[i] = new double[timeDependentSteps];

        }

        public LinearWeight EquivalentSDR(SDR sdr)
        {
            LinearWeight w = new LinearWeight(1, sdr.ToString());
            switch (sdr)
            {
                case SDR.MWR:
                    w.Local[(int)Features.Local.wrmJob][0] = +1;
                    return w;
                case SDR.LWR:
                    w.Local[(int)Features.Local.wrmJob][0] = -1;
                    return w;
                case SDR.SPT:
                    w.Local[(int)Features.Local.proc][0] = -1;
                    return w;
                case SDR.LPT:
                    w.Local[(int)Features.Local.proc][0] = +1;
                    return w;
                default:
                    return w; // do nothing
            }
        }

        public void ReadLinearWeights(string path, out Features.Mode featureType)
        {
            string[] content = new[] {"asdf"};
            //AuxFun.ReadTextFile(path, out content, "\r\n");

            bool foundLocal = false;
            bool foundGlobal = false;
        
            foreach (string line in content)
            {
                string pattern;
                for (int i = 0; i < (int)Features.Local.Count; i++)
                {
                    pattern = String.Format("phi.{0}", (Features.Local)i);
                    Match phi = Regex.Match(line, String.Format(@"(?<={0} (-?[0-9.]*)", pattern));
                    if (phi.Success)
                    {
                        double value = Convert.ToDouble(phi.Groups[2].ToString(),
                            CultureInfo.InvariantCulture);
                        Local[i][0] = value;
                        foundLocal = true;
                    }
                }

                for (int i = 0; i < (int)Features.Global.Count; i++)
                {
                    pattern = String.Format("phi.{0}", (Features.Global)i);
                    Match phi = Regex.Match(line, String.Format(@"(?<={0} (-?[0-9.]*)", pattern));
                    if (phi.Success)
                    {
                        double value = Convert.ToDouble(phi.Groups[2].ToString(),
                            CultureInfo.InvariantCulture);
                        Global[i][0] = value;
                        foundGlobal = true;
                    }
                }
            }

            featureType = foundGlobal ? Features.Mode.Global : foundLocal ? Features.Mode.Local : Features.Mode.None;
        
        }
    }

    public class LinearModel
    {
        public readonly string Classifer; // liblin or libsvm 
        public readonly string Param;
        public readonly string Name;
        public readonly LinearWeight Weights;
        public int NumInstances = 0;
        public readonly string PathTrainingData;
        public readonly string PathModel;
        public readonly Features.Mode FeatureMode = Features.Mode.Local;
        public readonly double Beta; // odds of doing optimal trajectory 

        #region PREF model

        public LinearModel(string classifer, string param, string path2TrainingData, string dir, Features.Mode featureMode)
        {
            var file = new FileInfo(path2TrainingData);
            var m = Regex.Match(file.Name, "^trdat(.+?).csv");
            var trdat = m.Success ? m.Groups[1].ToString() : "";

            Name = "model" + trdat + "." + classifer;
            Classifer = classifer;
            Param = param;
            PathTrainingData = path2TrainingData;
            PathModel = dir + Name + ".txt";

            FeatureMode = featureMode;
        }

        public double PriorityIndex(Features phi)
        {
            var step = Weights.TimeIndependent ? 0 : phi.PhiLocal[(int)Features.Local.step] - 1;
            double index = 0;

            for (var i = 0; i < (int)Features.Local.Count; i++)
                index += Weights.Local[i][step] * phi.PhiLocal[i];

            for (var i = 0; i < (int)Features.Global.Count; i++)
                index += Weights.Global[i][step] * phi.PhiGlobal[i];

            return index;
        }

        public LinearModel(double[][] localWeights, string name)
        {
            Name = name;
            PathModel = "User input";
            Weights = new LinearWeight(localWeights[0].Length, name) { Local = localWeights };
            FeatureMode = Features.Mode.Local;
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

            Weights.ReadLinearWeights(PathModel, out FeatureMode);
        }

        #endregion


        public LinearModel(SDR sdr)
        {
            Name = String.Format("model{0}", sdr);
            FeatureMode = Features.Mode.None;
            Weights = EquivalentSDR(sdr);
        }

        private LinearWeight EquivalentSDR(SDR sdr)
        {
            var w = new LinearWeight(1, sdr.ToString());
            switch (sdr)
            {
                case SDR.MWR:
                    w.Local[(int)Features.Local.wrmJob][0] = +1;
                    return w;
                case SDR.LWR:
                    w.Local[(int)Features.Local.wrmJob][0] = -1;
                    return w;
                case SDR.SPT:
                    w.Local[(int)Features.Local.proc][0] = -1;
                    return w;
                case SDR.LPT:
                    w.Local[(int)Features.Local.proc][0] = +1;
                    return w;
                default:
                    return w; // do nothing
            }
        }

        public LinearModel(RawData distribution)
        {
            Name = "CMA" + distribution.Distribution;
            FeatureMode = Features.Mode.Local;
            Weights = SetCMAWeight(distribution.Distribution);
            Classifer = "CMA-ES";
        }

        public LinearModel(object[] imitationLearning)
        {
            var logFile = new FileInfo(String.Format("{0}", imitationLearning[0]));
            var nrFeat = (int)imitationLearning[1];
            var model = (int)imitationLearning[2];
            var iter = (int)imitationLearning[4];

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

            var loggedWeights = ReadLoggedLinearWeights(logFile);
            if (loggedWeights == null)
                return; // error

            foreach (var w in loggedWeights.Where(w => w.NrFeat == nrFeat && w.ModelIndex == model))
            {
                PathModel = logFile.Name;
                Weights = new LinearWeight(w.Local[0].Length, Name) { Local = w.Local };
                Name = w.Name;
                break;
            }
            FeatureMode = Features.Mode.Local;
            Classifer = "PREF";
        }

        private LinearWeight SetCMAWeight(string distribution, string objFun = "Cmax")
        {
            Features.Mode featureType;
            var path = String.Format("CMAES\\model.{0}.CMAES.min_{1}", distribution, objFun);
            var weights = new LinearWeight(1, path);
            if (File.Exists(path))
                weights.ReadLinearWeights(path, out featureType);

            return weights;
        }

        private static LinearWeight[] ReadLoggedLinearWeights(FileInfo file)
        {
            string[] allContent;
            ReadTextFile(file.FullName, out allContent, "\r\n");
            var models = new List<LinearWeight>();

            // 	Weight,NrFeat,Model,Feature,NA,values
            const string SCIENTIFIC_NUMBER = @"[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?";
            var regModel = new Regex(String.Format("Weight,([0-9]+),([0-9]+),phi.([a-zA-Z]*),NA,({0})", SCIENTIFIC_NUMBER));
            var regWeight = new Regex(SCIENTIFIC_NUMBER);

            var strLocalFeature = new string[(int)Features.Local.Count];
            for (var i = 0; i < (int)Features.Local.Count; i++)
                strLocalFeature[i] = String.Format("{0}", (Features.Local)i);

            LinearWeight weights = null;
            var timeindependent = Regex.Match(file.Name, "timeindependent").Success;

            var dim = Regex.Match(file.Name, "([0-9]+x[0-9]+)");
            var dimension = dim.Groups[0].Value;
            var timeindependentSteps = timeindependent ? 1 : RawData.DimString2Num(dimension);

            int nrFeat = -1, featFound = -1;
            foreach (var line in allContent)
            {
                var m = regModel.Match(line);
                if (!m.Success) continue;
                if (featFound == nrFeat | featFound == -1)
                {
                    if (weights != null) models.Add(weights);
                    nrFeat = Convert.ToInt32(m.Groups[1].Value);
                    var idModel = Convert.ToInt32(m.Groups[2].Value);
                    weights = new LinearWeight(timeindependentSteps, file.Name.Substring(0, file.Name.Length - 4),
                        nrFeat, idModel);
                    featFound = 0;
                }

                var local = m.Groups[3].Value;
                if (timeindependent) // global model 
                {
                    var value = Convert.ToDouble(m.Groups[4].Value, CultureInfo.InvariantCulture);
                    for (var i = 0; i < (int)Features.Local.Count; i++)
                    {
                        if (String.Compare(local, strLocalFeature[i], StringComparison.InvariantCultureIgnoreCase) != 0)
                            continue;
                        if (weights != null) weights.Local[i][0] = value;
                        featFound++;
                        break;
                    }
                }
                else
                {
                    for (var i = 0; i < (int)Features.Local.Count; i++)
                    {
                        if (String.Compare(local, strLocalFeature[i], StringComparison.InvariantCultureIgnoreCase) != 0)
                            continue;
                        var wMatches = regWeight.Matches(line);
                        for (var step = 0; step < wMatches.Count; step++) // first two captures include NrFeat + Model 
                        {
                            var value = Convert.ToDouble(wMatches[step].Groups[1].Value,
                                CultureInfo.InvariantCulture);
                            if (weights != null) weights.Local[i][step] = value;
                        }
                        featFound++;
                        break;
                    }
                }
            }
            if (weights != null) models.Add(weights);
            //if (models.Count == 697)
            return models.ToArray();
        }

        public static bool ReadTextFile(string path2File, out string[] allContent, string sep)
        {
            allContent = null;
            if (!File.Exists(path2File))
                return false;

            var fullContent = File.ReadAllText(path2File);
            allContent = sep != ""
                ? Regex.Split(fullContent, "[\r\n ]*" + sep + "[\r\n ]*")
                : Regex.Split(fullContent, "[\r\n]+");
            return true;
        }
    }
}