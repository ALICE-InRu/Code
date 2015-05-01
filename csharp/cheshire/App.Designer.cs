using System;
using System.ComponentModel;
using System.Windows.Forms;
using ALICE;

namespace Chesire
{
    partial class App
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.components = new System.ComponentModel.Container();
            this.bkgWorkerPrefSet = new System.ComponentModel.BackgroundWorker();
            this.bkgWorkerOptimise = new System.ComponentModel.BackgroundWorker();
            this.bkgWorkerTrSet = new System.ComponentModel.BackgroundWorker();
            this.bkgWorkerCMAES = new System.ComponentModel.BackgroundWorker();
            this.bkgWorkerRetrace = new System.ComponentModel.BackgroundWorker();
            this.groupBoxData = new System.Windows.Forms.GroupBox();
            this.groupBoxSet = new System.Windows.Forms.GroupBox();
            this.Set = new System.Windows.Forms.CheckedListBox();
            this.Extended = new System.Windows.Forms.CheckedListBox();
            this.groupBoxProblem = new System.Windows.Forms.GroupBox();
            this.Problems = new System.Windows.Forms.CheckedListBox();
            this.ORLIB = new System.Windows.Forms.CheckedListBox();
            this.groupBoxDim = new System.Windows.Forms.GroupBox();
            this.Dimension = new System.Windows.Forms.CheckedListBox();
            this.progressBarInner = new System.Windows.Forms.ProgressBar();
            this.groupBoxCMAObjFun = new System.Windows.Forms.GroupBox();
            this.cancelAsyncButtonCMA = new System.Windows.Forms.Button();
            this.startAsyncButtonCMA = new System.Windows.Forms.Button();
            this.CMAwrtMakespan = new System.Windows.Forms.RadioButton();
            this.CMAwrtRho = new System.Windows.Forms.RadioButton();
            this.groupBoxBDR = new System.Windows.Forms.GroupBox();
            this.applyBDR = new System.Windows.Forms.Button();
            this.splitBDR = new System.Windows.Forms.NumericUpDown();
            this.label7 = new System.Windows.Forms.Label();
            this.label8 = new System.Windows.Forms.Label();
            this.SDR2 = new System.Windows.Forms.CheckedListBox();
            this.SDR1 = new System.Windows.Forms.CheckedListBox();
            this.label6 = new System.Windows.Forms.Label();
            this.groupBoxPREF = new System.Windows.Forms.GroupBox();
            this.groupBoxTracks = new System.Windows.Forms.GroupBox();
            this.cancelAsyncButtonTrSet = new System.Windows.Forms.Button();
            this.startAsyncButtonGenTrData = new System.Windows.Forms.Button();
            this.Tracks = new System.Windows.Forms.CheckedListBox();
            this.groupBoxRanks = new System.Windows.Forms.GroupBox();
            this.Ranks = new System.Windows.Forms.CheckedListBox();
            this.cancelAsyncButtonRankTrData = new System.Windows.Forms.Button();
            this.startAsyncButtonRankTrData = new System.Windows.Forms.Button();
            this.groupBoxRetrace = new System.Windows.Forms.GroupBox();
            this.cancelAsyncButtonRetrace = new System.Windows.Forms.Button();
            this.startAsyncButtonRetrace = new System.Windows.Forms.Button();
            this.PhiLocal = new System.Windows.Forms.RadioButton();
            this.PhiGlobal = new System.Windows.Forms.RadioButton();
            this.groupBoxDependent = new System.Windows.Forms.GroupBox();
            this.radioButtonCMAIndependent = new System.Windows.Forms.RadioButton();
            this.radioButtonCMADependent = new System.Windows.Forms.RadioButton();
            this.groupBoxSDR = new System.Windows.Forms.GroupBox();
            this.applySDR = new System.Windows.Forms.Button();
            this.SDR = new System.Windows.Forms.CheckedListBox();
            this.groupBoxOpt = new System.Windows.Forms.GroupBox();
            this.labelTmLimit = new System.Windows.Forms.Label();
            this.cancelAsyncButtonOptimize = new System.Windows.Forms.Button();
            this.TimeLimit = new System.Windows.Forms.NumericUpDown();
            this.startAsyncButtonOptimize = new System.Windows.Forms.Button();
            this.progressBarOuter = new System.Windows.Forms.ProgressBar();
            this.splitContainerForm = new System.Windows.Forms.SplitContainer();
            this.textHeader = new System.Windows.Forms.RichTextBox();
            this.textContent = new System.Windows.Forms.RichTextBox();
            this.timer1 = new System.Windows.Forms.Timer(this.components);
            this.groupBoxData.SuspendLayout();
            this.groupBoxSet.SuspendLayout();
            this.groupBoxProblem.SuspendLayout();
            this.groupBoxDim.SuspendLayout();
            this.groupBoxCMAObjFun.SuspendLayout();
            this.groupBoxBDR.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize) (this.splitBDR)).BeginInit();
            this.groupBoxPREF.SuspendLayout();
            this.groupBoxTracks.SuspendLayout();
            this.groupBoxRanks.SuspendLayout();
            this.groupBoxRetrace.SuspendLayout();
            this.groupBoxDependent.SuspendLayout();
            this.groupBoxSDR.SuspendLayout();
            this.groupBoxOpt.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize) (this.TimeLimit)).BeginInit();
            ((System.ComponentModel.ISupportInitialize) (this.splitContainerForm)).BeginInit();
            this.splitContainerForm.Panel1.SuspendLayout();
            this.splitContainerForm.Panel2.SuspendLayout();
            this.splitContainerForm.SuspendLayout();
            this.SuspendLayout();
            // 
            // groupBoxData
            // 
            this.groupBoxData.Controls.Add(this.groupBoxSet);
            this.groupBoxData.Controls.Add(this.groupBoxProblem);
            this.groupBoxData.Controls.Add(this.groupBoxDim);
            this.groupBoxData.Location = new System.Drawing.Point(10, 10);
            this.groupBoxData.Name = "groupBoxData";
            this.groupBoxData.Size = new System.Drawing.Size(130, 404);
            this.groupBoxData.TabIndex = 51;
            this.groupBoxData.TabStop = false;
            this.groupBoxData.Text = "Problem instances";
            // 
            // groupBoxSet
            // 
            this.groupBoxSet.Controls.Add(this.Set);
            this.groupBoxSet.Controls.Add(this.Extended);
            this.groupBoxSet.Location = new System.Drawing.Point(6, 320);
            this.groupBoxSet.Name = "groupBoxSet";
            this.groupBoxSet.Size = new System.Drawing.Size(119, 80);
            this.groupBoxSet.TabIndex = 52;
            this.groupBoxSet.TabStop = false;
            this.groupBoxSet.Text = "Set";
            // 
            // Set
            // 
            this.Set.FormattingEnabled = true;
            this.Set.Items.AddRange(new object[]
            {
                RawData.DataSet.train,
                RawData.DataSet.test
            });
            this.Set.Location = new System.Drawing.Point(5, 15);
            this.Set.Name = "Set";
            this.Set.Size = new System.Drawing.Size(110, 34);
            this.Set.TabIndex = 49;
            this.Set.SelectedIndexChanged += new System.EventHandler(this.ckb_SelectedIndexChanged);
            // 
            // Extended
            // 
            this.Extended.FormattingEnabled = true;
            this.Extended.Items.AddRange(new object[]
            {
                "Extended"
            });
            this.Extended.Location = new System.Drawing.Point(5, 55);
            this.Extended.Name = "Extended";
            this.Extended.Size = new System.Drawing.Size(110, 19);
            this.Extended.TabIndex = 50;
            this.Extended.SelectedIndexChanged += new System.EventHandler(this.ckb_SelectedIndexChanged);
            // 
            // groupBoxProblem
            // 
            this.groupBoxProblem.Controls.Add(this.Problems);
            this.groupBoxProblem.Controls.Add(this.ORLIB);
            this.groupBoxProblem.Location = new System.Drawing.Point(5, 15);
            this.groupBoxProblem.Name = "groupBoxProblem";
            this.groupBoxProblem.Size = new System.Drawing.Size(120, 204);
            this.groupBoxProblem.TabIndex = 1;
            this.groupBoxProblem.TabStop = false;
            this.groupBoxProblem.Text = "Distribution";
            // 
            // Problems
            // 
            this.Problems.FormattingEnabled = true;
            this.Problems.Items.AddRange(new object[]
            {
                "j.rnd",
                "j.rndn",
                "f.rnd",
                "f.rndn",
                "f.jc",
                "f.mc",
                "f.mxc",
                "j.rnd_p1mdoubled",
                "j.rnd_pj1doubled"
            });
            this.Problems.Location = new System.Drawing.Point(5, 15);
            this.Problems.Name = "Problems";
            this.Problems.Size = new System.Drawing.Size(110, 139);
            this.Problems.TabIndex = 22;
            this.Problems.SelectedIndexChanged += new System.EventHandler(this.ckb_SelectedIndexChanged);
            // 
            // ORLIB
            // 
            this.ORLIB.FormattingEnabled = true;
            this.ORLIB.Items.AddRange(new object[]
            {
                "ORLIB fsp",
                "ORLIB jsp"
            });
            this.ORLIB.Location = new System.Drawing.Point(5, 160);
            this.ORLIB.Name = "ORLIB";
            this.ORLIB.Size = new System.Drawing.Size(110, 34);
            this.ORLIB.TabIndex = 48;
            this.ORLIB.SelectedIndexChanged += new System.EventHandler(this.ckb_SelectedIndexChanged);
            // 
            // groupBoxDim
            // 
            this.groupBoxDim.Controls.Add(this.Dimension);
            this.groupBoxDim.Location = new System.Drawing.Point(5, 220);
            this.groupBoxDim.Name = "groupBoxDim";
            this.groupBoxDim.Size = new System.Drawing.Size(120, 100);
            this.groupBoxDim.TabIndex = 1;
            this.groupBoxDim.TabStop = false;
            this.groupBoxDim.Text = "Dimension";
            // 
            // Dimension
            // 
            this.Dimension.FormattingEnabled = true;
            this.Dimension.Items.AddRange(new object[]
            {
                "6x5",
                "8x8",
                "10x10",
                "12x12",
                "14x14"
            });
            this.Dimension.Location = new System.Drawing.Point(5, 15);
            this.Dimension.Name = "Dimension";
            this.Dimension.Size = new System.Drawing.Size(110, 79);
            this.Dimension.TabIndex = 48;
            this.Dimension.SelectedIndexChanged += new System.EventHandler(this.ckb_SelectedIndexChanged);
            // 
            // progressBarInner
            // 
            this.progressBarInner.Location = new System.Drawing.Point(12, 519);
            this.progressBarInner.Name = "progressBarInner";
            this.progressBarInner.Size = new System.Drawing.Size(332, 25);
            this.progressBarInner.TabIndex = 0;
            // 
            // groupBoxCMAObjFun
            // 
            this.groupBoxCMAObjFun.Controls.Add(this.cancelAsyncButtonCMA);
            this.groupBoxCMAObjFun.Controls.Add(this.startAsyncButtonCMA);
            this.groupBoxCMAObjFun.Controls.Add(this.CMAwrtMakespan);
            this.groupBoxCMAObjFun.Controls.Add(this.CMAwrtRho);
            this.groupBoxCMAObjFun.Location = new System.Drawing.Point(260, 460);
            this.groupBoxCMAObjFun.Name = "groupBoxCMAObjFun";
            this.groupBoxCMAObjFun.Size = new System.Drawing.Size(161, 84);
            this.groupBoxCMAObjFun.TabIndex = 23;
            this.groupBoxCMAObjFun.TabStop = false;
            this.groupBoxCMAObjFun.Text = "CMA-ES optimisation";
            // 
            // cancelAsyncButtonCMA
            // 
            this.cancelAsyncButtonCMA.Location = new System.Drawing.Point(80, 53);
            this.cancelAsyncButtonCMA.Name = "cancelAsyncButtonCMA";
            this.cancelAsyncButtonCMA.Size = new System.Drawing.Size(60, 25);
            this.cancelAsyncButtonCMA.TabIndex = 56;
            this.cancelAsyncButtonCMA.Text = "Cancel";
            this.cancelAsyncButtonCMA.UseVisualStyleBackColor = true;
            this.cancelAsyncButtonCMA.Click += new System.EventHandler(this.cancelAsyncButtonCMA_click);
            // 
            // startAsyncButtonCMA
            // 
            this.startAsyncButtonCMA.Location = new System.Drawing.Point(15, 53);
            this.startAsyncButtonCMA.Name = "startAsyncButtonCMA";
            this.startAsyncButtonCMA.Size = new System.Drawing.Size(60, 25);
            this.startAsyncButtonCMA.TabIndex = 55;
            this.startAsyncButtonCMA.Text = "Optimise";
            this.startAsyncButtonCMA.UseVisualStyleBackColor = true;
            this.startAsyncButtonCMA.Click += new System.EventHandler(this.startAsyncButtonCMA_click);
            // 
            // CMAwrtMakespan
            // 
            this.CMAwrtMakespan.AutoSize = true;
            this.CMAwrtMakespan.Location = new System.Drawing.Point(5, 35);
            this.CMAwrtMakespan.Name = "CMAwrtMakespan";
            this.CMAwrtMakespan.Size = new System.Drawing.Size(119, 17);
            this.CMAwrtMakespan.TabIndex = 41;
            this.CMAwrtMakespan.Text = "w.r.t. min makespan";
            this.CMAwrtMakespan.UseVisualStyleBackColor = true;
            // 
            // CMAwrtRho
            // 
            this.CMAwrtRho.AutoSize = true;
            this.CMAwrtRho.Checked = true;
            this.CMAwrtRho.Location = new System.Drawing.Point(5, 15);
            this.CMAwrtRho.Name = "CMAwrtRho";
            this.CMAwrtRho.Size = new System.Drawing.Size(85, 17);
            this.CMAwrtRho.TabIndex = 40;
            this.CMAwrtRho.TabStop = true;
            this.CMAwrtRho.Text = "w.r.t. min rho";
            this.CMAwrtRho.UseVisualStyleBackColor = true;
            // 
            // groupBoxBDR
            // 
            this.groupBoxBDR.Controls.Add(this.applyBDR);
            this.groupBoxBDR.Controls.Add(this.splitBDR);
            this.groupBoxBDR.Controls.Add(this.label7);
            this.groupBoxBDR.Controls.Add(this.label8);
            this.groupBoxBDR.Controls.Add(this.SDR2);
            this.groupBoxBDR.Controls.Add(this.SDR1);
            this.groupBoxBDR.Controls.Add(this.label6);
            this.groupBoxBDR.Location = new System.Drawing.Point(145, 147);
            this.groupBoxBDR.Name = "groupBoxBDR";
            this.groupBoxBDR.Size = new System.Drawing.Size(110, 240);
            this.groupBoxBDR.TabIndex = 0;
            this.groupBoxBDR.TabStop = false;
            this.groupBoxBDR.Text = "BDR";
            // 
            // applyBDR
            // 
            this.applyBDR.Location = new System.Drawing.Point(25, 210);
            this.applyBDR.Name = "applyBDR";
            this.applyBDR.Size = new System.Drawing.Size(60, 25);
            this.applyBDR.TabIndex = 46;
            this.applyBDR.Text = "Apply";
            this.applyBDR.UseVisualStyleBackColor = true;
            this.applyBDR.Click += new System.EventHandler(this.buttonSimpleBDR_Click);
            // 
            // splitBDR
            // 
            this.splitBDR.Location = new System.Drawing.Point(65, 15);
            this.splitBDR.Maximum = new decimal(new int[]
            {
                500,
                0,
                0,
                0
            });
            this.splitBDR.Minimum = new decimal(new int[]
            {
                1,
                0,
                0,
                0
            });
            this.splitBDR.Name = "splitBDR";
            this.splitBDR.Size = new System.Drawing.Size(40, 20);
            this.splitBDR.TabIndex = 49;
            this.splitBDR.Value = new decimal(new int[]
            {
                50,
                0,
                0,
                0
            });
            // 
            // label7
            // 
            this.label7.AutoSize = true;
            this.label7.Location = new System.Drawing.Point(2, 17);
            this.label7.Name = "label7";
            this.label7.Size = new System.Drawing.Size(65, 13);
            this.label7.TabIndex = 51;
            this.label7.Text = "Split at step:";
            // 
            // label8
            // 
            this.label8.AutoSize = true;
            this.label8.Location = new System.Drawing.Point(2, 38);
            this.label8.Name = "label8";
            this.label8.Size = new System.Drawing.Size(78, 13);
            this.label8.TabIndex = 53;
            this.label8.Text = "SDR (first half):";
            // 
            // SDR2
            // 
            this.SDR2.FormattingEnabled = true;
            this.SDR2.Items.AddRange(new object[]
            {
                SDRData.SDR.SPT,
                SDRData.SDR.LPT,
                SDRData.SDR.LWR,
                SDRData.SDR.MWR
            });
            this.SDR2.Location = new System.Drawing.Point(5, 140);
            this.SDR2.Name = "SDR2";
            this.SDR2.Size = new System.Drawing.Size(100, 64);
            this.SDR2.TabIndex = 47;
            this.SDR2.SelectedIndexChanged += new System.EventHandler(this.ckb_ClickAllowOnly1);
            // 
            // SDR1
            // 
            this.SDR1.FormattingEnabled = true;
            this.SDR1.Items.AddRange(new object[]
            {
                SDRData.SDR.SPT,
                SDRData.SDR.LPT,
                SDRData.SDR.LWR,
                SDRData.SDR.MWR
            });
            this.SDR1.Location = new System.Drawing.Point(5, 55);
            this.SDR1.Name = "SDR1";
            this.SDR1.Size = new System.Drawing.Size(100, 64);
            this.SDR1.TabIndex = 52;
            this.SDR1.SelectedIndexChanged += new System.EventHandler(this.ckb_ClickAllowOnly1);
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.Location = new System.Drawing.Point(5, 125);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(97, 13);
            this.label6.TabIndex = 48;
            this.label6.Text = "SDR (second half):";
            // 
            // groupBoxPREF
            // 
            this.groupBoxPREF.Controls.Add(this.groupBoxTracks);
            this.groupBoxPREF.Controls.Add(this.groupBoxRanks);
            this.groupBoxPREF.Controls.Add(this.groupBoxRetrace);
            this.groupBoxPREF.Location = new System.Drawing.Point(260, 10);
            this.groupBoxPREF.Name = "groupBoxPREF";
            this.groupBoxPREF.Size = new System.Drawing.Size(161, 444);
            this.groupBoxPREF.TabIndex = 4;
            this.groupBoxPREF.TabStop = false;
            this.groupBoxPREF.Text = "Preference learning";
            // 
            // groupBoxTracks
            // 
            this.groupBoxTracks.Controls.Add(this.cancelAsyncButtonTrSet);
            this.groupBoxTracks.Controls.Add(this.startAsyncButtonGenTrData);
            this.groupBoxTracks.Controls.Add(this.Tracks);
            this.groupBoxTracks.Location = new System.Drawing.Point(5, 15);
            this.groupBoxTracks.Name = "groupBoxTracks";
            this.groupBoxTracks.Size = new System.Drawing.Size(150, 205);
            this.groupBoxTracks.TabIndex = 1;
            this.groupBoxTracks.TabStop = false;
            this.groupBoxTracks.Text = "Trajectories";
            // 
            // cancelAsyncButtonTrSet
            // 
            this.cancelAsyncButtonTrSet.Location = new System.Drawing.Point(75, 175);
            this.cancelAsyncButtonTrSet.Name = "cancelAsyncButtonTrSet";
            this.cancelAsyncButtonTrSet.Size = new System.Drawing.Size(60, 25);
            this.cancelAsyncButtonTrSet.TabIndex = 2;
            this.cancelAsyncButtonTrSet.Text = "Cancel";
            this.cancelAsyncButtonTrSet.UseVisualStyleBackColor = true;
            this.cancelAsyncButtonTrSet.Click += new System.EventHandler(this.cancelAsyncButtonTrSet_Click);
            // 
            // startAsyncButtonGenTrData
            // 
            this.startAsyncButtonGenTrData.Location = new System.Drawing.Point(10, 175);
            this.startAsyncButtonGenTrData.Name = "startAsyncButtonGenTrData";
            this.startAsyncButtonGenTrData.Size = new System.Drawing.Size(60, 25);
            this.startAsyncButtonGenTrData.TabIndex = 1;
            this.startAsyncButtonGenTrData.Text = "Optimise";
            this.startAsyncButtonGenTrData.UseVisualStyleBackColor = true;
            this.startAsyncButtonGenTrData.Click += new System.EventHandler(this.startAsyncButtonTrSet_Click);
            // 
            // Tracks
            // 
            this.Tracks.FormattingEnabled = true;
            this.Tracks.Items.AddRange(new object[]
            {
                TrainingSet.Trajectory.OPT,
                TrainingSet.Trajectory.MWR,
                TrainingSet.Trajectory.LWR,
                TrainingSet.Trajectory.SPT,
                TrainingSet.Trajectory.LPT,
                TrainingSet.Trajectory.RND,
                TrainingSet.Trajectory.CMA,
                TrainingSet.Trajectory.ILSUP,
                TrainingSet.Trajectory.ILUNSUP,
                TrainingSet.Trajectory.ILFIX
            });
            this.Tracks.Location = new System.Drawing.Point(5, 15);
            this.Tracks.Name = "Tracks";
            this.Tracks.Size = new System.Drawing.Size(125, 154);
            this.Tracks.TabIndex = 23;
            this.Tracks.SelectedIndexChanged += new System.EventHandler(this.ckb_SelectedIndexChanged);
            // 
            // groupBoxRanks
            // 
            this.groupBoxRanks.Controls.Add(this.Ranks);
            this.groupBoxRanks.Controls.Add(this.cancelAsyncButtonRankTrData);
            this.groupBoxRanks.Controls.Add(this.startAsyncButtonRankTrData);
            this.groupBoxRanks.Location = new System.Drawing.Point(5, 320);
            this.groupBoxRanks.Name = "groupBoxRanks";
            this.groupBoxRanks.Size = new System.Drawing.Size(150, 115);
            this.groupBoxRanks.TabIndex = 3;
            this.groupBoxRanks.TabStop = false;
            this.groupBoxRanks.Text = "Preference set";
            // 
            // Ranks
            // 
            this.Ranks.FormattingEnabled = true;
            this.Ranks.Items.AddRange(new object[]
            {
                PreferenceSet.Ranking.Basic,
                PreferenceSet.Ranking.FullPareto,
                PreferenceSet.Ranking.PartialPareto,
                PreferenceSet.Ranking.All
            });
            this.Ranks.Location = new System.Drawing.Point(5, 15);
            this.Ranks.Name = "Ranks";
            this.Ranks.Size = new System.Drawing.Size(140, 64);
            this.Ranks.TabIndex = 24;
            this.Ranks.SelectedIndexChanged += new System.EventHandler(this.ckb_SelectedIndexChanged);
            // 
            // cancelAsyncButtonRankTrData
            // 
            this.cancelAsyncButtonRankTrData.Location = new System.Drawing.Point(75, 85);
            this.cancelAsyncButtonRankTrData.Name = "cancelAsyncButtonRankTrData";
            this.cancelAsyncButtonRankTrData.Size = new System.Drawing.Size(60, 25);
            this.cancelAsyncButtonRankTrData.TabIndex = 55;
            this.cancelAsyncButtonRankTrData.Text = "Cancel";
            this.cancelAsyncButtonRankTrData.UseVisualStyleBackColor = true;
            this.cancelAsyncButtonRankTrData.Click += new System.EventHandler(this.cancelAsyncButtonPrefSet_Click);
            // 
            // startAsyncButtonRankTrData
            // 
            this.startAsyncButtonRankTrData.Location = new System.Drawing.Point(10, 85);
            this.startAsyncButtonRankTrData.Name = "startAsyncButtonRankTrData";
            this.startAsyncButtonRankTrData.Size = new System.Drawing.Size(60, 25);
            this.startAsyncButtonRankTrData.TabIndex = 56;
            this.startAsyncButtonRankTrData.Text = "Rank";
            this.startAsyncButtonRankTrData.UseVisualStyleBackColor = true;
            this.startAsyncButtonRankTrData.Click += new System.EventHandler(this.startAsyncButtonPrefSet_Click);
            // 
            // groupBoxRetrace
            // 
            this.groupBoxRetrace.Controls.Add(this.cancelAsyncButtonRetrace);
            this.groupBoxRetrace.Controls.Add(this.startAsyncButtonRetrace);
            this.groupBoxRetrace.Controls.Add(this.PhiLocal);
            this.groupBoxRetrace.Controls.Add(this.PhiGlobal);
            this.groupBoxRetrace.Location = new System.Drawing.Point(5, 224);
            this.groupBoxRetrace.Name = "groupBoxRetrace";
            this.groupBoxRetrace.Size = new System.Drawing.Size(150, 90);
            this.groupBoxRetrace.TabIndex = 2;
            this.groupBoxRetrace.TabStop = false;
            this.groupBoxRetrace.Text = "Retrace";
            // 
            // cancelAsyncButtonRetrace
            // 
            this.cancelAsyncButtonRetrace.Location = new System.Drawing.Point(75, 60);
            this.cancelAsyncButtonRetrace.Name = "cancelAsyncButtonRetrace";
            this.cancelAsyncButtonRetrace.Size = new System.Drawing.Size(60, 25);
            this.cancelAsyncButtonRetrace.TabIndex = 56;
            this.cancelAsyncButtonRetrace.Text = "Cancel";
            this.cancelAsyncButtonRetrace.UseVisualStyleBackColor = true;
            this.cancelAsyncButtonRetrace.Click += new System.EventHandler(this.cancelAsyncButtonRetrace_Click);
            // 
            // startAsyncButtonRetrace
            // 
            this.startAsyncButtonRetrace.Location = new System.Drawing.Point(10, 60);
            this.startAsyncButtonRetrace.Name = "startAsyncButtonRetrace";
            this.startAsyncButtonRetrace.Size = new System.Drawing.Size(60, 25);
            this.startAsyncButtonRetrace.TabIndex = 55;
            this.startAsyncButtonRetrace.Text = "Retrace";
            this.startAsyncButtonRetrace.UseVisualStyleBackColor = true;
            this.startAsyncButtonRetrace.Click += new System.EventHandler(this.startAsyncButtonRetrace_Click);
            // 
            // PhiLocal
            // 
            this.PhiLocal.AutoSize = true;
            this.PhiLocal.Location = new System.Drawing.Point(5, 15);
            this.PhiLocal.Name = "PhiLocal";
            this.PhiLocal.Size = new System.Drawing.Size(92, 17);
            this.PhiLocal.TabIndex = 30;
            this.PhiLocal.TabStop = true;
            this.PhiLocal.Text = String.Format("{0} features", Features.Mode.Local);
            this.PhiLocal.UseVisualStyleBackColor = true;
            // 
            // PhiGlobal
            // 
            this.PhiGlobal.AutoSize = true;
            this.PhiGlobal.Location = new System.Drawing.Point(5, 35);
            this.PhiGlobal.Name = "PhiGlobal";
            this.PhiGlobal.Size = new System.Drawing.Size(96, 17);
            this.PhiGlobal.TabIndex = 32;
            this.PhiGlobal.TabStop = true;
            this.PhiGlobal.Text = String.Format("{0} features", Features.Mode.Global);
            this.PhiGlobal.UseVisualStyleBackColor = true;
            // 
            // groupBoxDependent
            // 
            this.groupBoxDependent.Controls.Add(this.radioButtonCMAIndependent);
            this.groupBoxDependent.Controls.Add(this.radioButtonCMADependent);
            this.groupBoxDependent.Location = new System.Drawing.Point(145, 392);
            this.groupBoxDependent.Name = "groupBoxDependent";
            this.groupBoxDependent.Size = new System.Drawing.Size(110, 62);
            this.groupBoxDependent.TabIndex = 24;
            this.groupBoxDependent.TabStop = false;
            this.groupBoxDependent.Text = "Model step";
            // 
            // radioButtonCMAIndependent
            // 
            this.radioButtonCMAIndependent.AutoSize = true;
            this.radioButtonCMAIndependent.Checked = true;
            this.radioButtonCMAIndependent.Location = new System.Drawing.Point(5, 15);
            this.radioButtonCMAIndependent.Name = "radioButtonCMAIndependent";
            this.radioButtonCMAIndependent.Size = new System.Drawing.Size(85, 17);
            this.radioButtonCMAIndependent.TabIndex = 37;
            this.radioButtonCMAIndependent.TabStop = true;
            this.radioButtonCMAIndependent.Text = "Independent";
            this.radioButtonCMAIndependent.UseVisualStyleBackColor = true;
            // 
            // radioButtonCMADependent
            // 
            this.radioButtonCMADependent.AutoSize = true;
            this.radioButtonCMADependent.Location = new System.Drawing.Point(5, 35);
            this.radioButtonCMADependent.Name = "radioButtonCMADependent";
            this.radioButtonCMADependent.Size = new System.Drawing.Size(78, 17);
            this.radioButtonCMADependent.TabIndex = 38;
            this.radioButtonCMADependent.Text = "Dependent";
            this.radioButtonCMADependent.UseVisualStyleBackColor = true;
            // 
            // groupBoxSDR
            // 
            this.groupBoxSDR.Controls.Add(this.applySDR);
            this.groupBoxSDR.Controls.Add(this.SDR);
            this.groupBoxSDR.Location = new System.Drawing.Point(145, 10);
            this.groupBoxSDR.Name = "groupBoxSDR";
            this.groupBoxSDR.Size = new System.Drawing.Size(110, 129);
            this.groupBoxSDR.TabIndex = 23;
            this.groupBoxSDR.TabStop = false;
            this.groupBoxSDR.Text = "SDR";
            // 
            // applySDR
            // 
            this.applySDR.Location = new System.Drawing.Point(25, 100);
            this.applySDR.Name = "applySDR";
            this.applySDR.Size = new System.Drawing.Size(60, 25);
            this.applySDR.TabIndex = 0;
            this.applySDR.Text = "Apply";
            this.applySDR.UseVisualStyleBackColor = true;
            this.applySDR.Click += new System.EventHandler(this.buttonSDRStart_Click);
            // 
            // SDR
            // 
            this.SDR.FormattingEnabled = true;
            this.SDR.Items.AddRange(new object[]
            {
                SDRData.SDR.SPT,
                SDRData.SDR.LPT,
                SDRData.SDR.LWR,
                SDRData.SDR.MWR,
                SDRData.SDR.RND
            });
            this.SDR.Location = new System.Drawing.Point(5, 15);
            this.SDR.Name = "SDR";
            this.SDR.Size = new System.Drawing.Size(100, 79);
            this.SDR.TabIndex = 24;
            this.SDR.SelectedIndexChanged += new System.EventHandler(this.ckb_SelectedIndexChanged);
            // 
            // groupBoxOpt
            // 
            this.groupBoxOpt.Controls.Add(this.labelTmLimit);
            this.groupBoxOpt.Controls.Add(this.cancelAsyncButtonOptimize);
            this.groupBoxOpt.Controls.Add(this.TimeLimit);
            this.groupBoxOpt.Controls.Add(this.startAsyncButtonOptimize);
            this.groupBoxOpt.Location = new System.Drawing.Point(10, 419);
            this.groupBoxOpt.Name = "groupBoxOpt";
            this.groupBoxOpt.Size = new System.Drawing.Size(130, 84);
            this.groupBoxOpt.TabIndex = 24;
            this.groupBoxOpt.TabStop = false;
            this.groupBoxOpt.Text = "Optimisation";
            // 
            // labelTmLimit
            // 
            this.labelTmLimit.AutoSize = true;
            this.labelTmLimit.Location = new System.Drawing.Point(5, 15);
            this.labelTmLimit.Name = "labelTmLimit";
            this.labelTmLimit.Size = new System.Drawing.Size(114, 13);
            this.labelTmLimit.TabIndex = 35;
            this.labelTmLimit.Text = "Time limit per instance:";
            // 
            // cancelAsyncButtonOptimize
            // 
            this.cancelAsyncButtonOptimize.Location = new System.Drawing.Point(65, 55);
            this.cancelAsyncButtonOptimize.Name = "cancelAsyncButtonOptimize";
            this.cancelAsyncButtonOptimize.Size = new System.Drawing.Size(60, 25);
            this.cancelAsyncButtonOptimize.TabIndex = 50;
            this.cancelAsyncButtonOptimize.Text = "Cancel";
            this.cancelAsyncButtonOptimize.UseVisualStyleBackColor = true;
            this.cancelAsyncButtonOptimize.Click += new System.EventHandler(this.cancelAsyncButtonOptimize_Click);
            // 
            // TimeLimit
            // 
            this.TimeLimit.Location = new System.Drawing.Point(80, 31);
            this.TimeLimit.Maximum = new decimal(new int[]
            {
                6000,
                0,
                0,
                0
            });
            this.TimeLimit.Minimum = new decimal(new int[]
            {
                1,
                0,
                0,
                0
            });
            this.TimeLimit.Name = "TimeLimit";
            this.TimeLimit.Size = new System.Drawing.Size(44, 20);
            this.TimeLimit.TabIndex = 34;
            this.TimeLimit.Value = new decimal(new int[]
            {
                10,
                0,
                0,
                0
            });
            // 
            // startAsyncButtonOptimize
            // 
            this.startAsyncButtonOptimize.Location = new System.Drawing.Point(5, 55);
            this.startAsyncButtonOptimize.Name = "startAsyncButtonOptimize";
            this.startAsyncButtonOptimize.Size = new System.Drawing.Size(60, 25);
            this.startAsyncButtonOptimize.TabIndex = 46;
            this.startAsyncButtonOptimize.Text = "Optimise";
            this.startAsyncButtonOptimize.UseVisualStyleBackColor = true;
            this.startAsyncButtonOptimize.Click += new System.EventHandler(this.startAsyncButtonOptimize_Click);
            // 
            // progressBarOuter
            // 
            this.progressBarOuter.Location = new System.Drawing.Point(12, 154);
            this.progressBarOuter.Name = "progressBarOuter";
            this.progressBarOuter.Size = new System.Drawing.Size(332, 25);
            this.progressBarOuter.TabIndex = 22;
            // 
            // splitContainerForm
            // 
            this.splitContainerForm.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainerForm.Location = new System.Drawing.Point(0, 0);
            this.splitContainerForm.Name = "splitContainerForm";
            // 
            // splitContainerForm.Panel1
            // 
            this.splitContainerForm.Panel1.Controls.Add(this.groupBoxBDR);
            this.splitContainerForm.Panel1.Controls.Add(this.groupBoxDependent);
            this.splitContainerForm.Panel1.Controls.Add(this.groupBoxCMAObjFun);
            this.splitContainerForm.Panel1.Controls.Add(this.groupBoxPREF);
            this.splitContainerForm.Panel1.Controls.Add(this.groupBoxOpt);
            this.splitContainerForm.Panel1.Controls.Add(this.groupBoxData);
            this.splitContainerForm.Panel1.Controls.Add(this.groupBoxSDR);
            // 
            // splitContainerForm.Panel2
            // 
            this.splitContainerForm.Panel2.Controls.Add(this.textHeader);
            this.splitContainerForm.Panel2.Controls.Add(this.textContent);
            this.splitContainerForm.Panel2.Controls.Add(this.progressBarInner);
            this.splitContainerForm.Panel2.Controls.Add(this.progressBarOuter);
            this.splitContainerForm.Size = new System.Drawing.Size(790, 556);
            this.splitContainerForm.SplitterDistance = 430;
            this.splitContainerForm.TabIndex = 0;
            // 
            // textHeader
            // 
            this.textHeader.Location = new System.Drawing.Point(12, 10);
            this.textHeader.Name = "textHeader";
            this.textHeader.Size = new System.Drawing.Size(332, 136);
            this.textHeader.TabIndex = 25;
            this.textHeader.Text = "";
            // 
            // textContent
            // 
            this.textContent.Location = new System.Drawing.Point(12, 189);
            this.textContent.Name = "textContent";
            this.textContent.Size = new System.Drawing.Size(332, 318);
            this.textContent.TabIndex = 24;
            this.textContent.Text = "";
            this.textContent.TextChanged += new System.EventHandler(this.textContent_TextChanged);
            // 
            // App
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(790, 556);
            this.Controls.Add(this.splitContainerForm);
            this.Name = "App";
            this.Text = "JSP PREF SIMULATION";
            this.Load += new System.EventHandler(this.App_Load);
            this.groupBoxData.ResumeLayout(false);
            this.groupBoxSet.ResumeLayout(false);
            this.groupBoxProblem.ResumeLayout(false);
            this.groupBoxDim.ResumeLayout(false);
            this.groupBoxCMAObjFun.ResumeLayout(false);
            this.groupBoxCMAObjFun.PerformLayout();
            this.groupBoxBDR.ResumeLayout(false);
            this.groupBoxBDR.PerformLayout();
            ((System.ComponentModel.ISupportInitialize) (this.splitBDR)).EndInit();
            this.groupBoxPREF.ResumeLayout(false);
            this.groupBoxTracks.ResumeLayout(false);
            this.groupBoxRanks.ResumeLayout(false);
            this.groupBoxRetrace.ResumeLayout(false);
            this.groupBoxRetrace.PerformLayout();
            this.groupBoxDependent.ResumeLayout(false);
            this.groupBoxDependent.PerformLayout();
            this.groupBoxSDR.ResumeLayout(false);
            this.groupBoxOpt.ResumeLayout(false);
            this.groupBoxOpt.PerformLayout();
            ((System.ComponentModel.ISupportInitialize) (this.TimeLimit)).EndInit();
            this.splitContainerForm.Panel1.ResumeLayout(false);
            this.splitContainerForm.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize) (this.splitContainerForm)).EndInit();
            this.splitContainerForm.ResumeLayout(false);
            this.ResumeLayout(false);

        }

        private void InitializeBackgroundWorker()
        {
            // 
            // bkgWorkerOptimize
            // 
            this.bkgWorkerOptimise.WorkerReportsProgress = true;
            this.bkgWorkerOptimise.WorkerSupportsCancellation = true;
            this.bkgWorkerOptimise.DoWork += new System.ComponentModel.DoWorkEventHandler(bkgWorkerOptimise_DoWork);
            this.bkgWorkerOptimise.RunWorkerCompleted +=
                new System.ComponentModel.RunWorkerCompletedEventHandler(bkgWorker_RunWorkerCompleted);
            this.bkgWorkerOptimise.ProgressChanged +=
                new System.ComponentModel.ProgressChangedEventHandler(bkgWorker_ProgressChanged);
            // 
            // bkgWorkerGenTrData
            // 
            this.bkgWorkerTrSet.WorkerReportsProgress = true;
            this.bkgWorkerTrSet.WorkerSupportsCancellation = true;
            this.bkgWorkerTrSet.DoWork += new System.ComponentModel.DoWorkEventHandler(bkgWorkerTrSet_DoWork);
            this.bkgWorkerTrSet.RunWorkerCompleted +=
                new System.ComponentModel.RunWorkerCompletedEventHandler(bkgWorker_RunWorkerCompleted);
            this.bkgWorkerTrSet.ProgressChanged +=
                new System.ComponentModel.ProgressChangedEventHandler(bkgWorker_ProgressChanged);
            // 
            // bkgWorkerFeatTrData
            //             
            this.bkgWorkerRetrace.WorkerReportsProgress = true;
            this.bkgWorkerRetrace.WorkerSupportsCancellation = true;
            this.bkgWorkerRetrace.DoWork += new System.ComponentModel.DoWorkEventHandler(bkgWorkerRetrace_DoWork);
            this.bkgWorkerRetrace.RunWorkerCompleted +=
                new System.ComponentModel.RunWorkerCompletedEventHandler(bkgWorker_RunWorkerCompleted);
            this.bkgWorkerRetrace.ProgressChanged +=
                new System.ComponentModel.ProgressChangedEventHandler(bkgWorker_ProgressChanged);
            // 
            // bkgWorkerRankTrData
            // 
            this.bkgWorkerPrefSet.WorkerReportsProgress = true;
            this.bkgWorkerPrefSet.WorkerSupportsCancellation = true;
            this.bkgWorkerPrefSet.DoWork += new System.ComponentModel.DoWorkEventHandler(bkgWorkerPrefSet_DoWork);
            this.bkgWorkerPrefSet.RunWorkerCompleted +=
                new System.ComponentModel.RunWorkerCompletedEventHandler(bkgWorker_RunWorkerCompleted);
            this.bkgWorkerPrefSet.ProgressChanged +=
                new System.ComponentModel.ProgressChangedEventHandler(bkgWorker_ProgressChanged);
            // 
            // bkgWorkerCMA
            // 
            this.bkgWorkerCMAES.WorkerReportsProgress = true;
            this.bkgWorkerCMAES.WorkerSupportsCancellation = true;
            this.bkgWorkerCMAES.DoWork += new System.ComponentModel.DoWorkEventHandler(bkgWorkerCMAES_DoWork);
            this.bkgWorkerCMAES.RunWorkerCompleted +=
                new System.ComponentModel.RunWorkerCompletedEventHandler(bkgWorker_RunWorkerCompleted);
            this.bkgWorkerCMAES.ProgressChanged +=
                new System.ComponentModel.ProgressChangedEventHandler(bkgWorker_ProgressChanged);
        }

        #endregion

        private BackgroundWorker bkgWorkerOptimise;
        private BackgroundWorker bkgWorkerTrSet;
        private BackgroundWorker bkgWorkerCMAES;
        private BackgroundWorker bkgWorkerPrefSet;
        private BackgroundWorker bkgWorkerRetrace;
        private GroupBox groupBoxData;
        private GroupBox groupBoxSet;
        private CheckedListBox Set;
        private ProgressBar progressBarOuter;
        private CheckedListBox Extended;
        private ProgressBar progressBarInner;
        private GroupBox groupBoxOpt;
        private Label labelTmLimit;
        private Button cancelAsyncButtonOptimize;
        private NumericUpDown TimeLimit;
        private Button startAsyncButtonOptimize;
        private GroupBox groupBoxProblem;
        private GroupBox groupBoxSDR;
        private Button applySDR;
        private CheckedListBox SDR;
        private GroupBox groupBoxPREF;
        private GroupBox groupBoxTracks;
        private Button cancelAsyncButtonTrSet;
        private Button startAsyncButtonGenTrData;
        private CheckedListBox Tracks;
        private GroupBox groupBoxRanks;
        private CheckedListBox Ranks;
        private GroupBox groupBoxDependent;
        private RadioButton radioButtonCMAIndependent;
        private RadioButton radioButtonCMADependent;
        private Button cancelAsyncButtonRankTrData;
        private Button startAsyncButtonRankTrData;
        private GroupBox groupBoxRetrace;
        private Button cancelAsyncButtonRetrace;
        private Button startAsyncButtonRetrace;
        private RadioButton PhiLocal;
        private RadioButton PhiGlobal;
        private CheckedListBox Problems;
        private GroupBox groupBoxCMAObjFun;
        private GroupBox groupBoxBDR;
        private Button applyBDR;
        private NumericUpDown splitBDR;
        private Label label7;
        private Label label8;
        private CheckedListBox SDR2;
        private CheckedListBox SDR1;
        private Label label6;
        private Button cancelAsyncButtonCMA;
        private Button startAsyncButtonCMA;
        private RadioButton CMAwrtMakespan;
        private RadioButton CMAwrtRho;
        private CheckedListBox ORLIB;
        private GroupBox groupBoxDim;
        private CheckedListBox Dimension;
        private SplitContainer splitContainerForm;
        private RichTextBox textHeader;
        private RichTextBox textContent;
        private Timer timer1;
    }
}