using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.IO;
using System.Data;
using System.Diagnostics;
using System.Windows.Forms;
using System.Drawing; 
using System.Globalization; 
using System.Text.RegularExpressions;
using auxiliaryFunctions;

namespace Scheduling
{
    public partial class App : Form
    {
        private const int HALFHOUR = 30 * 60 * 1000; // ms

        private const string SEPERATION_LINE = "\n++++++++++++++++++++++++\n";

        private readonly string _mainDirectory;
        private readonly string _dataDirectory;
        private readonly string _sdrDirectory;
        private readonly string _bdrDirectory;
        private readonly string _prefDirectory;
        private readonly string _optDirectory;
        private readonly string _cmaDirectory;
        private readonly string _trainingDirectoy;
        private string _workingDirectory;

        public App()
        {
            InitializeComponent();
            InitializeBackgroundWorker();
            _mainDirectory = AuxFun.GetCurrentDirectory();

            Icon ico = new Icon(String.Format(@"{0}\Resources\chesirecat.ico", _mainDirectory));
            Icon = ico;

            var main = new DirectoryInfo(_mainDirectory);
            Debug.Assert(main.Parent != null, "main.Parent != null");
            _dataDirectory = main.Parent.FullName + @"\rawData\";
            _sdrDirectory = main.Parent.FullName + @"\SDR\";
            _bdrDirectory = main.Parent.FullName + @"\BDR\";
            _optDirectory = main.Parent.FullName + @"\OPT\";
            _trainingDirectoy = main.Parent.FullName + @"\trainingData\";
            _prefDirectory= main.Parent.FullName + @"\PREF\";
            _cmaDirectory = main.Parent.FullName + @"\CMAES\";

            foreach (var dir in new[]
            {
                _dataDirectory, _sdrDirectory, _bdrDirectory, _optDirectory, _trainingDirectoy, _prefDirectory,
                _cmaDirectory
            }.Select(dir => new DirectoryInfo(dir)).Where(sec => !sec.Exists))
            {
                dir.Create();
            }

            _workingDirectory = _mainDirectory + @"wip\";
        }

        private void App_Load(object sender, EventArgs e)
        {
            richTextBox.Text = @"Welcome!";
            radioButtonGLPK.Select();
            radioSimpleProblemsAll.Select();
            radioButtonGLPKtraining.Select();
            radioLocal.Select();

            comboBoxLiblinearLogfile.Visible = false;
            numericLiblinearModel.Visible = false;
            labelLiblinearModel.Visible = false;
            numericLiblinearNrFeat.Visible = false;
            labelLiblinearNrFeat.Visible = false;
            radioImitationLearningSupervised.Visible = false;
            radioImitationLearningUnsupervised.Visible = false;
            radioImitationLearningUnsupervised.Checked = true;

            startAsyncButtonGenTrData.Text = ButtonTextValidate;
            startAsyncButtonRankTrData.Text = ButtonTextValidate;
            startAsyncButtonOptimize.Text = ButtonTextValidate;
            startAsyncButtonFeatTrData.Text = ButtonTextValidate;
            startAsyncButtonCMA.Text = ButtonTextValidate;

            cancelAsyncButtonGenTrData.Visible = false;
            cancelAsyncButtonFeatTrData.Visible = false;
            cancelAsyncButtonRankTrData.Visible = false;
            cancelAsyncButtonOptimize.Visible = false;
            cancelAsyncButtonCMA.Visible = false;

            radioButtonCMAIndependent.Select();
            radioButtonCMAwrtRho.Select();
            
            pictureBox.Visible = false;
            comboBoxScheme.SelectedIndex = 3; // wip
            comboBoxScheme_SelectedIndexChanged(sender, e);

        }

        #region general

        private void UnValidate(object sender, EventArgs e)
        {
            switch (tabControl.SelectedTab.Name)
            {
                case "tabSimple":
                    if (startAsyncButtonOptimize.Text == ButtonTextStart)
                        startAsyncButtonOptimize.Text = ButtonTextValidate;
                    break;
                case "tabTraining":
                    if (startAsyncButtonGenTrData.Text == ButtonTextStart)
                        startAsyncButtonGenTrData.Text = ButtonTextValidate;
                    if (startAsyncButtonRankTrData.Text == ButtonTextStart)
                        startAsyncButtonRankTrData.Text = ButtonTextValidate;
                    break;
                case "tabCMA":
                    if (startAsyncButtonCMA.Text == ButtonTextStart)
                        startAsyncButtonCMA.Text = ButtonTextValidate;
                    if (startAsyncButtonCMA.Text == ButtonTextStart)
                        startAsyncButtonCMA.Text = ButtonTextValidate;
                    break;
            }
            if (comboBoxScheme.SelectedIndex != -1)
            {
                comboBoxScheme.SelectedIndex = -1; // no longer the selected schema
                textBoxDir.Text = "";
            }
        }

        private void CleanApp()
        {
            List<CheckedListBox> ckbs = new List<CheckedListBox>
            {
                ckbProblemModel,
                ckbRanks,
                ckbSimpleDataSet,
                ckbSimpleDim,
                ckbSimpleProblem,
                ckbSimpleSDR
            };

            foreach (CheckedListBox ckb in ckbs)
                foreach (int id in ckb.CheckedIndices)
                    ckb.SetItemChecked(id, false);

        }

        //private void OnOutputDataReceived(object sender, DataReceivedEventArgs e)
        //{
        //    //Never gets called...
        //}
        private void comboBoxScheme_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (comboBoxScheme.SelectedIndex == -1) return;
            CleanApp();
            string scheme = comboBoxScheme.Items[comboBoxScheme.SelectedIndex].ToString();
            switch (scheme)
            {
                case "LION5":

                    #region LION5 step by step model

                    if (tabControl.SelectedTab.Name == "tabSimple")
                        tabControl.SelectTab("tabTraining");
                    ckbProblemModel.SetItemChecked(0, true);
                    ckbProblemModel.SetItemChecked(1, true);
                    ckbTracks.SetItemChecked(0, true);
                    ckbRanks.SetItemChecked(0, true);
                    radioLocal.Select();
                    textBoxDir.Text = scheme;
                    break;

                    #endregion

                case "LION7/MISTA12":

                    #region LION7/MISTA different tracks

                    if (tabControl.SelectedTab.Name == "tabSimple")
                        tabControl.SelectTab("tabTraining");
                    ckbProblemModel.SetItemChecked(0, true);
                    ckbProblemModel.SetItemChecked(1, true);
                    ckbTracks.SetItemChecked(0, true);
                    ckbTracks.SetItemChecked(1, true);
                    ckbTracks.SetItemChecked(2, true);
                    ckbTracks.SetItemChecked(3, true);
                    ckbTracks.SetItemChecked(4, true);
                    ckbTracks.SetItemChecked(7, true);
                    ckbRanks.SetItemChecked(0, true);
                    ckbRanks.SetItemChecked(1, true);
                    ckbRanks.SetItemChecked(2, true);
                    radioLocal.Select();
                    textBoxDir.Text = scheme.Substring(0, 5);
                    break;

                    #endregion


                case "wip":
                    tabControl.SelectTab("tabTraining");
                    ckbProblemModel.SetItemChecked(1, true); // j.rndn
                    ckbProblemModel.SelectedIndex = 0;
                    ckbRanks.SetItemChecked(2, true); // partial subsequent ranking
                    ckbRanks.SelectedIndex = 2;
                    ckbTrainingDim.SetItemChecked(1, true); // 10x10
                    ckbTrainingDim.SelectedIndex = 1;
                    radioLocal.Select();
                    radioButtonGUROBItraining.Select();
                    ckbTracks.SetItemChecked(7, true); // imitation learning
                    radioImitationLearningSupervised.Select();
                    UpdateImitationLearning();
                    //string pat = String.Format("{1}\\exhaust.{0}.{1}.{2}.OPT.equal.weights.timeindependent.csv",
                    //    ckbProblemModel.SelectedItem, "10x10", ckbRanks.SelectedItem.ToString().ToLower()[0]);
                    //comboBoxLiblinearLogfile.SelectedIndex = comboBoxLiblinearLogfile.FindString(pat);
                    break;

                case "JOH":

                    #region JOH

                    if (tabControl.SelectedTab.Name == "tabSimple")
                        tabControl.SelectTab("tabTraining");
                    ckbProblemModel.SetItemChecked(0, true);
                    ckbProblemModel.SetItemChecked(1, true);
                    ckbProblemModel.SetItemChecked(2, true);
                    ckbProblemModel.SetItemChecked(3, true);
                    ckbProblemModel.SetItemChecked(4, true);
                    ckbTracks.SetItemChecked(0, true);
                    ckbTracks.SetItemChecked(1, true);
                    ckbTracks.SetItemChecked(2, true);
                    ckbTracks.SetItemChecked(3, true);
                    ckbTracks.SetItemChecked(4, true);
                    ckbTracks.SetItemChecked(6, true);
                    ckbTracks.SetItemChecked(7, true);
                    ckbRanks.SetItemChecked(0, true);
                    radioGlobal.Select();
                    textBoxDir.Text = scheme;
                    break;

                    #endregion


                case "LIBLINEAR":

                    tabControl.SelectTab("tabLinear");
                    tabControl_SelectedIndexChanged(sender, e);
                    comboBoxLiblinearLogs.Select();

                    ckbDataLIN.SetSelected(0, true); // jrnd
                    ckbDataLIN.SetItemChecked(0, true); // jrnd
                    ckbSetLIN.SetItemChecked(0, true); // train
                    ckbDimLIN.SetItemChecked(2, true); // 10x10

                    //textBoxDir.Text = scheme;
                    textBoxDir.Text = @"exhaust";
                    string dummy;
                    SetWorkingDirectory(out _workingDirectory, out dummy);

                    break;
            }
        }

        private void tabControl_SelectedIndexChanged(object sender, EventArgs e)
        {
            richTextBoxConsole.Text = "";
            richTextBox.Text = "";
            pictureBox.Image = null;

            if (tabControl.SelectedTab == tabControl.TabPages["tabSimple"])
            {
                pictureBox.Visible = true;
                richTextBoxConsole.Visible = false;
            }
            else
            {
                pictureBox.Visible = false;
                richTextBoxConsole.Visible = true;
            }
        }

