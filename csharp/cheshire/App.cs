using System;
using System.ComponentModel;
using System.Diagnostics;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;
using ALICE;

namespace Chesire
{
    public partial class App : Form
    {
        private const int AUTOSAVE = 30; // minutes

        public App()
        {
            InitializeComponent();
            InitializeBackgroundWorker();
            Icon ico = new Icon(String.Format(@"C:\users\helga\alice\Code\csharp\cheshire\Resources\chesirecat.ico"));
            Icon = ico;
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

            radioButtonCMAIndependent.Select();
            CMAwrtRho.Select();

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
            SDRData[] sets = (from set in Set.CheckedItems.Cast<RawData.DataSet>()
                from dim in Dimension.CheckedItems.Cast<string>()
                from problem in Problems.CheckedItems.Cast<string>()
                from sdr in SDR.CheckedItems.Cast<SDRData.SDR>()
                select new SDRData(problem, dim, set, Extended.CheckedItems.Count > 0, sdr)).Where(
                    x => x.AlreadySavedPID < x.NumInstances).ToArray();

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
            textHeader.AppendText(String.Format("\n{0} configurations: #{1} complete!", sets.GetType(), sets.Length));
        }


        #region backgroundworkers

        #region common work

        private void bkgWorker_ProgressChanged(object sender, ProgressChangedEventArgs e)
        {
            //This event is raised on the main thread.  
            //It is safe to access UI controls here.              
            object[] info = (object[]) e.UserState;
            if (Convert.ToInt32(info[0]) == 0)
            {
                progressBarOuter.Value = e.ProgressPercentage;
                progressBarInner.Value = e.ProgressPercentage > 0 ? 100 : 0;
                textHeader.AppendText(String.Format("\n{0}", info[1]));
            }
            else
            {
                progressBarInner.Value = e.ProgressPercentage;
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
            cancelAsyncButtonRetrace.Visible = false;
            cancelAsyncButtonCMA.Visible = false;
            cancelAsyncButtonOptimize.Visible = false;
            cancelAsyncButtonTrSet.Visible = false;
            cancelAsyncButtonRankTrData.Visible = false;
        }

        #endregion

        #region bkgWorkerOptimize

        private void startAsyncButtonOptimize_Click(object sender, EventArgs e)
        {
            OPTData[] sets = (from set in Set.CheckedItems.Cast<RawData.DataSet>()
                from dim in Dimension.CheckedItems.Cast<string>()
                from problem in Problems.CheckedItems.Cast<string>()
                select new OPTData(problem, dim, set, Extended.CheckedItems.Count > 0, Convert.ToInt32(TimeLimit.Value)))
                .Where(
                    x => x.AlreadySavedPID < x.NumInstances).ToArray();

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

        private void cancelAsyncButtonOptimize_Click(object sender, EventArgs e)
        {
            bkgWorkerOptimise.CancelAsync();
            textHeader.AppendText("\nCancelling optimization...");
            cancelAsyncButtonOptimize.Visible = false;
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
            //the RunWorkerCompletedEventArgs object, method bkgWorkerOptimise_RunWorkerCompleted  

            OPTData[] sets = (OPTData[]) e.Argument;
            e.Result = "";
            int iter = 0;
            bkgWorkerOptimise.ReportProgress((int) (100.0*iter/sets.Length),
                new object[] {0, String.Format("{0} configurations: #{1}", sets.GetType(), sets.Length)});

            foreach (var set in sets)
            {
                DateTime start = DateTime.Now;
                DateTime autoSave = DateTime.Now;

                bkgWorkerOptimise.ReportProgress((int) (100.0*iter/sets.Length),
                    new object[] {0, String.Format("Starting optimising {0}", set.FileInfo.Name)});

                for (int pid = set.AlreadySavedPID + 1; pid <= set.NumInstances; pid++)
                {
                    string info = set.Optimise(pid);
                    bkgWorkerOptimise.ReportProgress((int) (100.0*pid/set.NumInstances),
                        new object[] {1, info});

                    if ((DateTime.Now - autoSave).TotalMinutes > AUTOSAVE | bkgWorkerOptimise.CancellationPending)
                    {
                        bkgWorkerOptimise.ReportProgress((int) (100.0*iter/sets.Length),
                            new object[]
                            {
                                0,
                                String.Format("Auto saving {0} ({1:0}min {2}PIDS)", set.FileInfo.Name,
                                    (DateTime.Now - autoSave).TotalMinutes, pid - set.AlreadySavedPID)
                            });
                        set.Write();
                        autoSave = DateTime.Now;
                    }

                    if (!bkgWorkerOptimise.CancellationPending) continue;
                    bkgWorkerOptimise.ReportProgress((int) (100.0*pid/set.NumInstances),
                        new object[] {1, String.Format("{0} cancelled!", set.FileInfo.Name)});
                    e.Cancel = true;
                    return;
                }
                set.Write();
                bkgWorkerOptimise.ReportProgress((int) (100.0*++iter/sets.Length),
                    new object[]
                    {
                        0,
                        String.Format("Finished optimising {0} ({1:0}min)", set.FileInfo.Name,
                            (DateTime.Now - start).TotalMinutes)
                    });
            }
            bkgWorkerOptimise.ReportProgress((int) (100.0*iter/sets.Length),
                new object[] {0, String.Format("{0} configurations: #{1} complete!", sets.GetType(), sets.Length)});
        }

        #endregion

        #region bkgWorkerTrSet

        private void startAsyncButtonTrSet_Click(object sender, EventArgs e)
        {
            TrainingSet[] sets = (from track in Tracks.CheckedItems.Cast<TrainingSet.Trajectory>()
                from dim in Dimension.CheckedItems.Cast<string>()
                from problem in Problems.CheckedItems.Cast<string>()
                select new TrainingSet(problem, dim, track, Extended.CheckedItems.Count > 0)).Where(
                    x => x.AlreadySavedPID < x.NumInstances).ToArray();

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

        private void cancelAsyncButtonTrSet_Click(object sender, EventArgs e)
        {
            bkgWorkerTrSet.CancelAsync();
            textHeader.AppendText("\nCancelling generation of training data...");
            cancelAsyncButtonTrSet.Visible = false;
        }

        private void bkgWorkerTrSet_DoWork(object sender, DoWorkEventArgs e)
        {
            TrainingSet[] sets = (TrainingSet[]) e.Argument;
            e.Result = "";
            int iter = 0;
            bkgWorkerTrSet.ReportProgress((int) (100.0*iter/sets.Length),
                new object[] {0, String.Format("{0} configurations: #{1}", sets.GetType(), sets.Length)});

            foreach (var set in sets)
            {
                DateTime start = DateTime.Now;
                DateTime autoSave = DateTime.Now;

                bkgWorkerTrSet.ReportProgress((int) (100.0*iter/sets.Length),
                    new object[] {0, String.Format("Starting collecting and labelling {0}", set.FileInfo.Name)});

                for (int pid = set.AlreadySavedPID + 1; pid <= set.NumInstances; pid++)
                {
                    string info = set.Apply(pid);
                    bkgWorkerTrSet.ReportProgress((int) (100.0*pid/set.NumInstances),
                        new object[] {1, info});

                    if ((DateTime.Now - autoSave).TotalMinutes > AUTOSAVE | bkgWorkerTrSet.CancellationPending)
                    {
                        bkgWorkerTrSet.ReportProgress((int) (100.0*iter/sets.Length),
                            new object[]
                            {
                                0,
                                String.Format("Auto saving {0} ({1:0}min {2}PIDS)", set.FileInfo.Name,
                                    (DateTime.Now - autoSave).TotalMinutes, pid - set.AlreadySavedPID)
                            });
                        set.Write();
                        autoSave = DateTime.Now;
                    }

                    if (!bkgWorkerTrSet.CancellationPending) continue;
                    bkgWorkerTrSet.ReportProgress((int) (100.0*pid/set.NumInstances),
                        new object[] {1, String.Format("{0} cancelled!", set.FileInfo.Name)});
                    e.Cancel = true;
                    return;
                }
                set.Write();
                bkgWorkerTrSet.ReportProgress((int) (100.0*++iter/sets.Length),
                    new object[]
                    {
                        0,
                        String.Format(
                            "Finished collecting and labelling {0} ({1:0}min)\n\tGrand total of {2} preferences.",
                            set.FileInfo.Name, (DateTime.Now - start).TotalMinutes, set.NumFeatures)
                    });
            }
            bkgWorkerTrSet.ReportProgress((int) (100.0*iter/sets.Length),
                new object[] {0, String.Format("{0} configurations: #{1} complete!", sets.GetType(), sets.Length)});
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

            RetraceSet[] sets = (from problem in Problems.CheckedItems.Cast<string>()
                from dim in Dimension.CheckedItems.Cast<string>()
                from track in Tracks.CheckedItems.Cast<TrainingSet.Trajectory>()
                select new RetraceSet(problem, dim, track, Extended.CheckedItems.Count > 0, featureMode))
                .Where(x => x.AlreadySavedPID > 0).ToArray();

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

        private void cancelAsyncButtonRetrace_Click(object sender, EventArgs e)
        {
            bkgWorkerRetrace.CancelAsync();
            textHeader.AppendText(
                "\nCancelling feature update of training data...");
            cancelAsyncButtonRetrace.Visible = false;
        }

        private void bkgWorkerRetrace_DoWork(object sender, DoWorkEventArgs e)
        {
            RetraceSet[] sets = (RetraceSet[]) e.Argument;
            e.Result = "";
            int iter = 0;
            bkgWorkerRetrace.ReportProgress((int) (100.0*iter/sets.Length),
                new object[] {0, String.Format("{0} configurations: #{1}", sets.GetType(), sets.Length)});

            foreach (var set in sets)
            {
                DateTime start = DateTime.Now;
                bkgWorkerRetrace.ReportProgress((int) (100.0*iter/sets.Length),
                    new object[] {0, String.Format("Starting retracing {0}", set.FileInfo.Name)});

                for (int pid = 1; pid <= set.AlreadySavedPID; pid++)
                {
                    string info = set.Apply(pid);
                    bkgWorkerRetrace.ReportProgress((int) (100.0*pid/set.AlreadySavedPID),
                        new object[] {1, info});

                    if (!bkgWorkerRetrace.CancellationPending) continue;
                    bkgWorkerRetrace.ReportProgress((int) (100.0*pid/set.AlreadySavedPID),
                        new object[] {1, String.Format("{0} cancelled!", set.FileInfo.Name)});
                    e.Cancel = true;
                    return;
                }
                set.Write();
                bkgWorkerRetrace.ReportProgress((int) (100.0*++iter/sets.Length),
                    new object[]
                    {
                        0,
                        String.Format("Finished retracing {0} ({1:0}min)", set.FileInfo.Name,
                            (DateTime.Now - start).TotalMinutes)
                    });
            }
            bkgWorkerRetrace.ReportProgress((int) (100.0*iter/sets.Length),
                new object[] {0, String.Format("{0} configurations: #{1} complete!", sets.GetType(), sets.Length)});
        }

        #endregion

        #region bkgWorkerPrefSet

        private void startAsyncButtonPrefSet_Click(object sender, EventArgs e)
        {
            PreferenceSet[] sets = (from rank in Ranks.CheckedItems.Cast<PreferenceSet.Ranking>()
                from track in Tracks.CheckedItems.Cast<TrainingSet.Trajectory>()
                from problem in Problems.CheckedItems.Cast<string>()
                from dim in Dimension.CheckedItems.Cast<string>()
                select new PreferenceSet(problem, dim, track, Extended.CheckedItems.Count > 0, rank)).Where(
                    x => x.AlreadySavedPID >= x.NumInstances).ToArray();

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

        private void cancelAsyncButtonPrefSet_Click(object sender, EventArgs e)
        {
            bkgWorkerPrefSet.CancelAsync();
            textHeader.AppendText("\nCancelling ranking of training data...");
            cancelAsyncButtonRankTrData.Visible = false;
        }

        private void bkgWorkerPrefSet_DoWork(object sender, DoWorkEventArgs e)
        {
            PreferenceSet[] sets = (PreferenceSet[]) e.Argument;
            e.Result = "";
            int iter = 0;
            bkgWorkerPrefSet.ReportProgress((int) (100.0*iter/sets.Length),
                new object[] {0, String.Format("{0} configurations: #{1}", sets.GetType(), sets.Length)});

            foreach (var set in sets)
            {
                DateTime start = DateTime.Now;

                bkgWorkerPrefSet.ReportProgress((int) (100.0*iter/sets.Length),
                    new object[] {0, String.Format("Starting ranking {0}", set.FileInfo.Name)});
                set.Apply();
                bkgWorkerPrefSet.ReportProgress((int) (100.0*++iter/sets.Length),
                    new object[]
                    {
                        0,
                        String.Format(
                            "Finished ranking {0} ({1:0}min)\n\tGrand total of {2} preferences make {3} pairs.",
                            set.FileInfo.Name, (DateTime.Now - start).TotalMinutes, set.NumFeatures, set.NumPreferences)
                    });
            }
            bkgWorkerPrefSet.ReportProgress((int) (100.0*iter/sets.Length),
                new object[] {0, String.Format("{0} configurations: #{1} complete!", sets.GetType(), sets.Length)});
        }


        #endregion

        #endregion

        private void buttonSimpleBDR_Click(object sender, EventArgs e)
        {
            BDRData[] sets = (from set in Set.CheckedItems.Cast<RawData.DataSet>()
                from dim in Dimension.CheckedItems.Cast<string>()
                from problem in Problems.CheckedItems.Cast<string>()
                from sdr1 in SDR1.CheckedItems.Cast<SDRData.SDR>()
                from sdr2 in SDR2.CheckedItems.Cast<SDRData.SDR>()
                select
                    new BDRData(problem, dim, set, Extended.CheckedItems.Count > 0, sdr1, sdr2,
                        Convert.ToInt32(splitBDR.Value))).Where(
                            x => x.AlreadySavedPID < x.NumInstances).ToArray();

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
            textHeader.AppendText(String.Format("\n{0} configurations: #{1} complete!", sets.GetType(), sets.Length));
        }

        private void startAsyncButtonCMA_click(object sender, EventArgs e)
        {
            throw new NotImplementedException();
            CMAESData cmaes = new CMAESData("j.rnd", "10x10", "MinimumMakespan", false);

            while (bkgWorkerCMAES.IsBusy)
            {
                /* wait */
            }


            bkgWorkerCMAES.RunWorkerAsync(cmaes);
            cancelAsyncButtonCMA.Visible = true;
        }

        private void cancelAsyncButtonCMA_click(object sender, EventArgs e)
        {
            bkgWorkerTrSet.CancelAsync();
            textHeader.AppendText("\nCancelling CMA-ES optimisation...");
            cancelAsyncButtonTrSet.Visible = false;
        }

        private void bkgWorkerCMAES_DoWork(object sender, DoWorkEventArgs e)
        {
            throw new NotImplementedException();
            CMAESData[] cmaesDatas = (CMAESData[]) e.Argument;
            int iData = 0;
            foreach (var cmaes in cmaesDatas)
            {

                bkgWorkerCMAES.ReportProgress((int) (100.0*iData/cmaesDatas.Length),
                    String.Format("{0}\n", cmaes.FileInfo.Name));

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
                        string info = String.Format("\nDuration: {0:0} s.", (DateTime.Now - start).TotalSeconds);
                        cmaes.WriteResultsCSV();
                        bkgWorkerCMAES.ReportProgress((int) (100.0*cmaes.CountEval/cmaes.StopEval), info);
                        e.Cancel = true;
                        return;
                    }
                    bkgWorkerCMAES.ReportProgress((int) (100.0*cmaes.CountEval/cmaes.StopEval), cmaes.Step);

                    if (autoSave.ElapsedMilliseconds <= AUTOSAVE) continue;
                    cmaes.WriteResultsCSV();
                    autoSave.Restart();
                }
                // save current work 
                cmaes.WriteFinalResultsCSV();
                e.Result = String.Format("Total duration: {0:0}min", (DateTime.Now - start).TotalMinutes);
                bkgWorkerCMAES.ReportProgress((int) (100.0*++iData/cmaesDatas.Length), e.Result);
            }
        }
    }
}