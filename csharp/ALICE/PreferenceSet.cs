using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace ALICE
{
    /// <summary>
    /// Preference set from RawData
    /// </summary>
    public class PreferenceSet : TrainingSet
    {
        public int NumPreferences;

        private readonly List<PrefSet>[,] _diffData;
        private readonly Func<List<TrSet>, int, int, int> _rankingFunction;
        private readonly Ranking _ranking; 

        public enum Ranking
        {
            FullPareto = 'f',
            PartialPareto = 'p',
            Basic = 'b',
            All = 'a'
        };

        public class PrefSet
        {
            public Features Feature;
            public int ResultingOptMakespan;
            public int Rank;
            public bool Followed;
        }

        public PreferenceSet(string problem, string dim, string track, bool extended, char rank)
            : base(problem, dim, track, extended)
        {
            FileInfo =
                new FileInfo(string.Format(
                    "C://Users//helga//Alice//Code//trainingData//trdat.{0}.{1}.{2}.Local.diff.{3}.csv",
                    Distribution, Dimension, StrTrack, rank));

            Columns.Add("Rank", typeof(int));

            _ranking = (Ranking)rank;
            switch (_ranking)
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
                //case Ranking.PartialPareto:
                default:
                    _rankingFunction = PartialParetoRanking;
                    break;
            }

            _diffData = new List<PrefSet>[NumInstances, NumDimension];
        }

        public string CreatePreferencePairs(int pid)
        {
            int currentNumPreferences = 0;
            RankPreferences(pid);
            for (var step = 0; step < NumDimension; step++)
            {
                var prefs = TrData[pid, step].ToList().OrderBy(p => p.Rank).ToList();
                currentNumPreferences += _rankingFunction(prefs, pid, step);
            }
            NumPreferences += currentNumPreferences;
            return String.Format("{0}.{1}.{2} {3}.{4} #{5}", Distribution, Dimension, pid, StrTrack, _ranking,
                currentNumPreferences);
        }

        private int BasicRanking(List<TrSet> prefs, int pid, int step)
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
                    _diffData[pid, step].Add(prefs[opt].Difference(prefs[sub]));
                    _diffData[pid, step].Add(prefs[sub].Difference(prefs[opt]));
                }
            }
            return _diffData[pid, step].Count;
        }

        private int FullParetoRanking(List<TrSet> prefs, int pid, int step)
        {
            _diffData[pid, step].AddRange(from pi in prefs
                from pj in prefs
                where /* subsequent ranking */ Math.Abs(pi.Rank - pj.Rank) == 1
                select pi.Difference(pj));
            return _diffData[pid, step].Count;
        }

        private int PartialParetoRanking(List<TrSet> prefs, int pid, int step)
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
                            _diffData[pid, step].Add(ijDiff);

                            var jiDiff = prefs[j].Difference(prefs[i]);
                            _diffData[pid, step].Add(jiDiff);

                            inTrainingSet[i] = true;
                            inTrainingSet[j] = true;
                        }
            return _diffData[pid, step].Count;
        }

        private int AllRankings(List<TrSet> prefs, int pid, int step)
        {
            _diffData[pid, step].AddRange(from pi in prefs
                from pj in prefs
                where /* full ranking */ pi.Rank != pj.Rank
                select pi.Difference(pj));
            return _diffData[pid, step].Count;
        }

        private void RankPreferences(int pid)
        {
            for (var step = 0; step < NumDimension; step++)
            {
                var prefs = TrData[pid, step];
                var cmax = prefs.Select(p => p.ResultingOptMakespan).Distinct().OrderBy(x => x).ToList();
                foreach (var pref in prefs)
                {
                    var rank = cmax.FindIndex(ms => ms == pref.ResultingOptMakespan);
                    pref.Rank = rank;
                }
            }
        }

    }
}