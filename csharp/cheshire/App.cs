using System;
using System.ComponentModel;
using System.Diagnostics;
using System.Drawing;
using System.Globalization;
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
            textContent.SelectionStart = textContent.Text.Length;
            textContent.ScrollToCaret();
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

            SDRData[] sdrSets = (from problem in Problems.CheckedItems.Cast<string>()
                from dim in Dimension.CheckedItems.Cast<string>()
                from set in Set.CheckedItems.Cast<RawData.DataSet>()
                from sdr in SDR.CheckedItems.Cast<SDRData.SDR>()
                select new SDRData(problem, dim, set, Extended.CheckedItems.Count > 0, sdr)).Where(
                    x => x.AlreadySavedPID < x.NumInstances).ToArray();

            if (sdrSets.Length == 0)
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

            textHeader.AppendText(String.Format("\nSDR configurations: #{0}", sdrSets.Length));
            int iter = 0;
            progressBarOuter.Value = 0;
            foreach (var set in sdrSets)
            {
                progressBarInner.Value = 0;
                set.Apply();
                progressBarInner.Value = 100;
                progressBarOuter.Value = 100*(++iter/sdrSets.Length);
                textContent.AppendText(String.Format("\n{0} updated for {1}:{2}", set.FileInfo.Name,
                    set.HeuristicName, set.HeuristicValue));
            }
            textHeader.AppendText(String.Format("\nSDR configurations: #{0} complete!", sdrSets.Length));
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
            OPTData[] optSets = (from dim in Dimension.CheckedItems.Cast<string>()
                from problem in Problems.CheckedItems.Cast<string>()
                from set in Set.CheckedItems.Cast<RawData.DataSet>()
                select new OPTData(problem, dim, set, Extended.CheckedItems.Count > 0, Convert.ToInt32(TimeLimit.Value)))
                .Where(
                    x => x.AlreadySavedPID < x.NumInstances).ToArray();

            if (optSets.Length == 0)
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

            bkgWorkerOptimise.RunWorkerAsync(optSets);
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
            textHeader.AppendText(String.Format("\nOPT configurations: #{0}", sets.Length));
            int iter = 0;
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
            textHeader.AppendText(String.Format("\nOPT configurations: #{0} complete!", sets.Length));
        }

        #endregion

        #region bkgWorkerTrSet

        private void startAsyncButtonTrSet_Click(object sender, EventArgs e)
        {
            TrainingSet[] trSets = (from problem in Problems.CheckedItems.Cast<string>()
                from dim in Dimension.CheckedItems.Cast<string>()
                from track in Tracks.CheckedItems.Cast<TrainingSet.Trajectory>()
                select new TrainingSet(problem, dim, track, Extended.CheckedItems.Count > 0)).Where(
                    x => x.AlreadySavedPID < x.NumInstances).ToArray();

            if (trSets.Length == 0)
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
            bkgWorkerTrSet.RunWorkerAsync(trSets);
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
            textHeader.AppendText(String.Format("\nTRSET configurations: #{0}", sets.Length));
            int iter = 0;
            foreach (var set in sets)
            {
                DateTime start = DateTime.Now;
                DateTime autoSave = DateTime.Now;

                bkgWorkerTrSet.ReportProgress((int) (100.0*iter/sets.Length),
                    new object[] {0, String.Format("Starting collecting and labelling {0}", set.FileInfo.Name)});

                for (int pid = set.AlreadySavedPID + 1; pid <= set.NumInstances; pid++)
                {
                    string info = set.CollectAndLabel(pid);
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
            textHeader.AppendText(String.Format("\nTRSET configurations: #{0} complete!", sets.Length));
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
                textContent.AppendText("\nCannot optimise set:");
                textContent.AppendText("\n\tPlease choose a feature mode.");
            }

            RetraceSet[] retraceSets = (from problem in Problems.CheckedItems.Cast<string>()
                from dim in Dimension.CheckedItems.Cast<string>()
                from track in Tracks.CheckedItems.Cast<TrainingSet.Trajectory>()
                select new RetraceSet(problem, dim, track, Extended.CheckedItems.Count > 0, featureMode))
                .Where(x => x.AlreadySavedPID > 0).ToArray();

            if (retraceSets.Length == 0)
            {
                textContent.AppendText("\nCannot optimise set:");
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
            
            bkgWorkerRetrace.RunWorkerAsync(retraceSets);
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
            textHeader.AppendText(String.Format("\nRETRACESET configurations: #{0}", sets.Length));
            int iter = 0;
            foreach (var set in sets)
            {
                DateTime start = DateTime.Now;
                bkgWorkerRetrace.ReportProgress((int) (100.0*iter/sets.Length),
                    new object[] {0, String.Format("Starting retracing {0}", set.FileInfo.Name)});

                for (int pid = 1; pid <= set.AlreadySavedPID; pid++)
                {
                    string info = set.Retrace(pid);
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
            textHeader.AppendText(String.Format("\nRETRACESET configurations: #{0} complete!", sets.Length));
        }

        #endregion

        #region bkgWorkerPrefSet

        private void startAsyncButtonPrefSet_Click(object sender, EventArgs e)
        {
            throw new NotImplementedException();
            PreferenceSet prefSet = new PreferenceSet("j.rnd", "6x5", TrainingSet.Trajectory.OPT, false, 'p');
            while (bkgWorkerPrefSet.IsBusy)
            {
                /* wait */
            }

            bkgWorkerPrefSet.RunWorkerAsync(prefSet);
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
            throw new NotImplementedException();

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


        #endregion

        #endregion

        private void buttonSimpleBDR_Click(object sender, EventArgs e)
        {
            BDRData[] bdrDatas = (from problem in Problems.CheckedItems.Cast<string>()
                from dim in Dimension.CheckedItems.Cast<string>()
                from set in Set.CheckedItems.Cast<RawData.DataSet>()
                from sdr1 in SDR1.CheckedItems.Cast<SDRData.SDR>()
                from sdr2 in SDR2.CheckedItems.Cast<SDRData.SDR>()
                select
                    new BDRData(problem, dim, set, Extended.CheckedItems.Count > 0, sdr1, sdr2,
                        Convert.ToInt32(splitBDR.Value))).Where(
                            x => x.AlreadySavedPID < x.NumInstances).ToArray();

            if (bdrDatas.Length == 0)
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

            textHeader.AppendText(String.Format("\nBDR configurations: #{0}", bdrDatas.Length));
            int iter = 0;
            progressBarOuter.Value = 0;
            foreach (var bdrData in bdrDatas)
            {
                progressBarInner.Value = 0;
                bdrData.Apply();
                progressBarInner.Value = 100;
                progressBarOuter.Value = 100 * (++iter / bdrDatas.Length);
                textContent.AppendText(String.Format("\n{0} updated for {1}:{2}", bdrData.FileInfo.Name,
                    bdrData.HeuristicName, bdrData.HeuristicValue));
            }
            textHeader.AppendText(String.Format("\nBDR configurations: #{0} complete!", bdrDatas.Length));
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
            CMAESData[] cmaesDatas = (CMAESData[])e.Argument;
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