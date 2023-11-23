

using Gee;


public class Tuner.RadioTimesController : Object {
    public RadioTimes.Client? provider { get; set; }
    public Model.StationStore store { get; set; }

    public RadioTimesController (Model.StationStore store) {
        try {
            var client = new RadioTimes.Client ();
            this.provider = client;
        } catch (RadioTimes.DataError e) {
            critical (@"RadioTimes unavailable");
        }

        this.store = store;

        // migrate from <= 1.2.3 settings to json based store
        //  this.migrate_favourites ();
    }

    public RTStationSource load_search_stations (owned string utext, uint limit) {
        stdout.printf(@"load_search_stations: $utext\n");
        var params = RadioTimes.SearchParams() {
            query    = utext
        };
        var source = new RTStationSource(limit, params, provider, store, null); 
        // var rsp = source.next();
        // stdout.printf(@"load_search_stations: $(rsp.size)\n");
        return source;
    }

    public RTStationSource load_by_url (owned string url, uint limit) {
        Soup.URI uri = new Soup.URI (url);
        return new RTStationSource(limit, null, provider, store, @"$(uri.get_path())?$(uri.get_query())".substring(1)); 
    }

    public ArrayList<Model.Item> categories () {
        try {
            return provider.get_stations("Browse.ashx?filter=s");
        } catch (RadioTimes.DataError e) {
            critical (@"RadioTimes unavailable");
            return new ArrayList<Model.Item>();
        }
    }

    public string get_album_image(string id) {
        return provider.get_album_image (id);
    }
}

public class Tuner.RTStationSource : Object {
    private uint _offset = 0;
    private uint _page_size = 20;
    private bool _more = true;
    private string? _url = null;

    private RadioTimes.SearchParams? _params;
    private RadioTimes.Client _client;
    private Model.StationStore _store;

    public RTStationSource (uint limit, 
                          RadioTimes.SearchParams? params, 
                          RadioTimes.Client client,
                          Model.StationStore store,
                          string? url) {
        Object ();
        // This disables paging for now
        _page_size = limit;
        _params = params;
        _client = client;
        _store = store;
        _url = url;
    }

    private bool make_starred(Model.Item i) {
        if(i is Model.RTStation) {
            var s = i as Model.RTStation;

            if (_store.contains (s)) {
                s.starred = true;
            }

            s.notify["starred"].connect ( (sender, property) => {
                if (s.starred) {
                    _store.add (s);
                } else {
                    _store.remove (s);
                }
            });
            return true;
        }
        return false;
    }

    public ArrayList<Model.Item>? next () throws SourceError {
        // Fetch one more to determine if source has more items than page size 
        try {
            var stations = _client.get_stations (_url);
            stations.foreach((i)=> {
                if(i is Model.RTStation) {
                    return make_starred(i);
                } 
                if(i.children != null) 
                    return i.children.foreach((i)=> make_starred(i) );
                return false;
            });
            
            return stations;
            
            // var filtered_stations = raw_stations.iterator ();
            // var stations = convert_stations (filtered_stations);
            // _offset += _page_size;
            // _more = stations.size > _page_size;
            // if (_more) stations.remove_at( (int)_page_size);

            // stdout.printf(@"NEXT $(stations.size)\n");
            // return stations;
        } catch (RadioTimes.DataError e) {
            stdout.printf(@"ERROR $(e.message)\n");
            throw new SourceError.UNAVAILABLE("Directory Error");
        }
    }

    public bool has_more () {
        return _more;
    }
}