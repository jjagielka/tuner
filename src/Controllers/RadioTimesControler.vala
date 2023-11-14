
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
        var source = new StationSource2(limit, params, provider, store); 
        var rsp = source.next();
        stdout.printf(@"load_search_stations: $(rsp.size)\n");
        return source;
    }
}

public class Tuner.StationSource2 : Object {
    private uint _offset = 0;
    private uint _page_size = 20;
    private bool _more = true;
    private RadioTimes.SearchParams _params;
    private RadioTimes.Client _client;
    private Model.StationStore _store;

    public StationSource2 (uint limit, 
                          RadioTimes.SearchParams params, 
                          RadioTimes.Client client,
                          Model.StationStore store) {
        Object ();
        // This disables paging for now
        _page_size = limit;
        _params = params;
        _client = client;
        _store = store;
    }

    public ArrayList<Model.Station>? next () throws SourceError {
        // Fetch one more to determine if source has more items than page size 
        try {
            var raw_stations = _client.search (_params, _page_size + 1, _offset);
            // TODO Place filter here?
            //var filtered_stations = raw_stations.filter (filterByCountry);
            var filtered_stations = raw_stations.iterator ();

            var stations = convert_stations (filtered_stations);
            _offset += _page_size;
            _more = stations.size > _page_size;
            if (_more) stations.remove_at( (int)_page_size);
            return stations;    
        } catch (RadioTimes.DataError e) {
            throw new SourceError.UNAVAILABLE("Directory Error");
        }
    }

    public bool has_more () {
        return _more;
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