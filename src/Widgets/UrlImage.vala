
public class Tuner.UrlImage : Gtk.Image {
    public string default_icon { get; set; }

    private string _cache_file;
    private string _url;


    public UrlImage (string default_icon, string? cache_id = null) {
        Object (
            icon_name: default_icon,
            icon_size: Gtk.IconSize.DIALOG
        );
        this.default_icon = default_icon;

        if(cache_id != null)
            _cache_file = Path.build_filename (Application.instance.cache_dir, cache_id);
    }
    
    public string url {
        set {
            if(value == "") return;
            
            _url = value;

            if(!read_from_cache())
                load_from_url();
        }
        get {
            return _url;
        }
    }

    
    private void load_from_url () {
        // Set default icon first, in case loading takes long or fails
        set_from_icon_name (default_icon, Gtk.IconSize.DIALOG);

        if (url.length == 0) {
            return;
        }
    
        var session = new Soup.Session ();
        var message = new Soup.Message ("GET", url);
        
        session.queue_message (message, (sess, mess) => {
            if (mess.status_code != 200) {
                warning (@"Unexpected status code: $(mess.status_code), will not render $(url)");
                return;
            }
    
            var data_stream = new MemoryInputStream.from_data (mess.response_body.data);
        
            if(set_favicon_from_stream(data_stream)) {
                write_to_cache();
            }
        });
    }     

    private bool set_favicon_from_stream (InputStream stream) {
        Gdk.Pixbuf pxbuf;

        try {
            pxbuf = new Gdk.Pixbuf.from_stream_at_scale (stream, 48, 48, true, null);
            set_from_pixbuf (pxbuf);
            set_size_request (48, 48);
            return true;
        } catch (Error e) {
            warning (@"Unable to convert data to image: %s", e.message);
            //debug ("Couldn't render favicon: %s (%s)",
            //    station.favicon_url ?? "unknown url",
            //    e.message);
        }
        return false;
    }

    private bool read_from_cache () {
        if(_cache_file == null)
            return false;

        if (FileUtils.test (_cache_file, FileTest.EXISTS | FileTest.IS_REGULAR)) {
            var file = File.new_for_path (_cache_file);
            try {
                var favicon_stream = file.read ();
                if (!set_favicon_from_stream (favicon_stream)) {
                    warning (@"unable to read local favicon: %s", _cache_file);
                };
                favicon_stream.close ();
                return true;
            } catch (Error e) {
                warning (@"unable to read local favicon: %s %s", _cache_file, e.message);
            }
        }
        return false;
    }

    private void write_to_cache () {     
        if(_cache_file == null)
            return;
        
        var file = File.new_for_path (_cache_file);
        try {
            var stream = file.create_readwrite (FileCreateFlags.PRIVATE);
            pixbuf.save_to_stream (stream.output_stream, "png", null);
            stream.close ();
        } catch (Error e) {
            // File already created by another stationbox
            // TODO: possible race condition
            // TODO: Create stationboxes as singletons?
        }
    }


    
}