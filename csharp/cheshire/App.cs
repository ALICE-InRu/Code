using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.Globalization;
using System.Windows.Forms;
using ALICE;

namespace Chesire
{
    public partial class App : Form
    {
        private const int HALFHOUR = 30*60*1000; // ms

        private const string SEPERATION_LINE = "\n++++++++++++++++++++++++\n";

        public App()
        {
            InitializeComponent();
            InitializeBackgroundWorker();
            Icon ico = new Icon(String.Format(@"C:\users\helga\alice\Code\csharp\cheshire\Resources\chesirecat.ico"));
            Icon = ico;
        }

        private void App_Load(object sender, EventArgs e)
        {
            richTextBox.Text = @"Welcome!";
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

        private void richTextBox_TextChanged(object sender, EventArgs e)
        {
            richTextBox.SelectionStart = richTextBox.Text.Length;
            richTextBox.ScrollToCaret();
            richTextBoxConsole.SelectionStart = richTextBoxConsole.Text.Length;
            richTextBoxConsole.ScrollToCaret();
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
                    pictureBox.Image.Save(name, ImageFormat.Bmp);
                }
            }
        }

        #endregion

        #region tab: simple priority dispatching rules and optimize


        private void buttonSDRStart_Click(object sender, EventArgs e)
        {
            throw new NotImplementedException();

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

            progressBarOuter.Value = 0;
            DateTime start = DateTime.Now;
            int iter = 0;
            foreach (SDR sdr in sdrs)
            {
                SDRData sdrData = new SDRData("j.rnd", "10x10", "test", sdr);
                richTextBox.AppendText(String.Format("\nApplying {0}", sdrData.FileInfo.Name));
                if (radioSimpleProblemsSingle.Checked)
                {
                    Schedule jssp = sdrData.Apply((int) numericUpDownInstanceID.Value);
                    //if (!File.Exists(filePath + ".gif") | !File.Exists(filePath + ".jpg"))
                    //    jssp.PlotSchedule(pictureBox.Width, pictureBox.Height, filePath);
                    try
                    {
                        //pictureBox.Image = Image.FromFile(filePath + ".gif");
                    }
                    catch
                    {
                        //pictureBox.Image = Image.FromFile(filePath + ".jpg");
                    }
                    richTextBox.AppendText(String.Format("\n{0}", jssp.PrintSchedule()));
                }
                else
                {
                    sdrData.Apply();
                }
                progressBarInner.Value = 100;
                progressBarOuter.Value = (int) (100.0*(++iter)/sdrs.Count);
            }
            richTextBox.AppendText(String.Format("\n\nDuration: {1:0}s {0}", SEPERATION_LINE,
                (DateTime.Now - start).TotalSeconds));
            progressBarOuter.Value = 100;

            #endregion
        }

        #endregion

        #region backgroundworkers

        #region bkgWorkerGenTrData

        #region start / stop

        private const string MSG_TASK_COMPLETE = "The task has been completed";

        private void startAsyncButtonGenTrData_Click(object sender, EventArgs e)
        {
            throw new NotImplementedException();

            richTextBox.Text = "";
            richTextBoxConsole.Text = "";

            TrainingSet trSet = new TrainingSet("j.rnd", "10x10", "SPT", false);
            if (trSet.AlreadyAutoSavedPID >= trSet.NumInstances)
            {
                richTextBox.AppendText(String.Format("\n{0} already exists", trSet.FileInfo));
                return; // already completed 
            }
            trSet.CollectTrainingSet(trSet.AlreadyAutoSavedPID + 1);

            while (bkgWorkerTrSet.IsBusy)
            {
                /* wait */
            }
            
            bkgWorkerTrSet.RunWorkerAsync(trSet);
            cancelAsyncButtonGenTrData.Visible = true;
        }

