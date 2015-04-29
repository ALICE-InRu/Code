using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;
using Microsoft.VisualBasic.FileIO;

public partial class About : Page
{
    protected void Page_Load(object sender, EventArgs e)
    {

    }

    private bool IsExtended()
    {
        return TrdatExtended.SelectedItem != null;
    }

    protected void CreateLocalTrdat_Click(object sender, EventArgs e)
    {
        if (!TrdatProblems.Items.Cast<ListItem>().Any(x => x.Selected))
            lblCreateLocalTrdat.Text = "... please choose at least one problem distribution.";
        if (!TrdatDims.Items.Cast<ListItem>().Any(x => x.Selected))
            lblCreateLocalTrdat.Text = "... please choose at least one dimension.";
        if (!TrdatTracks.Items.Cast<ListItem>().Any(x => x.Selected))
            lblCreateLocalTrdat.Text = "... please choose at least one trajectory.";

        int numTracks = 0;
        foreach (TrainingSet trSet in from problem in TrdatProblems.Items.Cast<ListItem>().Where(x => x.Selected)
            from dim in TrdatDims.Items.Cast<ListItem>().Where(x => x.Selected)
            from track in TrdatTracks.Items.Cast<ListItem>().Where(x => x.Selected)
            select new TrainingSet(problem.Value, dim.Value, track.Value, IsExtended()))
        {
            for (int pid = trSet.AlreadyAutoSavedPID + 1; pid <= trSet.NumInstances; pid++)
            {
                trSet.CollectTrainingSet(pid);
            }
            lblCreateLocalTrdat.Text = String.Format("{0} trajectories created", ++numTracks);
        }
    }

    protected void CreatePrefSet_Click(object sender, EventArgs e)
    {
        if (!TrdatProblems.Items.Cast<ListItem>().Any(x => x.Selected))
            lblCreatePrefSet.Text = "... please choose at least one problem distribution.";
        if (!TrdatDims.Items.Cast<ListItem>().Any(x => x.Selected))
            lblCreatePrefSet.Text = "... please choose at least one dimension.";
        if (!TrdatTracks.Items.Cast<ListItem>().Any(x => x.Selected))
            lblCreatePrefSet.Text = "... please choose at least one trajectory.";
        if (!TrdatRanks.Items.Cast<ListItem>().Any(x => x.Selected))
            lblCreatePrefSet.Text = "... please choose at least one ranking.";

        int numPrefs = 0;
        foreach (FileInfo trdat in from problem in TrdatProblems.Items.Cast<ListItem>().Where(x => x.Selected)
            from dim in TrdatDims.Items.Cast<ListItem>().Where(x => x.Selected)
            from track in TrdatTracks.Items.Cast<ListItem>().Where(x => x.Selected)
            select new FileInfo(
                String.Format(
                    "C:\\Users\\helga\\Alice\\Code\\trainingData\\trdat.{0}.{1}.{2}{3}.Local.csv",
                    problem.Value, dim.Value, track.Value, IsExtended() ? "EXT" : ""))
            into trdat
            where trdat.Exists
            select trdat)
        {
            foreach (ListItem rank in TrdatRanks.Items.Cast<ListItem>().Where(x => x.Selected))
            {
                FileInfo pref =
                    new FileInfo(String.Format("{0}.diff.{1}.csv",
                        trdat.FullName.Substring(0, trdat.FullName.Length - 4), rank.Value));
                if (!pref.Exists)
                {
                    string text = File.ReadAllText(trdat.FullName);
                    // do something here
                }
                lblCreatePrefSet.Text = String.Format("{0} preference sets", ++numPrefs);
            }
        }
    }

    protected void CreateGlobalTrdat_Click(object sender, EventArgs e)
    {
        if (!TrdatProblems.Items.Cast<ListItem>().Any(x => x.Selected))
            lblCreateGlobalTrdat.Text = "... please choose at least one problem distribution.";
        if (!TrdatDims.Items.Cast<ListItem>().Any(x => x.Selected))
            lblCreateGlobalTrdat.Text = "... please choose at least one dimension.";
        if (!TrdatTracks.Items.Cast<ListItem>().Any(x => x.Selected))
            lblCreateGlobalTrdat.Text = "... please choose at least one trajectory.";

        int numGlobal = 0;
        foreach (FileInfo local in from problem in TrdatProblems.Items.Cast<ListItem>().Where(x => x.Selected)
            from dim in TrdatDims.Items.Cast<ListItem>().Where(x => x.Selected)
            from track in TrdatTracks.Items.Cast<ListItem>().Where(x => x.Selected)
            select new FileInfo(
                String.Format(
                    "C:\\Users\\helga\\Alice\\Code\\trainingData\\trdat.{0}.{1}.{2}.Local.csv",
                    problem.Value, dim.Value, track.Value))
            into local
            where local.Exists
            select local)
        {
            FileInfo global =
                new FileInfo(String.Format("{0}.Global.csv", local.FullName.Substring(0, local.FullName.Length - 10)));
            if (!global.Exists)
            {
                string text = File.ReadAllText(local.FullName);
                // do something here
            }
            lblCreateGlobalTrdat.Text = String.Format("{0} global trajectories created", ++numGlobal);
        }
        if(numGlobal==0)
            lblCreateGlobalTrdat.Text = String.Format("Local features need to be present for retracing.");
    }

    private void ReadTrajectory(FileInfo localTrainingData)
    {
        using (TextFieldParser parser = new TextFieldParser(localTrainingData.FullName))
        {
            parser.TextFieldType = FieldType.Delimited;
            parser.SetDelimiters(",");
            string[] fields = parser.ReadFields();
            if (fields == null) return;
            List<string> header = fields.ToList();
            int iPID = header.FindIndex(x => x == "PID");
            int iStep = header.FindIndex(x => x == "Step");
            int iDispatch = header.FindIndex(x => x == "Dispatch");
            int iFollowed = header.FindIndex(x => x == "Followed");
            int iResultingOptMakespan = header.FindIndex(x => x == "ResultingOptMakespan");

            while (!parser.EndOfData)
            {
                //Processing row
                fields = parser.ReadFields();
                foreach (string field in fields)
                {
                    //TODO: Process field
                }
            }
        }
        
    }


}
