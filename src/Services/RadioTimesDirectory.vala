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

public abstract class Element : Object {
    public string element { get; set; }  // "outline",
    //  public string type { get; set; }  // "link",
    public string text { get; set; }  // "Lokalne Radio",
    public abstract Model.Item to_model();
}

public class Group : Element {
    public string key { get; set; }  // "local"
    //  public Json.Array children { get; set; }
    public ArrayList<Element> children;

    public string to_string () {
        return @"Group: $text: $key";
    }

    public override Model.Item to_model () {
        var item = new Model.Item();
        item.title = text;
        item.url = "";
        item.id = "guide_id";
        item.homepage = "";
        item.favicon_url = "";

        if(children != null) {
            var l = new ArrayList<Model.Item>();
            children.foreach((x) => l.add(x.to_model()));
            item.children = l;
        }

        return item;
    }
}

public class Link : Element {
    public string key { get; set; }  // "local"
    public string URL { get; set; }  // "http://opml.radiotime.com/Browse.ashx?c=local",
    public string? guide_id { get; set; }  // "s159857",

    public string to_string () {
        return @"Link: $text: $URL";
    }

    public override Model.Item to_model () {
        var item = new Model.Item();
        item.title = text;
        item.url = URL;
        item.id = guide_id;
        item.homepage = "";
        item.favicon_url = "";

        return item;
    }
}

public class Station : Element {
    public string bitrate { get; set; }  // "256",
    public string reliability { get; set; }  // "99",
    public string subtext { get; set; }  // "Tearjerker - You Can",
    public string genre_id { get; set; }  // "g2748",
    public string formats { get; set; }  // "mp3",
    public string playing { get; set; }  // "Tearjerker - You Can",
    public string playing_image { get; set; }  // "http://cdn-albums.tunein.com/gn/Q5R53HC7QVq.jpg",
    public string item { get; set; }  // "station",
    public string image { get; set; }  // "http://cdn-profiles.tunein.com/s159857/images/logoq.jpg",
    public string now_playing_id { get; set; }  // "s159857",
    public string preset_id { get; set; }  // "s159857"
    public string URL { get; set; }  // "http://opml.radiotime.com/Browse.ashx?c=local",
    public string guide_id { get; set; }  // "s159857",

    Regex re = /\s\((.*)\)$/;

    public override Model.Item to_model() {
        var station = new Model.RTStation(preset_id, re.replace(text, text.length, 0, ""), "FR", URL);
        station.homepage = "";
        station.codec = formats;
        station.bitrate = int.parse(bitrate);
        MatchInfo info;
        if (re.match(text, 0, out info)) {
            station.location = info.fetch(1);
        }
        station.favicon_url = image;

        station.clickcount = 0;
        station.resolve = resolve;

        station.now_playing_url = playing_image;
        return station as Model.Item;
    }

    private string resolve(string url) {
        var session = new Soup.Session ();
        var message = new Soup.Message ("GET", url);
        var response_code = session.send_message(message);
        if(response_code == 200) {
            var body = (string) message.response_body.data;
            return body.split("\n")[0];
        }
        debug (@"response: $(response_code)");
        return "";
    }
}

public class Description : Object {
    public string current_artist_art { get; set; }
    public string current_album_art { get; set; }
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

        var message = new Soup.Message ("GET", @"$current_server/$resource&filter=s&render=json");
        Json.Node rootnode;

        var response_code = _session.send_message (message);
        debug (@"response from radio-time.com: $response_code");

        var body = (string) message.response_body.data;
        //  stdout.printf(body);

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


    public string get_album_image(string station_id) {
        // gn/T5N4K2CK39
        var resource = @"Describe.ashx?id=$station_id";

        var response = get_resource(resource);
        var result = "";
        response.body.foreach_element ((array, index, element) => {
            Description? obj = Json.gobject_deserialize (typeof (Description), element) as Description;
            if (obj != null && obj.current_album_art != null)
                result = @"http://cdn-albums.tunein.com/$(obj.current_album_art)q.jpg";
        });

        return result;
    }

    private Element? deserialize(Json.Node element) {

        var _type = element.get_object().get_member("type");
        if (_type != null) {
            switch (_type.get_string())
            {
                case "link":
                    return Json.gobject_deserialize (typeof (Link), element) as Element;
                case "audio":
                    return Json.gobject_deserialize (typeof (Station), element) as Element;
                default:
                    return null;
            };
        }

        // not 'type' means Group
        var group = Json.gobject_deserialize (typeof (Group), element) as Group;
        var children = element.get_object().get_member("children").get_array();
        if(children == null) 
            return null;

        group.children = new ArrayList<Element>();

        children.foreach_element ((array, index, element) => {
            var e = deserialize(element);
            group.children.add(e);
        });

        return group as Element;
    }

    public ArrayList<Model.Item> get_stations (string resource) throws DataError {
        ArrayList<Model.Item> result = new ArrayList<Model.Item>();
        var response = get_resource(resource);

        response.body.foreach_element ((array, index, element) => {
            Element? obj = deserialize(element);
            if (obj != null) result.add (obj.to_model());
        });

        return result;
    }

    public ArrayList<Model.Item> search (SearchParams params,
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
        var resource = @"Search.ashx?render=json&filter=s";
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
