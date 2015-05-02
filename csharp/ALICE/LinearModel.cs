using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

namespace ALICE
{
    public class LinearModel
    {
        public readonly string Name;
        private readonly int _numFeatures;
        private readonly int _modelID;
        public readonly Features.Mode FeatureMode;

        public double[][] LocalWeights = new double[(int) Features.Local.Count][];
        public readonly double[][] GlobalWeights = new double[(int) Features.Global.Count][];
        public readonly bool TimeIndependent;

        protected LinearModel(Features.Mode featureMode, int numFeatures, int modelID, bool timeIndependent)
        {
            FeatureMode = featureMode;
            _numFeatures = numFeatures;
            _modelID = modelID;
            Name = String.Format("{0}.{1}", _numFeatures, _modelID);
            TimeIndependent = timeIndependent;
        }

        protected LinearModel(Features.Mode featureMode, int timeDependentSteps, int numFeatures, int modelID)
            : this(featureMode, numFeatures, modelID, timeDependentSteps == 1)
        {
            switch (featureMode)
            {
                case Features.Mode.Global:
                    for (int i = 0; i < (int) Features.Global.Count; i++)
                        GlobalWeights[i] = new double[timeDependentSteps];
                    break;
                case Features.Mode.Local:
                    for (int i = 0; i < (int) Features.Local.Count; i++)
                        LocalWeights[i] = new double[timeDependentSteps];
                    break;
            }
        }

        public LinearModel(SDRData.SDR sdr) : this(Features.Mode.Local, 1, 1, (int) sdr)
        {
            Name = String.Format("{0}Equiv", sdr);
            switch (sdr)
            {
                case SDRData.SDR.MWR:
                    LocalWeights[(int) Features.Local.wrmJob][0] = +1;
                    return;
                case SDRData.SDR.LWR:
                    LocalWeights[(int) Features.Local.wrmJob][0] = -1;
                    return;
                case SDRData.SDR.SPT:
                    LocalWeights[(int) Features.Local.proc][0] = -1;
                    return;
                case SDRData.SDR.LPT:
                    LocalWeights[(int) Features.Local.proc][0] = +1;
                    return;
                default:
                    return; // do nothing
            }
        }

        public LinearModel(FileInfo file, int numFeatures, int modelID)
            : this(
                Regex.IsMatch(file.Name, Features.Mode.Global.ToString()) ? Features.Mode.Global : Features.Mode.Local,
                numFeatures, modelID, Regex.IsMatch(file.Name, "timeindependent"))
        {
            LinearModel[] loggedWeights = ReadLoggedLinearWeights(file);

            foreach (var w in loggedWeights.Where(w => w._numFeatures == numFeatures && w._modelID == _modelID))
            {
                LocalWeights = w.LocalWeights;
                return;
            }
            throw new Exception(String.Format("Cannot find weights {0} to user requirements from {1}!", Name, file.Name));
        }

        public double PriorityIndex(Features phi)
        {
            var step = TimeIndependent ? 0 : phi.PhiLocal[(int) Features.Local.step] - 1;
            double index = 0;
            switch (FeatureMode)
            {
                case Features.Mode.Local:
                    for (var i = 0; i < (int) Features.Local.Count; i++)
                        index += LocalWeights[i][step]*phi.PhiLocal[i];
                    break;
                case Features.Mode.Global:
                    for (var i = 0; i < (int) Features.Global.Count; i++)
                        index += GlobalWeights[i][step]*phi.PhiGlobal[i];
                    break;
            }
            return index;
        }

        public LinearModel(double[][] localWeights, int generation)
            : this(Features.Mode.Local, localWeights[0].Length, (int) Features.Local.Count, generation)
        {
            LocalWeights = localWeights;
        }
    
        private LinearModel[] ReadLoggedLinearWeights(FileInfo file)
        {
            if (!file.Exists)
                throw new Exception(String.Format("File {0} doesn't exist! Cannot read weights.", file.Name));

            List<string> header;
            List<string[]> content = CSV.Read(file, out header);
            
            // 	Weight,NrFeat,Model,Feature,NA,values
            const int WEIGHT = 0;
            const int NRFEAT = 1;
            const int MODEL = 2;
            const int FEATURE = 3;
            const int VALUE = 5;

            var strLocalFeature = new string[(int) Features.Local.Count];
            for (var i = 0; i < (int) Features.Local.Count; i++)
                strLocalFeature[i] = String.Format("phi.{0}", (Features.Local) i);

            var models = new List<LinearModel>();
            LinearModel linearWeights = null;

            int uniqueTimeSteps;
            if (!TimeIndependent)
            {
                var dim = Regex.Match(file.Name, "([0-9]+x[0-9]+)");
                var dimension = dim.Groups[0].Value;
                uniqueTimeSteps = RawData.DimString2Num(dimension);
            }
            else uniqueTimeSteps = 1;


            int nrFeat = -1, featFound = -1;
            foreach (var line in content.Where(line => line[WEIGHT].Equals("Weight")))
            {
                if (featFound == nrFeat | featFound == -1)
                {
                    if (linearWeights != null) models.Add(linearWeights);
                    nrFeat = Convert.ToInt32(line[NRFEAT]);
                    var idModel = Convert.ToInt32(line[MODEL]);
                    linearWeights = new LinearModel(FeatureMode, uniqueTimeSteps, nrFeat, idModel);
                    featFound = 0;
                }

                var local = line[FEATURE];
                if (TimeIndependent) // robust model 
                {
                    var value = Convert.ToDouble(line[VALUE], CultureInfo.InvariantCulture);
                    for (var i = 0; i < (int) Features.Local.Count; i++)
                    {
                        if (String.Compare(local, strLocalFeature[i], StringComparison.InvariantCultureIgnoreCase) != 0)
                            continue;
                        if (linearWeights != null) linearWeights.LocalWeights[i][0] = value;
                        featFound++;
                        break;
                    }
                }
                else
                {
                    for (var i = 0; i < (int) Features.Local.Count; i++)
                    {
                        if (String.Compare(local, strLocalFeature[i], StringComparison.InvariantCultureIgnoreCase) != 0)
                            continue;
                        for (var step = 0; step < uniqueTimeSteps - 1; step++)
                        {
                            var value = Convert.ToDouble(line[VALUE + step], CultureInfo.InvariantCulture);
                            if (linearWeights != null) linearWeights.LocalWeights[i][step] = value;
                        }
                        featFound++;
                        break;
                    }
                }
            }
            if (linearWeights != null) models.Add(linearWeights);
            //if (models.Count == 697)
            return models.ToArray();
        }
    }
}