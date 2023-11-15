/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 Jakub Jagielka <jjagielka@gmail.com>
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

public class Station : Object {
    public string stationuuid { get; set; }
    public string name { get; set; }
    public string url_resolved { get; set; }
    public string country { get; set; }
    public string countrycode { get; set; }
    public string favicon { get; set; }
    public uint clickcount { get; set; }
    public string homepage { get; set; }
    public string codec { get; set; }
    public int bitrate { get; set; }
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

    public ArrayList<Station> get_stations (string resource) throws DataError {
        debug (@"RB $resource");

        var message = new Soup.Message ("GET", @"$current_server/$resource");
        Json.Node rootnode;

        var response_code = _session.send_message (message);
        debug (@"response from radio-browser.info: $response_code");

        var body = (string) message.response_body.data;
        if (body == null) {
            throw new DataError.NO_CONNECTION (@"unable to read response");
        }
        try {
            rootnode = Json.from_string (body);
        } catch (Error e) {
            throw new DataError.PARSE_DATA (@"unable to parse JSON response: $(e.message)");
        }
        var rootarray = rootnode.get_root()["body"].get_array ();

        stdout.printf (@"$rootarray\n");
        return new ArrayList<Station>();

        var stations = jarray_to_stations (rootarray);
        return stations;
    }

    private Station jnode_to_station (Json.Node node) {
        return Json.gobject_deserialize (typeof (Station), node) as Station;
    }

    private ArrayList<Station> jarray_to_stations (Json.Array data) {
        var stations = new ArrayList<Station> ();

        data.foreach_element ((array, index, element) => {
            Station s = jnode_to_station (element);
            stations.add (s);
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
        var resource = @"Search.ashx?render=json";
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
