using System;
using System.ComponentModel;
using System.Diagnostics.CodeAnalysis;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Windows.Forms;
using ALICE;

namespace Cheshire
{
    public partial class App : Form
    {
        private const int AUTOSAVE = 30; // minutes
        private static readonly DirectoryInfo DataDir = new DirectoryInfo(@"C:\users\helga\alice\Data");

        [SuppressMessage("ReSharper", "CoVariantArrayConversion")]
        public App()
        {
            InitializeComponent();
            InitializeBackgroundWorker();
            Icon ico = new Icon(String.Format(@"C:\users\helga\alice2\Code\csharp\cheshire\Resources\cheshirecat.ico"));
            Icon = ico;

            TimeLimit.Value = AUTOSAVE;
            Tracks.Items.AddRange(Enum.GetNames(typeof (TrainingSet.Trajectory)));
            Ranks.Items.AddRange(Enum.GetNames(typeof (PreferenceSet.Ranking)));
            Set.Items.AddRange(Enum.GetNames(typeof (RawData.DataSet)));
            SDR.Items.AddRange(Enum.GetNames(typeof (SDRData.SDR)));
            SDR1.Items.AddRange(Enum.GetNames(typeof (SDRData.SDR)));
            SDR2.Items.AddRange(Enum.GetNames(typeof (SDRData.SDR)));

            ApplyModel.SelectedIndex = 0;
            StepwiseBias.SelectedIndex = 0;
        }

        private void App_Load(object sender, EventArgs e)
        {
            textHeader.Text = @"Welcome!";
            PhiLocal.Select();

            cancelAsyncButtonTrSet.Visible = false;
            cancelAsyncButtonRetrace.Visible = false;
            cancelAsyncButtonRankTrData.Visible = false;
            cancelAsyncButtonOptimize.Visible = false;
            cancelAsyncButtonCMA.Visible = false;
            cancelAsyncButtonApply.Visible = false;
            cancelAsyncButtonTrAcc.Visible = false;

            IndependentModel.Select();
            CMAwrtRho.Select();
            PhiLocal.Select();

        }

        #region general

        //private void OnOutputDataReceived(object sender, DataReceivedEventArgs e)
        //{
        //    //Never gets called...
        //}

