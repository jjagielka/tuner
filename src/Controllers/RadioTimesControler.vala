

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

    public StationSource2 load_search_stations (owned string utext, uint limit) {
        stdout.printf(@"load_search_stations: $utext\n");
        var params = RadioTimes.SearchParams() {
            query    = utext
        };
        var source = new StationSource2(limit, params, provider, store, null); 
        // var rsp = source.next();
        // stdout.printf(@"load_search_stations: $(rsp.size)\n");
        return source;
    } 

    public StationSource2 load_by_url (owned string url, uint limit) {
        Soup.URI uri = new Soup.URI (url);
        return new StationSource2(limit, null, provider, store, @"$(uri.get_path())?$(uri.get_query())".substring(1)); 
    }

    public ArrayList<RadioTimes.Link> categories () {
        try {
            return provider.get_links("Browse.ashx?render=json");
        } catch (RadioTimes.DataError e) {
            critical (@"RadioTimes unavailable");
            return new ArrayList<RadioTimes.Link>();
        }
    }

}

public class Tuner.StationSource2 : Object {
    private uint _offset = 0;
    private uint _page_size = 20;
    private bool _more = true;
    private string? _url = null;

    private RadioTimes.SearchParams? _params;
    private RadioTimes.Client _client;
    private Model.StationStore _store;

    public StationSource2 (uint limit, 
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

    private ArrayList<RadioTimes.Station> get_stations ()  throws RadioTimes.DataError {
        if(_url == null)
            return _client.search (_params, _page_size + 1, _offset);
        else
            return _client.get_ (_url).stations;
    }

    public ArrayList<Model.Station>? next () throws SourceError {
        stdout.printf(@"NEXT $_url\n");

        // Fetch one more to determine if source has more items than page size 
        try {
            // var raw_stations = get_stations ();
            var links = _client.get_ (_url).links;
            var stations = convert_links (links.iterator ());
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

    private ArrayList<Model.Station> convert_links (Iterator<RadioTimes.Link> raw_links) {
        var stations = new ArrayList<Model.Station> ();
        while (raw_links.next()) {
            var link = raw_links.get ();
            var s = new Model.Station ("0", link.text, "", link.URL);
            s.favicon_url = "";
            s.clickcount = 0;
            s.homepage = "homepage";
            s.codec = "category";
            s.bitrate = 0;
            stations.add (s);
        }
        return stations;
    }

    private ArrayList<Model.Station> convert_stations (Iterator<RadioTimes.Station> raw_stations) {
        var stations = new ArrayList<Model.Station> ();

        while (raw_stations.next()) {
        // foreach (var station in raw_stations) {
            var station = raw_stations.get ();
            var s = new Model.Station (
                station.stationuuid,
                station.name,
                Model.Countries.get_by_code(station.countrycode, station.country),
                station.url_resolved);
            if (_store.contains (s)) {
                s.starred = true;
            }

            stdout.printf(@"RAW $(station.stationuuid), $(station.name), $(Model.Countries.get_by_code(station.countrycode, station.country)), $(station.bitrate)\n");
            s.favicon_url = station.favicon;
            s.clickcount = station.clickcount;
            s.homepage = station.homepage;
            s.codec = station.codec;
            s.bitrate = station.bitrate;

            s.notify["starred"].connect ( (sender, property) => {
                if (s.starred) {
                    _store.add (s);
                } else {
                    _store.remove (s);
                }
            });
            stations.add (s);
        }
        return stations;
    }
}