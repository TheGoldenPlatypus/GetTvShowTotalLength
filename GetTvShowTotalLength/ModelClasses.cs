using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using Newtonsoft.Json;

namespace ModelClasses
{
    public class Show
    {

        public int Id { get; set; }
        public string Name { get; set; }
        // public Episode[] Episodes { get => _embedded.Episodes; set => _embedded.Episodes = value; }

        [JsonProperty(PropertyName = "_embedded")]
        public EpisodesWrapper Embedded { get; set; }

    }

    public class EpisodesWrapper
    {
        public Episode[] Episodes;
    }

    public class ShowPremieredCheckEntity
    {
        public string Id { get; set; }
        public string Name { get; set; }

        [JsonProperty("property_name", NullValueHandling = NullValueHandling.Ignore)]
        public DateTime Premiered { get; set; } = DateTime.MinValue + TimeSpan.FromDays(1);
    }

    public class EntityWrapper
    {
        public ShowPremieredCheckEntity Show { get; set; }
    }

    public class Episode
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public int Runtime { get; set; }

        public override string ToString()
        {
            return Id + "," + Name + "," + Runtime;
        }
    }

}