        private void textContent_TextChanged(object sender, EventArgs e)
        {
            var richTextBox = (RichTextBox) sender;
            richTextBox.SelectionStart = richTextBox.Text.Length;
            richTextBox.ScrollToCaret();
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

        #endregion



        private void buttonSDRStart_Click(object sender, EventArgs e)
        {
            SDRData[] sets = (from set in Set.CheckedItems.Cast<string>()
                from dim in Dimension.CheckedItems.Cast<string>()
                from problem in Problems.CheckedItems.Cast<string>()
                from sdr in SDR.CheckedItems.Cast<string>()
                select
                    new SDRData(problem, dim, (RawData.DataSet) Enum.Parse(typeof (RawData.DataSet), set),
                        Extended.CheckedItems.Count > 0, (SDRData.SDR) Enum.Parse(typeof (SDRData.SDR), sdr), DataDir))
                .ToArray();

            if (sets.Length == 0)
            {
                textContent.AppendText("\nCannot apply SDR:");
                if (Problems.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one problem distribution.");
                if (Dimension.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one problem dimension.");
                if (Set.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least train or test set.");
                if (SDR.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one SDR.");
                textContent.AppendText("\n");
                return;
            }

            textHeader.AppendText(String.Format("\n{0} configurations: #{1}", sets.GetType(), sets.Length));
            sets = sets.Where(
                x => x.AlreadySavedPID < x.NumInstances).ToArray();

            int iter = 0;
            progressBarOuter.Value = 0;
            foreach (var set in sets)
            {
                progressBarInner.Value = 0;
                set.Apply();
                progressBarInner.Value = 100;
                progressBarOuter.Value = 100*(++iter/sets.Length);
                textContent.AppendText(String.Format("\n{0} updated for {1}:{2}", set.FileInfo.Name,
                    set.HeuristicName, set.HeuristicValue));
            }
            textHeader.AppendText(String.Format("\n{0} configurations: #{1} newly completed!", sets.GetType(),
                sets.Length));
        }


        #region backgroundworkers

        #region common work

        private void bkgWorker_ProgressChanged(object sender, ProgressChangedEventArgs e)
        {
            //This event is raised on the main thread.  
            //It is safe to access UI controls here.              
            object[] info = (object[]) e.UserState;
            bool valid = e.ProgressPercentage >= 0 & e.ProgressPercentage <= 100;
            if (Convert.ToInt32(info[0]) == 0)
            {
                progressBarOuter.Value = valid ? e.ProgressPercentage : 100;
                progressBarInner.Value = valid ? 100 : 0;
                textHeader.AppendText(String.Format("\n{0}", info[1]));
            }
            else
            {
                progressBarInner.Value = valid ? e.ProgressPercentage : 100;
                textContent.AppendText(String.Format("\n{0}", info[1]));
            }
        }

        //This is executed after the task is complete whatever the task has completed: a) successfully, b) with error c) has been cancelled  
        private void bkgWorker_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
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
                MessageBox.Show(String.Format("{0}. {1}", "The task has been completed", e.Result));
            }

            if (sender == bkgWorkerRetrace)
                cancelAsyncButtonRetrace.Visible = false;
            else if (sender == bkgWorkerCMAES)
                cancelAsyncButtonCMA.Visible = false;
            else if (sender == bkgWorkerOptimise)
                cancelAsyncButtonOptimize.Visible = false;
            else if (sender == bkgWorkerTrSet)
                cancelAsyncButtonTrSet.Visible = false;
            else if (sender == bkgWorkerPrefSet)
                cancelAsyncButtonRankTrData.Visible = false;
            else if (sender == bkgWorkerApply)
                cancelAsyncButtonApply.Visible = false;
            else if (sender == bkgWorkerTrAcc)
                cancelAsyncButtonTrAcc.Visible = false;
            else 
                throw new NotSupportedException();
        }

        private void cancelAsyncButton_Click(object sender, EventArgs e)
        {
            BackgroundWorker bkgWorker;
            if (sender == cancelAsyncButtonRetrace)
            {
                cancelAsyncButtonRetrace.Visible = false;
                textHeader.AppendText("\nCancelling feature update of training data...");
                bkgWorker = bkgWorkerRetrace;
            }
            else if (sender == cancelAsyncButtonCMA)
            {
                cancelAsyncButtonCMA.Visible = false;
                textHeader.AppendText("\nCancelling CMA-ES optimisation...");
                bkgWorker = bkgWorkerCMAES;
            }
            else if (sender == cancelAsyncButtonOptimize)
            {
                cancelAsyncButtonOptimize.Visible = false;
                textHeader.AppendText("\nCancelling optimization...");
                bkgWorker = bkgWorkerOptimise;
            }
            else if (sender == cancelAsyncButtonTrSet)
            {
                cancelAsyncButtonTrSet.Visible = false;
                textHeader.AppendText("\nCancelling collection of training data...");
                bkgWorker = bkgWorkerTrSet;
            }
            else if (sender == cancelAsyncButtonRankTrData)
            {
                cancelAsyncButtonRankTrData.Visible = false;
                textHeader.AppendText("\nCancelling ranking of training data...");
                bkgWorker = bkgWorkerPrefSet;
            }
            else if (sender == cancelAsyncButtonApply)
            {
                cancelAsyncButtonApply.Visible = false;
                textHeader.AppendText("\nCancelling application of models...");
                bkgWorker = bkgWorkerApply;
            }
            else if (sender == cancelAsyncButtonTrAcc)
            {
                cancelAsyncButtonTrAcc.Visible = false;
                textHeader.AppendText("\nCancelling accuracy of models...");
                bkgWorker = bkgWorkerTrAcc;
            }
            else throw new NotSupportedException();
            bkgWorker.CancelAsync();
        }

        #endregion

        #region bkgWorkerOptimize

        private void startAsyncButtonOptimize_Click(object sender, EventArgs e)
        {
            OPTData[] sets = (from set in Set.CheckedItems.Cast<string>()
                from dim in Dimension.CheckedItems.Cast<string>()
                from problem in Problems.CheckedItems.Cast<string>()
                select
                    new OPTData(problem, dim, (RawData.DataSet) Enum.Parse(typeof (RawData.DataSet), set),
                        Extended.CheckedItems.Count > 0, Convert.ToInt32(TimeLimit.Value),
                        DataDir)).ToArray();

            if (sets.Length == 0)
            {
                textContent.AppendText("\nCannot optimise set:");
                if (Problems.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one problem distribution.");
                if (Dimension.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one problem dimension.");
                if (Set.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least train or test set.");
                textContent.AppendText("\n");
                return;
            }

            while (bkgWorkerOptimise.IsBusy)
            {
                /* wait */
            }

            bkgWorkerOptimise.RunWorkerAsync(sets);
            cancelAsyncButtonOptimize.Visible = true;
        }

        //This method is executed in a separate thread created by the background worker.  
        //so don't try to access any UI controls here!! (unless you use a delegate to do it)  
        //this attribute will prevent the debugger to stop here if any exception is raised.  
        //[System.Diagnostics.DebuggerNonUserCodeAttribute()]  
        private void bkgWorkerOptimise_DoWork(object sender, DoWorkEventArgs e)
        {
            //NOTE: we shouldn't use a try catch block here (unless you rethrow the exception)  
            //the background worker will be able to detect any exception on this code.  
            //if any exception is produced, it will be available to you on   
            //the RunWorker completedEventArgs object, method bkgWorkerOptimise_RunWorker completed  

            BackgroundWorker bkgWorker = bkgWorkerOptimise; 
            OPTData[] sets = (OPTData[]) e.Argument;
            e.Result = "";
            int iter = 0;
            bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                new object[] {0, String.Format("{0} configurations: #{1}", sets.GetType(), sets.Length)});

            sets = sets.Where(x => x.AlreadySavedPID < x.NumInstances).ToArray();

            foreach (var set in sets)
            {
                DateTime start = DateTime.Now;
                DateTime autoSave = DateTime.Now;

                bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                    new object[] {0, String.Format("Starting optimising {0}", set.FileInfo.Name)});

                for (int pid = set.AlreadySavedPID + 1; pid <= set.NumInstances; pid++)
                {
                    string info = set.Optimise(pid);
                    bkgWorker.ReportProgress((int)(100.0 * pid / set.NumInstances),
                        new object[] {1, info});

                    if ((DateTime.Now - autoSave).TotalMinutes > AUTOSAVE | bkgWorker.CancellationPending)
                    {
                        bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                            new object[]
                            {
                                0,
                                String.Format("Auto saving {0} ({1:0}min {2} PIDS)", set.FileInfo.Name,
                                    (DateTime.Now - autoSave).TotalMinutes, pid - set.AlreadySavedPID)
                            });
                        set.Write();
                        autoSave = DateTime.Now;
                    }

                    if (!bkgWorker.CancellationPending) continue;
                    bkgWorker.ReportProgress((int)(100.0 * pid / set.NumInstances),
                        new object[] {1, String.Format("{0} cancelled!", set.FileInfo.Name)});
                    e.Cancel = true;
                    return;
                }
                set.Write();
                bkgWorker.ReportProgress((int)(100.0 * ++iter / sets.Length),
                    new object[]
                    {
                        0,
                        String.Format("Finished optimising {0} ({1:0}min)", set.FileInfo.Name,
                            (DateTime.Now - start).TotalMinutes)
                    });
            }
            bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                new object[]
                {0, String.Format("{0} configurations: #{1} newly completed!", sets.GetType(), sets.Length)});
        }

        #endregion

        #region bkgWorkerTrSet

        private void startAsyncButtonTrSet_Click(object sender, EventArgs e)
        {
            TrainingSet[] sets = (from track in Tracks.CheckedItems.Cast<string>()
                from dim in Dimension.CheckedItems.Cast<string>()
                from problem in Problems.CheckedItems.Cast<string>()
                select
                    new TrainingSet(problem, dim,
                        (TrainingSet.Trajectory) Enum.Parse(typeof (TrainingSet.Trajectory), track),
                        Extended.CheckedItems.Count > 0, DataDir)).ToArray();

            if (sets.Length == 0)
            {
                textContent.AppendText("\nCannot collect training set:");
                if (Problems.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one problem distribution.");
                if (Dimension.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one problem dimension.");
                if (Tracks.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one training trajectory.");
                textContent.AppendText("\n");
                return;
            }

            while (bkgWorkerTrSet.IsBusy)
            {
                /* wait */
            }
            bkgWorkerTrSet.RunWorkerAsync(sets);
            cancelAsyncButtonTrSet.Visible = true;
        }


        private void bkgWorkerTrSet_DoWork(object sender, DoWorkEventArgs e)
        {
            BackgroundWorker bkgWorker = bkgWorkerTrSet;
            TrainingSet[] sets = (TrainingSet[]) e.Argument;
            e.Result = "";
            int iter = 0;
            bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                new object[] {0, String.Format("{0} configurations: #{1}", sets.GetType(), sets.Length)});

            sets = sets.Where(x => x.AlreadySavedPID < x.NumInstances).ToArray();

            foreach (var set in sets)
            {
                DateTime start = DateTime.Now;
                DateTime autoSave = DateTime.Now;

                bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                    new object[] {0, String.Format("Starting collecting and labelling {0}", set.FileInfo.Name)});

                for (int pid = set.AlreadySavedPID + 1; pid <= set.NumInstances; pid++)
                {
                    string info = set.Apply(pid);
                    bkgWorker.ReportProgress((int)(100.0 * (pid % set.NumTraining) / set.NumTraining),
                        new object[] {1, info});

                    if ((DateTime.Now - autoSave).TotalMinutes > AUTOSAVE | bkgWorker.CancellationPending)
                    {
                        bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                            new object[]
                            {
                                0,
                                String.Format("Auto saving {0} ({1:0}min {2} PIDS)", set.FileInfo.Name,
                                    (DateTime.Now - autoSave).TotalMinutes, pid - set.AlreadySavedPID)
                            });
                        set.Write();
                        autoSave = DateTime.Now;
                    }

                    if (!bkgWorker.CancellationPending) continue;
                    bkgWorker.ReportProgress((int)(100.0 * pid / set.NumInstances),
                        new object[] {1, String.Format("{0} cancelled!", set.FileInfo.Name)});
                    e.Cancel = true;
                    return;
                }
                set.Write();
                bkgWorker.ReportProgress((int)(100.0 * ++iter / sets.Length),
                    new object[]
                    {
                        0,
                        String.Format(
                            "Finished collecting and labelling {0} ({1:0}min)\n\tGrand total of {2} preferences.",
                            set.FileInfo.Name, (DateTime.Now - start).TotalMinutes, set.NumFeatures)
                    });
            }
            bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                new object[]
                {0, String.Format("{0} configurations: #{1} newly completed!", sets.GetType(), sets.Length)});
        }

        #endregion

        #region bkgWorkerTrAcc

        private void startAsyncButtonTrAccuracy_Click(object sender, EventArgs e)
        {
            LinearModel[] models = GetModels();
            if (models == null || models.Length < 1) return;
            
            CDRAccuracy set = new CDRAccuracy(models[0], DataDir);

            CDRAccuracy[] sets = (from model in models.Where(m => m.Type == LinearModel.Model.PREF)
                select set.Clone(model, DataDir)).ToArray();
            
            if (sets.Length == 0)
            {
                textContent.AppendText("\nCannot collect training set:");
                if (Problems.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease select preference model.");
                textContent.AppendText("\n");
                return;
            }
            
            while (bkgWorkerTrAcc.IsBusy)
            {
                /* wait */
            }
            bkgWorkerTrAcc.RunWorkerAsync(sets);
            cancelAsyncButtonTrAcc.Visible = true;
        }

        private void bkgWorkerTrAcc_DoWork(object sender, DoWorkEventArgs e)
        {
            BackgroundWorker bkgWorker = bkgWorkerTrAcc;
            CDRAccuracy[] sets = (CDRAccuracy[]) e.Argument;
            e.Result = "";
            int iter = 0;
            bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                new object[] { 0, String.Format("{0} configurations: #{1}", sets.GetType(), sets.Length) });

            sets = sets.Where(x => x.NumApplied < x.NumInstances).ToArray();

            foreach (var set in sets)
            {
                string model = set.Apply();
                bkgWorker.ReportProgress((int) (100.0*++iter/sets.Length),
                    new object[]
                    {
                        1,
                        String.Format("Accuracy for {0} {1}", set.FileInfo.Name, model)
                    });

                if (!bkgWorker.CancellationPending) continue;
                bkgWorker.ReportProgress((int) (100.0*iter/sets.Length),
                    new object[] {1, String.Format("{0} cancelled!", set.FileInfo.Name)});
                e.Cancel = true;
                return;
            }

            bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                new object[] { 0, String.Format("{0} configurations: #{1} newly completed!", sets.GetType(), sets.Length) });
        }

