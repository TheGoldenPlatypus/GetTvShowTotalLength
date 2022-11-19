using Newtonsoft.Json.Linq;
using System.Net;
using Newtonsoft.Json;
using ModelClasses;

namespace HWRaven
{
    enum ExitCode : int
    {
        Success = 0,
        GeneralError = 1,
        ShowCannotBeFound = 10,
    }

    internal class Program
    {
        private static async Task<int> Main(string[] args)
        {
            var showName = "";

            if (args.Length < 1)
                return (int)ExitCode.GeneralError;
            else
                showName = args[0];

            // showName = "Grey's Anatomy";

            var baseURL = "https://api.tvmaze.com/";

            Show show;
            try
            {
                using (var client = new HttpClient())
                {
                    EntityWrapper[] showsEntities;
                    var decodedShowName = showName.Replace(" ", "%20");
                    var response0 = await client.GetAsync(baseURL + $"search/shows?q={decodedShowName}");
                    if (response0 != null && response0.IsSuccessStatusCode)
                    {
                        var showsJson = await response0.Content.ReadAsStringAsync();
                        showsEntities = JsonConvert.DeserializeObject<EntityWrapper[]>(showsJson);
                    }
                    else
                    {
                        return (int)ExitCode.ShowCannotBeFound;
                    }

                    if (showsEntities==null)
                    {
                        return (int)ExitCode.ShowCannotBeFound;
                    }

                    var id = GetLastPremieredId(showsEntities);
                    if (id == "")
                    {
                        return (int)ExitCode.ShowCannotBeFound;
                    }
                    // var l = showsEntities.OrderBy(x => x.Show.Premiered)
                    //     .Where(x => x.Show.Name == showName)
                    //     .Select(x => $"{x.Show.Premiered} {x.Show.Id}")
                    //     .ToList<string>();
                    // Console.WriteLine($"Last: {l[l.Count - 1]}, got from function: {id}");

                    var response1 = await client.GetAsync(baseURL + $"shows/{id}?embed=episodes");
                    if (response1 != null && response1.IsSuccessStatusCode)
                    {
                        var showJson = await response1.Content.ReadAsStringAsync();
                        show = JsonConvert.DeserializeObject<Show>(showJson);
                    }
                    else
                    {
                        return (int)ExitCode.ShowCannotBeFound;
                    }
                    if (show == null)
                    {
                        return (int)ExitCode.ShowCannotBeFound;
                    }

                    double res = show.Embedded.Episodes.Sum(item => item.Runtime); // total TvShowTotalLength
                    Console.WriteLine(res);
                }
            }
            catch (Exception)
            {
                return (int)ExitCode.ShowCannotBeFound;
            }

            return (int)ExitCode.Success;
        }

        private static string GetLastPremieredId(EntityWrapper[] showsEntities)
        {
            var maxId = "";
            DateTime maxDate = DateTime.MinValue;
            foreach (var se in showsEntities)
            {
                if (se.Show.Premiered > maxDate)
                {
                    maxDate = se.Show.Premiered;
                    maxId = se.Show.Id;
                }
            }
            return maxId;
        }
    }


}
