using System.Drawing;

namespace Scheduling
{
    partial class App
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

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
            this.splitContainerForm = new System.Windows.Forms.SplitContainer();
            this.progressBarOuter = new System.Windows.Forms.ProgressBar();
            this.pictureBox = new System.Windows.Forms.PictureBox();
            this.labelDefault = new System.Windows.Forms.Label();
            this.comboBoxScheme = new System.Windows.Forms.ComboBox();
            this.labelStatusbar = new System.Windows.Forms.Label();
            this.labelFolder = new System.Windows.Forms.Label();
            this.richTextBoxConsole = new System.Windows.Forms.RichTextBox();
            this.textBoxDir = new System.Windows.Forms.TextBox();
            this.richTextBox = new System.Windows.Forms.RichTextBox();
            this.progressBarInner = new System.Windows.Forms.ProgressBar();
            this.bkgWorkerRankTrData = new System.ComponentModel.BackgroundWorker();
            this.bkgWorkerOptimize = new System.ComponentModel.BackgroundWorker();
            this.bkgWorkerGenTrData = new System.ComponentModel.BackgroundWorker();
            this.bkgWorkerCMA = new System.ComponentModel.BackgroundWorker();
            this.bkgWorkerFeatTrData = new System.ComponentModel.BackgroundWorker();
            this.tabCMAES = new System.Windows.Forms.TabPage();
            this.splitContainer10 = new System.Windows.Forms.SplitContainer();
            this.splitContainer11 = new System.Windows.Forms.SplitContainer();
            this.splitContainer12 = new System.Windows.Forms.SplitContainer();
            this.cancelAsyncButtonCMA = new System.Windows.Forms.Button();
            this.startAsyncButtonCMA = new System.Windows.Forms.Button();
            this.radioButtonCMAIndependent = new System.Windows.Forms.RadioButton();
            this.radioButtonCMADependent = new System.Windows.Forms.RadioButton();
            this.label36 = new System.Windows.Forms.Label();
            this.radioButtonCMAwrtRho = new System.Windows.Forms.RadioButton();
            this.radioButtonCMAwrtMakespan = new System.Windows.Forms.RadioButton();
            this.label37 = new System.Windows.Forms.Label();
            this.label33 = new System.Windows.Forms.Label();
            this.label34 = new System.Windows.Forms.Label();
            this.ckbDimCMA = new System.Windows.Forms.CheckedListBox();
            this.ckbProblemCMA = new System.Windows.Forms.CheckedListBox();
            this.tabLinear = new System.Windows.Forms.TabPage();
            this.splitContainer8 = new System.Windows.Forms.SplitContainer();
            this.label17 = new System.Windows.Forms.Label();
            this.tbLocal5 = new System.Windows.Forms.TextBox();
            this.label13 = new System.Windows.Forms.Label();
            this.tbLocal6 = new System.Windows.Forms.TextBox();
            this.tbLocal1 = new System.Windows.Forms.TextBox();
            this.label14 = new System.Windows.Forms.Label();
            this.label18 = new System.Windows.Forms.Label();
            this.tbLocal2 = new System.Windows.Forms.TextBox();
            this.label15 = new System.Windows.Forms.Label();
            this.tbLocal7 = new System.Windows.Forms.TextBox();
            this.tbLocal3 = new System.Windows.Forms.TextBox();
            this.label25 = new System.Windows.Forms.Label();
            this.label19 = new System.Windows.Forms.Label();
            this.label26 = new System.Windows.Forms.Label();
            this.tbLocal4 = new System.Windows.Forms.TextBox();
            this.tbLocal8 = new System.Windows.Forms.TextBox();
            this.tbLocal13 = new System.Windows.Forms.TextBox();
            this.label16 = new System.Windows.Forms.Label();
            this.label20 = new System.Windows.Forms.Label();
            this.label21 = new System.Windows.Forms.Label();
            this.tbLocal9 = new System.Windows.Forms.TextBox();
            this.label22 = new System.Windows.Forms.Label();
            this.tbLocal10 = new System.Windows.Forms.TextBox();
            this.label23 = new System.Windows.Forms.Label();
            this.tbLocal11 = new System.Windows.Forms.TextBox();
            this.label24 = new System.Windows.Forms.Label();
            this.tbLocal12 = new System.Windows.Forms.TextBox();
            this.label27 = new System.Windows.Forms.Label();
            this.tbLocal14 = new System.Windows.Forms.TextBox();
            this.label28 = new System.Windows.Forms.Label();
            this.tbLocal15 = new System.Windows.Forms.TextBox();
            this.label29 = new System.Windows.Forms.Label();
            this.tbLocal16 = new System.Windows.Forms.TextBox();
            this.label30 = new System.Windows.Forms.Label();
            this.tbLocal17 = new System.Windows.Forms.TextBox();
            this.label31 = new System.Windows.Forms.Label();
            this.tbLocal0 = new System.Windows.Forms.TextBox();
            this.label32 = new System.Windows.Forms.Label();
            this.tbLocal18 = new System.Windows.Forms.TextBox();
            this.btnLocalReset = new System.Windows.Forms.Button();
            this.btnLocalApply = new System.Windows.Forms.Button();
            this.splitContainer9 = new System.Windows.Forms.SplitContainer();
            this.radioButtonIndependent = new System.Windows.Forms.RadioButton();
            this.buttonApplyLiblinearLogs = new System.Windows.Forms.Button();
            this.comboBoxLiblinearLogs = new System.Windows.Forms.ComboBox();
            this.radioButtonDependent = new System.Windows.Forms.RadioButton();
            this.labelLiblinearLogs = new System.Windows.Forms.Label();
            this.ckbSetLIN = new System.Windows.Forms.CheckedListBox();
            this.ckbDataLIN = new System.Windows.Forms.CheckedListBox();
            this.label11 = new System.Windows.Forms.Label();
            this.label10 = new System.Windows.Forms.Label();
            this.label12 = new System.Windows.Forms.Label();
            this.ckbDimLIN = new System.Windows.Forms.CheckedListBox();
            this.tabBDR = new System.Windows.Forms.TabPage();
            this.splitContainer7 = new System.Windows.Forms.SplitContainer();
            this.ckbSDR2BDR = new System.Windows.Forms.CheckedListBox();
            this.label6 = new System.Windows.Forms.Label();
            this.buttonSimpleBDR = new System.Windows.Forms.Button();
            this.numericUpDownBDRsplitStep = new System.Windows.Forms.NumericUpDown();
            this.label7 = new System.Windows.Forms.Label();
            this.ckbSDR1BDR = new System.Windows.Forms.CheckedListBox();
            this.label8 = new System.Windows.Forms.Label();
            this.label9 = new System.Windows.Forms.Label();
            this.ckbDataBDR = new System.Windows.Forms.CheckedListBox();
            this.label5 = new System.Windows.Forms.Label();
            this.label4 = new System.Windows.Forms.Label();
            this.label3 = new System.Windows.Forms.Label();
            this.ckbSetBDR = new System.Windows.Forms.CheckedListBox();
            this.ckbDimBDR = new System.Windows.Forms.CheckedListBox();
            this.tabTraining = new System.Windows.Forms.TabPage();
            this.splitContainer2 = new System.Windows.Forms.SplitContainer();
            this.splitContainer3 = new System.Windows.Forms.SplitContainer();
            this.splitContainer13 = new System.Windows.Forms.SplitContainer();
            this.splitContainer14 = new System.Windows.Forms.SplitContainer();
            this.ckbExtendTrainingSet = new System.Windows.Forms.CheckedListBox();
            this.radioImitationLearningUnsupervised = new System.Windows.Forms.RadioButton();
            this.radioImitationLearningSupervised = new System.Windows.Forms.RadioButton();
            this.radioImitationLearningFixedSupervision = new System.Windows.Forms.RadioButton();
            this.ckbRanks = new System.Windows.Forms.CheckedListBox();
            this.startAsyncButtonRankTrData = new System.Windows.Forms.Button();
            this.labelRanks = new System.Windows.Forms.Label();
            this.cancelAsyncButtonRankTrData = new System.Windows.Forms.Button();
            this.splitContainer6 = new System.Windows.Forms.SplitContainer();
            this.radioLocal = new System.Windows.Forms.RadioButton();
            this.radioGlobal = new System.Windows.Forms.RadioButton();
            this.cancelAsyncButtonFeatTrData = new System.Windows.Forms.Button();
            this.labelScale = new System.Windows.Forms.Label();
            this.startAsyncButtonFeatTrData = new System.Windows.Forms.Button();
            this.cancelAsyncButtonGenTrData = new System.Windows.Forms.Button();
            this.radioButtonGUROBItraining = new System.Windows.Forms.RadioButton();
            this.startAsyncButtonGenTrData = new System.Windows.Forms.Button();
            this.radioButtonGLPKtraining = new System.Windows.Forms.RadioButton();
            this.linearSolver = new System.Windows.Forms.Label();
            this.labelProblemModel = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.labelTracks = new System.Windows.Forms.Label();
            this.ckbTracks = new System.Windows.Forms.CheckedListBox();
            this.ckbTrainingDim = new System.Windows.Forms.CheckedListBox();
            this.ckbProblemModel = new System.Windows.Forms.CheckedListBox();
            this.labelModel = new System.Windows.Forms.Label();
            this.comboBoxLiblinearLogfile = new System.Windows.Forms.ComboBox();
            this.labelLiblinearModel = new System.Windows.Forms.Label();
            this.labelLiblinearNrFeat = new System.Windows.Forms.Label();
            this.numericLiblinearModel = new System.Windows.Forms.NumericUpDown();
            this.numericLiblinearNrFeat = new System.Windows.Forms.NumericUpDown();
            this.tabSimple = new System.Windows.Forms.TabPage();
            this.splitContainer1 = new System.Windows.Forms.SplitContainer();
            this.splitContainer4 = new System.Windows.Forms.SplitContainer();
            this.radioButtonGUROBI = new System.Windows.Forms.RadioButton();
            this.startAsyncButtonOptimize = new System.Windows.Forms.Button();
            this.labelTmLimit = new System.Windows.Forms.Label();
            this.numericUpDownTmLimit = new System.Windows.Forms.NumericUpDown();
            this.radioButtonGLPK = new System.Windows.Forms.RadioButton();
            this.labelOptimize = new System.Windows.Forms.Label();
            this.cancelAsyncButtonOptimize = new System.Windows.Forms.Button();
            this.labelOptimization = new System.Windows.Forms.Label();
            this.ckbSimpleSDR = new System.Windows.Forms.CheckedListBox();
            this.labelSimpleSDR = new System.Windows.Forms.Label();
            this.buttonSimpleStart = new System.Windows.Forms.Button();
            this.numericUpDownInstanceID = new System.Windows.Forms.NumericUpDown();
            this.ckbSimpleProblem = new System.Windows.Forms.CheckedListBox();
            this.labelSimpleProblem = new System.Windows.Forms.Label();
            this.labelSimpleData = new System.Windows.Forms.Label();
            this.labelSimpleInstanceID = new System.Windows.Forms.Label();
            this.labelSimpleDim = new System.Windows.Forms.Label();
            this.ckbSimpleDataSet = new System.Windows.Forms.CheckedListBox();
            this.ckbSimpleDim = new System.Windows.Forms.CheckedListBox();
            this.radioSimpleProblemsAll = new System.Windows.Forms.RadioButton();
            this.radioSimpleProblemsSingle = new System.Windows.Forms.RadioButton();
            this.ckbSimpleORLIB = new System.Windows.Forms.CheckedListBox();
            this.tabControl = new System.Windows.Forms.TabControl();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainerForm)).BeginInit();
            this.splitContainerForm.Panel1.SuspendLayout();
            this.splitContainerForm.Panel2.SuspendLayout();
            this.splitContainerForm.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox)).BeginInit();
            this.tabCMAES.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer10)).BeginInit();
            this.splitContainer10.Panel1.SuspendLayout();
            this.splitContainer10.Panel2.SuspendLayout();
            this.splitContainer10.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer11)).BeginInit();
            this.splitContainer11.Panel1.SuspendLayout();
            this.splitContainer11.Panel2.SuspendLayout();
            this.splitContainer11.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer12)).BeginInit();
            this.splitContainer12.Panel1.SuspendLayout();
            this.splitContainer12.Panel2.SuspendLayout();
            this.splitContainer12.SuspendLayout();
            this.tabLinear.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer8)).BeginInit();
            this.splitContainer8.Panel1.SuspendLayout();
            this.splitContainer8.Panel2.SuspendLayout();
            this.splitContainer8.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer9)).BeginInit();
            this.splitContainer9.Panel1.SuspendLayout();
            this.splitContainer9.Panel2.SuspendLayout();
            this.splitContainer9.SuspendLayout();
            this.tabBDR.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer7)).BeginInit();
            this.splitContainer7.Panel1.SuspendLayout();
            this.splitContainer7.Panel2.SuspendLayout();
            this.splitContainer7.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.numericUpDownBDRsplitStep)).BeginInit();
            this.tabTraining.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer2)).BeginInit();
            this.splitContainer2.Panel1.SuspendLayout();
            this.splitContainer2.Panel2.SuspendLayout();
            this.splitContainer2.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer3)).BeginInit();
            this.splitContainer3.Panel1.SuspendLayout();
            this.splitContainer3.Panel2.SuspendLayout();
            this.splitContainer3.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer13)).BeginInit();
            this.splitContainer13.Panel1.SuspendLayout();
            this.splitContainer13.Panel2.SuspendLayout();
            this.splitContainer13.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer14)).BeginInit();
            this.splitContainer14.Panel1.SuspendLayout();
            this.splitContainer14.Panel2.SuspendLayout();
            this.splitContainer14.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer6)).BeginInit();
            this.splitContainer6.Panel1.SuspendLayout();
            this.splitContainer6.Panel2.SuspendLayout();
            this.splitContainer6.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.numericLiblinearModel)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.numericLiblinearNrFeat)).BeginInit();
            this.tabSimple.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer1)).BeginInit();
            this.splitContainer1.Panel1.SuspendLayout();
            this.splitContainer1.Panel2.SuspendLayout();
            this.splitContainer1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer4)).BeginInit();
            this.splitContainer4.Panel1.SuspendLayout();
            this.splitContainer4.Panel2.SuspendLayout();
            this.splitContainer4.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.numericUpDownTmLimit)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.numericUpDownInstanceID)).BeginInit();
            this.tabControl.SuspendLayout();
            this.SuspendLayout();
            // 
            // splitContainerForm
            // 
            this.splitContainerForm.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainerForm.Location = new System.Drawing.Point(0, 0);
            this.splitContainerForm.Name = "splitContainerForm";
            // 
            // splitContainerForm.Panel1
            // 
            this.splitContainerForm.Panel1.Controls.Add(this.tabControl);
            // 
            // splitContainerForm.Panel2
            // 
            this.splitContainerForm.Panel2.Controls.Add(this.progressBarOuter);
            this.splitContainerForm.Panel2.Controls.Add(this.pictureBox);
            this.splitContainerForm.Panel2.Controls.Add(this.labelDefault);
            this.splitContainerForm.Panel2.Controls.Add(this.comboBoxScheme);
            this.splitContainerForm.Panel2.Controls.Add(this.labelStatusbar);
            this.splitContainerForm.Panel2.Controls.Add(this.labelFolder);
            this.splitContainerForm.Panel2.Controls.Add(this.richTextBoxConsole);
            this.splitContainerForm.Panel2.Controls.Add(this.textBoxDir);
            this.splitContainerForm.Panel2.Controls.Add(this.richTextBox);
            this.splitContainerForm.Panel2.Controls.Add(this.progressBarInner);
            this.splitContainerForm.Size = new System.Drawing.Size(1133, 500);
            this.splitContainerForm.SplitterDistance = 354;
            this.splitContainerForm.TabIndex = 0;
            // 
            // progressBarOuter
            // 
            this.progressBarOuter.Location = new System.Drawing.Point(665, 420);
            this.progressBarOuter.Name = "progressBarOuter";
            this.progressBarOuter.Size = new System.Drawing.Size(100, 23);
            this.progressBarOuter.TabIndex = 22;
            // 
            // pictureBox
            // 
            this.pictureBox.Location = new System.Drawing.Point(426, 19);
            this.pictureBox.Name = "pictureBox";
            this.pictureBox.Size = new System.Drawing.Size(339, 380);
            this.pictureBox.TabIndex = 21;
            this.pictureBox.TabStop = false;
            this.pictureBox.Click += new System.EventHandler(this.pictureBox_Click);
            // 
            // labelDefault
            // 
            this.labelDefault.AutoSize = true;
            this.labelDefault.Location = new System.Drawing.Point(22, 425);
            this.labelDefault.Name = "labelDefault";
            this.labelDefault.Size = new System.Drawing.Size(44, 13);
            this.labelDefault.TabIndex = 20;
            this.labelDefault.Text = "Default:";
            // 
            // comboBoxScheme
            // 
            this.comboBoxScheme.FormattingEnabled = true;
            this.comboBoxScheme.Items.AddRange(new object[] {
            "LION5",
            "LION7/MISTA12",
            "JOH",
            "wip"});
            this.comboBoxScheme.Location = new System.Drawing.Point(72, 421);
            this.comboBoxScheme.Name = "comboBoxScheme";
            this.comboBoxScheme.Size = new System.Drawing.Size(121, 21);
            this.comboBoxScheme.TabIndex = 7;
            this.comboBoxScheme.SelectedIndexChanged += new System.EventHandler(this.comboBoxScheme_SelectedIndexChanged);
            // 
            // labelStatusbar
            // 
            this.labelStatusbar.AutoSize = true;
            this.labelStatusbar.Location = new System.Drawing.Point(530, 426);
            this.labelStatusbar.Name = "labelStatusbar";
            this.labelStatusbar.Size = new System.Drawing.Size(40, 13);
            this.labelStatusbar.TabIndex = 6;
            this.labelStatusbar.Text = "Status:";
            // 
            // labelFolder
            // 
            this.labelFolder.AutoSize = true;
            this.labelFolder.Location = new System.Drawing.Point(22, 451);
            this.labelFolder.Name = "labelFolder";
            this.labelFolder.Size = new System.Drawing.Size(55, 13);
            this.labelFolder.TabIndex = 7;
            this.labelFolder.Text = "Subfolder:";
            // 
            // richTextBoxConsole
            // 
            this.richTextBoxConsole.Font = new System.Drawing.Font("Courier New", 8F);
            this.richTextBoxConsole.Location = new System.Drawing.Point(426, 19);
            this.richTextBoxConsole.Name = "richTextBoxConsole";
            this.richTextBoxConsole.Size = new System.Drawing.Size(339, 380);
            this.richTextBoxConsole.TabIndex = 5;
            this.richTextBoxConsole.Text = "";
            this.richTextBoxConsole.TextChanged += new System.EventHandler(this.richTextBox_TextChanged);
            // 
            // textBoxDir
            // 
            this.textBoxDir.Font = new System.Drawing.Font("Courier New", 8F);
            this.textBoxDir.Location = new System.Drawing.Point(83, 447);
            this.textBoxDir.Name = "textBoxDir";
            this.textBoxDir.Size = new System.Drawing.Size(110, 20);
            this.textBoxDir.TabIndex = 6;
            this.textBoxDir.Text = "wip";
            // 
            // richTextBox
            // 
            this.richTextBox.Font = new System.Drawing.Font("Courier New", 8F);
            this.richTextBox.Location = new System.Drawing.Point(12, 21);
            this.richTextBox.Name = "richTextBox";
            this.richTextBox.Size = new System.Drawing.Size(408, 380);
            this.richTextBox.TabIndex = 0;
            this.richTextBox.Text = "";
            this.richTextBox.TextChanged += new System.EventHandler(this.richTextBox_TextChanged);
            // 
            // progressBarInner
            // 
            this.progressBarInner.Location = new System.Drawing.Point(665, 449);
            this.progressBarInner.Name = "progressBarInner";
            this.progressBarInner.Size = new System.Drawing.Size(100, 23);
            this.progressBarInner.TabIndex = 0;
            // 
            // tabCMAES
            // 
            this.tabCMAES.Controls.Add(this.splitContainer10);
            this.tabCMAES.Location = new System.Drawing.Point(4, 22);
            this.tabCMAES.Name = "tabCMAES";
            this.tabCMAES.Padding = new System.Windows.Forms.Padding(3);
            this.tabCMAES.Size = new System.Drawing.Size(340, 465);
            this.tabCMAES.TabIndex = 5;
            this.tabCMAES.Text = "CMA-ES";
            this.tabCMAES.UseVisualStyleBackColor = true;
            // 
            // splitContainer10
            // 
            this.splitContainer10.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer10.Location = new System.Drawing.Point(3, 3);
            this.splitContainer10.Name = "splitContainer10";
            // 
            // splitContainer10.Panel1
            // 
            this.splitContainer10.Panel1.Controls.Add(this.ckbProblemCMA);
            this.splitContainer10.Panel1.Controls.Add(this.ckbDimCMA);
            this.splitContainer10.Panel1.Controls.Add(this.label34);
            this.splitContainer10.Panel1.Controls.Add(this.label33);
            // 
            // splitContainer10.Panel2
            // 
            this.splitContainer10.Panel2.Controls.Add(this.splitContainer11);
            this.splitContainer10.Size = new System.Drawing.Size(334, 459);
            this.splitContainer10.SplitterDistance = 162;
            this.splitContainer10.TabIndex = 0;
            // 
            // splitContainer11
            // 
            this.splitContainer11.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer11.Location = new System.Drawing.Point(0, 0);
            this.splitContainer11.Name = "splitContainer11";
            this.splitContainer11.Orientation = System.Windows.Forms.Orientation.Horizontal;
            // 
            // splitContainer11.Panel1
            // 
            this.splitContainer11.Panel1.Controls.Add(this.label37);
            this.splitContainer11.Panel1.Controls.Add(this.radioButtonCMAwrtMakespan);
            this.splitContainer11.Panel1.Controls.Add(this.radioButtonCMAwrtRho);
            // 
            // splitContainer11.Panel2
            // 
            this.splitContainer11.Panel2.Controls.Add(this.splitContainer12);
            this.splitContainer11.Size = new System.Drawing.Size(168, 459);
            this.splitContainer11.SplitterDistance = 78;
            this.splitContainer11.TabIndex = 0;
            // 
            // splitContainer12
            // 
            this.splitContainer12.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer12.Location = new System.Drawing.Point(0, 0);
            this.splitContainer12.Name = "splitContainer12";
            this.splitContainer12.Orientation = System.Windows.Forms.Orientation.Horizontal;
            // 
            // splitContainer12.Panel1
            // 
            this.splitContainer12.Panel1.Controls.Add(this.label36);
            this.splitContainer12.Panel1.Controls.Add(this.radioButtonCMADependent);
            this.splitContainer12.Panel1.Controls.Add(this.radioButtonCMAIndependent);
            // 
            // splitContainer12.Panel2
            // 
            this.splitContainer12.Panel2.Controls.Add(this.startAsyncButtonCMA);
            this.splitContainer12.Panel2.Controls.Add(this.cancelAsyncButtonCMA);
            this.splitContainer12.Size = new System.Drawing.Size(168, 377);
            this.splitContainer12.SplitterDistance = 72;
            this.splitContainer12.TabIndex = 0;
            // 
            // cancelAsyncButtonCMA
            // 
            this.cancelAsyncButtonCMA.Location = new System.Drawing.Point(65, 12);
            this.cancelAsyncButtonCMA.Name = "cancelAsyncButtonCMA";
            this.cancelAsyncButtonCMA.Size = new System.Drawing.Size(60, 23);
            this.cancelAsyncButtonCMA.TabIndex = 56;
            this.cancelAsyncButtonCMA.UseVisualStyleBackColor = true;
            this.cancelAsyncButtonCMA.Click += new System.EventHandler(this.cancelAsyncButtonCMA_click);
            // 
            // startAsyncButtonCMA
            // 
            this.startAsyncButtonCMA.Location = new System.Drawing.Point(5, 12);
            this.startAsyncButtonCMA.Name = "startAsyncButtonCMA";
            this.startAsyncButtonCMA.Size = new System.Drawing.Size(60, 23);
            this.startAsyncButtonCMA.TabIndex = 55;
            this.startAsyncButtonCMA.UseVisualStyleBackColor = true;
            this.startAsyncButtonCMA.Click += new System.EventHandler(this.startAsyncButtonCMA_click);
            // 
            // radioButtonCMAIndependent
            // 
            this.radioButtonCMAIndependent.AutoSize = true;
            this.radioButtonCMAIndependent.Location = new System.Drawing.Point(6, 25);
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
            this.radioButtonCMADependent.Location = new System.Drawing.Point(6, 45);
            this.radioButtonCMADependent.Name = "radioButtonCMADependent";
            this.radioButtonCMADependent.Size = new System.Drawing.Size(78, 17);
            this.radioButtonCMADependent.TabIndex = 38;
            this.radioButtonCMADependent.TabStop = true;
            this.radioButtonCMADependent.Text = "Dependent";
            this.radioButtonCMADependent.UseVisualStyleBackColor = true;
            // 
            // label36
            // 
            this.label36.AutoSize = true;
            this.label36.Location = new System.Drawing.Point(3, 9);
            this.label36.Name = "label36";
            this.label36.Size = new System.Drawing.Size(66, 13);
            this.label36.TabIndex = 36;
            this.label36.Text = "Robustness:";
            // 
            // radioButtonCMAwrtRho
            // 
            this.radioButtonCMAwrtRho.AutoSize = true;
            this.radioButtonCMAwrtRho.Location = new System.Drawing.Point(6, 32);
            this.radioButtonCMAwrtRho.Name = "radioButtonCMAwrtRho";
            this.radioButtonCMAwrtRho.Size = new System.Drawing.Size(85, 17);
            this.radioButtonCMAwrtRho.TabIndex = 40;
            this.radioButtonCMAwrtRho.TabStop = true;
            this.radioButtonCMAwrtRho.Text = "w.r.t. min rho";
            this.radioButtonCMAwrtRho.UseVisualStyleBackColor = true;
            // 
            // radioButtonCMAwrtMakespan
            // 
            this.radioButtonCMAwrtMakespan.AutoSize = true;
            this.radioButtonCMAwrtMakespan.Location = new System.Drawing.Point(6, 52);
            this.radioButtonCMAwrtMakespan.Name = "radioButtonCMAwrtMakespan";
            this.radioButtonCMAwrtMakespan.Size = new System.Drawing.Size(119, 17);
            this.radioButtonCMAwrtMakespan.TabIndex = 41;
            this.radioButtonCMAwrtMakespan.TabStop = true;
            this.radioButtonCMAwrtMakespan.Text = "w.r.t. min makespan";
            this.radioButtonCMAwrtMakespan.UseVisualStyleBackColor = true;
            // 
            // label37
            // 
            this.label37.AutoSize = true;
            this.label37.Location = new System.Drawing.Point(3, 16);
            this.label37.Name = "label37";
            this.label37.Size = new System.Drawing.Size(96, 13);
            this.label37.TabIndex = 39;
            this.label37.Text = "Objective function:";
            // 
            // label33
            // 
            this.label33.AutoSize = true;
            this.label33.Location = new System.Drawing.Point(6, 170);
            this.label33.Name = "label33";
            this.label33.Size = new System.Drawing.Size(59, 13);
            this.label33.TabIndex = 67;
            this.label33.Text = "Dimension:";
            // 
            // label34
            // 
            this.label34.AutoSize = true;
            this.label34.Location = new System.Drawing.Point(3, 0);
            this.label34.Name = "label34";
            this.label34.Size = new System.Drawing.Size(96, 13);
            this.label34.TabIndex = 65;
            this.label34.Text = "Problem instances:";
            // 
            // ckbDimCMA
            // 
            this.ckbDimCMA.FormattingEnabled = true;
            this.ckbDimCMA.Items.AddRange(new object[] {
            "6 job, 5 machine",
            "10 job, 10 machine"});
            this.ckbDimCMA.Location = new System.Drawing.Point(6, 186);
            this.ckbDimCMA.Name = "ckbDimCMA";
            this.ckbDimCMA.Size = new System.Drawing.Size(120, 34);
            this.ckbDimCMA.TabIndex = 66;
            this.ckbDimCMA.SelectedIndexChanged += new System.EventHandler(this.ckb_ClickAllowOnly1);
            // 
            // ckbProblemCMA
            // 
            this.ckbProblemCMA.FormattingEnabled = true;
            this.ckbProblemCMA.Items.AddRange(new object[] {
            "j.rnd",
            "j.rndn",
            "f.rnd",
            "f.rndn",
            "f.jc",
            "f.mc",
            "f.mxc",
            "j.rnd_p1mdoubled",
            "j.rnd_pj1doubled"});
            this.ckbProblemCMA.Location = new System.Drawing.Point(6, 16);
            this.ckbProblemCMA.Name = "ckbProblemCMA";
            this.ckbProblemCMA.Size = new System.Drawing.Size(120, 139);
            this.ckbProblemCMA.TabIndex = 64;
            this.ckbProblemCMA.SelectedIndexChanged += new System.EventHandler(this.ckb_ClickAllowOnly1);
            // 
            // tabLinear
            // 
            this.tabLinear.Controls.Add(this.splitContainer8);
            this.tabLinear.Location = new System.Drawing.Point(4, 22);
            this.tabLinear.Name = "tabLinear";
            this.tabLinear.Padding = new System.Windows.Forms.Padding(3);
            this.tabLinear.Size = new System.Drawing.Size(340, 465);
            this.tabLinear.TabIndex = 4;
            this.tabLinear.Text = "LIN";
            this.tabLinear.UseVisualStyleBackColor = true;
            // 
            // splitContainer8
            // 
            this.splitContainer8.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer8.Location = new System.Drawing.Point(3, 3);
            this.splitContainer8.Name = "splitContainer8";
            // 
            // splitContainer8.Panel1
            // 
            this.splitContainer8.Panel1.Controls.Add(this.splitContainer9);
            // 
            // splitContainer8.Panel2
            // 
            this.splitContainer8.Panel2.Controls.Add(this.btnLocalApply);
            this.splitContainer8.Panel2.Controls.Add(this.btnLocalReset);
            this.splitContainer8.Panel2.Controls.Add(this.tbLocal18);
            this.splitContainer8.Panel2.Controls.Add(this.label32);
            this.splitContainer8.Panel2.Controls.Add(this.tbLocal0);
            this.splitContainer8.Panel2.Controls.Add(this.label31);
            this.splitContainer8.Panel2.Controls.Add(this.tbLocal17);
            this.splitContainer8.Panel2.Controls.Add(this.label30);
            this.splitContainer8.Panel2.Controls.Add(this.tbLocal16);
            this.splitContainer8.Panel2.Controls.Add(this.label29);
            this.splitContainer8.Panel2.Controls.Add(this.tbLocal15);
            this.splitContainer8.Panel2.Controls.Add(this.label28);
            this.splitContainer8.Panel2.Controls.Add(this.tbLocal14);
            this.splitContainer8.Panel2.Controls.Add(this.label27);
            this.splitContainer8.Panel2.Controls.Add(this.tbLocal12);
            this.splitContainer8.Panel2.Controls.Add(this.label24);
            this.splitContainer8.Panel2.Controls.Add(this.tbLocal11);
            this.splitContainer8.Panel2.Controls.Add(this.label23);
            this.splitContainer8.Panel2.Controls.Add(this.tbLocal10);
            this.splitContainer8.Panel2.Controls.Add(this.label22);
            this.splitContainer8.Panel2.Controls.Add(this.tbLocal9);
            this.splitContainer8.Panel2.Controls.Add(this.label21);
            this.splitContainer8.Panel2.Controls.Add(this.label20);
            this.splitContainer8.Panel2.Controls.Add(this.label16);
            this.splitContainer8.Panel2.Controls.Add(this.tbLocal13);
            this.splitContainer8.Panel2.Controls.Add(this.tbLocal8);
            this.splitContainer8.Panel2.Controls.Add(this.tbLocal4);
            this.splitContainer8.Panel2.Controls.Add(this.label26);
            this.splitContainer8.Panel2.Controls.Add(this.label19);
            this.splitContainer8.Panel2.Controls.Add(this.label25);
            this.splitContainer8.Panel2.Controls.Add(this.tbLocal3);
            this.splitContainer8.Panel2.Controls.Add(this.tbLocal7);
            this.splitContainer8.Panel2.Controls.Add(this.label15);
            this.splitContainer8.Panel2.Controls.Add(this.tbLocal2);
            this.splitContainer8.Panel2.Controls.Add(this.label18);
            this.splitContainer8.Panel2.Controls.Add(this.label14);
            this.splitContainer8.Panel2.Controls.Add(this.tbLocal1);
            this.splitContainer8.Panel2.Controls.Add(this.tbLocal6);
            this.splitContainer8.Panel2.Controls.Add(this.label13);
            this.splitContainer8.Panel2.Controls.Add(this.tbLocal5);
            this.splitContainer8.Panel2.Controls.Add(this.label17);
            this.splitContainer8.Size = new System.Drawing.Size(334, 459);
            this.splitContainer8.SplitterDistance = 128;
            this.splitContainer8.TabIndex = 0;
            // 
            // label17
            // 
            this.label17.AutoSize = true;
            this.label17.Location = new System.Drawing.Point(12, 124);
            this.label17.Name = "label17";
            this.label17.Size = new System.Drawing.Size(61, 13);
            this.label17.TabIndex = 73;
            this.label17.Text = "w5: totProc";
            // 
            // tbLocal5
            // 
            this.tbLocal5.Font = new System.Drawing.Font("Courier New", 8F);
            this.tbLocal5.Location = new System.Drawing.Point(99, 124);
            this.tbLocal5.Name = "tbLocal5";
            this.tbLocal5.Size = new System.Drawing.Size(90, 20);
            this.tbLocal5.TabIndex = 72;
            this.tbLocal5.Text = "0";
            // 
            // label13
            // 
            this.label13.AutoSize = true;
            this.label13.Location = new System.Drawing.Point(12, 48);
            this.label13.Name = "label13";
            this.label13.Size = new System.Drawing.Size(70, 13);
            this.label13.TabIndex = 59;
            this.label13.Text = "w1: startTime";
            // 
            // tbLocal6
            // 
            this.tbLocal6.Font = new System.Drawing.Font("Courier New", 8F);
            this.tbLocal6.Location = new System.Drawing.Point(99, 142);
            this.tbLocal6.Name = "tbLocal6";
            this.tbLocal6.Size = new System.Drawing.Size(90, 20);
            this.tbLocal6.TabIndex = 70;
            this.tbLocal6.Text = "0";
            // 
            // tbLocal1
            // 
            this.tbLocal1.Font = new System.Drawing.Font("Courier New", 8F);
            this.tbLocal1.Location = new System.Drawing.Point(99, 48);
            this.tbLocal1.Name = "tbLocal1";
            this.tbLocal1.Size = new System.Drawing.Size(90, 20);
            this.tbLocal1.TabIndex = 58;
            this.tbLocal1.Text = "0";
            // 
            // label14
            // 
            this.label14.AutoSize = true;
            this.label14.Location = new System.Drawing.Point(12, 69);
            this.label14.Name = "label14";
            this.label14.Size = new System.Drawing.Size(68, 13);
            this.label14.TabIndex = 61;
            this.label14.Text = "w2: endTime";
            // 
            // label18
            // 
            this.label18.AutoSize = true;
            this.label18.Location = new System.Drawing.Point(12, 142);
            this.label18.Name = "label18";
            this.label18.Size = new System.Drawing.Size(46, 13);
            this.label18.TabIndex = 71;
            this.label18.Text = "w6: wait";
            // 
            // tbLocal2
            // 
            this.tbLocal2.Font = new System.Drawing.Font("Courier New", 8F);
            this.tbLocal2.Location = new System.Drawing.Point(99, 67);
            this.tbLocal2.Name = "tbLocal2";
            this.tbLocal2.Size = new System.Drawing.Size(90, 20);
            this.tbLocal2.TabIndex = 60;
            this.tbLocal2.Text = "0";
            // 
            // label15
            // 
            this.label15.AutoSize = true;
            this.label15.Location = new System.Drawing.Point(12, 86);
            this.label15.Name = "label15";
            this.label15.Size = new System.Drawing.Size(60, 13);
            this.label15.TabIndex = 63;
            this.label15.Text = "w3: jobOps";
            // 
            // tbLocal7
            // 
            this.tbLocal7.Font = new System.Drawing.Font("Courier New", 8F);
            this.tbLocal7.Location = new System.Drawing.Point(99, 160);
            this.tbLocal7.Name = "tbLocal7";
            this.tbLocal7.Size = new System.Drawing.Size(90, 20);
            this.tbLocal7.TabIndex = 68;
            this.tbLocal7.Text = "0";
            // 
            // tbLocal3
            // 
            this.tbLocal3.Font = new System.Drawing.Font("Courier New", 8F);
            this.tbLocal3.Location = new System.Drawing.Point(99, 86);
            this.tbLocal3.Name = "tbLocal3";
            this.tbLocal3.Size = new System.Drawing.Size(90, 20);
            this.tbLocal3.TabIndex = 62;
            this.tbLocal3.Text = "0";
            // 
            // label25
            // 
            this.label25.AutoSize = true;
            this.label25.Location = new System.Drawing.Point(12, 13);
            this.label25.Name = "label25";
            this.label25.Size = new System.Drawing.Size(49, 13);
            this.label25.TabIndex = 58;
            this.label25.Text = "Weights:";
            // 
            // label19
            // 
            this.label19.AutoSize = true;
            this.label19.Location = new System.Drawing.Point(12, 160);
            this.label19.Name = "label19";
            this.label19.Size = new System.Drawing.Size(47, 13);
            this.label19.TabIndex = 69;
            this.label19.Text = "w7: mac";
            // 
            // label26
            // 
            this.label26.AutoSize = true;
            this.label26.Location = new System.Drawing.Point(12, 274);
            this.label26.Name = "label26";
            this.label26.Size = new System.Drawing.Size(54, 13);
            this.label26.TabIndex = 83;
            this.label26.Text = "w13: slots";
            // 
            // tbLocal4
            // 
            this.tbLocal4.Font = new System.Drawing.Font("Courier New", 8F);
            this.tbLocal4.Location = new System.Drawing.Point(99, 105);
            this.tbLocal4.Name = "tbLocal4";
            this.tbLocal4.Size = new System.Drawing.Size(90, 20);
            this.tbLocal4.TabIndex = 64;
            this.tbLocal4.Text = "0";
            // 
            // tbLocal8
            // 
            this.tbLocal8.Font = new System.Drawing.Font("Courier New", 8F);
            this.tbLocal8.Location = new System.Drawing.Point(99, 179);
            this.tbLocal8.Name = "tbLocal8";
            this.tbLocal8.Size = new System.Drawing.Size(90, 20);
            this.tbLocal8.TabIndex = 66;
            this.tbLocal8.Text = "0";
            // 
            // tbLocal13
            // 
            this.tbLocal13.Font = new System.Drawing.Font("Courier New", 8F);
            this.tbLocal13.Location = new System.Drawing.Point(99, 274);
            this.tbLocal13.Name = "tbLocal13";
            this.tbLocal13.Size = new System.Drawing.Size(90, 20);
            this.tbLocal13.TabIndex = 82;
            this.tbLocal13.Text = "0";
            // 
            // label16
            // 
            this.label16.AutoSize = true;
            this.label16.Location = new System.Drawing.Point(12, 105);
            this.label16.Name = "label16";
            this.label16.Size = new System.Drawing.Size(78, 13);
            this.label16.TabIndex = 65;
            this.label16.Text = "w4: arrivalTime";
            // 
            // label20
            // 
            this.label20.AutoSize = true;
            this.label20.Location = new System.Drawing.Point(12, 179);
            this.label20.Name = "label20";
            this.label20.Size = new System.Drawing.Size(66, 13);
            this.label20.TabIndex = 67;
            this.label20.Text = "w8: macOps";
            // 
            // label21
            // 
            this.label21.AutoSize = true;
            this.label21.Location = new System.Drawing.Point(12, 198);
            this.label21.Name = "label21";
            this.label21.Size = new System.Drawing.Size(68, 13);
            this.label21.TabIndex = 81;
            this.label21.Text = "w9: macFree";
            // 
            // tbLocal9
            // 
            this.tbLocal9.Font = new System.Drawing.Font("Courier New", 8F);
            this.tbLocal9.Location = new System.Drawing.Point(99, 198);
            this.tbLocal9.Name = "tbLocal9";
            this.tbLocal9.Size = new System.Drawing.Size(90, 20);
            this.tbLocal9.TabIndex = 80;
            this.tbLocal9.Text = "0";
            // 
            // label22
            // 
            this.label22.AutoSize = true;
            this.label22.Location = new System.Drawing.Point(12, 217);
            this.label22.Name = "label22";
            this.label22.Size = new System.Drawing.Size(82, 13);
            this.label22.TabIndex = 79;
            this.label22.Text = "w10: makespan";
            // 
            // tbLocal10
            // 
            this.tbLocal10.Font = new System.Drawing.Font("Courier New", 8F);
            this.tbLocal10.Location = new System.Drawing.Point(99, 217);
            this.tbLocal10.Name = "tbLocal10";
            this.tbLocal10.Size = new System.Drawing.Size(90, 20);
            this.tbLocal10.TabIndex = 78;
            this.tbLocal10.Text = "0";
            // 
            // label23
            // 
            this.label23.AutoSize = true;
            this.label23.Location = new System.Drawing.Point(12, 236);
            this.label23.Name = "label23";
            this.label23.Size = new System.Drawing.Size(53, 13);
            this.label23.TabIndex = 77;
            this.label23.Text = "w11: step";
            // 
            // tbLocal11
            // 
            this.tbLocal11.Font = new System.Drawing.Font("Courier New", 8F);
            this.tbLocal11.Location = new System.Drawing.Point(99, 236);
            this.tbLocal11.Name = "tbLocal11";
            this.tbLocal11.Size = new System.Drawing.Size(90, 20);
            this.tbLocal11.TabIndex = 76;
            this.tbLocal11.Text = "0";
            // 
            // label24
            // 
            this.label24.AutoSize = true;
            this.label24.Location = new System.Drawing.Point(12, 255);
            this.label24.Name = "label24";
            this.label24.Size = new System.Drawing.Size(93, 13);
            this.label24.TabIndex = 75;
            this.label24.Text = "w12: slotReduced";
            // 
            // tbLocal12
            // 
            this.tbLocal12.Font = new System.Drawing.Font("Courier New", 8F);
            this.tbLocal12.Location = new System.Drawing.Point(99, 255);
            this.tbLocal12.Name = "tbLocal12";
            this.tbLocal12.Size = new System.Drawing.Size(90, 20);
            this.tbLocal12.TabIndex = 74;
            this.tbLocal12.Text = "0";
            // 
            // label27
            // 
            this.label27.AutoSize = true;
            this.label27.Location = new System.Drawing.Point(12, 293);
            this.label27.Name = "label27";
            this.label27.Size = new System.Drawing.Size(78, 13);
            this.label27.TabIndex = 85;
            this.label27.Text = "w14: slotsTotal";
            // 
            // tbLocal14
            // 
            this.tbLocal14.Font = new System.Drawing.Font("Courier New", 8F);
            this.tbLocal14.Location = new System.Drawing.Point(99, 293);
            this.tbLocal14.Name = "tbLocal14";
            this.tbLocal14.Size = new System.Drawing.Size(90, 20);
            this.tbLocal14.TabIndex = 84;
            this.tbLocal14.Text = "0";
            // 
            // label28
            // 
            this.label28.AutoSize = true;
            this.label28.Location = new System.Drawing.Point(12, 312);
            this.label28.Name = "label28";
            this.label28.Size = new System.Drawing.Size(73, 13);
            this.label28.TabIndex = 87;
            this.label28.Text = "w15: wrmMac";
            // 
            // tbLocal15
            // 
            this.tbLocal15.Font = new System.Drawing.Font("Courier New", 8F);
            this.tbLocal15.Location = new System.Drawing.Point(99, 312);
            this.tbLocal15.Name = "tbLocal15";
            this.tbLocal15.Size = new System.Drawing.Size(90, 20);
            this.tbLocal15.TabIndex = 86;
            this.tbLocal15.Text = "0";
            // 
            // label29
            // 
            this.label29.AutoSize = true;
            this.label29.Location = new System.Drawing.Point(12, 331);
            this.label29.Name = "label29";
            this.label29.Size = new System.Drawing.Size(72, 13);
            this.label29.TabIndex = 89;
            this.label29.Text = "w16: wrmJob ";
            // 
            // tbLocal16
            // 
            this.tbLocal16.Font = new System.Drawing.Font("Courier New", 8F);
            this.tbLocal16.Location = new System.Drawing.Point(99, 331);
            this.tbLocal16.Name = "tbLocal16";
            this.tbLocal16.Size = new System.Drawing.Size(90, 20);
            this.tbLocal16.TabIndex = 88;
            this.tbLocal16.Text = "0";
            // 
            // label30
            // 
            this.label30.AutoSize = true;
            this.label30.Location = new System.Drawing.Point(12, 350);
            this.label30.Name = "label30";
            this.label30.Size = new System.Drawing.Size(76, 13);
            this.label30.TabIndex = 91;
            this.label30.Text = "w17: wrmTotal";
            // 
            // tbLocal17
            // 
            this.tbLocal17.Font = new System.Drawing.Font("Courier New", 8F);
            this.tbLocal17.Location = new System.Drawing.Point(99, 350);
            this.tbLocal17.Name = "tbLocal17";
            this.tbLocal17.Size = new System.Drawing.Size(90, 20);
            this.tbLocal17.TabIndex = 90;
            this.tbLocal17.Text = "0";
            // 
            // label31
            // 
            this.label31.AutoSize = true;
            this.label31.Location = new System.Drawing.Point(12, 29);
            this.label31.Name = "label31";
            this.label31.Size = new System.Drawing.Size(48, 13);
            this.label31.TabIndex = 93;
            this.label31.Text = "w0: proc";
            // 
            // tbLocal0
            // 
            this.tbLocal0.Font = new System.Drawing.Font("Courier New", 8F);
            this.tbLocal0.Location = new System.Drawing.Point(99, 29);
            this.tbLocal0.Name = "tbLocal0";
            this.tbLocal0.Size = new System.Drawing.Size(90, 20);
            this.tbLocal0.TabIndex = 92;
            this.tbLocal0.Text = "0";
            // 
            // label32
            // 
            this.label32.AutoSize = true;
            this.label32.Location = new System.Drawing.Point(12, 369);
            this.label32.Name = "label32";
            this.label32.Size = new System.Drawing.Size(53, 13);
            this.label32.TabIndex = 95;
            this.label32.Text = "w18: Bias";
            // 
            // tbLocal18
            // 
            this.tbLocal18.Font = new System.Drawing.Font("Courier New", 8F);
            this.tbLocal18.Location = new System.Drawing.Point(99, 369);
            this.tbLocal18.Name = "tbLocal18";
            this.tbLocal18.Size = new System.Drawing.Size(90, 20);
            this.tbLocal18.TabIndex = 94;
            this.tbLocal18.Text = "0";
            // 
            // btnLocalReset
            // 
            this.btnLocalReset.Location = new System.Drawing.Point(9, 421);
            this.btnLocalReset.Name = "btnLocalReset";
            this.btnLocalReset.Size = new System.Drawing.Size(75, 23);
            this.btnLocalReset.TabIndex = 46;
            this.btnLocalReset.Text = "Reset";
            this.btnLocalReset.UseVisualStyleBackColor = true;
            this.btnLocalReset.Click += new System.EventHandler(this.btnLocalReset_Click);
            // 
            // btnLocalApply
            // 
            this.btnLocalApply.Location = new System.Drawing.Point(99, 421);
            this.btnLocalApply.Name = "btnLocalApply";
            this.btnLocalApply.Size = new System.Drawing.Size(75, 23);
            this.btnLocalApply.TabIndex = 96;
            this.btnLocalApply.Text = "Apply";
            this.btnLocalApply.UseVisualStyleBackColor = true;
            this.btnLocalApply.Click += new System.EventHandler(this.btnLocalApply_Click);
            // 
            // splitContainer9
            // 
            this.splitContainer9.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer9.Location = new System.Drawing.Point(0, 0);
            this.splitContainer9.Name = "splitContainer9";
            this.splitContainer9.Orientation = System.Windows.Forms.Orientation.Horizontal;
            // 
            // splitContainer9.Panel1
            // 
            this.splitContainer9.Panel1.Controls.Add(this.ckbDimLIN);
            this.splitContainer9.Panel1.Controls.Add(this.label12);
            this.splitContainer9.Panel1.Controls.Add(this.label10);
            this.splitContainer9.Panel1.Controls.Add(this.label11);
            this.splitContainer9.Panel1.Controls.Add(this.ckbDataLIN);
            this.splitContainer9.Panel1.Controls.Add(this.ckbSetLIN);
            // 
            // splitContainer9.Panel2
            // 
            this.splitContainer9.Panel2.Controls.Add(this.labelLiblinearLogs);
            this.splitContainer9.Panel2.Controls.Add(this.radioButtonDependent);
            this.splitContainer9.Panel2.Controls.Add(this.comboBoxLiblinearLogs);
            this.splitContainer9.Panel2.Controls.Add(this.buttonApplyLiblinearLogs);
            this.splitContainer9.Panel2.Controls.Add(this.radioButtonIndependent);
            this.splitContainer9.Size = new System.Drawing.Size(128, 459);
            this.splitContainer9.SplitterDistance = 346;
            this.splitContainer9.TabIndex = 0;
            // 
            // radioButtonIndependent
            // 
            this.radioButtonIndependent.AutoSize = true;
            this.radioButtonIndependent.Location = new System.Drawing.Point(6, 22);
            this.radioButtonIndependent.Name = "radioButtonIndependent";
            this.radioButtonIndependent.Size = new System.Drawing.Size(85, 17);
            this.radioButtonIndependent.TabIndex = 60;
            this.radioButtonIndependent.Text = "Independent";
            this.radioButtonIndependent.UseVisualStyleBackColor = true;
            // 
            // buttonApplyLiblinearLogs
            // 
            this.buttonApplyLiblinearLogs.Location = new System.Drawing.Point(49, 70);
            this.buttonApplyLiblinearLogs.Name = "buttonApplyLiblinearLogs";
            this.buttonApplyLiblinearLogs.Size = new System.Drawing.Size(75, 23);
            this.buttonApplyLiblinearLogs.TabIndex = 97;
            this.buttonApplyLiblinearLogs.Text = "Apply";
            this.buttonApplyLiblinearLogs.UseVisualStyleBackColor = true;
            this.buttonApplyLiblinearLogs.Click += new System.EventHandler(this.buttonApplyLiblinearLogs_Click);
            // 
            // comboBoxLiblinearLogs
            // 
            this.comboBoxLiblinearLogs.FormattingEnabled = true;
            this.comboBoxLiblinearLogs.Location = new System.Drawing.Point(3, 44);
            this.comboBoxLiblinearLogs.Name = "comboBoxLiblinearLogs";
            this.comboBoxLiblinearLogs.Size = new System.Drawing.Size(121, 21);
            this.comboBoxLiblinearLogs.TabIndex = 60;
            this.comboBoxLiblinearLogs.Click += new System.EventHandler(this.comboBoxLiblinearLogs_Update);
            // 
            // radioButtonDependent
            // 
            this.radioButtonDependent.AutoSize = true;
            this.radioButtonDependent.Location = new System.Drawing.Point(67, 23);
            this.radioButtonDependent.Name = "radioButtonDependent";
            this.radioButtonDependent.Size = new System.Drawing.Size(78, 17);
            this.radioButtonDependent.TabIndex = 59;
            this.radioButtonDependent.TabStop = true;
            this.radioButtonDependent.Text = "Dependent";
            this.radioButtonDependent.UseVisualStyleBackColor = true;
            // 
            // labelLiblinearLogs
            // 
            this.labelLiblinearLogs.AutoSize = true;
            this.labelLiblinearLogs.Location = new System.Drawing.Point(3, 7);
            this.labelLiblinearLogs.Name = "labelLiblinearLogs";
            this.labelLiblinearLogs.Size = new System.Drawing.Size(78, 13);
            this.labelLiblinearLogs.TabIndex = 98;
            this.labelLiblinearLogs.Text = "Read Weights:";
            // 
            // ckbSetLIN
            // 
            this.ckbSetLIN.FormattingEnabled = true;
            this.ckbSetLIN.Items.AddRange(new object[] {
            "Train",
            "Test"});
            this.ckbSetLIN.Location = new System.Drawing.Point(1, 196);
            this.ckbSetLIN.Name = "ckbSetLIN";
            this.ckbSetLIN.Size = new System.Drawing.Size(120, 34);
            this.ckbSetLIN.TabIndex = 55;
            // 
            // ckbDataLIN
            // 
            this.ckbDataLIN.FormattingEnabled = true;
            this.ckbDataLIN.Items.AddRange(new object[] {
            "j.rnd",
            "j.rndn",
            "f.rnd",
            "f.rndn",
            "f.jc",
            "f.mc",
            "f.mxc",
            "j.rnd, p1m doubled",
            "j.rnd, pj1 doubled"});
            this.ckbDataLIN.Location = new System.Drawing.Point(1, 29);
            this.ckbDataLIN.Name = "ckbDataLIN";
            this.ckbDataLIN.Size = new System.Drawing.Size(120, 139);
            this.ckbDataLIN.TabIndex = 52;
            // 
            // label11
            // 
            this.label11.AutoSize = true;
            this.label11.Location = new System.Drawing.Point(-2, 180);
            this.label11.Name = "label11";
            this.label11.Size = new System.Drawing.Size(33, 13);
            this.label11.TabIndex = 57;
            this.label11.Text = "Data:";
            // 
            // label10
            // 
            this.label10.AutoSize = true;
            this.label10.Location = new System.Drawing.Point(-2, 244);
            this.label10.Name = "label10";
            this.label10.Size = new System.Drawing.Size(59, 13);
            this.label10.TabIndex = 56;
            this.label10.Text = "Dimension:";
            // 
            // label12
            // 
            this.label12.AutoSize = true;
            this.label12.Location = new System.Drawing.Point(0, 13);
            this.label12.Name = "label12";
            this.label12.Size = new System.Drawing.Size(96, 13);
            this.label12.TabIndex = 53;
            this.label12.Text = "Problem instances:";
            // 
            // ckbDimLIN
            // 
            this.ckbDimLIN.FormattingEnabled = true;
            this.ckbDimLIN.Items.AddRange(new object[] {
            "6 job, 5 machine",
            "8 job, 8 machine",
            "10 job, 10 machine",
            "12 job, 12 machine",
            "14 job, 14 machine"});
            this.ckbDimLIN.Location = new System.Drawing.Point(1, 260);
            this.ckbDimLIN.Name = "ckbDimLIN";
            this.ckbDimLIN.Size = new System.Drawing.Size(120, 79);
            this.ckbDimLIN.TabIndex = 54;
            this.ckbDimLIN.SelectedIndexChanged += new System.EventHandler(this.ckb_ClickAllowOnly1);
            // 
            // tabBDR
            // 
            this.tabBDR.Controls.Add(this.splitContainer7);
            this.tabBDR.Location = new System.Drawing.Point(4, 22);
            this.tabBDR.Name = "tabBDR";
            this.tabBDR.Padding = new System.Windows.Forms.Padding(3);
            this.tabBDR.Size = new System.Drawing.Size(340, 465);
            this.tabBDR.TabIndex = 3;
            this.tabBDR.Text = "BDR";
            this.tabBDR.UseVisualStyleBackColor = true;
            // 
            // splitContainer7
            // 
            this.splitContainer7.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer7.Location = new System.Drawing.Point(3, 3);
            this.splitContainer7.Name = "splitContainer7";
            // 
            // splitContainer7.Panel1
            // 
            this.splitContainer7.Panel1.Controls.Add(this.ckbDimBDR);
            this.splitContainer7.Panel1.Controls.Add(this.ckbSetBDR);
            this.splitContainer7.Panel1.Controls.Add(this.label3);
            this.splitContainer7.Panel1.Controls.Add(this.label4);
            this.splitContainer7.Panel1.Controls.Add(this.label5);
            this.splitContainer7.Panel1.Controls.Add(this.ckbDataBDR);
            // 
            // splitContainer7.Panel2
            // 
            this.splitContainer7.Panel2.Controls.Add(this.label9);
            this.splitContainer7.Panel2.Controls.Add(this.label8);
            this.splitContainer7.Panel2.Controls.Add(this.ckbSDR1BDR);
            this.splitContainer7.Panel2.Controls.Add(this.label7);
            this.splitContainer7.Panel2.Controls.Add(this.numericUpDownBDRsplitStep);
            this.splitContainer7.Panel2.Controls.Add(this.buttonSimpleBDR);
            this.splitContainer7.Panel2.Controls.Add(this.label6);
            this.splitContainer7.Panel2.Controls.Add(this.ckbSDR2BDR);
            this.splitContainer7.Size = new System.Drawing.Size(334, 459);
            this.splitContainer7.SplitterDistance = 150;
            this.splitContainer7.TabIndex = 0;
            // 
            // ckbSDR2BDR
            // 
            this.ckbSDR2BDR.FormattingEnabled = true;
            this.ckbSDR2BDR.Items.AddRange(new object[] {
            "MWR",
            "LWR",
            "SPT",
            "LPT"});
            this.ckbSDR2BDR.Location = new System.Drawing.Point(11, 168);
            this.ckbSDR2BDR.Name = "ckbSDR2BDR";
            this.ckbSDR2BDR.Size = new System.Drawing.Size(120, 64);
            this.ckbSDR2BDR.TabIndex = 47;
            this.ckbSDR2BDR.SelectedIndexChanged += new System.EventHandler(this.ckb_ClickAllowOnly1);
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.Location = new System.Drawing.Point(8, 152);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(97, 13);
            this.label6.TabIndex = 48;
            this.label6.Text = "SDR (second half):";
            // 
            // buttonSimpleBDR
            // 
            this.buttonSimpleBDR.Location = new System.Drawing.Point(11, 241);
            this.buttonSimpleBDR.Name = "buttonSimpleBDR";
            this.buttonSimpleBDR.Size = new System.Drawing.Size(75, 23);
            this.buttonSimpleBDR.TabIndex = 46;
            this.buttonSimpleBDR.Text = "Apply";
            this.buttonSimpleBDR.UseVisualStyleBackColor = true;
            this.buttonSimpleBDR.Click += new System.EventHandler(this.buttonSimpleBDR_Click);
            // 
            // numericUpDownBDRsplitStep
            // 
            this.numericUpDownBDRsplitStep.Location = new System.Drawing.Point(93, 37);
            this.numericUpDownBDRsplitStep.Maximum = new decimal(new int[] {
            500,
            0,
            0,
            0});
            this.numericUpDownBDRsplitStep.Minimum = new decimal(new int[] {
            1,
            0,
            0,
            0});
            this.numericUpDownBDRsplitStep.Name = "numericUpDownBDRsplitStep";
            this.numericUpDownBDRsplitStep.Size = new System.Drawing.Size(38, 20);
            this.numericUpDownBDRsplitStep.TabIndex = 49;
            this.numericUpDownBDRsplitStep.Value = new decimal(new int[] {
            50,
            0,
            0,
            0});
            // 
            // label7
            // 
            this.label7.AutoSize = true;
            this.label7.Location = new System.Drawing.Point(8, 37);
            this.label7.Name = "label7";
            this.label7.Size = new System.Drawing.Size(84, 13);
            this.label7.TabIndex = 51;
            this.label7.Text = "Split at timestep:";
            // 
            // ckbSDR1BDR
            // 
            this.ckbSDR1BDR.FormattingEnabled = true;
            this.ckbSDR1BDR.Items.AddRange(new object[] {
            "MWR",
            "LWR",
            "SPT",
            "LPT"});
            this.ckbSDR1BDR.Location = new System.Drawing.Point(11, 76);
            this.ckbSDR1BDR.Name = "ckbSDR1BDR";
            this.ckbSDR1BDR.Size = new System.Drawing.Size(120, 64);
            this.ckbSDR1BDR.TabIndex = 52;
            this.ckbSDR1BDR.SelectedIndexChanged += new System.EventHandler(this.ckb_ClickAllowOnly1);
            // 
            // label8
            // 
            this.label8.AutoSize = true;
            this.label8.Location = new System.Drawing.Point(8, 60);
            this.label8.Name = "label8";
            this.label8.Size = new System.Drawing.Size(78, 13);
            this.label8.TabIndex = 53;
            this.label8.Text = "SDR (first half):";
            // 
            // label9
            // 
            this.label9.AutoSize = true;
            this.label9.Location = new System.Drawing.Point(12, 10);
            this.label9.Name = "label9";
            this.label9.Size = new System.Drawing.Size(67, 13);
            this.label9.TabIndex = 52;
            this.label9.Text = "Simple CDR:";
            // 
            // ckbDataBDR
            // 
            this.ckbDataBDR.FormattingEnabled = true;
            this.ckbDataBDR.Items.AddRange(new object[] {
            "jrnd",
            "jrndn",
            "frnd",
            "frndn",
            "fjc",
            "fmc",
            "fmxc",
            "jrnd, p1m doubled",
            "jrnd, pj1 doubled"});
            this.ckbDataBDR.Location = new System.Drawing.Point(17, 26);
            this.ckbDataBDR.Name = "ckbDataBDR";
            this.ckbDataBDR.Size = new System.Drawing.Size(120, 139);
            this.ckbDataBDR.TabIndex = 46;
            this.ckbDataBDR.SelectedIndexChanged += new System.EventHandler(this.ckb_SelectedIndexChanged);
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Location = new System.Drawing.Point(16, 10);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(96, 13);
            this.label5.TabIndex = 47;
            this.label5.Text = "Problem instances:";
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Location = new System.Drawing.Point(14, 177);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(33, 13);
            this.label4.TabIndex = 51;
            this.label4.Text = "Data:";
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(14, 241);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(59, 13);
            this.label3.TabIndex = 50;
            this.label3.Text = "Dimension:";
            // 
            // ckbSetBDR
            // 
            this.ckbSetBDR.FormattingEnabled = true;
            this.ckbSetBDR.Items.AddRange(new object[] {
            "Train",
            "Test"});
            this.ckbSetBDR.Location = new System.Drawing.Point(17, 193);
            this.ckbSetBDR.Name = "ckbSetBDR";
            this.ckbSetBDR.Size = new System.Drawing.Size(120, 34);
            this.ckbSetBDR.TabIndex = 49;
            this.ckbSetBDR.SelectedIndexChanged += new System.EventHandler(this.ckb_SelectedIndexChanged);
            // 
            // ckbDimBDR
            // 
            this.ckbDimBDR.FormattingEnabled = true;
            this.ckbDimBDR.Items.AddRange(new object[] {
            "6 job, 5 machine",
            "8 job, 8 machine",
            "10 job, 10 machine",
            "12 job, 12 machine",
            "14 job, 14 machine"});
            this.ckbDimBDR.Location = new System.Drawing.Point(17, 257);
            this.ckbDimBDR.Name = "ckbDimBDR";
            this.ckbDimBDR.Size = new System.Drawing.Size(120, 79);
            this.ckbDimBDR.TabIndex = 48;
            this.ckbDimBDR.SelectedIndexChanged += new System.EventHandler(this.ckb_SelectedIndexChanged);
            // 
            // tabTraining
            // 
            this.tabTraining.Controls.Add(this.splitContainer2);
            this.tabTraining.Location = new System.Drawing.Point(4, 22);
            this.tabTraining.Name = "tabTraining";
            this.tabTraining.Padding = new System.Windows.Forms.Padding(3);
            this.tabTraining.Size = new System.Drawing.Size(340, 465);
            this.tabTraining.TabIndex = 1;
            this.tabTraining.Text = "Generate training data";
            this.tabTraining.UseVisualStyleBackColor = true;
            // 
            // splitContainer2
            // 
            this.splitContainer2.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer2.Location = new System.Drawing.Point(3, 3);
            this.splitContainer2.Name = "splitContainer2";
            // 
            // splitContainer2.Panel1
            // 
            this.splitContainer2.Panel1.Controls.Add(this.numericLiblinearNrFeat);
            this.splitContainer2.Panel1.Controls.Add(this.numericLiblinearModel);
            this.splitContainer2.Panel1.Controls.Add(this.labelLiblinearNrFeat);
            this.splitContainer2.Panel1.Controls.Add(this.labelLiblinearModel);
            this.splitContainer2.Panel1.Controls.Add(this.comboBoxLiblinearLogfile);
            this.splitContainer2.Panel1.Controls.Add(this.labelModel);
            this.splitContainer2.Panel1.Controls.Add(this.ckbProblemModel);
            this.splitContainer2.Panel1.Controls.Add(this.ckbTrainingDim);
            this.splitContainer2.Panel1.Controls.Add(this.ckbTracks);
            this.splitContainer2.Panel1.Controls.Add(this.labelTracks);
            this.splitContainer2.Panel1.Controls.Add(this.label2);
            this.splitContainer2.Panel1.Controls.Add(this.labelProblemModel);
            // 
            // splitContainer2.Panel2
            // 
            this.splitContainer2.Panel2.Controls.Add(this.splitContainer3);
            this.splitContainer2.Size = new System.Drawing.Size(334, 459);
            this.splitContainer2.SplitterDistance = 126;
            this.splitContainer2.TabIndex = 0;
            // 
            // splitContainer3
            // 
            this.splitContainer3.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer3.Location = new System.Drawing.Point(0, 0);
            this.splitContainer3.Name = "splitContainer3";
            this.splitContainer3.Orientation = System.Windows.Forms.Orientation.Horizontal;
            // 
            // splitContainer3.Panel1
            // 
            this.splitContainer3.Panel1.Controls.Add(this.splitContainer6);
            // 
            // splitContainer3.Panel2
            // 
            this.splitContainer3.Panel2.Controls.Add(this.splitContainer13);
            this.splitContainer3.Size = new System.Drawing.Size(204, 459);
            this.splitContainer3.SplitterDistance = 209;
            this.splitContainer3.TabIndex = 0;
            // 
            // splitContainer13
            // 
            this.splitContainer13.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer13.Location = new System.Drawing.Point(0, 0);
            this.splitContainer13.Name = "splitContainer13";
            this.splitContainer13.Orientation = System.Windows.Forms.Orientation.Horizontal;
            // 
            // splitContainer13.Panel1
            // 
            this.splitContainer13.Panel1.Controls.Add(this.cancelAsyncButtonRankTrData);
            this.splitContainer13.Panel1.Controls.Add(this.labelRanks);
            this.splitContainer13.Panel1.Controls.Add(this.startAsyncButtonRankTrData);
            this.splitContainer13.Panel1.Controls.Add(this.ckbRanks);
            // 
            // splitContainer13.Panel2
            // 
            this.splitContainer13.Panel2.Controls.Add(this.splitContainer14);
            this.splitContainer13.Size = new System.Drawing.Size(204, 246);
            this.splitContainer13.SplitterDistance = 123;
            this.splitContainer13.TabIndex = 57;
            // 
            // splitContainer14
            // 
            this.splitContainer14.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer14.Location = new System.Drawing.Point(0, 0);
            this.splitContainer14.Name = "splitContainer14";
            this.splitContainer14.Orientation = System.Windows.Forms.Orientation.Horizontal;
            // 
            // splitContainer14.Panel1
            // 
            this.splitContainer14.Panel1.Controls.Add(this.radioImitationLearningFixedSupervision);
            this.splitContainer14.Panel1.Controls.Add(this.radioImitationLearningSupervised);
            this.splitContainer14.Panel1.Controls.Add(this.radioImitationLearningUnsupervised);
            // 
            // splitContainer14.Panel2
            // 
            this.splitContainer14.Panel2.Controls.Add(this.ckbExtendTrainingSet);
            this.splitContainer14.Size = new System.Drawing.Size(204, 119);
            this.splitContainer14.SplitterDistance = 68;
            this.splitContainer14.TabIndex = 0;
            // 
            // ckbExtendTrainingSet
            // 
            this.ckbExtendTrainingSet.FormattingEnabled = true;
            this.ckbExtendTrainingSet.Items.AddRange(new object[] {
            "Extended dataset"});
            this.ckbExtendTrainingSet.Location = new System.Drawing.Point(4, 10);
            this.ckbExtendTrainingSet.Name = "ckbExtendTrainingSet";
            this.ckbExtendTrainingSet.Size = new System.Drawing.Size(120, 19);
            this.ckbExtendTrainingSet.TabIndex = 50;
            // 
            // radioImitationLearningUnsupervised
            // 
            this.radioImitationLearningUnsupervised.AutoSize = true;
            this.radioImitationLearningUnsupervised.Location = new System.Drawing.Point(6, 25);
            this.radioImitationLearningUnsupervised.Name = "radioImitationLearningUnsupervised";
            this.radioImitationLearningUnsupervised.Size = new System.Drawing.Size(130, 17);
            this.radioImitationLearningUnsupervised.TabIndex = 58;
            this.radioImitationLearningUnsupervised.TabStop = true;
            this.radioImitationLearningUnsupervised.Text = "Unsupervised learning";
            this.radioImitationLearningUnsupervised.UseVisualStyleBackColor = true;
            // 
            // radioImitationLearningSupervised
            // 
            this.radioImitationLearningSupervised.AutoSize = true;
            this.radioImitationLearningSupervised.Location = new System.Drawing.Point(6, 3);
            this.radioImitationLearningSupervised.Name = "radioImitationLearningSupervised";
            this.radioImitationLearningSupervised.Size = new System.Drawing.Size(118, 17);
            this.radioImitationLearningSupervised.TabIndex = 57;
            this.radioImitationLearningSupervised.TabStop = true;
            this.radioImitationLearningSupervised.Text = "Supervised learning";
            this.radioImitationLearningSupervised.UseVisualStyleBackColor = true;
            // 
            // radioImitationLearningFixedSupervision
            // 
            this.radioImitationLearningFixedSupervision.AutoSize = true;
            this.radioImitationLearningFixedSupervision.Location = new System.Drawing.Point(6, 49);
            this.radioImitationLearningFixedSupervision.Name = "radioImitationLearningFixedSupervision";
            this.radioImitationLearningFixedSupervision.Size = new System.Drawing.Size(144, 17);
            this.radioImitationLearningFixedSupervision.TabIndex = 59;
            this.radioImitationLearningFixedSupervision.TabStop = true;
            this.radioImitationLearningFixedSupervision.Text = "Fixed supervised learning";
            this.radioImitationLearningFixedSupervision.UseVisualStyleBackColor = true;
            // 
            // ckbRanks
            // 
            this.ckbRanks.FormattingEnabled = true;
            this.ckbRanks.Items.AddRange(new object[] {
            "Basic ranking (opt vs. subopt)",
            "Full Pareto ranking",
            "Partial Pareto ranking",
            "All rankings"});
            this.ckbRanks.Location = new System.Drawing.Point(6, 21);
            this.ckbRanks.Name = "ckbRanks";
            this.ckbRanks.Size = new System.Drawing.Size(193, 64);
            this.ckbRanks.TabIndex = 24;
            this.ckbRanks.SelectedIndexChanged += new System.EventHandler(this.ckb_ckbTracks);
            // 
            // startAsyncButtonRankTrData
            // 
            this.startAsyncButtonRankTrData.Location = new System.Drawing.Point(3, 91);
            this.startAsyncButtonRankTrData.Name = "startAsyncButtonRankTrData";
            this.startAsyncButtonRankTrData.Size = new System.Drawing.Size(60, 23);
            this.startAsyncButtonRankTrData.TabIndex = 56;
            this.startAsyncButtonRankTrData.UseVisualStyleBackColor = true;
            this.startAsyncButtonRankTrData.Click += new System.EventHandler(this.startAsyncButtonRankTrData_Click);
            // 
            // labelRanks
            // 
            this.labelRanks.AutoSize = true;
            this.labelRanks.Location = new System.Drawing.Point(3, 5);
            this.labelRanks.Name = "labelRanks";
            this.labelRanks.Size = new System.Drawing.Size(41, 13);
            this.labelRanks.TabIndex = 27;
            this.labelRanks.Text = "Ranks:";
            // 
            // cancelAsyncButtonRankTrData
            // 
            this.cancelAsyncButtonRankTrData.Location = new System.Drawing.Point(69, 91);
            this.cancelAsyncButtonRankTrData.Name = "cancelAsyncButtonRankTrData";
            this.cancelAsyncButtonRankTrData.Size = new System.Drawing.Size(60, 23);
            this.cancelAsyncButtonRankTrData.TabIndex = 55;
            this.cancelAsyncButtonRankTrData.UseVisualStyleBackColor = true;
            this.cancelAsyncButtonRankTrData.Click += new System.EventHandler(this.cancelAsyncButtonRankTrData_Click);
            // 
            // splitContainer6
            // 
            this.splitContainer6.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer6.Location = new System.Drawing.Point(0, 0);
            this.splitContainer6.Name = "splitContainer6";
            this.splitContainer6.Orientation = System.Windows.Forms.Orientation.Horizontal;
            // 
            // splitContainer6.Panel1
            // 
            this.splitContainer6.Panel1.Controls.Add(this.linearSolver);
            this.splitContainer6.Panel1.Controls.Add(this.radioButtonGLPKtraining);
            this.splitContainer6.Panel1.Controls.Add(this.startAsyncButtonGenTrData);
            this.splitContainer6.Panel1.Controls.Add(this.radioButtonGUROBItraining);
            this.splitContainer6.Panel1.Controls.Add(this.cancelAsyncButtonGenTrData);
            // 
            // splitContainer6.Panel2
            // 
            this.splitContainer6.Panel2.Controls.Add(this.startAsyncButtonFeatTrData);
            this.splitContainer6.Panel2.Controls.Add(this.labelScale);
            this.splitContainer6.Panel2.Controls.Add(this.cancelAsyncButtonFeatTrData);
            this.splitContainer6.Panel2.Controls.Add(this.radioGlobal);
            this.splitContainer6.Panel2.Controls.Add(this.radioLocal);
            this.splitContainer6.Size = new System.Drawing.Size(204, 209);
            this.splitContainer6.SplitterDistance = 109;
            this.splitContainer6.TabIndex = 0;
            // 
            // radioLocal
            // 
            this.radioLocal.AutoSize = true;
            this.radioLocal.Location = new System.Drawing.Point(5, 25);
            this.radioLocal.Name = "radioLocal";
            this.radioLocal.Size = new System.Drawing.Size(82, 17);
            this.radioLocal.TabIndex = 30;
            this.radioLocal.TabStop = true;
            this.radioLocal.Text = "Local model";
            this.radioLocal.UseVisualStyleBackColor = true;
            // 
            // radioGlobal
            // 
            this.radioGlobal.AutoSize = true;
            this.radioGlobal.Location = new System.Drawing.Point(5, 45);
            this.radioGlobal.Name = "radioGlobal";
            this.radioGlobal.Size = new System.Drawing.Size(86, 17);
            this.radioGlobal.TabIndex = 32;
            this.radioGlobal.TabStop = true;
            this.radioGlobal.Text = "Global model";
            this.radioGlobal.UseVisualStyleBackColor = true;
            // 
            // cancelAsyncButtonFeatTrData
            // 
            this.cancelAsyncButtonFeatTrData.Location = new System.Drawing.Point(63, 68);
            this.cancelAsyncButtonFeatTrData.Name = "cancelAsyncButtonFeatTrData";
            this.cancelAsyncButtonFeatTrData.Size = new System.Drawing.Size(60, 23);
            this.cancelAsyncButtonFeatTrData.TabIndex = 56;
            this.cancelAsyncButtonFeatTrData.UseVisualStyleBackColor = true;
            this.cancelAsyncButtonFeatTrData.Click += new System.EventHandler(this.cancelAsyncButtonFeatTrData_Click);
            // 
            // labelScale
            // 
            this.labelScale.AutoSize = true;
            this.labelScale.Location = new System.Drawing.Point(2, 9);
            this.labelScale.Name = "labelScale";
            this.labelScale.Size = new System.Drawing.Size(57, 13);
            this.labelScale.TabIndex = 29;
            this.labelScale.Text = "Scalability:";
            // 
            // startAsyncButtonFeatTrData
            // 
            this.startAsyncButtonFeatTrData.Location = new System.Drawing.Point(3, 68);
            this.startAsyncButtonFeatTrData.Name = "startAsyncButtonFeatTrData";
            this.startAsyncButtonFeatTrData.Size = new System.Drawing.Size(60, 23);
            this.startAsyncButtonFeatTrData.TabIndex = 55;
            this.startAsyncButtonFeatTrData.UseVisualStyleBackColor = true;
            this.startAsyncButtonFeatTrData.Click += new System.EventHandler(this.startAsyncButtonFeatTrData_Click);
            // 
            // cancelAsyncButtonGenTrData
            // 
            this.cancelAsyncButtonGenTrData.Location = new System.Drawing.Point(63, 80);
            this.cancelAsyncButtonGenTrData.Name = "cancelAsyncButtonGenTrData";
            this.cancelAsyncButtonGenTrData.Size = new System.Drawing.Size(60, 23);
            this.cancelAsyncButtonGenTrData.TabIndex = 2;
            this.cancelAsyncButtonGenTrData.UseVisualStyleBackColor = true;
            this.cancelAsyncButtonGenTrData.Click += new System.EventHandler(this.cancelAsyncButtonGenTrData_Click);
            // 
            // radioButtonGUROBItraining
            // 
            this.radioButtonGUROBItraining.AutoSize = true;
            this.radioButtonGUROBItraining.Location = new System.Drawing.Point(6, 48);
            this.radioButtonGUROBItraining.Name = "radioButtonGUROBItraining";
            this.radioButtonGUROBItraining.Size = new System.Drawing.Size(56, 17);
            this.radioButtonGUROBItraining.TabIndex = 54;
            this.radioButtonGUROBItraining.TabStop = true;
            this.radioButtonGUROBItraining.Text = "Gurobi";
            this.radioButtonGUROBItraining.UseVisualStyleBackColor = true;
            // 
            // startAsyncButtonGenTrData
            // 
            this.startAsyncButtonGenTrData.Location = new System.Drawing.Point(3, 80);
            this.startAsyncButtonGenTrData.Name = "startAsyncButtonGenTrData";
            this.startAsyncButtonGenTrData.Size = new System.Drawing.Size(60, 23);
            this.startAsyncButtonGenTrData.TabIndex = 1;
            this.startAsyncButtonGenTrData.UseVisualStyleBackColor = true;
            this.startAsyncButtonGenTrData.Click += new System.EventHandler(this.startAsyncButtonGenTrData_Click);
            // 
            // radioButtonGLPKtraining
            // 
            this.radioButtonGLPKtraining.AutoSize = true;
            this.radioButtonGLPKtraining.Location = new System.Drawing.Point(6, 25);
            this.radioButtonGLPKtraining.Name = "radioButtonGLPKtraining";
            this.radioButtonGLPKtraining.Size = new System.Drawing.Size(53, 17);
            this.radioButtonGLPKtraining.TabIndex = 52;
            this.radioButtonGLPKtraining.TabStop = true;
            this.radioButtonGLPKtraining.Text = "GLPK";
            this.radioButtonGLPKtraining.UseVisualStyleBackColor = true;
            // 
            // linearSolver
            // 
            this.linearSolver.AutoSize = true;
            this.linearSolver.Location = new System.Drawing.Point(3, 9);
            this.linearSolver.Name = "linearSolver";
            this.linearSolver.Size = new System.Drawing.Size(72, 13);
            this.linearSolver.TabIndex = 53;
            this.linearSolver.Text = "Linear Solver:";
            // 
            // labelProblemModel
            // 
            this.labelProblemModel.AutoSize = true;
            this.labelProblemModel.Location = new System.Drawing.Point(0, 37);
            this.labelProblemModel.Name = "labelProblemModel";
            this.labelProblemModel.Size = new System.Drawing.Size(96, 13);
            this.labelProblemModel.TabIndex = 25;
            this.labelProblemModel.Text = "Problem instances:";
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(3, 399);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(59, 13);
            this.label2.TabIndex = 50;
            this.label2.Text = "Dimension:";
            // 
            // labelTracks
            // 
            this.labelTracks.AutoSize = true;
            this.labelTracks.Location = new System.Drawing.Point(0, 202);
            this.labelTracks.Name = "labelTracks";
            this.labelTracks.Size = new System.Drawing.Size(43, 13);
            this.labelTracks.TabIndex = 26;
            this.labelTracks.Text = "Tracks:";
            // 
            // ckbTracks
            // 
            this.ckbTracks.FormattingEnabled = true;
            this.ckbTracks.Items.AddRange(new object[] {
            "optimal",
            "MWR",
            "LWR",
            "SPT",
            "LPT",
            "RND",
            "CMA-ES",
            "Imitation Learning"});
            this.ckbTracks.Location = new System.Drawing.Point(3, 218);
            this.ckbTracks.Name = "ckbTracks";
            this.ckbTracks.Size = new System.Drawing.Size(120, 124);
            this.ckbTracks.TabIndex = 23;
            this.ckbTracks.SelectedIndexChanged += new System.EventHandler(this.ckb_ckbTracks);
            // 
            // ckbTrainingDim
            // 
            this.ckbTrainingDim.FormattingEnabled = true;
            this.ckbTrainingDim.Items.AddRange(new object[] {
            "6 job, 5 machine",
            "10 job, 10 machine"});
            this.ckbTrainingDim.Location = new System.Drawing.Point(3, 415);
            this.ckbTrainingDim.Name = "ckbTrainingDim";
            this.ckbTrainingDim.Size = new System.Drawing.Size(120, 34);
            this.ckbTrainingDim.TabIndex = 49;
            this.ckbTrainingDim.SelectedIndexChanged += new System.EventHandler(this.ckb_ckbTracks);
            // 
            // ckbProblemModel
            // 
            this.ckbProblemModel.FormattingEnabled = true;
            this.ckbProblemModel.Items.AddRange(new object[] {
            "j.rnd",
            "j.rndn",
            "f.rnd",
            "f.rndn",
            "f.jc",
            "f.mc",
            "f.mxc",
            "j.rnd_p1mdoubled",
            "j.rnd_pj1doubled"});
            this.ckbProblemModel.Location = new System.Drawing.Point(3, 53);
            this.ckbProblemModel.Name = "ckbProblemModel";
            this.ckbProblemModel.Size = new System.Drawing.Size(120, 139);
            this.ckbProblemModel.TabIndex = 22;
            this.ckbProblemModel.SelectedIndexChanged += new System.EventHandler(this.ckb_ckbTracks);
            // 
            // labelModel
            // 
            this.labelModel.AutoSize = true;
            this.labelModel.Location = new System.Drawing.Point(5, 9);
            this.labelModel.Name = "labelModel";
            this.labelModel.Size = new System.Drawing.Size(36, 13);
            this.labelModel.TabIndex = 28;
            this.labelModel.Text = "Model";
            // 
            // comboBoxLiblinearLogfile
            // 
            this.comboBoxLiblinearLogfile.FormattingEnabled = true;
            this.comboBoxLiblinearLogfile.Location = new System.Drawing.Point(2, 349);
            this.comboBoxLiblinearLogfile.Name = "comboBoxLiblinearLogfile";
            this.comboBoxLiblinearLogfile.Size = new System.Drawing.Size(121, 21);
            this.comboBoxLiblinearLogfile.TabIndex = 60;
            // 
            // labelLiblinearModel
            // 
            this.labelLiblinearModel.AutoSize = true;
            this.labelLiblinearModel.Location = new System.Drawing.Point(62, 379);
            this.labelLiblinearModel.Name = "labelLiblinearModel";
            this.labelLiblinearModel.Size = new System.Drawing.Size(16, 13);
            this.labelLiblinearModel.TabIndex = 49;
            this.labelLiblinearModel.Text = "M";
            // 
            // labelLiblinearNrFeat
            // 
            this.labelLiblinearNrFeat.AutoSize = true;
            this.labelLiblinearNrFeat.Location = new System.Drawing.Point(5, 379);
            this.labelLiblinearNrFeat.Name = "labelLiblinearNrFeat";
            this.labelLiblinearNrFeat.Size = new System.Drawing.Size(13, 13);
            this.labelLiblinearNrFeat.TabIndex = 62;
            this.labelLiblinearNrFeat.Text = "F";
            // 
            // numericLiblinearModel
            // 
            this.numericLiblinearModel.Location = new System.Drawing.Point(84, 377);
            this.numericLiblinearModel.Maximum = new decimal(new int[] {
            560,
            0,
            0,
            0});
            this.numericLiblinearModel.Minimum = new decimal(new int[] {
            1,
            0,
            0,
            0});
            this.numericLiblinearModel.Name = "numericLiblinearModel";
            this.numericLiblinearModel.Size = new System.Drawing.Size(38, 20);
            this.numericLiblinearModel.TabIndex = 35;
            this.numericLiblinearModel.Value = new decimal(new int[] {
            1,
            0,
            0,
            0});
            // 
            // numericLiblinearNrFeat
            // 
            this.numericLiblinearNrFeat.Location = new System.Drawing.Point(24, 376);
            this.numericLiblinearNrFeat.Maximum = new decimal(new int[] {
            16,
            0,
            0,
            0});
            this.numericLiblinearNrFeat.Minimum = new decimal(new int[] {
            1,
            0,
            0,
            0});
            this.numericLiblinearNrFeat.Name = "numericLiblinearNrFeat";
            this.numericLiblinearNrFeat.Size = new System.Drawing.Size(38, 20);
            this.numericLiblinearNrFeat.TabIndex = 63;
            this.numericLiblinearNrFeat.Value = new decimal(new int[] {
            16,
            0,
            0,
            0});
            // 
            // tabSimple
            // 
            this.tabSimple.Controls.Add(this.splitContainer1);
            this.tabSimple.Location = new System.Drawing.Point(4, 22);
            this.tabSimple.Name = "tabSimple";
            this.tabSimple.Padding = new System.Windows.Forms.Padding(3);
            this.tabSimple.Size = new System.Drawing.Size(340, 465);
            this.tabSimple.TabIndex = 0;
            this.tabSimple.Text = "Init";
            this.tabSimple.UseVisualStyleBackColor = true;
            // 
            // splitContainer1
            // 
            this.splitContainer1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer1.Location = new System.Drawing.Point(3, 3);
            this.splitContainer1.Name = "splitContainer1";
            // 
            // splitContainer1.Panel1
            // 
            this.splitContainer1.Panel1.Controls.Add(this.ckbSimpleORLIB);
            this.splitContainer1.Panel1.Controls.Add(this.radioSimpleProblemsSingle);
            this.splitContainer1.Panel1.Controls.Add(this.radioSimpleProblemsAll);
            this.splitContainer1.Panel1.Controls.Add(this.ckbSimpleDim);
            this.splitContainer1.Panel1.Controls.Add(this.ckbSimpleDataSet);
            this.splitContainer1.Panel1.Controls.Add(this.labelSimpleDim);
            this.splitContainer1.Panel1.Controls.Add(this.labelSimpleInstanceID);
            this.splitContainer1.Panel1.Controls.Add(this.labelSimpleData);
            this.splitContainer1.Panel1.Controls.Add(this.labelSimpleProblem);
            this.splitContainer1.Panel1.Controls.Add(this.ckbSimpleProblem);
            this.splitContainer1.Panel1.Controls.Add(this.numericUpDownInstanceID);
            // 
            // splitContainer1.Panel2
            // 
            this.splitContainer1.Panel2.Controls.Add(this.splitContainer4);
            this.splitContainer1.Size = new System.Drawing.Size(334, 459);
            this.splitContainer1.SplitterDistance = 132;
            this.splitContainer1.TabIndex = 0;
            // 
            // splitContainer4
            // 
            this.splitContainer4.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer4.Location = new System.Drawing.Point(0, 0);
            this.splitContainer4.Name = "splitContainer4";
            this.splitContainer4.Orientation = System.Windows.Forms.Orientation.Horizontal;
            // 
            // splitContainer4.Panel1
            // 
            this.splitContainer4.Panel1.Controls.Add(this.buttonSimpleStart);
            this.splitContainer4.Panel1.Controls.Add(this.labelSimpleSDR);
            this.splitContainer4.Panel1.Controls.Add(this.ckbSimpleSDR);
            // 
            // splitContainer4.Panel2
            // 
            this.splitContainer4.Panel2.Controls.Add(this.labelOptimization);
            this.splitContainer4.Panel2.Controls.Add(this.cancelAsyncButtonOptimize);
            this.splitContainer4.Panel2.Controls.Add(this.labelOptimize);
            this.splitContainer4.Panel2.Controls.Add(this.radioButtonGLPK);
            this.splitContainer4.Panel2.Controls.Add(this.numericUpDownTmLimit);
            this.splitContainer4.Panel2.Controls.Add(this.labelTmLimit);
            this.splitContainer4.Panel2.Controls.Add(this.startAsyncButtonOptimize);
            this.splitContainer4.Panel2.Controls.Add(this.radioButtonGUROBI);
            this.splitContainer4.Size = new System.Drawing.Size(198, 459);
            this.splitContainer4.SplitterDistance = 201;
            this.splitContainer4.TabIndex = 0;
            // 
            // radioButtonGUROBI
            // 
            this.radioButtonGUROBI.AutoSize = true;
            this.radioButtonGUROBI.Location = new System.Drawing.Point(6, 71);
            this.radioButtonGUROBI.Name = "radioButtonGUROBI";
            this.radioButtonGUROBI.Size = new System.Drawing.Size(155, 17);
            this.radioButtonGUROBI.TabIndex = 49;
            this.radioButtonGUROBI.TabStop = true;
            this.radioButtonGUROBI.Text = "Gurobi (commercial licence)";
            this.radioButtonGUROBI.UseVisualStyleBackColor = true;
            // 
            // startAsyncButtonOptimize
            // 
            this.startAsyncButtonOptimize.Location = new System.Drawing.Point(6, 127);
            this.startAsyncButtonOptimize.Name = "startAsyncButtonOptimize";
            this.startAsyncButtonOptimize.Size = new System.Drawing.Size(75, 23);
            this.startAsyncButtonOptimize.TabIndex = 46;
            this.startAsyncButtonOptimize.UseVisualStyleBackColor = true;
            this.startAsyncButtonOptimize.Click += new System.EventHandler(this.startAsyncButtonOptimize_Click);
            // 
            // labelTmLimit
            // 
            this.labelTmLimit.AutoSize = true;
            this.labelTmLimit.Location = new System.Drawing.Point(3, 103);
            this.labelTmLimit.Name = "labelTmLimit";
            this.labelTmLimit.Size = new System.Drawing.Size(151, 13);
            this.labelTmLimit.TabIndex = 35;
            this.labelTmLimit.Text = "Time limit per instance (in sec):";
            // 
            // numericUpDownTmLimit
            // 
            this.numericUpDownTmLimit.Location = new System.Drawing.Point(156, 100);
            this.numericUpDownTmLimit.Maximum = new decimal(new int[] {
            6000,
            0,
            0,
            0});
            this.numericUpDownTmLimit.Minimum = new decimal(new int[] {
            1,
            0,
            0,
            0});
            this.numericUpDownTmLimit.Name = "numericUpDownTmLimit";
            this.numericUpDownTmLimit.Size = new System.Drawing.Size(38, 20);
            this.numericUpDownTmLimit.TabIndex = 34;
            this.numericUpDownTmLimit.Value = new decimal(new int[] {
            10,
            0,
            0,
            0});
            // 
            // radioButtonGLPK
            // 
            this.radioButtonGLPK.AutoSize = true;
            this.radioButtonGLPK.Location = new System.Drawing.Point(6, 48);
            this.radioButtonGLPK.Name = "radioButtonGLPK";
            this.radioButtonGLPK.Size = new System.Drawing.Size(123, 17);
            this.radioButtonGLPK.TabIndex = 48;
            this.radioButtonGLPK.TabStop = true;
            this.radioButtonGLPK.Text = "GLPK (free software)";
            this.radioButtonGLPK.UseVisualStyleBackColor = true;
            // 
            // labelOptimize
            // 
            this.labelOptimize.AutoSize = true;
            this.labelOptimize.Location = new System.Drawing.Point(3, 32);
            this.labelOptimize.Name = "labelOptimize";
            this.labelOptimize.Size = new System.Drawing.Size(72, 13);
            this.labelOptimize.TabIndex = 48;
            this.labelOptimize.Text = "Linear Solver:";
            // 
            // cancelAsyncButtonOptimize
            // 
            this.cancelAsyncButtonOptimize.Location = new System.Drawing.Point(87, 127);
            this.cancelAsyncButtonOptimize.Name = "cancelAsyncButtonOptimize";
            this.cancelAsyncButtonOptimize.Size = new System.Drawing.Size(75, 23);
            this.cancelAsyncButtonOptimize.TabIndex = 50;
            this.cancelAsyncButtonOptimize.UseVisualStyleBackColor = true;
            this.cancelAsyncButtonOptimize.Click += new System.EventHandler(this.cancelAsyncButtonOptimize_Click);
            // 
            // labelOptimization
            // 
            this.labelOptimization.AutoSize = true;
            this.labelOptimization.Location = new System.Drawing.Point(3, 4);
            this.labelOptimization.Name = "labelOptimization";
            this.labelOptimization.Size = new System.Drawing.Size(84, 13);
            this.labelOptimization.TabIndex = 51;
            this.labelOptimization.Text = "OPTIMIZATION";
            // 
            // ckbSimpleSDR
            // 
            this.ckbSimpleSDR.FormattingEnabled = true;
            this.ckbSimpleSDR.Items.AddRange(new object[] {
            "MWR",
            "LWR",
            "SPT",
            "LPT",
            "RND"});
            this.ckbSimpleSDR.Location = new System.Drawing.Point(6, 31);
            this.ckbSimpleSDR.Name = "ckbSimpleSDR";
            this.ckbSimpleSDR.Size = new System.Drawing.Size(120, 79);
            this.ckbSimpleSDR.TabIndex = 24;
            this.ckbSimpleSDR.SelectedIndexChanged += new System.EventHandler(this.ckb_SelectedIndexChanged);
            // 
            // labelSimpleSDR
            // 
            this.labelSimpleSDR.AutoSize = true;
            this.labelSimpleSDR.Location = new System.Drawing.Point(3, 15);
            this.labelSimpleSDR.Name = "labelSimpleSDR";
            this.labelSimpleSDR.Size = new System.Drawing.Size(164, 13);
            this.labelSimpleSDR.TabIndex = 45;
            this.labelSimpleSDR.Text = "Simple Priority Dispatching Rules:";
            // 
            // buttonSimpleStart
            // 
            this.buttonSimpleStart.Location = new System.Drawing.Point(6, 116);
            this.buttonSimpleStart.Name = "buttonSimpleStart";
            this.buttonSimpleStart.Size = new System.Drawing.Size(75, 23);
            this.buttonSimpleStart.TabIndex = 0;
            this.buttonSimpleStart.Text = "Apply";
            this.buttonSimpleStart.UseVisualStyleBackColor = true;
            this.buttonSimpleStart.Click += new System.EventHandler(this.buttonSDRStart_Click);
            // 
            // numericUpDownInstanceID
            // 
            this.numericUpDownInstanceID.Location = new System.Drawing.Point(48, 262);
            this.numericUpDownInstanceID.Maximum = new decimal(new int[] {
            500,
            0,
            0,
            0});
            this.numericUpDownInstanceID.Minimum = new decimal(new int[] {
            1,
            0,
            0,
            0});
            this.numericUpDownInstanceID.Name = "numericUpDownInstanceID";
            this.numericUpDownInstanceID.Size = new System.Drawing.Size(38, 20);
            this.numericUpDownInstanceID.TabIndex = 34;
            this.numericUpDownInstanceID.Value = new decimal(new int[] {
            1,
            0,
            0,
            0});
            this.numericUpDownInstanceID.Click += new System.EventHandler(this.UnValidate);
            // 
            // ckbSimpleProblem
            // 
            this.ckbSimpleProblem.FormattingEnabled = true;
            this.ckbSimpleProblem.Items.AddRange(new object[] {
            "jrnd",
            "jrndn",
            "frnd",
            "frndn",
            "fjc",
            "fmc",
            "fmxc",
            "jrnd, p1m doubled",
            "jrnd, pj1 doubled"});
            this.ckbSimpleProblem.Location = new System.Drawing.Point(3, 71);
            this.ckbSimpleProblem.Name = "ckbSimpleProblem";
            this.ckbSimpleProblem.Size = new System.Drawing.Size(120, 139);
            this.ckbSimpleProblem.TabIndex = 14;
            this.ckbSimpleProblem.SelectedIndexChanged += new System.EventHandler(this.ckb_SelectedIndexChanged);
            // 
            // labelSimpleProblem
            // 
            this.labelSimpleProblem.AutoSize = true;
            this.labelSimpleProblem.Location = new System.Drawing.Point(5, 12);
            this.labelSimpleProblem.Name = "labelSimpleProblem";
            this.labelSimpleProblem.Size = new System.Drawing.Size(96, 13);
            this.labelSimpleProblem.TabIndex = 15;
            this.labelSimpleProblem.Text = "Problem instances:";
            // 
            // labelSimpleData
            // 
            this.labelSimpleData.AutoSize = true;
            this.labelSimpleData.Location = new System.Drawing.Point(3, 291);
            this.labelSimpleData.Name = "labelSimpleData";
            this.labelSimpleData.Size = new System.Drawing.Size(33, 13);
            this.labelSimpleData.TabIndex = 45;
            this.labelSimpleData.Text = "Data:";
            // 
            // labelSimpleInstanceID
            // 
            this.labelSimpleInstanceID.AutoSize = true;
            this.labelSimpleInstanceID.Location = new System.Drawing.Point(3, 223);
            this.labelSimpleInstanceID.Name = "labelSimpleInstanceID";
            this.labelSimpleInstanceID.Size = new System.Drawing.Size(56, 13);
            this.labelSimpleInstanceID.TabIndex = 35;
            this.labelSimpleInstanceID.Text = "Instances:";
            // 
            // labelSimpleDim
            // 
            this.labelSimpleDim.AutoSize = true;
            this.labelSimpleDim.Location = new System.Drawing.Point(3, 355);
            this.labelSimpleDim.Name = "labelSimpleDim";
            this.labelSimpleDim.Size = new System.Drawing.Size(59, 13);
            this.labelSimpleDim.TabIndex = 42;
            this.labelSimpleDim.Text = "Dimension:";
            // 
            // ckbSimpleDataSet
            // 
            this.ckbSimpleDataSet.FormattingEnabled = true;
            this.ckbSimpleDataSet.Items.AddRange(new object[] {
            "Train",
            "Test"});
            this.ckbSimpleDataSet.Location = new System.Drawing.Point(6, 307);
            this.ckbSimpleDataSet.Name = "ckbSimpleDataSet";
            this.ckbSimpleDataSet.Size = new System.Drawing.Size(120, 34);
            this.ckbSimpleDataSet.TabIndex = 26;
            this.ckbSimpleDataSet.SelectedIndexChanged += new System.EventHandler(this.ckb_SelectedIndexChanged);
            // 
            // ckbSimpleDim
            // 
            this.ckbSimpleDim.FormattingEnabled = true;
            this.ckbSimpleDim.Items.AddRange(new object[] {
            "6 job, 5 machine",
            "8 job, 8 machine",
            "10 job, 10 machine",
            "12 job, 12 machine",
            "14 job, 14 machine"});
            this.ckbSimpleDim.Location = new System.Drawing.Point(6, 371);
            this.ckbSimpleDim.Name = "ckbSimpleDim";
            this.ckbSimpleDim.Size = new System.Drawing.Size(120, 79);
            this.ckbSimpleDim.TabIndex = 25;
            this.ckbSimpleDim.SelectedIndexChanged += new System.EventHandler(this.ckb_SelectedIndexChanged);
            // 
            // radioSimpleProblemsAll
            // 
            this.radioSimpleProblemsAll.AutoSize = true;
            this.radioSimpleProblemsAll.Location = new System.Drawing.Point(6, 239);
            this.radioSimpleProblemsAll.Name = "radioSimpleProblemsAll";
            this.radioSimpleProblemsAll.Size = new System.Drawing.Size(36, 17);
            this.radioSimpleProblemsAll.TabIndex = 46;
            this.radioSimpleProblemsAll.TabStop = true;
            this.radioSimpleProblemsAll.Text = "All";
            this.radioSimpleProblemsAll.UseVisualStyleBackColor = true;
            this.radioSimpleProblemsAll.CheckedChanged += new System.EventHandler(this.UnValidate);
            // 
            // radioSimpleProblemsSingle
            // 
            this.radioSimpleProblemsSingle.AutoSize = true;
            this.radioSimpleProblemsSingle.Location = new System.Drawing.Point(6, 262);
            this.radioSimpleProblemsSingle.Name = "radioSimpleProblemsSingle";
            this.radioSimpleProblemsSingle.Size = new System.Drawing.Size(51, 17);
            this.radioSimpleProblemsSingle.TabIndex = 47;
            this.radioSimpleProblemsSingle.TabStop = true;
            this.radioSimpleProblemsSingle.Text = "Index";
            this.radioSimpleProblemsSingle.UseVisualStyleBackColor = true;
            this.radioSimpleProblemsSingle.CheckedChanged += new System.EventHandler(this.UnValidate);
            // 
            // ckbSimpleORLIB
            // 
            this.ckbSimpleORLIB.FormattingEnabled = true;
            this.ckbSimpleORLIB.Items.AddRange(new object[] {
            "ORLIB fsp",
            "ORLIB jsp"});
            this.ckbSimpleORLIB.Location = new System.Drawing.Point(3, 31);
            this.ckbSimpleORLIB.Name = "ckbSimpleORLIB";
            this.ckbSimpleORLIB.Size = new System.Drawing.Size(120, 34);
            this.ckbSimpleORLIB.TabIndex = 48;
            this.ckbSimpleORLIB.SelectedIndexChanged += new System.EventHandler(this.ckb_SelectedIndexChanged);
            // 
            // tabControl
            // 
            this.tabControl.Controls.Add(this.tabSimple);
            this.tabControl.Controls.Add(this.tabTraining);
            this.tabControl.Controls.Add(this.tabBDR);
            this.tabControl.Controls.Add(this.tabLinear);
            this.tabControl.Controls.Add(this.tabCMAES);
            this.tabControl.Location = new System.Drawing.Point(7, 6);
            this.tabControl.Name = "tabControl";
            this.tabControl.SelectedIndex = 0;
            this.tabControl.Size = new System.Drawing.Size(348, 491);
            this.tabControl.TabIndex = 0;
            this.tabControl.SelectedIndexChanged += new System.EventHandler(this.tabControl_SelectedIndexChanged);
            // 
            // App
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1133, 500);
            this.Controls.Add(this.splitContainerForm);
            this.Name = "App";
            this.Text = "JSP PREF SIMULATION";
            this.Load += new System.EventHandler(this.App_Load);
            this.splitContainerForm.Panel1.ResumeLayout(false);
            this.splitContainerForm.Panel2.ResumeLayout(false);
            this.splitContainerForm.Panel2.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainerForm)).EndInit();
            this.splitContainerForm.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox)).EndInit();
            this.tabCMAES.ResumeLayout(false);
            this.splitContainer10.Panel1.ResumeLayout(false);
            this.splitContainer10.Panel1.PerformLayout();
            this.splitContainer10.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer10)).EndInit();
            this.splitContainer10.ResumeLayout(false);
            this.splitContainer11.Panel1.ResumeLayout(false);
            this.splitContainer11.Panel1.PerformLayout();
            this.splitContainer11.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer11)).EndInit();
            this.splitContainer11.ResumeLayout(false);
            this.splitContainer12.Panel1.ResumeLayout(false);
            this.splitContainer12.Panel1.PerformLayout();
            this.splitContainer12.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer12)).EndInit();
            this.splitContainer12.ResumeLayout(false);
            this.tabLinear.ResumeLayout(false);
            this.splitContainer8.Panel1.ResumeLayout(false);
            this.splitContainer8.Panel2.ResumeLayout(false);
            this.splitContainer8.Panel2.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer8)).EndInit();
            this.splitContainer8.ResumeLayout(false);
            this.splitContainer9.Panel1.ResumeLayout(false);
            this.splitContainer9.Panel1.PerformLayout();
            this.splitContainer9.Panel2.ResumeLayout(false);
            this.splitContainer9.Panel2.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer9)).EndInit();
            this.splitContainer9.ResumeLayout(false);
            this.tabBDR.ResumeLayout(false);
            this.splitContainer7.Panel1.ResumeLayout(false);
            this.splitContainer7.Panel1.PerformLayout();
            this.splitContainer7.Panel2.ResumeLayout(false);
            this.splitContainer7.Panel2.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer7)).EndInit();
            this.splitContainer7.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.numericUpDownBDRsplitStep)).EndInit();
            this.tabTraining.ResumeLayout(false);
            this.splitContainer2.Panel1.ResumeLayout(false);
            this.splitContainer2.Panel1.PerformLayout();
            this.splitContainer2.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer2)).EndInit();
            this.splitContainer2.ResumeLayout(false);
            this.splitContainer3.Panel1.ResumeLayout(false);
            this.splitContainer3.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer3)).EndInit();
            this.splitContainer3.ResumeLayout(false);
            this.splitContainer13.Panel1.ResumeLayout(false);
            this.splitContainer13.Panel1.PerformLayout();
            this.splitContainer13.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer13)).EndInit();
            this.splitContainer13.ResumeLayout(false);
            this.splitContainer14.Panel1.ResumeLayout(false);
            this.splitContainer14.Panel1.PerformLayout();
            this.splitContainer14.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer14)).EndInit();
            this.splitContainer14.ResumeLayout(false);
            this.splitContainer6.Panel1.ResumeLayout(false);
            this.splitContainer6.Panel1.PerformLayout();
            this.splitContainer6.Panel2.ResumeLayout(false);
            this.splitContainer6.Panel2.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer6)).EndInit();
            this.splitContainer6.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.numericLiblinearModel)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.numericLiblinearNrFeat)).EndInit();
            this.tabSimple.ResumeLayout(false);
            this.splitContainer1.Panel1.ResumeLayout(false);
            this.splitContainer1.Panel1.PerformLayout();
            this.splitContainer1.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer1)).EndInit();
            this.splitContainer1.ResumeLayout(false);
            this.splitContainer4.Panel1.ResumeLayout(false);
            this.splitContainer4.Panel1.PerformLayout();
            this.splitContainer4.Panel2.ResumeLayout(false);
            this.splitContainer4.Panel2.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer4)).EndInit();
            this.splitContainer4.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.numericUpDownTmLimit)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.numericUpDownInstanceID)).EndInit();
            this.tabControl.ResumeLayout(false);
            this.ResumeLayout(false);

        }

        private void InitializeBackgroundWorker()
        {
            // 
            // bkgWorkerFeatTrData
            //             
            this.bkgWorkerFeatTrData.WorkerReportsProgress = true;
            this.bkgWorkerFeatTrData.WorkerSupportsCancellation = true;
            this.bkgWorkerFeatTrData.DoWork += new System.ComponentModel.DoWorkEventHandler(bkgWorkerFeatTrData_DoWork);
            this.bkgWorkerFeatTrData.RunWorkerCompleted += new System.ComponentModel.RunWorkerCompletedEventHandler(bkgWorkerFeatTrData_RunWorkerCompleted);
            this.bkgWorkerFeatTrData.ProgressChanged += new System.ComponentModel.ProgressChangedEventHandler(bkgWorker_ProgressChanged);
            // 
            // bkgWorkerRankTrData
            // 
            this.bkgWorkerRankTrData.WorkerReportsProgress = true;
            this.bkgWorkerRankTrData.WorkerSupportsCancellation = true;
            this.bkgWorkerRankTrData.DoWork += new System.ComponentModel.DoWorkEventHandler(bkgWorkerRankTrData_DoWork);
            this.bkgWorkerRankTrData.RunWorkerCompleted += new System.ComponentModel.RunWorkerCompletedEventHandler(bkgWorkerRankTrData_RunWorkerCompleted);
            this.bkgWorkerRankTrData.ProgressChanged += new System.ComponentModel.ProgressChangedEventHandler(bkgWorker_ProgressChanged);
            // 
            // bkgWorkerOptimize
            // 
            this.bkgWorkerOptimize.WorkerReportsProgress = true;
            this.bkgWorkerOptimize.WorkerSupportsCancellation = true;
            this.bkgWorkerOptimize.DoWork += new System.ComponentModel.DoWorkEventHandler(bkgWorkerOptimize_DoWork);
            this.bkgWorkerOptimize.RunWorkerCompleted += new System.ComponentModel.RunWorkerCompletedEventHandler(bkgWorkerOptimize_RunWorkerCompleted);
            this.bkgWorkerOptimize.ProgressChanged += new System.ComponentModel.ProgressChangedEventHandler(bkgWorker_ProgressChanged);
            // 
            // bkgWorkerGenTrData
            // 
            this.bkgWorkerGenTrData.WorkerReportsProgress = true;
            this.bkgWorkerGenTrData.WorkerSupportsCancellation = true;
            this.bkgWorkerGenTrData.DoWork += new System.ComponentModel.DoWorkEventHandler(bkgWorkerGenTrData_DoWork);
            this.bkgWorkerGenTrData.RunWorkerCompleted += new System.ComponentModel.RunWorkerCompletedEventHandler(bkgWorkerGenTrData_RunWorkerCompleted);
            this.bkgWorkerGenTrData.ProgressChanged += new System.ComponentModel.ProgressChangedEventHandler(bkgWorker_ProgressChanged);
            // 
            // bkgWorkerCMA
            // 
            this.bkgWorkerCMA.WorkerReportsProgress = true;
            this.bkgWorkerCMA.WorkerSupportsCancellation = true;
            this.bkgWorkerCMA.DoWork += new System.ComponentModel.DoWorkEventHandler(bkgWorkerCMA_DoWork);
            this.bkgWorkerCMA.RunWorkerCompleted += new System.ComponentModel.RunWorkerCompletedEventHandler(bkgWorkerCMA_RunWorkerCompleted);
            this.bkgWorkerCMA.ProgressChanged += new System.ComponentModel.ProgressChangedEventHandler(bkgWorker_ProgressChanged);
        }

        #endregion

        private System.Windows.Forms.SplitContainer splitContainerForm;
        private System.Windows.Forms.ProgressBar progressBarInner;
        private System.Windows.Forms.RichTextBox richTextBoxConsole;
        private System.Windows.Forms.Label labelFolder;
        private System.Windows.Forms.TextBox textBoxDir;
        private System.Windows.Forms.Label labelStatusbar;
        private System.Windows.Forms.Label labelDefault;
        private System.Windows.Forms.ComboBox comboBoxScheme;
        private System.Windows.Forms.PictureBox pictureBox;
        private System.ComponentModel.BackgroundWorker bkgWorkerOptimize;
        private System.ComponentModel.BackgroundWorker bkgWorkerGenTrData;
        private System.ComponentModel.BackgroundWorker bkgWorkerCMA;
        private System.ComponentModel.BackgroundWorker bkgWorkerRankTrData;
        private System.Windows.Forms.ProgressBar progressBarOuter;
        private System.ComponentModel.BackgroundWorker bkgWorkerFeatTrData;
        private System.Windows.Forms.RichTextBox richTextBox;
        private System.Windows.Forms.TabControl tabControl;
        private System.Windows.Forms.TabPage tabSimple;
        private System.Windows.Forms.SplitContainer splitContainer1;
        private System.Windows.Forms.CheckedListBox ckbSimpleORLIB;
        private System.Windows.Forms.RadioButton radioSimpleProblemsSingle;
        private System.Windows.Forms.RadioButton radioSimpleProblemsAll;
        private System.Windows.Forms.CheckedListBox ckbSimpleDim;
        private System.Windows.Forms.CheckedListBox ckbSimpleDataSet;
        private System.Windows.Forms.Label labelSimpleDim;
        private System.Windows.Forms.Label labelSimpleInstanceID;
        private System.Windows.Forms.Label labelSimpleData;
        private System.Windows.Forms.Label labelSimpleProblem;
        private System.Windows.Forms.CheckedListBox ckbSimpleProblem;
        private System.Windows.Forms.NumericUpDown numericUpDownInstanceID;
        private System.Windows.Forms.SplitContainer splitContainer4;
        private System.Windows.Forms.Button buttonSimpleStart;
        private System.Windows.Forms.Label labelSimpleSDR;
        private System.Windows.Forms.CheckedListBox ckbSimpleSDR;
        private System.Windows.Forms.Label labelOptimization;
        private System.Windows.Forms.Button cancelAsyncButtonOptimize;
        private System.Windows.Forms.Label labelOptimize;
        private System.Windows.Forms.RadioButton radioButtonGLPK;
        private System.Windows.Forms.NumericUpDown numericUpDownTmLimit;
        private System.Windows.Forms.Label labelTmLimit;
        private System.Windows.Forms.Button startAsyncButtonOptimize;
        private System.Windows.Forms.RadioButton radioButtonGUROBI;
        private System.Windows.Forms.TabPage tabTraining;
        private System.Windows.Forms.SplitContainer splitContainer2;
        private System.Windows.Forms.NumericUpDown numericLiblinearNrFeat;
        private System.Windows.Forms.NumericUpDown numericLiblinearModel;
        private System.Windows.Forms.Label labelLiblinearNrFeat;
        private System.Windows.Forms.Label labelLiblinearModel;
        private System.Windows.Forms.ComboBox comboBoxLiblinearLogfile;
        private System.Windows.Forms.Label labelModel;
        private System.Windows.Forms.CheckedListBox ckbProblemModel;
        private System.Windows.Forms.CheckedListBox ckbTrainingDim;
        private System.Windows.Forms.CheckedListBox ckbTracks;
        private System.Windows.Forms.Label labelTracks;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Label labelProblemModel;
        private System.Windows.Forms.SplitContainer splitContainer3;
        private System.Windows.Forms.SplitContainer splitContainer6;
        private System.Windows.Forms.Label linearSolver;
        private System.Windows.Forms.RadioButton radioButtonGLPKtraining;
        private System.Windows.Forms.Button startAsyncButtonGenTrData;
        private System.Windows.Forms.RadioButton radioButtonGUROBItraining;
        private System.Windows.Forms.Button cancelAsyncButtonGenTrData;
        private System.Windows.Forms.Button startAsyncButtonFeatTrData;
        private System.Windows.Forms.Label labelScale;
        private System.Windows.Forms.Button cancelAsyncButtonFeatTrData;
        private System.Windows.Forms.RadioButton radioGlobal;
        private System.Windows.Forms.RadioButton radioLocal;
        private System.Windows.Forms.SplitContainer splitContainer13;
        private System.Windows.Forms.Button cancelAsyncButtonRankTrData;
        private System.Windows.Forms.Label labelRanks;
        private System.Windows.Forms.Button startAsyncButtonRankTrData;
        private System.Windows.Forms.CheckedListBox ckbRanks;
        private System.Windows.Forms.SplitContainer splitContainer14;
        private System.Windows.Forms.RadioButton radioImitationLearningFixedSupervision;
        private System.Windows.Forms.RadioButton radioImitationLearningSupervised;
        private System.Windows.Forms.RadioButton radioImitationLearningUnsupervised;
        private System.Windows.Forms.CheckedListBox ckbExtendTrainingSet;
        private System.Windows.Forms.TabPage tabBDR;
        private System.Windows.Forms.SplitContainer splitContainer7;
        private System.Windows.Forms.CheckedListBox ckbDimBDR;
        private System.Windows.Forms.CheckedListBox ckbSetBDR;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.Label label5;
        private System.Windows.Forms.CheckedListBox ckbDataBDR;
        private System.Windows.Forms.Label label9;
        private System.Windows.Forms.Label label8;
        private System.Windows.Forms.CheckedListBox ckbSDR1BDR;
        private System.Windows.Forms.Label label7;
        private System.Windows.Forms.NumericUpDown numericUpDownBDRsplitStep;
        private System.Windows.Forms.Button buttonSimpleBDR;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.CheckedListBox ckbSDR2BDR;
        private System.Windows.Forms.TabPage tabLinear;
        private System.Windows.Forms.SplitContainer splitContainer8;
        private System.Windows.Forms.SplitContainer splitContainer9;
        private System.Windows.Forms.CheckedListBox ckbDimLIN;
        private System.Windows.Forms.Label label12;
        private System.Windows.Forms.Label label10;
        private System.Windows.Forms.Label label11;
        private System.Windows.Forms.CheckedListBox ckbDataLIN;
        private System.Windows.Forms.CheckedListBox ckbSetLIN;
        private System.Windows.Forms.Label labelLiblinearLogs;
        private System.Windows.Forms.RadioButton radioButtonDependent;
        private System.Windows.Forms.ComboBox comboBoxLiblinearLogs;
        private System.Windows.Forms.Button buttonApplyLiblinearLogs;
        private System.Windows.Forms.RadioButton radioButtonIndependent;
        private System.Windows.Forms.Button btnLocalApply;
        private System.Windows.Forms.Button btnLocalReset;
        private System.Windows.Forms.TextBox tbLocal18;
        private System.Windows.Forms.Label label32;
        private System.Windows.Forms.TextBox tbLocal0;
        private System.Windows.Forms.Label label31;
        private System.Windows.Forms.TextBox tbLocal17;
        private System.Windows.Forms.Label label30;
        private System.Windows.Forms.TextBox tbLocal16;
        private System.Windows.Forms.Label label29;
        private System.Windows.Forms.TextBox tbLocal15;
        private System.Windows.Forms.Label label28;
        private System.Windows.Forms.TextBox tbLocal14;
        private System.Windows.Forms.Label label27;
        private System.Windows.Forms.TextBox tbLocal12;
        private System.Windows.Forms.Label label24;
        private System.Windows.Forms.TextBox tbLocal11;
        private System.Windows.Forms.Label label23;
        private System.Windows.Forms.TextBox tbLocal10;
        private System.Windows.Forms.Label label22;
        private System.Windows.Forms.TextBox tbLocal9;
        private System.Windows.Forms.Label label21;
        private System.Windows.Forms.Label label20;
        private System.Windows.Forms.Label label16;
        private System.Windows.Forms.TextBox tbLocal13;
        private System.Windows.Forms.TextBox tbLocal8;
        private System.Windows.Forms.TextBox tbLocal4;
        private System.Windows.Forms.Label label26;
        private System.Windows.Forms.Label label19;
        private System.Windows.Forms.Label label25;
        private System.Windows.Forms.TextBox tbLocal3;
        private System.Windows.Forms.TextBox tbLocal7;
        private System.Windows.Forms.Label label15;
        private System.Windows.Forms.TextBox tbLocal2;
        private System.Windows.Forms.Label label18;
        private System.Windows.Forms.Label label14;
        private System.Windows.Forms.TextBox tbLocal1;
        private System.Windows.Forms.TextBox tbLocal6;
        private System.Windows.Forms.Label label13;
        private System.Windows.Forms.TextBox tbLocal5;
        private System.Windows.Forms.Label label17;
        private System.Windows.Forms.TabPage tabCMAES;
        private System.Windows.Forms.SplitContainer splitContainer10;
        private System.Windows.Forms.CheckedListBox ckbProblemCMA;
        private System.Windows.Forms.CheckedListBox ckbDimCMA;
        private System.Windows.Forms.Label label34;
        private System.Windows.Forms.Label label33;
        private System.Windows.Forms.SplitContainer splitContainer11;
        private System.Windows.Forms.Label label37;
        private System.Windows.Forms.RadioButton radioButtonCMAwrtMakespan;
        private System.Windows.Forms.RadioButton radioButtonCMAwrtRho;
        private System.Windows.Forms.SplitContainer splitContainer12;
        private System.Windows.Forms.Label label36;
        private System.Windows.Forms.RadioButton radioButtonCMADependent;
        private System.Windows.Forms.RadioButton radioButtonCMAIndependent;
        private System.Windows.Forms.Button startAsyncButtonCMA;
        private System.Windows.Forms.Button cancelAsyncButtonCMA;        
    }
}