        #endregion 

        #region bkgWorkerRetrace

        private void startAsyncButtonRetrace_Click(object sender, EventArgs e)
        {
            var featureMode = PhiGlobal.Checked
                ? Features.Mode.Global
                : PhiLocal.Checked ? Features.Mode.Local : Features.Mode.None;

            if (featureMode == Features.Mode.None)
            {
                textContent.AppendText("\nCannot retrace set:");
                textContent.AppendText("\n\tPlease choose a feature mode.");
            }

            int iter = Convert.ToInt32(Iteration.Value);
            RetraceSet[] sets = (from problem in Problems.CheckedItems.Cast<string>()
                from dim in Dimension.CheckedItems.Cast<string>()
                from track in Tracks.CheckedItems.Cast<string>()
                select
                    new RetraceSet(problem, dim,
                        (TrainingSet.Trajectory) Enum.Parse(typeof (TrainingSet.Trajectory), track), iter,
                        Extended.CheckedItems.Count > 0, featureMode, DataDir)).ToArray();

            if (sets.Length == 0)
            {
                textContent.AppendText("\nCannot retrace set:");
                if (Problems.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one problem distribution.");
                if (Dimension.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one problem dimension.");
                if (Tracks.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one training trajectory.");
                textContent.AppendText("\n");
                return;
            }

            while (bkgWorkerRetrace.IsBusy)
            {
                /* wait */
            }

            bkgWorkerRetrace.RunWorkerAsync(sets);
            cancelAsyncButtonRetrace.Visible = true;
        }

        private void bkgWorkerRetrace_DoWork(object sender, DoWorkEventArgs e)
        {
            BackgroundWorker bkgWorker = bkgWorkerRetrace;
            RetraceSet[] sets = (RetraceSet[]) e.Argument;
            e.Result = "";
            int iter = 0;
            bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                new object[] {0, String.Format("{0} configurations: #{1}", sets.GetType(), sets.Length)});

            sets = sets.Where(x => x.AlreadySavedPID > 0).ToArray();

            foreach (var set in sets)
            {
                DateTime start = DateTime.Now;
                bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                    new object[] {0, String.Format("Starting retracing {0}", set.FileInfo.Name)});

                for (int pid = 1; pid <= set.AlreadySavedPID; pid++)
                {
                    string info = set.Apply(pid);
                    bkgWorker.ReportProgress((int)(100.0 * pid / set.AlreadySavedPID),
                        new object[] {1, info});

                    if (!bkgWorker.CancellationPending) continue;
                    bkgWorker.ReportProgress((int)(100.0 * pid / set.AlreadySavedPID),
                        new object[] {1, String.Format("{0} cancelled!", set.FileInfo.Name)});
                    e.Cancel = true;
                    return;
                }
                set.Write();
                bkgWorker.ReportProgress((int)(100.0 * ++iter / sets.Length),
                    new object[]
                    {
                        0,
                        String.Format("Finished retracing {0} ({1:0}min)", set.FileInfo.Name,
                            (DateTime.Now - start).TotalMinutes)
                    });
            }
            bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                new object[]
                {0, String.Format("{0} configurations: #{1} newly completed!", sets.GetType(), sets.Length)});
        }

