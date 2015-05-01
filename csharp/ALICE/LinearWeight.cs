using System;
using System.Globalization;
using System.Text.RegularExpressions;

namespace ALICE
{
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

        public LinearWeight EquivalentSDR(SDRData.SDR sdr)
        {
            LinearWeight w = new LinearWeight(1, sdr.ToString());
            switch (sdr)
            {
                case SDRData.SDR.MWR:
                    w.Local[(int)Features.Local.wrmJob][0] = +1;
                    return w;
                case SDRData.SDR.LWR:
                    w.Local[(int)Features.Local.wrmJob][0] = -1;
                    return w;
                case SDRData.SDR.SPT:
                    w.Local[(int)Features.Local.proc][0] = -1;
                    return w;
                case SDRData.SDR.LPT:
                    w.Local[(int)Features.Local.proc][0] = +1;
                    return w;
                default:
                    return w; // do nothing
            }
        }

        public void ReadLinearWeights(string path, out Features.Mode featureType)
        {
            string[] content = new[] { "asdf" };
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
}