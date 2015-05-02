using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

namespace ALICE
{
    class CSV
    {
        public static List<string[]> Read(FileInfo fileInfo, out List<string> header)
        {
            if (!fileInfo.Exists)
            {
                header = null;
                return null;
            }
            var content = new List<string[]>();

            var fs = new FileStream(fileInfo.FullName, FileMode.Open, FileAccess.Read);
            using (var st = new StreamReader(fs))
            {
                while (st.Peek() != -1) // stops when it reachs the end of the file
                {
                    var line = st.ReadLine();
                    if (line == null) continue;
                    var row = Regex.Split(line, ",");
                    content.Add(row);
                }
                st.Close();
            }
            fs.Close();

            header = content[0].ToList();
            content.RemoveAt(0);
            return content;
        }
    }
}