        #endregion

        #region bkgWorkerPrefSet

        private void startAsyncButtonPrefSet_Click(object sender, EventArgs e)
        {
            int iter = Convert.ToInt32(Iteration.Value);

            PreferenceSet[] sets = (from rank in Ranks.CheckedItems.Cast<string>()
                from track in Tracks.CheckedItems.Cast<string>()
                from problem in Problems.CheckedItems.Cast<string>()
                from dim in Dimension.CheckedItems.Cast<string>()
                select
                    new PreferenceSet(problem, dim,
                        (TrainingSet.Trajectory) Enum.Parse(typeof (TrainingSet.Trajectory), track), iter, 
                        Extended.CheckedItems.Count > 0,
                        (PreferenceSet.Ranking) Enum.Parse(typeof (PreferenceSet.Ranking), rank), DataDir))
                .ToArray();

            if (sets.Length == 0)
            {
                textContent.AppendText("\nCannot collect training set:");
                if (Problems.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one problem distribution.");
                if (Dimension.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one problem dimension.");
                if (Tracks.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one training trajectory.");
                if (Ranks.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one ranking scheme.");
                textContent.AppendText("\n");
                return;
            }

            while (bkgWorkerPrefSet.IsBusy)
            {
                /* wait */
            }

            bkgWorkerPrefSet.RunWorkerAsync(sets);
            cancelAsyncButtonRankTrData.Visible = true;
        }

        private void bkgWorkerPrefSet_DoWork(object sender, DoWorkEventArgs e)
        {
            BackgroundWorker bkgWorker = bkgWorkerPrefSet;
            PreferenceSet[] sets = (PreferenceSet[]) e.Argument;
            e.Result = "";
            int iter = 0;
            bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                new object[] {0, String.Format("{0} configurations: #{1}", sets.GetType(), sets.Length)});

            sets = sets.Where(x => x.AlreadySavedPID >= x.NumInstances).ToArray();

            foreach (var set in sets)
            {
                DateTime start = DateTime.Now;

                bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                    new object[] {0, String.Format("Starting ranking {0}", set.FileInfo.Name)});
                set.Apply();
                bkgWorker.ReportProgress((int)(100.0 * ++iter / sets.Length),
                    new object[]
                    {
                        0,
                        String.Format(
                            "Finished ranking {0} ({1:0}min)\n\tGrand total of {2} preferences make {3} pairs.",
                            set.FileInfo.Name, (DateTime.Now - start).TotalMinutes, set.NumFeatures, set.NumPreferences)
                    });

                if (!bkgWorker.CancellationPending) continue;
                bkgWorker.ReportProgress(100,
                    new object[] {1, String.Format("{0} cancelled!", set.FileInfo.Name)});
                e.Cancel = true;
                return;

            }
            bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                new object[]
                {0, String.Format("{0} configurations: #{1} newly completed!", sets.GetType(), sets.Length)});
        }

        #endregion

        #region bkgWorkerCMAES

        private void startAsyncButtonCMA_click(object sender, EventArgs e)
        {
            bool dependentModel = DependentModel.Checked && !IndependentModel.Checked;
            CMAESData.ObjectiveFunction objFun = CMAwrtMakespan.Checked
                ? CMAESData.ObjectiveFunction.MinimumMakespan
                : CMAESData.ObjectiveFunction.MinimumRho;

            CMAESData[] sets = (from dim in Dimension.CheckedItems.Cast<string>()
                from problem in Problems.CheckedItems.Cast<string>()
                select new CMAESData(problem, dim, objFun, dependentModel, DataDir)).ToArray();

            if (sets.Length == 0)
            {
                textContent.AppendText("\nCannot apply CMA-ES:");
                if (Problems.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one problem distribution.");
                if (Dimension.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one problem dimension.");
                textContent.AppendText("\n");
                return;
            }

            while (bkgWorkerCMAES.IsBusy)
            {
                /* wait */
            }

            bkgWorkerCMAES.RunWorkerAsync(sets);
            cancelAsyncButtonCMA.Visible = true;
        }

        private void bkgWorkerCMAES_DoWork(object sender, DoWorkEventArgs e)
        {
            BackgroundWorker bkgWorker = bkgWorkerCMAES;
            CMAESData[] sets = (CMAESData[]) e.Argument;

            e.Result = "";
            int iter = 0;
            bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                new object[] {0, String.Format("{0} configurations: #{1}", sets.GetType(), sets.Length)});

            sets = sets.Where(x => !x.OptimistationComplete).ToArray();

            foreach (var set in sets)
            {
                DateTime start = DateTime.Now;
                DateTime autoSave = DateTime.Now;

                bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                    new object[] {0, String.Format("Starting optimising with CMA-ES {0}", set.FileInfo.Name)});

                while (!set.OptimistationComplete)
                {
                    string info = set.Optimise(set.Generation); //do some intense task here.
                    bkgWorker.ReportProgress((int)(100.0 * set.CountEval / set.StopEval),
                        new object[] {1, info});

                    if ((DateTime.Now - autoSave).TotalMinutes > AUTOSAVE | bkgWorker.CancellationPending)
                    {
                        bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                            new object[]
                            {
                                0,
                                String.Format("Auto saving {0} ({1:0}min {2} generations)", set.FileInfo.Name,
                                    (DateTime.Now - autoSave).TotalMinutes, set.Generation - set.AlreadySavedPID)
                            });
                        set.Write();
                        autoSave = DateTime.Now;
                    }

                    if (!bkgWorker.CancellationPending) continue;
                    bkgWorker.ReportProgress((int)(100.0 * set.CountEval / set.StopEval),
                        new object[] {1, String.Format("{0} cancelled!", set.FileInfo.Name)});
                    e.Cancel = true;
                    return;
                }
                set.Write();

                bkgWorker.ReportProgress((int)(100.0 * ++iter / sets.Length),
                    new object[]
                    {
                        0,
                        String.Format(
                            "Finished optimising with CMA-ES {0} ({1:0}min)\n\tGrand total of {2} generations with {3} evaluations.",
                            set.FileInfo.Name, (DateTime.Now - start).TotalMinutes, set.Generation, set.CountEval)
                    });
            }
            bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                new object[]
                {0, String.Format("{0} configurations: #{1} newly completed!", sets.GetType(), sets.Length)});
        }