        private string ReadProblem(string problem, string dim, string set, out Data problems, out bool success,
            int specialEntry = -1)
        {
            problems = null;
            success = false;
            if (problem == null)
            {
                return "Error, problem instance distribution missing.";
            }

            if (!Regex.IsMatch(problem, "ORLIB"))
            {
                if (dim == string.Empty)
                    return "Error, must choose a dimension for the problem.";
                if (set == string.Empty)
                    return "Error, must choose either train or test instance.";
            }
            else
            {
                set = string.Empty;
                dim = string.Empty;
            }

            Match dimOK = Regex.Match(dim, "[0-9]+x[0-9]+");
            if (!dimOK.Success)
            {
                Regex rgx = new Regex("[^0-9,]");
                dim = rgx.Replace(dim, "");
                dim = dim.Replace(',', 'x');
            }

            string fname;

            Match variation = Regex.Match(problem, "([A-Za-z]+)[,]+");
            string subfolder;
            AuxFun.ManipulateProcs manipulateProblem;
            if (variation.Success)
            {
                subfolder = String.Format("{0}_{1}", variation.Groups[1], dim);

                problem = problem.Replace(",", "_");
                problem = problem.Replace(" ", string.Empty);

                Match m = Regex.Match(problem, "j1doubled");
                manipulateProblem = m.Success ? AuxFun.ManipulateProcs.Job1 : AuxFun.ManipulateProcs.Machine1;

            }
            else
            {
                subfolder = problem + "_" + dim;
                manipulateProblem = AuxFun.ManipulateProcs.None;
            }
            subfolder = subfolder.Substring(1); // not include the shopProblem

            switch (problem)
            {
                case "ORLIB fsp":
                    fname = "flowshop1.txt";
                    break;
                case "ORLIB jsp":
                    fname = "jobshop1.txt";
                    break;
                default:

                    fname = problem[1] == '.'
                        ? String.Format("{0}.{1}.{2}.txt", problem, dim, set.ToLower())
                        : String.Format("{0}.{1}.{2}.{3}.txt", problem[0], problem.Substring(1), dim, set.ToLower());

                    FileInfo info = new FileInfo(_dataDirectory + fname);
                    if (!info.Exists)
                        AuxFun.WriteGeneratedData(fname, _dataDirectory, subfolder, manipulateProblem);
                    else if (info.Length == 0)
                        AuxFun.WriteGeneratedData(fname, _dataDirectory, subfolder, manipulateProblem);
                    break;
            }
            FileInfo finfo = new FileInfo(_dataDirectory + fname);
            if (!finfo.Exists)
            {
                string errorMsg = String.Format("Please save {0} in directory {1}\n", fname, _dataDirectory);
                if (Regex.IsMatch(problem, "ORLIB"))
                    errorMsg += "ORLIB is located at http://people.brunel.ac.uk/~mastjjb/jeb/orlib/files/";
                return errorMsg;
            }

            AuxFun.ReadRawData(fname, _dataDirectory, out problems,
                (radioSimpleProblemsSingle.Checked ? specialEntry : -1));

            if (problems.NumInstances == 0)
            {
                return radioSimpleProblemsSingle.Checked
                    ? String.Format("Warning, Index number is not available, please choose from 1-{0}\n",
                        numericUpDownInstanceID.Value)
                    : "File " + fname + " is not in the right format.";
            }
            success = true;
            return "";
        }

        private void richTextBox_TextChanged(object sender, EventArgs e)
        {
            richTextBox.SelectionStart = richTextBox.Text.Length;
            richTextBox.ScrollToCaret();
            richTextBoxConsole.SelectionStart = richTextBoxConsole.Text.Length;
            richTextBoxConsole.ScrollToCaret();
        }


        private void UpdateImitationLearning()
        {
            var pref = ckbTracks.Items[ckbTracks.Items.Count - 1];
            if (ckbTracks.CheckedItems.Contains(pref))
            {
                comboBoxLiblinearLogfile.Visible = true;
                numericLiblinearModel.Visible = true;
                labelLiblinearModel.Visible = true;
                numericLiblinearNrFeat.Visible = true;
                labelLiblinearNrFeat.Visible = true;
                radioImitationLearningSupervised.Visible = true;
                radioImitationLearningUnsupervised.Visible = true;

                if (ckbProblemModel.CheckedItems.Count != 1)
                {
                    richTextBox.Text = String.Format("Can only have one problem distribution checked\n");
                    return;
                }
                if (ckbTrainingDim.CheckedItems.Count != 1)
                {
                    richTextBox.Text = String.Format("Can only have one dimension checked\n");
                    return;
                }
                if (ckbRanks.CheckedItems.Count != 1)
                {
                    richTextBox.Text = String.Format("Can only have rank dimension checked\n");
                    return;
                }
                richTextBox.Text = "";

                string distribution = ckbProblemModel.CheckedItems[0].ToString();
                string dimension = SimpleDimName(ckbTrainingDim.CheckedItems[0].ToString());
                string rank = ckbRanks.CheckedItems[0].ToString().ToLower();

                comboBoxLiblinearLogfile.Items.Clear();
                string[] allfiles = LiblinearLogs_Update(distribution, dimension);
                bool supervised = radioImitationLearningSupervised.Checked;
                bool unsupervised = radioImitationLearningUnsupervised.Checked;
                string strSupervised = supervised ? "SUP" : unsupervised ? "UNSUP" : "FIXSUP";
                string pat = String.Format("{0}.{1}.{2}.(OPT|IL[0-9]+{3}).*.timeindependent", distribution, dimension,
                    rank[0], strSupervised);
                foreach (string fname in allfiles.Where(fname => Regex.IsMatch(fname, pat)))
                {
                    comboBoxLiblinearLogfile.Items.Add(fname);
                }
            }
            else
            {
                radioImitationLearningSupervised.Visible = false;
                radioImitationLearningUnsupervised.Visible = false;
                comboBoxLiblinearLogfile.Visible = false;
                numericLiblinearModel.Visible = false;
                labelLiblinearModel.Visible = false;
                numericLiblinearNrFeat.Visible = false;
                labelLiblinearNrFeat.Visible = false;
            }
        }

        private void ckb_ckbTracks(object sender, EventArgs e)
        {
            ckb_SelectedIndexChanged(sender, e);
            UpdateImitationLearning();
        }

        private void ckb_SelectedIndexChanged(object sender, EventArgs e)
        {
            CheckedListBox ckb = sender as CheckedListBox;
            if (ckb == null) return;
            foreach (int ix in ckb.SelectedIndices)
                ckb.SetItemChecked(ix, true);
        }

        private void ckb_ClickAllowOnly1(object sender, EventArgs e)
        {
            CheckedListBox ckb = sender as CheckedListBox;
            if (ckb == null) return;
            for (int ix = 0; ix < ckb.Items.Count; ++ix)
                ckb.SetItemChecked(ix, ix == ckb.SelectedIndex);
        }

        private void pictureBox_Click(object sender, EventArgs e)
        {
            if (pictureBox.Image != null)
            {
                SaveFileDialog saveImageDialog = new SaveFileDialog
                {
                    Filter = @"Image files | *.bmp",
                    DefaultExt = "bmp"
                };

                if (saveImageDialog.ShowDialog() == DialogResult.OK)
                {
                    string name = saveImageDialog.FileName;
                    pictureBox.Image.Save(name, System.Drawing.Imaging.ImageFormat.Bmp);
                }
            }
        }

        #endregion

        #region tab: simple priority dispatching rules and optimize

        private bool SimpleTab(out Data[] problems, out string info)
        {
            int idPlot = radioSimpleProblemsAll.Checked ? -1 : (int) numericUpDownInstanceID.Value;
            pictureBox.Image = null;
            problems = null;

            List<string> distributions =
                (from int index in ckbSimpleProblem.CheckedIndices select ckbSimpleProblem.Items[index].ToString())
                    .ToList();

            List<string> dims =
                (from int index in ckbSimpleDim.CheckedIndices select ckbSimpleDim.Items[index].ToString()).ToList();

            List<string> sets =
                (from int index in ckbSimpleDataSet.CheckedIndices select ckbSimpleDataSet.Items[index].ToString())
                    .ToList();

            if (distributions.Count > 0)
            {
                if (dims.Count == 0)
                {
                    info = "Dimensions not selected\n";
                    return false;
                }
                if (sets.Count == 0)
                {
                    info = "Data set not selected\n";
                    return false;
                }

                if (!ReadData(distributions, sets, dims, out problems, out info, idPlot))
                {
                    return false;
                }
            }
            else
            {
                problems = new Data[0];
            }

            List<string> orlib =
                (from int index in ckbSimpleORLIB.CheckedIndices select ckbSimpleORLIB.Items[index].ToString()).ToList();

            if (orlib.Count > 0)
            {
                Data[] orlibData;
                if (
                    !ReadData(orlib, new List<string> {"test"}, new List<string> {"mixed"}, out orlibData, out info,
                        idPlot))
                {
                    return false;
                }

                Array.Resize(ref problems, problems.Length + orlibData.Length);
                Array.Copy(orlibData, 0, problems, distributions.Count, orlibData.Length);
                distributions = distributions.Union(orlib).ToList();
            }
            else info = "";

            if (distributions.Count == 0)
            {
                info = "Problem instance not selected\n";
                return false;
            }

            richTextBox.AppendText(info);
            return true;
        }

        private bool SimpleTabBDR(out Data[] problems, out int splitStepProc, out SDR firstSDR, out SDR secondSDR,
            out string info)
        {
            splitStepProc = (int) numericUpDownBDRsplitStep.Value;

            pictureBox.Image = null;
            problems = null;

            firstSDR = SDR.RND;
            secondSDR = SDR.RND;

            if (ckbSDR1BDR.CheckedIndices.Count > 0)
                firstSDR = (SDR) ckbSDR1BDR.CheckedIndices[0];
            else
            {
                info = string.Format("SDR for before {0}% steps must be chosen", splitStepProc);
                return false;
            }

            if (ckbSDR2BDR.CheckedIndices.Count > 0)
                secondSDR = (SDR) ckbSDR2BDR.CheckedIndices[0];
            else
            {
                info = string.Format("SDR for after {0}% steps must be chosen", splitStepProc);
                return false;
            }

            List<string> distributions =
                (from int index in ckbDataBDR.CheckedIndices select ckbDataBDR.Items[index].ToString()).ToList();

            List<string> dims =
                (from int index in ckbDimBDR.CheckedIndices select ckbDimBDR.Items[index].ToString()).ToList();

            List<string> sets =
                (from int index in ckbSetBDR.CheckedIndices select ckbSetBDR.Items[index].ToString()).ToList();

            if (distributions.Count > 0)
            {
                if (dims.Count == 0)
                {
                    info = "Dimensions not selected\n";
                    return false;
                }
                if (sets.Count == 0)
                {
                    info = "Data set not selected\n";
                    return false;
                }

                if (!ReadData(distributions, sets, dims, out problems, out info))
                {
                    return false;
                }
            }
            else
            {
                info = "Problem instance not selected\n";
                return false;
            }

            info = string.Format("Applying {0} to first {2}% of the data, then {1} to the rest", firstSDR, secondSDR,
                splitStepProc);

            richTextBox.AppendText(info);
            return true;
        }

