
public class Tuner.UrlImage : Gtk.Image {
    public string default_icon_name { get; set; }
    public Gtk.IconSize default_icon_size { get; set; }

    public bool keep_size { get; set; }

    private string _cache_file;


    public UrlImage (string default_icon_name, Gtk.IconSize default_icon_size,  string? cache_id = null) {
        Object (
            icon_name: default_icon_name,
            icon_size: Gtk.IconSize.DIALOG
        );
        this.default_icon_name = default_icon_name;
        this.default_icon_size = default_icon_size;

        this.keep_size = true;

        if(cache_id != null)
            _cache_file = Path.build_filename (Application.instance.cache_dir, cache_id);
    }

    public void set_from_url (string url) {
        // Set default icon first, in case loading takes long or fails
        set_from_icon_name (default_icon_name, default_icon_size);

        if (read_from_cache()) {
            return;
        }

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

            if(set_from_stream(data_stream)) {
                write_to_cache();
            }
        });
    }

    public void set_from_url_cachable (string url, string cache_id) {
        if (read_from_cache()) {
            return;
        }
    }

    private bool set_from_stream (InputStream stream) {
        Gdk.Pixbuf pxbuf;

        try {
            if(keep_size) {
                int width, height;
                if(!Gtk.IconSize.lookup(default_icon_size, out width, out height))
                    width = height = 48;  // Gtk.IconSize.DIALOG

                pxbuf = new Gdk.Pixbuf.from_stream_at_scale (stream, width, height, true);
                set_size_request (width, height);
            } else {
                pxbuf = new Gdk.Pixbuf.from_stream (stream);
            }
            set_from_pixbuf (pxbuf);
            return true;
        } catch (Error e) {
            warning (@"Unable to convert data to image: %s", e.message);
        }
        return false;
    }

    private bool read_from_cache () {
        if(_cache_file == null)
            return false;

        if (FileUtils.test (_cache_file, FileTest.EXISTS | FileTest.IS_REGULAR)) {
            var file = File.new_for_path (_cache_file);
            try {
                var stream = file.read ();
                if (!set_from_stream (stream)) {
                    warning (@"unable to read local favicon: %s", _cache_file);
                };
                stream.close ();
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