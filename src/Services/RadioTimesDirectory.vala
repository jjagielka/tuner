/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 Jakub Jagielka <jjagielka@gmail.com>
 */

 /*
Found docs:

http://0john.blogspot.com/2011/06/opml-inside-radiotime.html

*/

using Gee;

namespace Tuner.RadioTimes {

public errordomain DataError {
    PARSE_DATA,
    NO_CONNECTION
}

public struct SearchParams {
    string query;
}



public class StationRaw : Object {
    public string element { get; set; }  // "outline",
    //  [JsonProperty("@type")]
    //  public string type { get; set; }  // "audio",
    public string text { get; set; }  // "NME 1",
    public string URL { get; set; }  // "http://opml.radiotime.com/Tune.ashx?id=s159857",
    public string bitrate { get; set; }  // "256",
    public string reliability { get; set; }  // "99",
    public string guide_id { get; set; }  // "s159857",
    public string subtext { get; set; }  // "Tearjerker - You Can",
    public string genre_id { get; set; }  // "g2748",
    public string formats { get; set; }  // "mp3",
    public string playing { get; set; }  // "Tearjerker - You Can",
    public string playing_image { get; set; }  // "http://cdn-albums.tunein.com/gn/Q5R53HC7QVq.jpg",
    public string item { get; set; }  // "station",
    public string image { get; set; }  // "http://cdn-profiles.tunein.com/s159857/images/logoq.jpg",
    public string now_playing_id { get; set; }  // "s159857",
    public string preset_id { get; set; }  // "s159857"    
}

// JSON STUCTURES
private class ResponseHead : Object {
    public string title { get; set; }
    public string status { get; set; }
}

private class Response : Object {
    public ResponseHead head { get; set; }
    public Json.Array body { get; set; }

    public string to_string () {
        return @"$(head.status): $(head.title) - $(body.get_length())";
    }
}

public class Link : Object {
    public string element { get; set; }  // "outline",
    //  public string type { get; set; }  // "link",
    public string text { get; set; }  // "Lokalne Radio",
    public string URL { get; set; }  // "http://opml.radiotime.com/Browse.ashx?c=local",
    public string key { get; set; }  // "local"

    public string to_string () {
        return @"Link: $text: $URL";
    }    
}

public class Station : Object {
    private StationRaw station { get; set; }

    public Station(StationRaw station) {
        this.station = station;
    }

    public string stationuuid {
        get {
            if(station.preset_id == null)
                stdout.printf(@"$(station.text)\n");
            return station.preset_id;
        }
    }
    public string name {
        get {
            return station.text;
        }
    }

    public string countrycode {
        get {
            return "FR";  // sure to change it
        }
    }

    public string country {
        get {
            return "France";  // sure to change it
        }
    }
    public string url_resolved {
        get {
            return station.URL;  
        }
    }
    public string favicon {
        get {
            return station.image;  
        }
    }
    public uint clickcount {
        get {
            return 23;  // sure to change it
        }
    }
    public string homepage {
        get {
            return station.URL;  
        }
    }
    public int bitrate {
        get {
            //  return 128000;  // sure to change it
            return int.parse( station.bitrate );  
        }
    }
    public string codec {
        get {
            return "aac";  // sure to change it
        }
    }

}

private const string[] DEFAULT_BOOTSTRAP_SERVERS = {
    "opml.radiotime.com"
};

public bool EqualCompareString (string a, string b) {
    return a == b;
}

public int RandomSortFunc (string a, string b) {
    return Random.int_range (-1, 1);
}

public class Client : Object {
    private string current_server;
    private string USER_AGENT = @"$(Application.APP_ID)/$(Application.APP_VERSION)";
    private Soup.Session _session;
    private ArrayList<string> randomized_servers;

    public Client() throws DataError {
        Object();
        _session = new Soup.Session ();
        _session.user_agent = USER_AGENT;
        _session.timeout = 3;


        string[] servers;
        string _servers = GLib.Environment.get_variable ("TUNER_API");
        if ( _servers != null ){
            servers = _servers.split(":");
        } else {
            servers = DEFAULT_BOOTSTRAP_SERVERS;
        }

        randomized_servers = new ArrayList<string>.wrap (servers, EqualCompareString);
        randomized_servers.sort (RandomSortFunc);

        current_server = @"https://$(randomized_servers[0])";
        debug (@"Chosen radio-browser.info server: $current_server");
        // TODO: Implement server rotation on error    
    }

    private Response get_resource (string resource) throws DataError {
        debug (@"RB $resource");
        stdout.printf (@"RB $resource");
        
        var message = new Soup.Message ("GET", @"$current_server/$resource&render=json");
        Json.Node rootnode;

        var response_code = _session.send_message (message);
        debug (@"response from radio-time.com: $response_code");

        var body = (string) message.response_body.data;
        stdout.printf(body);

        if (body == null) {
            throw new DataError.NO_CONNECTION (@"unable to read response");
        }
        try {
            rootnode = Json.from_string (body);
        } catch (Error e) {
            throw new DataError.PARSE_DATA (@"unable to parse JSON response: $(e.message)");
        }
        var node = rootnode.get_object();

        return new Response() {
            head = Json.gobject_deserialize (typeof (ResponseHead), node.get_member("head")) as ResponseHead,
            body = node.get_member("body").get_array ()
        };
    }

    public ArrayList<Link> get_links (string resource) throws DataError {
        var response = get_resource(resource);
        var links = new ArrayList<Link> ();

        response.body.foreach_element ((array, index, element) => {
            //if(element.get_object().get_member("type").get_string() == "link") {}
            links.add (Json.gobject_deserialize (typeof (Link), element) as Link);
        });
        return links;    
    }

    public ArrayList<Station> get_stations (string resource) throws DataError {
        var response = get_resource(resource);
        var stations = new ArrayList<Station> ();
        response.body.foreach_element ((array, index, element) => {
            //  if(element.get_object().get_member("type").get_string() == "audio") {}
            StationRaw s = Json.gobject_deserialize (typeof (StationRaw), element) as StationRaw;
            stations.add (new Station(s));
        });
        return stations;
    }

    public ArrayList<Station> search (SearchParams params,
                                    uint rowcount,
                                    uint offset = 0) throws DataError {
        // by uuids
        //  if (params.uuids != null) {
        //      var stations = new ArrayList<Station> ();
        //      foreach (var uuid in params.uuids) {
        //          var station = this.by_uuid(uuid);
        //          if (station != null) {
        //              stations.add (station);
        //          }
        //      }
        //      return stations;
        //  }


        // by text or tags
        //  var resource = @"json/stations/search?limit=$rowcount&order=$(params.order)&offset=$offset";
        var resource = @"Search.ashx?render=json&filter=c";
        if (params.query != null && params.query != "") { 
            resource += @"&query=$(params.query)";
        }
        //  if (params.tags == null) {
        //      warning ("param tags is null");
        //  }
        //  if (params.tags.size > 0 ) {
        //      string tag_list = params.tags[0];
        //      if (params.tags.size > 1) {
        //          tag_list = string.joinv (",", params.tags.to_array());
        //      }
        //      resource += @"&tagList=$tag_list&tagExact=true";
        //  }
        //  if (params.countrycode.length > 0) {
        //      resource += @"&countrycode=$(params.countrycode)";
        //  }
        //  if (params.order != SortOrder.RANDOM) {
        //      // random and reverse doesn't make sense
        //      resource += @"&reverse=$(params.reverse)";
        //  }
        return get_stations (resource);
    }
}

}