        private LinearModel SimpleTabLinReadInputWeights(out string info)
        {
            double[][] localWeights = new double[(int) LocalFeature.Count][];

            localWeights[0] = new[] {Convert.ToDouble(tbLocal0.Text, CultureInfo.InvariantCulture)};
            localWeights[1] = new[] {Convert.ToDouble(tbLocal1.Text, CultureInfo.InvariantCulture)};
            localWeights[2] = new[] {Convert.ToDouble(tbLocal2.Text, CultureInfo.InvariantCulture)};
            localWeights[3] = new[] {Convert.ToDouble(tbLocal3.Text, CultureInfo.InvariantCulture)};
            localWeights[4] = new[] {Convert.ToDouble(tbLocal4.Text, CultureInfo.InvariantCulture)};
            localWeights[5] = new[] {Convert.ToDouble(tbLocal5.Text, CultureInfo.InvariantCulture)};
            localWeights[6] = new[] {Convert.ToDouble(tbLocal6.Text, CultureInfo.InvariantCulture)};
            localWeights[7] = new[] {Convert.ToDouble(tbLocal7.Text, CultureInfo.InvariantCulture)};
            localWeights[8] = new[] {Convert.ToDouble(tbLocal8.Text, CultureInfo.InvariantCulture)};
            localWeights[9] = new[] {Convert.ToDouble(tbLocal9.Text, CultureInfo.InvariantCulture)};
            localWeights[10] = new[] {Convert.ToDouble(tbLocal10.Text, CultureInfo.InvariantCulture)};
            localWeights[11] = new[] {Convert.ToDouble(tbLocal11.Text, CultureInfo.InvariantCulture)};
            localWeights[12] = new[] {Convert.ToDouble(tbLocal12.Text, CultureInfo.InvariantCulture)};
            localWeights[13] = new[] {Convert.ToDouble(tbLocal13.Text, CultureInfo.InvariantCulture)};
            localWeights[14] = new[] {Convert.ToDouble(tbLocal14.Text, CultureInfo.InvariantCulture)};
            localWeights[15] = new[] {Convert.ToDouble(tbLocal15.Text, CultureInfo.InvariantCulture)};
            localWeights[16] = new[] {Convert.ToDouble(tbLocal16.Text, CultureInfo.InvariantCulture)};
            localWeights[17] = new[] {Convert.ToDouble(tbLocal17.Text, CultureInfo.InvariantCulture)};
            //double bias = Convert.ToDouble(tbLocal18.Text, CultureInfo.InvariantCulture);
            LinearModel linear = new LinearModel(localWeights, DateTime.Now.ToShortDateString());

            info = "Applying linear weights:";
            for (int i = 0; i < (int) LocalFeature.Count; i++)
            {
                if (Math.Abs(linear.Weights.Local[i][0]) > 1.00e-6)
                    info += string.Format("\n\t{0}: {1}", (LocalFeature) i, linear.Weights.Local[i]);
            }
            info += "\nOther features are zero.\n\n";
            return linear;
        }

        private bool SimpleTabLin(out Data[] problems, out string info)
        {
            pictureBox.Image = null;
            problems = null;

            List<string> distributions =
                (from int index in ckbDataLIN.CheckedIndices select ckbDataLIN.Items[index].ToString()).ToList();

            List<string> dims =
                (from int index in ckbDimLIN.CheckedIndices select ckbDimLIN.Items[index].ToString()).ToList();

            List<string> sets =
                (from int index in ckbSetLIN.CheckedIndices select ckbSetLIN.Items[index].ToString()).ToList();

            if (distributions.Count > 0)
            {
                if (dims.Count == 0)
                {
                    info = "Dimensions not selected\n";
                    return false;
                }
                if (sets.Count == 0)
                {
                    info = "Data set not selected\n";
                    return false;
                }

                if (!ReadData(distributions, sets, dims, out problems, out info))
                {
                    return false;
                }
            }
            else
            {
                info = "Problem instance not selected\n";
                return false;
            }


            return true;
        }

        private bool ReadData(List<string> distributions, List<string> sets, List<string> dims, out Data[] problems,
            out string info, int idPlot = -1)
        {
            problems = new Data[distributions.Count*dims.Count*sets.Count];
            int i = 0;
            info = "";
            foreach (string distribution in distributions)
                foreach (string dim in dims)
                    foreach (string set in sets)
                    {
                        bool success;
                        string errorMsg = ReadProblem(distribution, dim, set, out problems[i], out success, idPlot);
                        if (!success)
                        {
                            info = errorMsg;
                            return false;
                        }

                        info += SEPERATION_LINE + distribution + " problem ";
                        if (radioSimpleProblemsSingle.Checked)
                            info += "#" + numericUpDownInstanceID.Value;
                        else
                            info += "#1-#" + problems[i].NumInstances.ToString();
                        info += (set != string.Empty ? " (" + set.ToLower() + " set)" : "");
                        info += (dim != string.Empty ? " of dimension " + dim : "") + ".\n";
                        i++;
                    }

            if (idPlot == -1)
                info = "";
            return true;
        }

        private void buttonSDRStart_Click(object sender, EventArgs e)
        {
            textBoxDir.Text = @"SDR";

            string info;
            SetWorkingDirectory(out _workingDirectory, out info);
            richTextBox.Text = info;

            Data[] problems;
            if (!SimpleTab(out problems, out info))
            {
                richTextBox.Text = String.Format("Error: {0}\n", info);
                return;
            }
            richTextBox.AppendText(info);

            List<SDR> sdrs = new List<SDR>();
            foreach (int index in ckbSimpleSDR.CheckedIndices)
            {
                string sdr = ckbSimpleSDR.Items[index].ToString();
                for (int i = 0; i < (int) SDR.Count; i++)
                    if (sdr == String.Format("{0}", (SDR) i))
                    {
                        sdrs.Add((SDR) i);
                        break;
                    }
            }
            if (sdrs.Count == 0)
            {
                richTextBox.Text = @"Error, missing simple priority dispatching rule (SDR)";
                return;
            }

            #region apply SDR

            DateTime start = DateTime.Now;
            int iter = 0;
            int totIter = sdrs.Count*problems.Length;
            progressBarOuter.Value = 0;
            foreach (Data problem in problems)
            {
                if (problem == null)
                    continue;
                richTextBox.AppendText(String.Format("\n{0}.{1}.{2}\n", problem.Name, problem.Dimension, problem.Set));
                foreach (SDR sdr in sdrs)
                {
                    Data optData = problem;
                    optData.ReadCsvOpt(_optDirectory);
                    progressBarInner.Value = 0;
                    if (radioSimpleProblemsSingle.Checked)
                    {
                        int id = (int) numericUpDownInstanceID.Value - 1;

                        var prob = problem.Rows[id];
                        string name = (string) prob["Name"];
                        Schedule jssp = new Schedule((ProblemInstance) prob["Problem"]);
                        jssp.ApplyMethod(sdr, FeatureType.None);

                        DataRow optRow = optData.Rows.Find(name);
                        int optMakespan = optRow != null ? (int) optRow["Makespan"] : int.MinValue;

                        problem.AddHeuristicMakespan(name, jssp.Makespan, optMakespan, sdr.ToString(), "SDR");

                        //richTextBoxConsole.Visible = false;
                        pictureBox.Visible = true;
                        string filePath = String.Format(@"{0}GIF\{1}_{2}", _mainDirectory, name,
                            ckbSimpleSDR.CheckedItems.Count > 0 ? ckbSimpleSDR.CheckedItems[0].ToString() : "OPT");

                        if (!File.Exists(filePath + ".gif") | !File.Exists(filePath + ".jpg"))
                            jssp.PlotSchedule(pictureBox.Width, pictureBox.Height, filePath);

                        try
                        {
                            pictureBox.Image = Image.FromFile(filePath + ".gif");
                        }
                        catch
                        {
                            pictureBox.Image = Image.FromFile(filePath + ".jpg");
                        }
                        info += "\n" + jssp.PrintSchedule();
                    }
                    else if (!problem.ReadCsvSDR(sdr, _sdrDirectory))
                    {
                        richTextBox.AppendText(sdr + " applied.\n");
                        for (int id = 0; id < problem.NumInstances; id++)
                        {
                            var prob = problem.Rows[id];
                            string name = (string) prob["Name"];
                            Schedule jssp = new Schedule((ProblemInstance) prob["Problem"]);
                            jssp.ApplyMethod(sdr, FeatureType.None);

                            DataRow optRow = optData.Rows.Find(name);
                            int optMakespan = optRow != null ? (int) optRow["Makespan"] : int.MinValue;

                            problem.AddHeuristicMakespan(name, jssp.Makespan, optMakespan, sdr.ToString(), "SDR");

                            info = name;
                            string errorMsg;
                            if (jssp.Validate(out errorMsg, true))
                                info = " Cmax: " + jssp.Makespan.ToString() + "\n";
                            else
                            {
                                info += " ERROR: Invalid solution reported: " + errorMsg + "\n";
                            }
                            //richTextBox.AppendText(info);
                            progressBarInner.Value = (int) (100.0*id/problem.NumInstances); //update progress bar  
                        }
                        // fin
                        problem.WriteCsvSDR(sdr.ToString(), _sdrDirectory);
                    }
                    else
                    {
                        richTextBox.AppendText(sdr + " previously applied.\n");
                    }
                    progressBarInner.Value = 100;
                    progressBarOuter.Value = (int) (100.0*(++iter)/totIter);
                }
            }
            TimeSpan duration = DateTime.Now - start;
            info = String.Format("{0}Duration: {1} s{0}", SEPERATION_LINE,
                duration.TotalSeconds.ToString(CultureInfo.InvariantCulture).Replace(',', '.'));
            richTextBox.AppendText(info);

            progressBarOuter.Value = 100;

            #endregion
        }

        #endregion

        
        #region backgroundworkers

        #region bkgWorkerGenTrData

        #region start / stop

        private const string ButtonTextValidate = "Validate";
        private const string ButtonTextStart = "Start";
        private const string ButtonTextCancel = "Cancel";
        private const string ButtonTextResume = "Resume";
        private const string MsgTaskComplete = "The task has been completed";

        private void startAsyncButtonGenTrData_Click(object sender, EventArgs e)
        {
            Data[] data;
            List<Track> tracks;
            string solver;
            string info;
            FeatureType featureType;
            object[] imitationLearning;
            bool success = ValidateGenTrData(out data, out tracks, out solver, out featureType, out info,
                out imitationLearning);

            object[] arg = new object[5];
            arg[0] = solver;
            arg[1] = tracks;
            arg[2] = data;
            arg[3] = featureType;
            arg[4] = imitationLearning;
            object args = arg;

            switch (startAsyncButtonGenTrData.Text)
            {
                case ButtonTextValidate:
                    richTextBox.Text = info;
                    if (!success)
                    {
                        return;
                    }
                    startAsyncButtonGenTrData.Text = ButtonTextStart;
                    break;
                case ButtonTextStart:
                    while (bkgWorkerGenTrData.IsBusy)
                    {
                        /* wait */
                    }

                    richTextBox.Text = "";
                    richTextBoxConsole.Text = "";
                    richTextBox.Text = info;

                    bkgWorkerGenTrData.RunWorkerAsync(args);
                    cancelAsyncButtonGenTrData.Visible = true;
                    break;
            }
        }

