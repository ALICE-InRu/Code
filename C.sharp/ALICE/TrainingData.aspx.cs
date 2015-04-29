using System;
using System.IO;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;
using ALICE.App_LocalResources;

namespace ALICE
{
    public partial class TrainingData : Page
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

        protected void CreateGlobalTrdat_Click(object sender, EventArgs e)
        {
            if (!TrdatProblems.Items.Cast<ListItem>().Any(x => x.Selected))
                lblCreateGlobalTrdat.Text = "... please choose at least one problem distribution.";
            if (!TrdatDims.Items.Cast<ListItem>().Any(x => x.Selected))
                lblCreateGlobalTrdat.Text = "... please choose at least one dimension.";
            if (!TrdatTracks.Items.Cast<ListItem>().Any(x => x.Selected))
                lblCreateGlobalTrdat.Text = "... please choose at least one trajectory.";

            int numGlobal = 0;
            foreach (TrainingSet local in from problem in TrdatProblems.Items.Cast<ListItem>().Where(x => x.Selected)
                                          from dim in TrdatDims.Items.Cast<ListItem>().Where(x => x.Selected)
                                          from track in TrdatTracks.Items.Cast<ListItem>().Where(x => x.Selected)
                                          select new TrainingSet(problem.Value, dim.Value, track.Value, IsExtended()))
            {
                if (local.AlreadyAutoSavedPID < local.NumInstances)
                    continue;

                FileInfo global = new FileInfo(String.Format("{0}.Global.csv", local.FileInfo.FullName.Substring(0, local.FileInfo.FullName.Length - 10)));
                if (!global.Exists)
                {
                    string text = File.ReadAllText(local.FileInfo.FullName);
                    // do something here
                }

                for (int pid = 1; pid <= local.NumInstances; pid++)
                {
                    local.Retrace(pid, Features.Mode.Global);
                }

                lblCreateGlobalTrdat.Text = String.Format("{0} global trajectories created", ++numGlobal);
            }

            
            
            
            
            
            
            
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
                lblCreateGlobalTrdat.Text = String.Format("{0} global trajectories created", ++numGlobal);
            }
            if (numGlobal == 0)
                lblCreateGlobalTrdat.Text = String.Format("Local features need to be present for retracing.");

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
    }
}