        private void cancelAsyncButtonGenTrData_Click(object sender, EventArgs e)
        {
            //notify bkg worker we want to cancel the operation.
            //this code doesn't actually cancel or kill the thread that is executing the job.
            bkgWorkerTrSet.CancelAsync();
            richTextBox.AppendText("\n\nCancelling generation of training data, i.e. preference pairs of features  ...");
            cancelAsyncButtonGenTrData.Visible = false;
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

            TrainingSet[] trsets = (TrainingSet[]) e.Argument;
            DateTime start = DateTime.Now;
            Stopwatch autoSave = new Stopwatch();
            autoSave.Start();
            e.Result = "";
            int iter = 0;
            foreach (TrainingSet trset in trsets)
            {
                bkgWorkerTrSet.ReportProgress((int) (100.0*iter/trsets.Length),
                    String.Format("Generating training data for {0} ...", trset.FileInfo.Name));

                for (int pid = trset.AlreadyAutoSavedPID + 1; pid < trset.NumInstances; pid++)
                {
                    string info = trset.CollectTrainingSet(pid); // intense task 
                    bkgWorkerTrSet.ReportProgress((int) (100.0*pid/trset.NumInstances), info);
                    if (bkgWorkerTrSet.CancellationPending)
                    {
                        trset.Write();
                        bkgWorkerTrSet.ReportProgress((int) (100.0*pid/trset.NumInstances),
                            String.Format("\n\nDuration: {0:0}min.", (DateTime.Now - start).Minutes));
                        e.Cancel = true;
                        return;
                    }
                    if (autoSave.ElapsedMilliseconds <= HALFHOUR) continue;
                    trset.Write(); 
                    autoSave.Restart();
                } 
                trset.Write();
                bkgWorkerTrSet.ReportProgress((int) (100.0*++iter/trsets.Length), e.Result);
                e.Result = String.Format("{0} total duration: {1:0} s.", trset.FileInfo.Name, (DateTime.Now - start).TotalMinutes);
            }
        }