        private void cancelAsyncButtonGenTrData_Click(object sender, EventArgs e)
        {
            //notify bkg worker we want to cancel the operation.
            //this code doesn't actually cancel or kill the thread that is executing the job.
            bkgWorkerGenTrData.CancelAsync();
            richTextBox.AppendText("\n\nCancelling generation of training data, i.e. preference pairs of features  ...");
            cancelAsyncButtonGenTrData.Visible = false;
        }

        #endregion

        #region validate

        private string SimpleDimName(string fulldim)
        {
            string mac = Regex.Match(fulldim, @"([\d]*) machine").Groups[1].Value;
            string job = Regex.Match(fulldim, @"([\d]*) job").Groups[1].Value;
            return job + "x" + mac;
        }

        private bool ValidateGenTrData(out Data[] trainingData, out List<Track> tracks, out string solver,
            out FeatureType featureType, out string info, out object[] imitationLearning)
        {
            imitationLearning = null;
            solver = radioButtonGUROBItraining.Checked ? "GUROBI" : "GLPK";

            trainingData = null;
            tracks = new List<Track>();
            List<string> dims = new List<string>();

            // Get selected index, and then make sure it is valid.
            info = "Creating training data ...";

            int nrFeat = Convert.ToInt32(numericLiblinearNrFeat.Value);
            int model = Convert.ToInt32(numericLiblinearModel.Value);

            string logFile = (comboBoxLiblinearLogfile.SelectedItem == null)
                ? ""
                : comboBoxLiblinearLogfile.SelectedItem.ToString();

            info += "\nTracks: ";
            foreach (int selected in ckbTracks.CheckedIndices)
            {
                string track = ckbTracks.Items[selected].ToString();
                if (track == "Imitation Learning")
                {
                    track = "PREF";
                    if (logFile == string.Empty)
                    {
                        info = "Must select logfile for imitation learning";
                        featureType = FeatureType.None;
                        return false;
                    }
                    if (Regex.IsMatch(logFile, "^full."))
                    {
                        nrFeat = 16;
                        model = 1;
                    }
                    else
                    {
                        bool ok;
                        switch (nrFeat)
                        {
                            case 1:
                                ok = (model > 0 & model <= 16);
                                break;
                            case 2:
                                ok = (model > 0 & model <= 120);
                                break;
                            case 3:
                                ok = (model > 0 & model <= 560);
                                break;
                            case 16:
                                ok = (model > 0 & model <= 1);
                                break;
                            default:
                                ok = false;
                                break;
                        }
                        if (!ok)
                        {
                            info = string.Format("NrFeat and Model combination {1}.{2} doesn't exist for {0}", logFile,
                                nrFeat, model);
                            featureType = FeatureType.None;
                            return false;
                        }
                    }
                    FileInfo file = new FileInfo(String.Format("{0}weights\\{1}", _prefDirectory, logFile));
                    int iteration;
                    bool supervised = radioImitationLearningSupervised.Checked;
                    bool unsupervised = radioImitationLearningUnsupervised.Checked;
                    string strSupervised = supervised ? "SUP" : unsupervised ? "UNSUP" : "FIXSUP";
                    if (Regex.IsMatch(file.Name, "IL"))
                    {
                        Match m = Regex.Match(file.Name, string.Format("IL(?<iteration>[0-9]){0}", strSupervised));
                        iteration = Convert.ToInt32(m.Groups[1].Value);
                    }
                    else iteration = 0;
                    iteration++;
                    imitationLearning = new object[]
                    {
                        file.FullName, nrFeat, model, String.Format("IL{0:0}{1}", iteration, strSupervised), iteration,
                        strSupervised
                    };
                }
                else track = track.Substring(0, 3).ToUpper();
                info += " " + track;
                for (int i = 0; i < (int) Track.Count; i++)
                    if (track == string.Format("{0}", (Track) i))
                    {
                        tracks.Add((Track) i);
                        break;
                    }

            }
            if (!tracks.Any())
            {
                info = "Error, must at least choose one tracjectory for sampling the problem instances' features.";
                featureType = FeatureType.None;
                return false;
            }
            info += "\n";

            info += "\nDimensions: ";
            foreach (int selected in ckbTrainingDim.CheckedIndices)
            {
                string dim = SimpleDimName(ckbTrainingDim.Items[selected].ToString());
                info += " " + dim;
                dims.Add(dim);
            }
            if (!dims.Any())
            {
                info = "Error, must at least choose one dimension for problem instances' features.";
                featureType = FeatureType.None;
                return false;
            }
            info += "\n";

            List<string> trainInstances = new List<string>();
            info += "\nProblem instances: ";
            foreach (string dimStr in dims)
            {
                string fnameEnd = "." + dimStr + ".train.txt";
                foreach (int selected in ckbProblemModel.CheckedIndices)
                {
                    string problem = ckbProblemModel.Items[selected].ToString();
                    info += " " + problem + "." + dimStr;

                    if (!File.Exists(_dataDirectory + problem + fnameEnd))
                    {
                        info = "Error, problem reading " + problem + ", files cannot be located in directory:\n" +
                               _dataDirectory;
                        featureType = FeatureType.None;
                        return false;
                    }
                    trainInstances.Add(problem + fnameEnd);
                }
            }
            if (!trainInstances.Any())
            {
                info = "Error, must choose at least one problem distribution for collecting training data.";
                featureType = FeatureType.None;
                return false;
            }

            featureType = radioGlobal.Checked
                ? FeatureType.Global
                : radioLocal.Checked ? FeatureType.Local : FeatureType.None;
            if (featureType == FeatureType.None)
            {
                info = "Error, feature scheme must be set, either local or global";
                return false;
            }

            trainingData = new Data[trainInstances.Count];
            for (int i = 0; i < trainInstances.Count; i++)
            {
                if (ckbExtendTrainingSet.SelectedItem != null)
                    AuxFun.ReadRawData(trainInstances[i], _dataDirectory, out trainingData[i], -1, 5000);
                else
                    AuxFun.ReadRawData(trainInstances[i], _dataDirectory, out trainingData[i]);

                trainingData[i].ReadCsvOpt(_optDirectory);
            }
            return true;
        }

        #endregion

        //This method is executed in a separate thread created by the background worker.  
        //so don't try to access any UI controls here!! (unless you use a delegate to do it)  
        //this attribute will prevent the debugger to stop here if any exception is raised.  
        //[System.Diagnostics.DebuggerNonUserCodeAttribute()]  
        private void bkgWorkerGenTrData_DoWork(object sender, DoWorkEventArgs e)
        {
            //NOTE: we shouldn't use a try catch block here (unless you rethrow the exception)  
            //the background worker will be able to detect any exception on this code.  
            //if any exception is produced, it will be available to you on   
            //the RunWorkerCompletedEventArgs object, method bkgWorkerPrefModel_RunWorkerCompleted  

            object[] arg = (object[]) e.Argument;
            string solver = arg[0].ToString();
            List<Track> tracks = (List<Track>) arg[1];
            Data[] distributions = (Data[]) arg[2];
            const FeatureType FEATURE_TYPE = FeatureType.Local; // always start as local
            object[] imitationLearning = (object[]) arg[4];

            #region minimal training data

            int iData = 0;
            int totIter = tracks.Count*distributions.Length;
            foreach (Data data in distributions)
            {
                string distribution = data.Name;
                bkgWorkerGenTrData.ReportProgress((int) (100.0*iData/totIter),
                    String.Format("{0}{1}\n", SEPERATION_LINE, distribution));

                foreach (Track track in tracks)
                {
                    string trackName = track.ToString();
                    LinearModel linModel = null;
                    switch (track)
                    {
                        case Track.CMA:
                            linModel = new LinearModel(data);
                            break;
                        case Track.PREF:
                            linModel = new LinearModel(imitationLearning);
                            trackName = (string) imitationLearning[3];
                            break;
                    }

                    TrainingData training = new TrainingData(data, track, trackName, solver, FEATURE_TYPE,
                        _trainingDirectoy, _workingDirectory);
                    FileInfo fileTraining = new FileInfo(training.FileName);
                    if (!fileTraining.Exists && FEATURE_TYPE == FeatureType.Global)
                        fileTraining =
                            new FileInfo(training.FileName.Replace(FeatureType.Global.ToString(),
                                FeatureType.Local.ToString()));

                    int dataNumInstances = data.Rows.Count == 500 || track == Track.PREF
                        ? data.Dimension == "6x5" ? 500 : 300
                        : data.Rows.Count;
                    
                    int pidStart = 0;
                    if (fileTraining.Exists)
                    {
                        string[] allContent;
                        AuxFun.ReadTextFile(fileTraining.FullName, out allContent, "\r\n");
                        List<int> pids = new List<int>();

                        for (int i = 1; i < allContent.Length; i++)
                        {
                            Match m = Regex.Match(allContent[i], "^([0-9]+),");
                            if (m.Success)
                            {
                                int pid = Convert.ToInt32(m.Groups[1].Value);
                                pids.Add(pid);
                            }
                        }
                        pidStart = pids.Max();
                    }

                    if (track == Track.PREF && data.Rows.Count > 500)
                    {
                        pidStart = Math.Max(pidStart, dataNumInstances*(int) imitationLearning[4]);
                        dataNumInstances *= ((int) imitationLearning[4] + 1);
                    }

                    int alreadyAutoSavedPid = -1;
                    if (pidStart >= dataNumInstances)
                        e.Result = String.Format("Minimal training data exists for {0}", track);
                    else
                    {
                        DateTime start = DateTime.Now;
                        Stopwatch autoSave = new Stopwatch();
                        autoSave.Start();
                        TimeSpan duration;
                        e.Result = "";
                        bkgWorkerGenTrData.ReportProgress((int) (100.0*iData/totIter),
                            String.Format("Generating training data for {0} ...", track));
                        foreach (DataRow instance in data.Rows)
                        {
                            int pid = (int) instance["PID"];
                            if (pid <= pidStart) continue;
                            if (pid > dataNumInstances) break;

                            string info = training.CreateTrainingData(instance, track, linModel);
                            //do some intense task here.

                            if (bkgWorkerGenTrData.CancellationPending)
                            {
                                duration = DateTime.Now - start;
                                info += String.Format("\n\nDuration: {0:0} s.", duration.TotalSeconds);
                                training.WriteCSV(TrainingData.CSVType.Gen, new FileInfo(training.FileName), null,
                                    alreadyAutoSavedPid);
                                bkgWorkerGenTrData.ReportProgress((int) (100.0*pid/dataNumInstances), info);
                                e.Cancel = true;
                                return;
                            }
                            bkgWorkerGenTrData.ReportProgress((int) (100.0*pid/dataNumInstances), info);

                            if (autoSave.ElapsedMilliseconds <= HALFHOUR) continue;
                            training.WriteCSV(TrainingData.CSVType.Gen, new FileInfo(training.FileName), null,
                                alreadyAutoSavedPid);
                            alreadyAutoSavedPid = pid;
                            autoSave.Restart();
                        }
                        // save current work 
                        duration = DateTime.Now - start;
                        e.Result = String.Format("{0} total duration: {1:0} s.", track, duration.TotalSeconds);
                    }
                    training.WriteCSV(TrainingData.CSVType.Gen, new FileInfo(training.FileName), null,
                        alreadyAutoSavedPid);
                    bkgWorkerGenTrData.ReportProgress((int) (100.0*++iData/totIter), e.Result);
                }
            }

            #endregion
        }