        #endregion

        #region bkgWorkerApply

        private void startAsyncButtonApply_Click(object sender, EventArgs e)
        {
            LinearModel[] models = GetModels();
            
            RawData[] datas = (from dim in DimensionApply.CheckedItems.Cast<string>()
                from problem in ProblemsApply.CheckedItems.Cast<string>()
                from set in Set.CheckedItems.Cast<string>()
                select
                    new RawData(problem, dim, (RawData.DataSet) Enum.Parse(typeof (RawData.DataSet), set),
                        Extended.CheckedItems.Count > 0, DataDir)).ToArray();

            CDRData[] sets = models==null ? null : (from data in datas
                from model in models
                select
                    new CDRData(data, model)).ToArray();

            if (sets == null || sets.Length == 0)
            {
                textContent.AppendText("\nCannot apply sets to models:");
                if (ProblemsApply.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one problem distribution.");
                if (DimensionApply.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one problem dimension.");
                textContent.AppendText("\n");
                return;
            }

            while (bkgWorkerApply.IsBusy)
            {
                /* wait */
            }

            bkgWorkerApply.RunWorkerAsync(sets);
            cancelAsyncButtonApply.Visible = true;
        }

        private LinearModel[] GetModels()
        {
            bool dependentModel = DependentModel.Checked && !IndependentModel.Checked;
            LinearModel[] models;

            if (ApplyModel.SelectedItem.ToString().Substring(0, 4) == "PREF")
            {
                string stepwiseBias = StepwiseBias.SelectedItem.ToString();
                int iter = Convert.ToInt32(Iteration.Value);
                int numFeatures = Convert.ToInt32(NumFeatures.Value);
                int modelID = Convert.ToInt32(ModelIndex.Value);

                switch (ApplyModel.SelectedItem.ToString())
                {
                    case "PREF":
                        models = (from dim in Dimension.CheckedItems.Cast<string>()
                            from problem in Problems.CheckedItems.Cast<string>()
                            from track in Tracks.CheckedItems.Cast<string>()
                            from rank in Ranks.CheckedItems.Cast<string>()
                            select new LinearModel(problem, dim,
                                (TrainingSet.Trajectory) Enum.Parse(typeof (TrainingSet.Trajectory), track),
                                Extended.CheckedItems.Count > 0,
                                (PreferenceSet.Ranking) Enum.Parse(typeof (PreferenceSet.Ranking), rank), dependentModel,
                                DataDir, iter, stepwiseBias, numFeatures, modelID)).ToArray();
                        break;
                    case "PREF-exhaust":
                        models = GetAllPrefModels(stepwiseBias, iter, LinearModel.GetAllExhaustiveModels);
                        break;
                    case "PREF-varyLMAX":
                        models = GetAllPrefModels(stepwiseBias, iter, LinearModel.GetAllVaryLmaxModels);
                        break;
                    default:
                        throw new NotImplementedException();
                }

                if (models != null && models.Length != 0) return models;
                textContent.AppendText("\nCannot apply PREF models:");
                if (Problems.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one problem distribution.");
                if (Dimension.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one problem dimension.");
                if (Tracks.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one training trajectory.");
                if (Ranks.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one ranking scheme.");
                textContent.AppendText("\n");
                return null;
            }

            CMAESData.ObjectiveFunction objFun = CMAwrtMakespan.Checked
                ? CMAESData.ObjectiveFunction.MinimumMakespan
                : CMAESData.ObjectiveFunction.MinimumRho;

            models = (from dim in Dimension.CheckedItems.Cast<string>()
                from problem in Problems.CheckedItems.Cast<string>()
                select new LinearModel(problem, dim, objFun, dependentModel, DataDir)).ToArray();

            if (models.Length != 0) return models;
            textContent.AppendText("\nCannot apply CMA-ES models:");
            if (Problems.CheckedItems.Count == 0)
                textContent.AppendText("\n\tPlease choose at least one problem distribution.");
            if (Dimension.CheckedItems.Count == 0)
                textContent.AppendText("\n\tPlease choose at least one problem dimension.");
            textContent.AppendText("\n");
            return null;
        }

        private LinearModel[] GetAllPrefModels(string stepwiseBias, int iter,
            Func
                <string, string, TrainingSet.Trajectory, int, bool, PreferenceSet.Ranking, bool, DirectoryInfo, string,
                    LinearModel[]> getModelsFunc)
        {
            foreach (var models in from problem in Problems.CheckedItems.Cast<string>()
                from dim in Dimension.CheckedItems.Cast<string>()
                from rank in Ranks.CheckedItems.Cast<string>()
                from track in Tracks.CheckedItems.Cast<string>()
                select getModelsFunc(problem, dim,
                    (TrainingSet.Trajectory) Enum.Parse(typeof (TrainingSet.Trajectory), track), iter,
                    Extended.CheckedItems.Count > 0,
                    (PreferenceSet.Ranking) Enum.Parse(typeof (PreferenceSet.Ranking), rank),
                    false, DataDir, stepwiseBias)
                into models
                where models != null
                select models)
            {
                textHeader.AppendText(String.Format("\nOnly {0} is considered!", models[0].FileInfo.Name));
                return models;
            }
            return null;
        }

        private void bkgWorkerApply_DoWork(object sender, DoWorkEventArgs e)
        {
            BackgroundWorker bkgWorker = bkgWorkerApply;
            CDRData[] sets = (CDRData[]) e.Argument;

            e.Result = "";
            int iter = 0;
            bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                new object[] {0, String.Format("{0} configurations: #{1}", sets.GetType(), sets.Length)});

            sets = sets.Where(x => x.AlreadySavedPID < x.NumInstances).ToArray();

            foreach (var set in sets)
            {
                set.Apply();
                bkgWorker.ReportProgress((int)(100.0 * ++iter / sets.Length),
                    new object[]
                    {
                        1,
                        String.Format("Applied {0}\n\tto {1}", set.Model.FileInfo.Name, set.FileInfo.Name)
                    });

                if (!bkgWorker.CancellationPending) continue;
                bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                    new object[] {1, String.Format("{0} cancelled!", set.FileInfo.Name)});
                e.Cancel = true;
                return;
            }

            bkgWorker.ReportProgress((int)(100.0 * iter / sets.Length),
                new object[]
                {0, String.Format("{0} configurations: #{1} newly completed!", sets.GetType(), sets.Length)});
        }

        #endregion

        #endregion

        private void buttonSimpleBDR_Click(object sender, EventArgs e)
        {
            BDRData[] sets = (from set in Set.CheckedItems.Cast<string>()
                from dim in Dimension.CheckedItems.Cast<string>()
                from problem in Problems.CheckedItems.Cast<string>()
                from sdr1 in SDR1.CheckedItems.Cast<string>()
                from sdr2 in SDR2.CheckedItems.Cast<string>()
                select
                    new BDRData(problem, dim, (RawData.DataSet) Enum.Parse(typeof (RawData.DataSet), set),
                        Extended.CheckedItems.Count > 0,
                        (SDRData.SDR) Enum.Parse(typeof (SDRData.SDR), sdr1),
                        (SDRData.SDR) Enum.Parse(typeof (SDRData.SDR), sdr2),
                        Convert.ToInt32(splitBDR.Value), DataDir)).ToArray();

            if (sets.Length == 0)
            {
                textContent.AppendText("\nCannot apply BDR:");
                if (Problems.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one problem distribution.");
                if (Dimension.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one problem dimension.");
                if (Set.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least train or test set.");
                if (SDR1.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one SDR for first half.");
                if (SDR2.CheckedItems.Count == 0)
                    textContent.AppendText("\n\tPlease choose at least one SDR for second  half.");
                textContent.AppendText("\n");
                return;
            }

            textHeader.AppendText(String.Format("\n{0} configurations: #{1}", sets.GetType(), sets.Length));
            sets = sets.Where(x => x.AlreadySavedPID < x.NumInstances).ToArray();

            int iter = 0;
            progressBarOuter.Value = 0;
            foreach (var bdrData in sets)
            {
                progressBarInner.Value = 0;
                bdrData.Apply();
                progressBarInner.Value = 100;
                progressBarOuter.Value = 100*(++iter/sets.Length);
                textContent.AppendText(String.Format("\n{0} updated for {1}:{2}", bdrData.FileInfo.Name,
                    bdrData.HeuristicName, bdrData.HeuristicValue));
            }
            textHeader.AppendText(String.Format("\n{0} configurations: #{1} newly completed!", sets.GetType(),
                sets.Length));
        }



        private void NumFeatures_ValueChanged(object sender, EventArgs e)
        {
            ModelIndex.Minimum = 1;
            ModelIndex.Maximum = LinearModel.NChooseK(16, Convert.ToInt32(NumFeatures.Value));
        }

        private void Set_SelectedIndexChanged(object sender, EventArgs e)
        {
            ckb_SelectedIndexChanged(sender, e);
            bool useTrainSet = Set.CheckedItems.Contains(RawData.DataSet.train.ToString());

            if (DependentModel.Checked | useTrainSet)
            {
                ckb_ClickAllowOnly1(Dimension, e);
                DimensionApply.SelectedIndex = Dimension.SelectedIndex;
                ckb_ClickAllowOnly1(DimensionApply, e);
            }

            if (!useTrainSet) return;

            ckb_ClickAllowOnly1(Problems, e);
            ProblemsApply.SelectedIndex = Problems.SelectedIndex;
            ckb_ClickAllowOnly1(ProblemsApply, e);
            ORLIBApply.SelectedIndex = -1;
            ckb_ClickAllowOnly1(ORLIBApply, e);
        }
    }
}