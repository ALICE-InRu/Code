using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace ALICE
{
    /// <summary>
    /// Preference set from RawData
    /// </summary>
    public class PreferenceSet : RetraceSet
    {
        public int NumPreferences;

        private readonly List<Preference>[,] _diffData;
        private readonly Func<List<Preference>, int, int, int> _rankingFunction;

        public enum Ranking
        {
            FullPareto = 'f',
            PartialPareto = 'p',
            Basic = 'b',
            All = 'a'
        };

        public PreferenceSet(string distribution, string dimension, Trajectory track, int iter, bool extended,
            Ranking rank, DirectoryInfo data)
            : base(distribution, dimension, track, iter, extended, Features.Mode.Local, data)
        {
            FileInfo =
                new FileInfo(string.Format(
                    @"{0}\Training\{1}.diff.{2}.csv", data.FullName,
                    FileInfo.Name.Substring(0, FileInfo.Name.Length - FileInfo.Extension.Length), (char) rank));

            Data.Columns.Add("Rank", typeof (int));

            var ranking = rank;
            switch (ranking)
            {
                case Ranking.All:
                    _rankingFunction = AllRankings;
                    break;
                case Ranking.Basic:
                    _rankingFunction = BasicRanking;
                    break;
                case Ranking.FullPareto:
                    _rankingFunction = FullParetoRanking;
                    break;
                case Ranking.PartialPareto:
                    _rankingFunction = PartialParetoRanking;
                    break;
            }

            ApplyAll(Retrace, null);
            _diffData = new List<Preference>[NumInstances, NumDimension];
            for (int pid = 1; pid <= AlreadySavedPID; pid++)
                for (int step = 0; step < NumDimension; step++)
                    _diffData[pid - 1, step] = new List<Preference>();
        }

        public new void Write()
        {
            if (NumApplied == AlreadySavedPID)
                Write(FileMode.Create, _diffData);
        }

        public new void Apply()
        {
            ApplyAll(Apply, _diffData);
        }

        public new string Apply(int pid)
        {
            NumApplied++;
            return CreatePreferencePairs(pid);
        }

        internal string CreatePreferencePairs(int pid)
        {
            int currentNumPreferences = 0;
            for (var step = 0; step < NumDimension; step++)
            {
                var prefs = Preferences[pid - 1, step].ToList().OrderBy(p => p.Rank).ToList();
                currentNumPreferences += _rankingFunction(prefs, pid, step);
            }
            NumPreferences += currentNumPreferences;
            return String.Format("{0}:{1} #{2} pref", FileInfo.Name, pid, currentNumPreferences);
        }

        private int BasicRanking(List<Preference> prefs, int pid, int step)
        {
            for (var opt = 0; opt < prefs.Count; opt++)
            {
                if (prefs[opt].Rank > 0)
                {
                    break;
                }

                for (var sub = opt + 1; sub < prefs.Count; sub++)
                {
                    if (prefs[opt].Rank == prefs[sub].Rank) continue;
                    _diffData[pid - 1, step].Add(prefs[opt].Difference(prefs[sub]));
                    _diffData[pid - 1, step].Add(prefs[sub].Difference(prefs[opt]));
                }
            }
            return _diffData[pid - 1, step].Count;
        }

        private int FullParetoRanking(List<Preference> prefs, int pid, int step)
        {
            _diffData[pid - 1, step].AddRange(from pi in prefs
                from pj in prefs
                where /* subsequent ranking */ Math.Abs(pi.Rank - pj.Rank) == 1
                select pi.Difference(pj));
            return _diffData[pid - 1, step].Count;
        }

        private int PartialParetoRanking(List<Preference> prefs, int pid, int step)
        {
            // subsequent ranking
            // partial, yet sufficient, pareto ranking
            var inTrainingSet = new bool[prefs.Count];
            for (var i = 0; i < prefs.Count; i++)
                for (var j = 0; j < prefs.Count; j++)
                    if (Math.Abs(prefs[i].Rank - prefs[j].Rank) == 1) // subsequent ranking
                        // partial, yet sufficient, pareto ranking
                        if (!inTrainingSet[i] | !inTrainingSet[j])
                        {
                            var ijDiff = prefs[i].Difference(prefs[j]);
                            _diffData[pid - 1, step].Add(ijDiff);

                            var jiDiff = prefs[j].Difference(prefs[i]);
                            _diffData[pid - 1, step].Add(jiDiff);

                            inTrainingSet[i] = true;
                            inTrainingSet[j] = true;
                        }
            return _diffData[pid - 1, step].Count;
        }

        private int AllRankings(List<Preference> prefs, int pid, int step)
        {
            _diffData[pid - 1, step].AddRange(from pi in prefs
                from pj in prefs
                where /* full ranking */ pi.Rank != pj.Rank
                select pi.Difference(pj));
            return _diffData[pid - 1, step].Count;
        }
    }
}