        //This is executed after the task is complete whatever the task has completed: a) successfully, b) with error c) has been cancelled  
        private void bkgWorkerGenTrData_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            if (e.Cancelled)
            {
                MessageBox.Show(@"The task has been cancelled.");
            }
            else if (e.Error != null)
            {
                MessageBox.Show(@"Error. Details: " + e.Error);
            }
            else
            {
                MessageBox.Show(String.Format("{0}. {1}", MSG_TASK_COMPLETE, e.Result));
                cancelAsyncButtonGenTrData.Visible = false;
            }
        }

        #endregion

        #region bkgWorkerOptimize

        #region stop /stop

        private void startAsyncButtonOptimize_Click(object sender, EventArgs e)
        {
            throw new NotImplementedException();

            OPTData opt = new OPTData("j.rnd", "10x10", "test", 1000);

            while (bkgWorkerGurobi.IsBusy)
            {
                /* wait */
            }

            richTextBox.Text = "";
            richTextBoxConsole.Text = "";

            bkgWorkerGurobi.RunWorkerAsync(opt);
            cancelAsyncButtonOptimize.Visible = true;
        }

        #endregion

        private void cancelAsyncButtonOptimize_Click(object sender, EventArgs e)
        {
            bkgWorkerGurobi.CancelAsync();
            richTextBox.AppendText("\n\nCancelling optimization...");
            cancelAsyncButtonOptimize.Visible = false;
        }

        #endregion

        private void bkgWorkerOptimize_DoWork(object sender, DoWorkEventArgs e)
        {
            OPTData[] opts = (OPTData[]) e.Argument;
            int iter = 0;
            foreach (OPTData opt in opts)
            {
                DateTime start = DateTime.Now;
                e.Result = "";
                bkgWorkerGurobi.ReportProgress(0,
                    string.Format("Optimising {0} with time limit {1}min", opt.FileInfo.Name, opt.TimeLimit/60));
                string info;
                for (int pid = opt.AlreadyAutoSavedPID + 1; pid < opt.NumInstances; pid++)
                {
                    info = opt.Optimise(pid);
                    bkgWorkerGurobi.ReportProgress((int) (100.0*pid/opt.NumInstances), info);

                    if (bkgWorkerGurobi.CancellationPending)
                    {
                        info = String.Format("\n\nDuration: {0:0}", (DateTime.Now - start).TotalMinutes);
                        bkgWorkerGurobi.ReportProgress((int) (100.0*pid/opt.NumInstances), info);
                        e.Cancel = true;
                        return;
                    }
                }
                opt.Write();
                bkgWorkerGurobi.ReportProgress((int) (100.0*++iter/opts.Length), e.Result);
                e.Result = String.Format("{0} total duration: {1:0} s.", opt.FileInfo.Name,
                    (DateTime.Now - start).TotalMinutes);
            }
        }

        private void bkgWorkerOptimize_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            if (e.Cancelled)
            {
                MessageBox.Show(@"The task has been cancelled.");
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

                MessageBox.Show(String.Format("{0}. {1}", MSG_TASK_COMPLETE, e.Result));
                cancelAsyncButtonOptimize.Visible = false;
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
        
        #endregion

        #region bkgWorkerRankTrData

        private void startAsyncButtonRankTrData_Click(object sender, EventArgs e)
        {
            throw new NotImplementedException(); 
            PreferenceSet prefSet = new PreferenceSet("j.rnd", "6x5", "OPT", false, 'p');
            while (bkgWorkerPrefSet.IsBusy)
            {
                /* wait */
            }
            richTextBox.Text = "";
            richTextBoxConsole.Text = "";
            bkgWorkerPrefSet.RunWorkerAsync(prefSet);
            cancelAsyncButtonRankTrData.Visible = true;
        }

        private void cancelAsyncButtonRankTrData_Click(object sender, EventArgs e)
        {
            bkgWorkerPrefSet.CancelAsync();
            richTextBox.AppendText("\n\nCancelling ranking of training data, i.e. preference pairs of features  ...");
            cancelAsyncButtonRankTrData.Visible = false;
        }

        private void bkgWorkerRankTrData_DoWork(object sender, DoWorkEventArgs e)
        {
            //NOTE: we shouldn't use a try catch block here (unless you rethrow the exception)  
            //the background worker will be able to detect any exception on this code.  
            //if any exception is produced, it will be available to you on   
            //the RunWorkerCompletedEventArgs object, method bkgWorkerPrefModel_RunWorkerCompleted  

            PreferenceSet[] prefs = (PreferenceSet[]) e.Argument;
            DateTime start = DateTime.Now;
            e.Result = "";
            int iter = 0;
            foreach (PreferenceSet pref in prefs)
            {
                bkgWorkerPrefSet.ReportProgress(0, String.Format("\n{0}", pref.FileInfo.Name));

                for (int pid = 0; pid < pref.NumInstances; pid++)
                {
                    string info = pref.CreatePreferencePairs(pid); //do some intense task here.
                    bkgWorkerPrefSet.ReportProgress((int) (100.0*pid/pref.NumInstances), info);

                    if (!bkgWorkerPrefSet.CancellationPending) continue;
                    TimeSpan duration = DateTime.Now - start;
                    info = "Duration: " +
                           duration.TotalSeconds.ToString(CultureInfo.InvariantCulture)
                               .Replace(',', '.') +
                           " s.";
                    bkgWorkerPrefSet.ReportProgress((int) (100.0*iter/prefs.Length), info);
                    e.Cancel = true;
                    return;
                }
                bkgWorkerPrefSet.ReportProgress((int) (100.0*++iter/prefs.Length), e.Result);
            }
        }

        //This is executed after the task is complete whatever the task has completed: a) successfully, b) with error c) has been cancelled  
        private void bkgWorkerRankTrData_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            if (e.Cancelled)
            {
                MessageBox.Show(@"The task has been cancelled.");
            }
            else if (e.Error != null)
            {
                MessageBox.Show(@"Error. Details: " + e.Error);
            }
            else
            {
                MessageBox.Show(string.Format("The task has been completed. {0}", e.Result));
                cancelAsyncButtonRankTrData.Visible = false;
            }
        }

        #endregion

        
        private void startAsyncButtonFeatTrData_Click(object sender, EventArgs e)
        {
            throw new NotImplementedException();

            while (bkgWorkerRetrace.IsBusy)
            {
                /* wait */
            }

            richTextBoxConsole.Text = "";
            richTextBox.Text = "";

            //bkgWorkerFeatTrData.RunWorkerAsync(args);
            cancelAsyncButtonFeatTrData.Visible = true;
        }


        private void cancelAsyncButtonFeatTrData_Click(object sender, EventArgs e)
        {
            //notify bkg worker we want to cancel the operation.
            //this code doesn't actually cancel or kill the thread that is executing the job.
            bkgWorkerRetrace.CancelAsync();
            richTextBox.AppendText(
                "\n\nCancelling feature update of training data, i.e. preference pairs of features  ...");
            cancelAsyncButtonFeatTrData.Visible = false;
        }

        private void bkgWorkerFeatTrData_DoWork(object sender, DoWorkEventArgs e)
        {
            // object[] arg = (object[]) e.Argument;
            bkgWorkerRetrace.ReportProgress((int) (0), e.Result);
            throw new NotImplementedException();
        }

        //This is executed after the task is complete whatever the task has completed: a) successfully, b) with error c) has been cancelled  
        private void bkgWorkerFeatTrData_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            if (e.Cancelled)
            {
                MessageBox.Show(@"The task has been cancelled.");
            }
            else if (e.Error != null)
            {
                MessageBox.Show(@"Error. Details: " + e.Error);
            }
            else
            {
                MessageBox.Show(String.Format("{0}. {1}", MSG_TASK_COMPLETE, e.Result));
                cancelAsyncButtonFeatTrData.Visible = false;
            }
        }

        private void buttonSimpleBDR_Click(object sender, EventArgs e)
        {
            throw new NotImplementedException();
        }

        private void startAsyncButtonCMA_click(object sender, EventArgs e)
        {
            CMAESData cmaes = new CMAESData("j.rnd", "10x10", "MinimumMakespan", false);

            while (bkgWorkerCMAES.IsBusy)
            {
                /* wait */
            }

            richTextBox.Text = "";
            richTextBoxConsole.Text = "";

            bkgWorkerCMAES.RunWorkerAsync(cmaes);
            cancelAsyncButtonCMA.Visible = true;
        }

        private void cancelAsyncButtonCMA_click(object sender, EventArgs e)
        {
            //notify bkg worker we want to cancel the operation.
            //this code doesn't actually cancel or kill the thread that is executing the job.
            bkgWorkerTrSet.CancelAsync();
            richTextBox.AppendText("\n\nCancelling generation of training data, i.e. preference pairs of features  ...");
            cancelAsyncButtonGenTrData.Visible = false;
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

            CMAESData[] cmaesDatas = (CMAESData[]) e.Argument;
            int iData = 0;
            foreach (var cmaes in cmaesDatas)
            {
                bkgWorkerCMAES.ReportProgress((int) (100.0*iData/cmaesDatas.Length),
                    String.Format("{0}{1}\n", SEPERATION_LINE, cmaes.FileInfo.Name));

                DateTime start = DateTime.Now;
                Stopwatch autoSave = new Stopwatch();
                autoSave.Start();
                e.Result = "";

                while (!cmaes.OptimistationComplete)
                {
                    double currentMinimum;
                    cmaes.Optimize(out currentMinimum, true); //do some intense task here.

                    if (bkgWorkerTrSet.CancellationPending)
                    {
                        string info = String.Format("\n\nDuration: {0:0} s.", (DateTime.Now - start).TotalSeconds);
                        cmaes.WriteResultsCSV();
                        bkgWorkerCMAES.ReportProgress((int) (100.0*cmaes.CountEval/cmaes.StopEval), info);
                        e.Cancel = true;
                        return;
                    }
                    bkgWorkerCMAES.ReportProgress((int) (100.0*cmaes.CountEval/cmaes.StopEval), cmaes.Step);

                    if (autoSave.ElapsedMilliseconds <= HALFHOUR) continue;
                    cmaes.WriteResultsCSV();
                    autoSave.Restart();
                }
                // save current work 
                cmaes.WriteFinalResultsCSV();
                e.Result = String.Format("Total duration: {0:0}min", (DateTime.Now - start).TotalMinutes);
                bkgWorkerCMAES.ReportProgress((int) (100.0*++iData/cmaesDatas.Length), e.Result);
            }
        }

        //This is executed after the task is complete whatever the task has completed: a) successfully, b) with error c) has been cancelled  
        private void bkgWorkerCMA_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            if (e.Cancelled)
            {
                MessageBox.Show(@"The task has been cancelled.");
            }
            else if (e.Error != null)
            {
                MessageBox.Show(@"Error. Details: " + e.Error);
            }
            else
            {
                MessageBox.Show(String.Format("{0}. {1}", MSG_TASK_COMPLETE, e.Result));
                cancelAsyncButtonCMA.Visible = false;
            }
        }

        private void buttonApplyLiblinearLogs_Click(object sender, EventArgs e)
        {
            throw new NotImplementedException();
        }
        
    }
}