        //This is executed after the task is complete whatever the task has completed: a) successfully, b) with error c) has been cancelled  
        private void bkgWorkerGenTrData_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            if (e.Cancelled)
            {
                MessageBox.Show(startAsyncButtonGenTrData.Text == ButtonTextResume
                    ? "The task has been paused."
                    : "The task has been cancelled.");
            }
            else if (e.Error != null)
            {
                MessageBox.Show(@"Error. Details: " + e.Error);
            }
            else
            {
                MessageBox.Show(String.Format("{0}. {1}", MsgTaskComplete, e.Result));
                cancelAsyncButtonGenTrData.Visible = false;
                startAsyncButtonGenTrData.Text = ButtonTextValidate;
            }
        }

        #endregion

        #region bkgWorkerOptimize

        #region stop /stop

        private void startAsyncButtonOptimize_Click(object sender, EventArgs e)
        {
            textBoxDir.Text = @"OPT";
            string info;
            SetWorkingDirectory(out _workingDirectory, out info);

            string solver = radioButtonGLPK.Checked ? "GLPK" : "Gurobi";
            int tmlim = (int) numericUpDownTmLimit.Value;

            Data[] applyProblems;
            SimpleTab(out applyProblems, out info);

            object[] arg = new object[3];
            arg[0] = solver;
            arg[1] = tmlim;
            arg[2] = applyProblems;
            object args = arg;

            switch (startAsyncButtonOptimize.Text)
            {
                case ButtonTextValidate:
                    richTextBox.Text = info;
                    if (ValidateOptimize(out applyProblems))
                        startAsyncButtonOptimize.Text = ButtonTextStart;
                    break;
                case ButtonTextStart:
                    while (bkgWorkerOptimize.IsBusy)
                    {
                        /* wait */
                    }

                    richTextBox.Text = "";
                    richTextBoxConsole.Text = "";

                    bkgWorkerOptimize.RunWorkerAsync(args);
                    cancelAsyncButtonOptimize.Visible = true;
                    break;
            }
        }

        #endregion

        #region validate

        private bool ValidateOptimize(out Data[] applyProblems)
        {
            string info;
            if (!SimpleTab(out applyProblems, out info))
            {
                return false;
            }
            richTextBox.AppendText(info);
            richTextBox.AppendText("\nValid for optimization." + SEPERATION_LINE);

            return true;
        }

        private void cancelAsyncButtonOptimize_Click(object sender, EventArgs e)
        {
            bkgWorkerOptimize.CancelAsync();
            richTextBox.AppendText("\n\nCancelling optimization...");
            startAsyncButtonOptimize.Text = ButtonTextValidate;
            cancelAsyncButtonOptimize.Visible = false;
        }

        #endregion

        private void bkgWorkerOptimize_DoWork(object sender, DoWorkEventArgs e)
        {
            object[] arg = (object[]) e.Argument;

            string solver = (string) arg[0];
            int tmlim = Convert.ToInt32(arg[1]);
            Data[] problems = (Data[]) arg[2];

            bkgWorkerOptimize.ReportProgress(0,
                SEPERATION_LINE + "Optimizing with linear solver " + solver + " with time limit " + tmlim +
                "sec." + SEPERATION_LINE);

            #region do intensive work

            foreach (Data problem in problems)
            {
                string fname = "opt." + problem.Name + ".csv";
                bool missing;
                if (File.Exists(_workingDirectory + fname) & problem.NumInstances > 1)
                {
                    string content = File.ReadAllText(_workingDirectory + fname);
                    int found = problem.Rows.Cast<DataRow>().Count(row => Regex.IsMatch(content, (string) row["Name"]));

                    missing = found < problem.NumInstances;
                }
                else
                {
                    missing = true;
                }

                if (missing)
                {
                    DateTime start = DateTime.Now;
                    TimeSpan duration;
                    e.Result = "";
                    foreach (DataRow instance in problem.Rows)
                    {
                        int opt;
                        bool solved;
                        int simplexIterations;
                        string name = (string) instance["Name"];
                        int pid = (int) instance["PID"];
                        ProblemInstance prob = (ProblemInstance) instance["Problem"];
                        int[,] xTimeJob = prob.Optimize(_workingDirectory, solver, name, out opt, out solved,
                            out simplexIterations, tmlim); // INTENSE WORK

                        Schedule jssp = new Schedule(prob);
                        jssp.SetCompleteSchedule(xTimeJob, opt);

                        string info = name + ":";
                        string errorMsg;
                        if (jssp.Validate(out errorMsg, true))
                        {
                            problem.AddOptMakespan(name, opt, solved, xTimeJob, simplexIterations, solver);
                            info += opt.ToString() + (solved ? "" : "*");
                        }
                        else
                        {
                            info += "error " + errorMsg + "\n";
                        }

                        if (bkgWorkerOptimize.CancellationPending)
                        {
                            duration = DateTime.Now - start;
                            info += "\n\nDuration: " +
                                    duration.TotalSeconds.ToString(CultureInfo.InvariantCulture).Replace(',', '.') +
                                    " s.";
                            bkgWorkerOptimize.ReportProgress((int) (100.0*pid/problem.NumInstances), info);
                            e.Cancel = true;
                            return;
                        }
                        else
                        {
                            bkgWorkerOptimize.ReportProgress((int) (100.0*pid/problem.NumInstances), info);
                        }

                        if (problem.NumInstances == 1)
                        {
                            string filePath = String.Format(@"{0}GIF\{1}_{2}", _mainDirectory, name,
                                ckbSimpleSDR.CheckedItems.Count > 0 ? ckbSimpleSDR.CheckedItems[0].ToString() : "OPT");

                            if (!File.Exists(filePath + ".gif") | !File.Exists(filePath + ".jpg"))
                                jssp.PlotSchedule(pictureBox.Width, pictureBox.Height, filePath);

                            bkgWorkerOptimize.ReportProgress(100, filePath);
                            string[] results = new string[3];

                            results[0] = filePath + ".gif";
                            results[1] = filePath + ".jpg";
                            results[2] = String.Format("\n{0}\nSimplex iterations:{1}\n", jssp.PrintSchedule(),
                                simplexIterations);

                            e.Result = results;
                        }
                    }
                    // save current work
                    if (problem.NumInstances > 1)
                    {
                        problem.WriteCsvOpt(_optDirectory);
                        duration = DateTime.Now - start;
                        e.Result = fname + ": Total duration: " +
                                   duration.TotalSeconds.ToString(CultureInfo.InvariantCulture).Replace(',', '.') +
                                   " s.";
                    }
                }
                else
                {
                    e.Result = fname + ": Previously optimized";
                }
                bkgWorkerOptimize.ReportProgress(100, SEPERATION_LINE + e.Result + SEPERATION_LINE);
            }

            #endregion

            e.Result = "Optimization finished";
        }

        private void bkgWorkerOptimize_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            if (e.Cancelled)
            {
                MessageBox.Show(startAsyncButtonOptimize.Text == ButtonTextResume
                    ? "The task has been paused."
                    : "The task has been cancelled.");
            }
            else if (e.Error != null)
            {
                MessageBox.Show(@"Error. Details: " + e.Error);
            }
            else
            {
                if (e.Result.GetType() == typeof (string[]))
                {
                    string[] results = (string[]) e.Result;
                    //pictureBox.Visible = true;
                    try
                    {
                        pictureBox.Image = Image.FromFile(results[0]);
                    }
                    catch
                    {
                        pictureBox.Image = Image.FromFile(results[1]);
                    }
                    richTextBoxConsole.AppendText("\n" + results[2]);
                }

                MessageBox.Show(String.Format("{0}. {1}", MsgTaskComplete, e.Result));
                cancelAsyncButtonOptimize.Visible = false;
                startAsyncButtonOptimize.Text = ButtonTextValidate;
            }
        }

        #endregion

        #region common work



        private void bkgWorker_ProgressChanged(object sender, ProgressChangedEventArgs e)
        {
            //This event is raised on the main thread.  
            //It is safe to access UI controls here.              
            string info = Convert.ToString(e.UserState);
            if (info != "")
            {
                richTextBox.AppendText(info);
                richTextBox.AppendText(Environment.NewLine);
                progressBarOuter.Value = e.ProgressPercentage;
                progressBarInner.Value = e.ProgressPercentage > 0 ? 100 : 0;
            }
            else progressBarInner.Value = e.ProgressPercentage;

        }

        private bool SetWorkingDirectory(out string directory, out string info)
        {
            string folder = textBoxDir.Text;
            folder = Path.GetInvalidFileNameChars()
                .Aggregate(folder, (current, c) => current.Replace(c.ToString(), string.Empty));

            directory = _mainDirectory;

            if (folder != textBoxDir.Text)
            {
                textBoxDir.Text = folder;
                info = "Warning, folder your requested contains some illegal characters. Try again, perhaps use " +
                       folder + ".";
                return false;
            }
            else if (folder == string.Empty)
            {
                textBoxDir.Text = @"wip";
                info = "Warning, you haven't requested a directory for saving the results. Try again, perhaps use wip.";
                return false;
            }

            if (folder.Substring(folder.Length - 2, 2) != @"\\")
                folder += @"\";
            directory += folder;

            if (folder != string.Empty)
                if (!Directory.Exists(directory))
                {
                    Directory.CreateDirectory(directory);
                }

            info = "Working from subfolder: " + folder + "\n";
            return true;
        }

        #endregion

        #region bkgWorkerRankTrData

        private bool ValidateRankTrData(out TrainingData[] trainingData, bool readCsvFile)
        {
            string solver;
            List<Track> tracks;
            Data[] distributions;
            string info;
            FeatureType featureType;
            object[] imitationLearning;
            bool success = ValidateGenTrData(out distributions, out tracks, out solver, out featureType, out info,
                out imitationLearning);
            richTextBox.AppendText(info);
            if (!success)
            {
                trainingData = null;
                return false;
            }

            List<RankingScheme> rankingSchemes = new List<RankingScheme>();
            info = "Ranks: ";
            foreach (int index in ckbRanks.CheckedIndices)
            {
                string rank = ckbRanks.Items[index].ToString().ToLower();
                rank = Regex.Match(rank, "(.+?) ranking*").Groups[1].ToString().Replace(' ', '.');
                switch (rank[0])
                {
                    case 'b':
                        rankingSchemes.Add(RankingScheme.Basic);
                        break;
                    case 'p':
                        rankingSchemes.Add(RankingScheme.PartialPareto);
                        break;
                    case 'f':
                        rankingSchemes.Add(RankingScheme.FullPareto);
                        break;
                    case 'a':
                        rankingSchemes.Add(RankingScheme.All);
                        break;
                    default:
                        richTextBox.AppendText("Error, unknown ranking scheme");
                        trainingData = null;
                        return false;
                }
                info += " " + rank[0];
            }
            if (rankingSchemes.Count == 0)
            {
                richTextBox.AppendText("Error, ranking scheme missing");
                trainingData = null;
                return false;
            }
            richTextBox.AppendText(info + "\n");

            List<TrainingData> trainingDataList = new List<TrainingData>(distributions.Length*tracks.Count);

            foreach (Data data in distributions)
            {
                string distribution = data.Name;
                foreach (Track track in tracks)
                {
                    string trackName;
                    switch (track)
                    {
                        case Track.PREF:
                            trackName = imitationLearning[3].ToString();
                            break;
                        default:
                            trackName = track.ToString();
                            break;
                    }

                    string fileName = String.Format("{0}trdat.{1}.{2}.{3}.{4}.csv", _trainingDirectoy, distribution,
                        data.Dimension, trackName, featureType);
                    FileInfo fileInfo = new FileInfo(fileName);
                    if (!fileInfo.Exists)
                    {
                        richTextBox.AppendText("Error, training data has not been created for " + fileInfo.Name);
                        trainingData = null;
                        return false;
                    }
                    if (readCsvFile)
                    {
                        //richTextBox.AppendText("Reading " + distribution + "." + track + " for input.");
                        TrainingData training = new TrainingData(data, track, trackName, solver, featureType,
                            _trainingDirectoy, _workingDirectory, rankingSchemes.ToArray());
                        trainingDataList.Add(training);
                    }
                }
            }
            trainingData = trainingDataList.ToArray();
            return true;
        }

        private void startAsyncButtonRankTrData_Click(object sender, EventArgs e)
        {
            TrainingData[] trainingData;
            switch (startAsyncButtonRankTrData.Text)
            {
                case ButtonTextValidate:
                    richTextBox.Text = @"Validating ...\n";
                    if (!ValidateRankTrData(out trainingData, false))
                    {
                        return;
                    }
                    else richTextBox.AppendText("Validation successful\n");
                    startAsyncButtonRankTrData.Text = ButtonTextStart;
                    break;
                case ButtonTextStart:
                    while (bkgWorkerRankTrData.IsBusy)
                    {
                        /* wait */
                    }
                    richTextBox.Text = "";
                    richTextBoxConsole.Text = "";
                    ValidateRankTrData(out trainingData, true);
                    startAsyncButtonGenTrData.Text = ButtonTextValidate;
                    startAsyncButtonOptimize.Text = ButtonTextValidate;
                    bkgWorkerRankTrData.RunWorkerAsync(trainingData);
                    cancelAsyncButtonRankTrData.Visible = true;
                    break;
            }

        }

        private void cancelAsyncButtonRankTrData_Click(object sender, EventArgs e)
        {
            bkgWorkerRankTrData.CancelAsync();
            richTextBox.AppendText("\n\nCancelling ranking of training data, i.e. preference pairs of features  ...");
            cancelAsyncButtonRankTrData.Visible = false;
        }

        private void bkgWorkerRankTrData_DoWork(object sender, DoWorkEventArgs e)
        {
            //NOTE: we shouldn't use a try catch block here (unless you rethrow the exception)  
            //the background worker will be able to detect any exception on this code.  
            //if any exception is produced, it will be available to you on   
            //the RunWorkerCompletedEventArgs object, method bkgWorkerPrefModel_RunWorkerCompleted  

            TrainingData[] trainingDatas = (TrainingData[]) e.Argument;

            if (trainingDatas == null) return;

            #region do intensive work

            DateTime start = DateTime.Now;
            TimeSpan duration;
            e.Result = "";

            bkgWorkerRankTrData.ReportProgress(0,
                "\n" + SEPERATION_LINE + "Creating preference pairs ..." + SEPERATION_LINE + "\n\n");
            int totIter = trainingDatas.Length*trainingDatas[0].RankingSchemes.Length;
            int iter = 0;
            foreach (TrainingData training in trainingDatas)
            {
                bkgWorkerRankTrData.ReportProgress((int) (100.0*iter/(totIter)), training.FileName);
                if (!training.ReadCSV(_optDirectory, true))
                {
                    e.Result =
                        String.Format(training.Error != ""
                            ? training.Error
                            : String.Format("Error in reading {0}", training.FileName));

                    bkgWorkerRankTrData.ReportProgress((int) (100.0*++iter/totIter), e.Result);
                }
                else
                {
                    foreach (RankingScheme rankingScheme in training.RankingSchemes)
                    {

                        FileInfo fileDiff =
                            new FileInfo(training.FileName.Substring(0, training.FileName.Length - 4) + ".diff." +
                                         (char) rankingScheme + ".csv");

                        if (!fileDiff.Exists)
                        {

                            List<FullData.DiffPreference>[][] diffData =
                                new List<FullData.DiffPreference>[training.NumInstances][];
                            for (int pid = 0; pid < training.NumInstances; pid++)
                            {
                                diffData[pid] = new List<FullData.DiffPreference>[training.Dimension];
                                for (int dim = 0; dim < training.Dimension; dim++)
                                    diffData[pid][dim] = new List<FullData.DiffPreference>();
                            }

                            for (int pid = 0; pid < training.NumInstances; pid++)
                            {
                                training.CreatePreferencePairs(pid, rankingScheme, diffData);
                                //do some intense task here.

                                int progress = (int) (100.0*pid/training.NumInstances);
                                if (bkgWorkerRankTrData.CancellationPending)
                                {
                                    duration = DateTime.Now - start;
                                    string info = "Duration: " +
                                                  duration.TotalSeconds.ToString(CultureInfo.InvariantCulture)
                                                      .Replace(',', '.') +
                                                  " s.";
                                    bkgWorkerRankTrData.ReportProgress(progress, info);
                                    e.Cancel = true;
                                    return;
                                }
                                bkgWorkerRankTrData.ReportProgress(progress, "");
                            }
                            // save current work 
                            training.WriteCSV(TrainingData.CSVType.Diff, fileDiff, diffData);
                            e.Result = training.Distribution.Name + ":" + training.Track + ":" + (char) rankingScheme +
                                       ": #" + training.CountPreferencePairs(diffData) + " features";
                        }
                        bkgWorkerRankTrData.ReportProgress((int) (100.0*++iter/totIter), e.Result);
                    }
                }
            }
            duration = DateTime.Now - start;
            e.Result = "Total duration: " +
                       duration.TotalSeconds.ToString(CultureInfo.InvariantCulture).Replace(',', '.') + " s.";

            bkgWorkerRankTrData.ReportProgress((int) (100.0*iter/totIter), e.Result);

            #endregion
        }

        //This is executed after the task is complete whatever the task has completed: a) successfully, b) with error c) has been cancelled  
        private void bkgWorkerRankTrData_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            if (e.Cancelled)
            {
                MessageBox.Show(startAsyncButtonRankTrData.Text == ButtonTextResume
                    ? "The task has been paused."
                    : "The task has been cancelled.");
            }
            else if (e.Error != null)
            {
                MessageBox.Show(@"Error. Details: " + e.Error);
            }
            else
            {
                MessageBox.Show(string.Format("The task has been completed. {0}", e.Result));
                cancelAsyncButtonRankTrData.Visible = false;
                startAsyncButtonRankTrData.Text = ButtonTextValidate;
            }
        }

        #endregion




        #endregion

        private String[] LiblinearLogs_Update(string distribution, string dimension)
        {
            String[] allfiles = GetFilesWeight("full", distribution, dimension);
            String[] tmp = GetFilesWeight("exhaust", distribution, dimension);
            Array.Resize(ref allfiles, allfiles.Length + tmp.Length);
            Array.Copy(tmp, 0, allfiles, allfiles.Length - tmp.Length, tmp.Length);

            if (allfiles.Length == 0)
                richTextBox.AppendText(
                    String.Format("Liblinear logged weights for {0} cannot be found in directory: {1}weights\n", distribution,
                        _prefDirectory));
            return allfiles;
        }

        private void comboBoxLiblinearLogs_Update(object sender, EventArgs e)
        {
            if (ckbDataLIN.SelectedIndex == -1)
            {
                richTextBox.Text = @"Must select a problem distribution for Liblinear logged weights first";
                return;
            }

            string dimension, distribution;

            if (typeof (object[]) == sender.GetType())
            {
                object[] input = (object[]) sender;
                distribution = (string) input[0];
                dimension = (string) input[1];
            }
            else
            {
                distribution = ckbDataLIN.SelectedItem.ToString();
                dimension = SimpleDimName(ckbDimLIN.SelectedItem.ToString());
            }

            comboBoxLiblinearLogs.Items.Clear();
            string[] allfiles = LiblinearLogs_Update(distribution, dimension);
            foreach (string fname in allfiles)
                comboBoxLiblinearLogs.Items.Add(fname);
        }

        private String[] GetFilesWeight(string startOfFile, string distribution, string dimension)
        {
            string pattern =
                String.Format(
                    dimension == "10x10" ? "{0}*.{1}.{2}.p.*.equal.weights.time" : "{0}*.{1}.{2}.*.weights.time",
                    startOfFile, distribution, dimension);
            if (radioButtonIndependent.Checked) pattern += "independent";
            else if (radioButtonDependent.Checked) pattern += "dependent";
            else pattern += "*";
            pattern += ".csv";
            string[] files = Directory.GetFiles(String.Format("{0}weights", _prefDirectory), pattern,
                SearchOption.TopDirectoryOnly);
            return files.Select(Path.GetFileNameWithoutExtension).ToArray();
        }

        private void startAsyncButtonFeatTrData_Click(object sender, EventArgs e)
        {
            Data[] datas;
            List<Track> tracks;
            string solver;
            string info;
            FeatureType featureType;
            object[] imitationLearning;
            bool success = ValidateGenTrData(out datas, out tracks, out solver, out featureType, out info,
                out imitationLearning);

            object[] arg = new object[1];
            if (success)
            {
                List<TrainingData> trainingData = new List<TrainingData>();
                foreach (Data data in datas)
                    foreach (Track track in tracks)
                    {
                        string trackName = track == Track.PREF ? (string) imitationLearning[3] : track.ToString();
                        TrainingData training = new TrainingData(data, track, trackName, solver, featureType,
                            _trainingDirectoy, _workingDirectory);
                        FileInfo file = new FileInfo(training.FileName.Replace("Global", "Local"));
                        if (file.Exists)
                            trainingData.Add(training);
                        else
                        {
                            info += Environment.NewLine + String.Format("{0} missing", file.Name);
                            success = false;
                        }
                    }
                arg[0] = trainingData.ToArray();
            }
            object args = arg;

            switch (startAsyncButtonFeatTrData.Text)
            {
                case ButtonTextValidate:
                    richTextBox.Text = info;
                    if (!success)
                    {
                        return;
                    }
                    startAsyncButtonFeatTrData.Text = ButtonTextStart;
                    richTextBox.AppendText("\nValidation successful.\n");
                    break;
                case ButtonTextStart:
                    while (bkgWorkerFeatTrData.IsBusy)
                    {
                        /* wait */
                    }

                    richTextBoxConsole.Text = "";
                    richTextBox.Text = info;

                    bkgWorkerFeatTrData.RunWorkerAsync(args);
                    cancelAsyncButtonFeatTrData.Visible = true;
                    break;
            }
        }

        private void cancelAsyncButtonFeatTrData_Click(object sender, EventArgs e)
        {
            //notify bkg worker we want to cancel the operation.
            //this code doesn't actually cancel or kill the thread that is executing the job.
            bkgWorkerFeatTrData.CancelAsync();
            richTextBox.AppendText(
                "\n\nCancelling feature update of training data, i.e. preference pairs of features  ...");
            cancelAsyncButtonFeatTrData.Visible = false;
        }

        private void bkgWorkerFeatTrData_DoWork(object sender, DoWorkEventArgs e)
        {
            object[] arg = (object[]) e.Argument;
            TrainingData[] trainingData = (TrainingData[]) arg[0];

            #region full training data

            int iData = 0;
            foreach (TrainingData training in trainingData)
            {
                if (!training.ReadCSV(_optDirectory))
                {
                    FileInfo finfo = new FileInfo(training.FileName);
                    e.Result = "Failed reading " + finfo.Name;
                }
                else
                {
                    DateTime start = DateTime.Now;
                    TimeSpan duration;

                    e.Result = string.Format("Generating {0} training data for {1}", training.FeatureType,
                        training.Track);
                    bkgWorkerFeatTrData.ReportProgress((int) (100.0*iData/trainingData.Length), e.Result);
                    e.Result = "";

                    for (int pid = 0; pid < training.NumInstances; pid++)
                    {
                        training.Retrace(pid);
                        if (bkgWorkerFeatTrData.CancellationPending)
                        {
                            duration = DateTime.Now - start;
                            string info = "\n\nDuration: " +
                                          duration.TotalSeconds.ToString(CultureInfo.InvariantCulture).Replace(',', '.') +
                                          " s.";
                            bkgWorkerFeatTrData.ReportProgress((int) (100.0*pid/training.NumInstances), info);
                            e.Cancel = true;
                            return;
                        }
                        bkgWorkerFeatTrData.ReportProgress((int) (100.0*pid/training.NumInstances));
                    }
                    // save current work 
                    training.WriteCSV(TrainingData.CSVType.Rank, new FileInfo(training.FileName));

                    duration = DateTime.Now - start;
                    e.Result = "Total duration: " +
                               duration.TotalSeconds.ToString(CultureInfo.InvariantCulture).Replace(',', '.') + " s.";
                    bkgWorkerFeatTrData.ReportProgress((int) (100.0*++iData/trainingData.Length), e.Result);
                }
            }

            #endregion
        }

        //This is executed after the task is complete whatever the task has completed: a) successfully, b) with error c) has been cancelled  
        private void bkgWorkerFeatTrData_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            if (e.Cancelled)
            {
                MessageBox.Show(startAsyncButtonFeatTrData.Text == ButtonTextResume
                    ? "The task has been paused."
                    : "The task has been cancelled.");
            }
            else if (e.Error != null)
            {
                MessageBox.Show(@"Error. Details: " + e.Error);
            }
            else
            {
                MessageBox.Show(String.Format("{0}. {1}", MsgTaskComplete, e.Result));
                cancelAsyncButtonFeatTrData.Visible = false;
                startAsyncButtonFeatTrData.Text = ButtonTextValidate;
            }
        }

        private void buttonSimpleBDR_Click(object sender, EventArgs e)
        {
            textBoxDir.Text = @"BDR";

            string info;
            SetWorkingDirectory(out _workingDirectory, out info);
            richTextBox.Text = info;

            Data[] problems;
            int splitStep;
            SDR firstSDR, secondSDR;
            if (!SimpleTabBDR(out problems, out splitStep, out firstSDR, out secondSDR, out info))
            {
                richTextBox.Text = String.Format("Error: {0}\n", info);
                return;
            }
            richTextBox.AppendText(info);

            #region apply SDR

            DateTime start = DateTime.Now;
            int iter = 0;
            int totIter = problems.Length;
            progressBarOuter.Value = 0;
            foreach (Data problem in problems.Where(problem => problem != null))
            {
                richTextBox.AppendText(String.Format("\n{0}.{1}.{2}\n", problem.Name, problem.Dimension, problem.Set));

                string nameSDR = string.Format("{0}.{1}.{2}proc", firstSDR, secondSDR, splitStep);

                Data optData = problem;
                optData.ReadCsvOpt(_optDirectory);
                progressBarInner.Value = 0;

                richTextBox.AppendText(nameSDR + " applied.\n");
                for (int id = 0; id < problem.NumInstances; id++)
                {
                    var prob = problem.Rows[id];
                    string name = (string) prob["Name"];
                    Schedule jssp = new Schedule((ProblemInstance) prob["Problem"]);
                    jssp.ApplySplitSDR(firstSDR, secondSDR, splitStep);

                    DataRow optRow = optData.Rows.Find(name);
                    int optMakespan = optRow != null ? (int) optRow["Makespan"] : int.MinValue;

                    problem.AddHeuristicMakespan(name, jssp.Makespan, optMakespan, nameSDR);
                    
                    progressBarInner.Value = (int) (100.0*id/problem.NumInstances); //update progress bar  
                }
                // fin
                problem.WriteCsvSDR(nameSDR, _bdrDirectory);

                progressBarInner.Value = 100;
                progressBarOuter.Value = (int) (100.0*(++iter)/totIter);
            }
            TimeSpan duration = DateTime.Now - start;
            info = SEPERATION_LINE + "Duration: " +
                   duration.TotalSeconds.ToString(CultureInfo.InvariantCulture).Replace(',', '.') + " s." +
                   SEPERATION_LINE;
            richTextBox.AppendText(info);

            progressBarOuter.Value = 100;

            #endregion
        }

        private void btnLocalReset_Click(object sender, EventArgs e)
        {
            tbLocal0.Text = @"0";
            tbLocal1.Text = @"0";
            tbLocal2.Text = @"0";
            tbLocal3.Text = @"0";
            tbLocal4.Text = @"0";
            tbLocal5.Text = @"0";
            tbLocal6.Text = @"0";
            tbLocal7.Text = @"0";
            tbLocal8.Text = @"0";
            tbLocal9.Text = @"0";
            tbLocal10.Text = @"0";
            tbLocal11.Text = @"0";
            tbLocal12.Text = @"0";
            tbLocal13.Text = @"0";
            tbLocal14.Text = @"0";
            tbLocal15.Text = @"0";
            tbLocal16.Text = @"0";
            tbLocal17.Text = @"0";
            tbLocal18.Text = @"0";
        }

        private void btnLocalApply_Click(object sender, EventArgs e)
        {
            //textBoxDir.Text = "wip";

            string info;
            SetWorkingDirectory(out _workingDirectory, out info);
            richTextBox.Text = info;

            Data[] problems;
            if (!SimpleTabLin(out problems, out info))
            {
                richTextBox.Text = String.Format("Error: {0}\n", info);
                return;
            }
            richTextBox.AppendText(info);

            LinearModel linear = SimpleTabLinReadInputWeights(out info);
            richTextBox.AppendText(info);

            string modelName = "user";
            for (int i = 0; i < (int) LocalFeature.Count; i++)
            {
                if (Math.Abs(linear.Weights.Local[i][0]) > 0.001)
                    modelName += String.Format(".{0}{1:0.000}", (LocalFeature) i, linear.Weights.Local[i])
                        .Replace(',', '_');
            }

            #region apply SDR

            DateTime start = DateTime.Now;
            int iter = 0;
            int totIter = problems.Length;
            progressBarOuter.Value = 0;
            foreach (Data problem in problems)
            {
                if (problem == null)
                    continue;

                richTextBox.AppendText(String.Format("\n{0}.{1}.{2}\n", problem.Name, problem.Dimension, problem.Set));

                Data optData = problem;
                optData.ReadCsvOpt(_optDirectory);
                progressBarInner.Value = 0;

                richTextBox.AppendText(modelName + " applied.\n");
                for (int id = 0; id < problem.NumInstances; id++)
                {
                    var prob = problem.Rows[id];
                    string name = (string) prob["Name"];
                    Schedule jssp = new Schedule((ProblemInstance) prob["Problem"]);
                    jssp.ApplyMethod(linear, FeatureType.Local);

                    DataRow optRow = optData.Rows.Find(name);
                    int optMakespan = optRow != null ? (int) optRow["Makespan"] : int.MinValue;

                    problem.AddHeuristicMakespan(name, jssp.Makespan, optMakespan, modelName);

                    info = name;
                    string errorMsg;
                    if (jssp.Validate(out errorMsg, true))
                        info = " Cmax: " + jssp.Makespan.ToString() + "\n";
                    else
                        info += " ERROR: Invalid solution reported: " + errorMsg + "\n";

                    richTextBox.AppendText(info);
                    progressBarInner.Value = (int) (100.0*id/problem.NumInstances); //update progress bar  
                }
                // fin
                problem.WriteCsvSDR(modelName, _workingDirectory);

                progressBarInner.Value = 100;
                progressBarOuter.Value = (int) (100.0*(++iter)/totIter);
            }
            TimeSpan duration = DateTime.Now - start;
            info = SEPERATION_LINE + "Duration: " +
                   duration.TotalSeconds.ToString(CultureInfo.InvariantCulture).Replace(',', '.') + " s." +
                   SEPERATION_LINE;
            richTextBox.AppendText(info);

            progressBarOuter.Value = 100;

            #endregion
        }

        private bool FindLiblinearLogFiles(string problemName, string dimension, EventArgs e)
        {
            comboBoxLiblinearLogs_Update(new object[] {problemName, dimension}, e);
            if (comboBoxLiblinearLogs.Items.Count != 0) return true;
            richTextBox.Text =
                String.Format(
                    "Error: Missing log file for precomputed weights. Run LiblineaR script in R first and save in desired directory. (Currently set as {0}weights)\n",
                    _prefDirectory);
            return false;
        }

        private void buttonApplyLiblinearLogs_Click(object sender, EventArgs e)
        {
            //textBoxDir.Text = "wip";

            string info;
            Data[] problems;
            if (!SimpleTabLin(out problems, out info))
            {
                richTextBox.Text = "Error: " + info + "\n";
                return;
            }
            richTextBox.AppendText(info);

            foreach (Data problem in problems)
            {
                if (problem == null) continue;

                if (!FindLiblinearLogFiles(problem.Name, problem.Dimension, e))
                    return;

                List<FileInfo> weights = new List<FileInfo>();
                int alreadyDone = 0;
                if (comboBoxLiblinearLogs.SelectedIndex == -1)
                {
                    foreach (var item in comboBoxLiblinearLogs.Items)
                    {
                        FileInfo weight = new FileInfo(String.Format("{0}weights\\{1}.csv", _prefDirectory, item));
                        FileInfo summaryFile =
                            new FileInfo(String.Format("{0}summary\\{1}", _prefDirectory, weight.Name));
                        if (!summaryFile.Exists & weight.Exists) weights.Add(weight);
                        else if (summaryFile.Exists) alreadyDone++;
                    }
                }
                else
                {
                    FileInfo logFile =
                        new FileInfo(String.Format("{0}weights\\{1}.csv", _prefDirectory,
                            comboBoxLiblinearLogs.Items[comboBoxLiblinearLogs.SelectedIndex]));
                    FileInfo summaryFile =
                        new FileInfo(String.Format("{0}summary\\{1}", _prefDirectory, logFile.Name));
                    if (!summaryFile.Exists & logFile.Exists) weights.Add(logFile);
                    else if (summaryFile.Exists) alreadyDone++;
                }

                if (weights.Count == 0)
                {
                    if (alreadyDone > 0)
                        richTextBox.AppendText(String.Format("Already done {0} models for {1}, see summary files",
                            alreadyDone, problem.Name));
                    else
                    {
                        richTextBox.Text = @"Error: Missing logged weight file for precomputed weights\n";
                        return;
                    }
                }

                DateTime start = DateTime.Now;
                int outerIter = 0;
                progressBarOuter.Value = 0;

                foreach (FileInfo weight in weights)
                {
                    LinearWeight[] loggedWeights = AuxFun.ReadLoggedLinearWeights(weight);
                    if (loggedWeights == null) continue;

                    richTextBox.AppendText(string.Format("{0}\n", weight.Name));

                    LinearModel[] loggedModels = new LinearModel[loggedWeights.Length];
                    for (int i = 0; i < loggedWeights.Length; i++)
                        loggedModels[i] = new LinearModel(loggedWeights[i].Local, loggedWeights[i].Name);

                    #region apply linear weights

                    int iter = 0;
                    progressBarInner.Value = 0;

                    problem.NumInstances = Math.Min(500, problem.NumInstances); // limit to the first 500 examples
                    richTextBox.AppendText(String.Format("{0}.{1}.{2}\n", problem.Name, problem.Dimension, problem.Set));

                    Data optData = problem;
                    optData.ReadCsvOpt(_optDirectory);

                    foreach (LinearModel linear in loggedModels)
                    {
                        #region apply model to problem

                        FileInfo file =
                            new FileInfo(String.Format("{0}CDR\\{1}.on.{2}.{3}.{4}.csv", _prefDirectory, linear.Name,
                                problem.Name, problem.Dimension, problem.Set));
                        if (!file.Exists)
                        {
                            //richTextBox.AppendText(linear.Name + " applied.\n");
                            for (int id = 0; id < problem.NumInstances; id++)
                            {
                                var prob = problem.Rows[id];
                                string name = (string) prob["Name"];
                                Schedule jssp = new Schedule((ProblemInstance) prob["Problem"]);
                                jssp.ApplyMethod(linear, FeatureType.Local);

                                DataRow optRow = optData.Rows.Find(name);
                                int optMakespan = optRow != null ? (int) optRow["Makespan"] : int.MinValue;

                                problem.AddHeuristicMakespan(name, jssp.Makespan, optMakespan, linear.Name);
                            }
                            // fin
                            problem.WriteCsvHeuristic(file);
                        }
                        progressBarInner.Value = (int) (100.0*(++iter)/loggedModels.Length);

                        #endregion
                    }
                    progressBarInner.Value = 100;
                    progressBarOuter.Value = (int) (100.0*(++outerIter)/weights.Count);

                    #endregion
                }
                progressBarOuter.Value = 100;

                TimeSpan duration = DateTime.Now - start;
                info = SEPERATION_LINE + "Duration: " +
                       duration.TotalSeconds.ToString(CultureInfo.InvariantCulture).Replace(',', '.') + " s." +
                       SEPERATION_LINE;
                richTextBox.AppendText(info);
            }
        }

        private void startAsyncButtonCMA_click(object sender, EventArgs e)
        {
            Data[] data;
            string info;
            bool dependentModel;
            string strfitnessfct;
            bool success = ValidateCMA(out data, out info, out dependentModel, out strfitnessfct);

            object[] arg = new object[3];
            arg[0] = data;
            arg[1] = dependentModel;
            arg[2] = strfitnessfct;
            object args = arg;

            switch (startAsyncButtonCMA.Text)
            {
                case ButtonTextValidate:
                    richTextBox.Text = info;
                    if (!success)
                    {
                        return;
                    }
                    startAsyncButtonCMA.Text = ButtonTextStart;
                    break;
                case ButtonTextStart:
                    while (bkgWorkerCMA.IsBusy)
                    {
                        /* wait */
                    }

                    richTextBox.Text = "";
                    richTextBoxConsole.Text = "";
                    richTextBox.Text = info;

                    bkgWorkerCMA.RunWorkerAsync(args);
                    cancelAsyncButtonCMA.Visible = true;
                    break;
            }
        }

        private void cancelAsyncButtonCMA_click(object sender, EventArgs e)
        {
            //notify bkg worker we want to cancel the operation.
            //this code doesn't actually cancel or kill the thread that is executing the job.
            bkgWorkerGenTrData.CancelAsync();
            richTextBox.AppendText("\n\nCancelling generation of training data, i.e. preference pairs of features  ...");
            cancelAsyncButtonGenTrData.Visible = false;
        }


        private bool ValidateCMA(out Data[] trainingData, out string info, out bool depdendentModel, out string strfitnessfct)
        {
            depdendentModel = radioButtonCMADependent.Checked;
            strfitnessfct = radioButtonCMAwrtMakespan.Checked ? "MinimumMakespan" : "MinimumRho";

            trainingData = null;
            List<string> dims = new List<string>();

            // Get selected index, and then make sure it is valid.
            info = "Creating CMA-ES model ...";
            
            info += "\nDimensions: ";
            foreach (int selected in ckbDimCMA.CheckedIndices)
            {
                string dim = SimpleDimName(ckbDimCMA.Items[selected].ToString());
                info += " " + dim;
                dims.Add(dim);
            }
            if (!dims.Any())
            {
                info = "Error, must at least choose one dimension for problem instances' features.";
                return false;
            }
            info += "\n";

            List<string> trainInstances = new List<string>();
            info += "\nProblem instances: ";
            foreach (string dimStr in dims)
            {
                string fnameEnd = "." + dimStr + ".train.txt";
                foreach (int selected in ckbProblemCMA.CheckedIndices)
                {
                    string problem = ckbProblemCMA.Items[selected].ToString();
                    info += " " + problem + "." + dimStr;

                    if (!File.Exists(_dataDirectory + problem + fnameEnd))
                    {
                        info = "Error, problem reading " + problem + ", files cannot be located in directory:\n" +
                               _dataDirectory;
                        return false;
                    }
                    trainInstances.Add(problem + fnameEnd);
                }
            }
            if (!trainInstances.Any())
            {
                info = "Error, must choose at least one problem distribution for collecting training data.";
                return false;
            }

            trainingData = new Data[trainInstances.Count];
            for (int i = 0; i < trainInstances.Count; i++)
            {
                AuxFun.ReadRawData(trainInstances[i], _dataDirectory, out trainingData[i]);
                trainingData[i].ReadCsvOpt(_optDirectory);
            }
            return true;
        }



        //This method is executed in a separate thread created by the background worker.  
        //so don't try to access any UI controls here!! (unless you use a delegate to do it)  
        //this attribute will prevent the debugger to stop here if any exception is raised.  
        //[System.Diagnostics.DebuggerNonUserCodeAttribute()]  
        private void bkgWorkerCMA_DoWork(object sender, DoWorkEventArgs e)
        {
            //NOTE: we shouldn't use a try catch block here (unless you rethrow the exception)  
            //the background worker will be able to detect any exception on this code.  
            //if any exception is produced, it will be available to you on   
            //the RunWorkerCompletedEventArgs object, method bkgWorkerPrefModel_RunWorkerCompleted  

            object[] arg = (object[]) e.Argument;
            Data[] distributions = (Data[]) arg[0];
            bool dependentModel = (bool) arg[1];
            string strfitnessfct = (string) arg[2];

            int iData = 0;
            foreach (Data data in distributions)
            {
                string distribution = data.Name;
                bkgWorkerCMA.ReportProgress((int) (100.0*iData/distributions.Length),
                    String.Format("{0}{1}\n", SEPERATION_LINE, distribution));
                
                CMAES cmaes = new CMAES(data, strfitnessfct, dependentModel, _cmaDirectory);
                
                DateTime start = DateTime.Now;
                Stopwatch autoSave = new Stopwatch();
                autoSave.Start();
                TimeSpan duration;
                e.Result = "";
                bkgWorkerCMA.ReportProgress((int) (100.0*iData/distributions.Length),
                    String.Format("Generating CMA-ES optimisation w.r.t. {0} ...", strfitnessfct));

                while (!cmaes.OptimistationComplete)
                {
                    double currentMinimum;
                    cmaes.Optimize(out currentMinimum, true); //do some intense task here.

                    if (bkgWorkerGenTrData.CancellationPending)
                    {
                        duration = DateTime.Now - start;
                        string info = String.Format("\n\nDuration: {0:0} s.", duration.TotalSeconds);
                        cmaes.WriteResultsCSV();
                        bkgWorkerCMA.ReportProgress((int) (100.0*cmaes.CountEval/cmaes.StopEval), info);
                        e.Cancel = true;
                        return;
                    }
                    bkgWorkerCMA.ReportProgress((int) (100.0*cmaes.CountEval/cmaes.StopEval), cmaes.Step);

                    if (autoSave.ElapsedMilliseconds <= HALFHOUR) continue;
                    cmaes.WriteResultsCSV();
                    autoSave.Restart();
                }

                // save current work 
                duration = DateTime.Now - start;
                e.Result = "Total duration: " +
                           duration.TotalSeconds.ToString(CultureInfo.InvariantCulture).Replace(',', '.') + " s.";
                cmaes.WriteFinalResultsCSV();
                bkgWorkerCMA.ReportProgress((int)(100.0 * ++iData / distributions.Length), e.Result);
            }
        }

        //This is executed after the task is complete whatever the task has completed: a) successfully, b) with error c) has been cancelled  
        private void bkgWorkerCMA_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            if (e.Cancelled)
            {
                MessageBox.Show(startAsyncButtonCMA.Text == ButtonTextResume
                    ? "The task has been paused."
                    : "The task has been cancelled.");
            }
            else if (e.Error != null)
            {
                MessageBox.Show(@"Error. Details: " + e.Error);
            }
            else
            {
                MessageBox.Show(String.Format("{0}. {1}", MsgTaskComplete, e.Result));
                cancelAsyncButtonCMA.Visible = false;
                startAsyncButtonCMA.Text = ButtonTextValidate;
            }
        }


  
    }
}