delegate string StringToString(string a);

StringToString TagListGetter (Gst.TagList tagList) {
    return (tag) => {
        var type = Gst.Tags.get_type(tag);
        switch(type) {
            case GLib.Type.STRING:
                string val = "";
                tagList.get_string(tag, out val);
                return val;
            case GLib.Type.UINT:
                uint val = 0;
                tagList.get_uint(tag, out val);
                return @"$val";
            case GLib.Type.BOOLEAN:
                bool val = false;
                tagList.get_boolean(tag, out val);
                return @"$val";
        }
        
        stdout.printf(@"Tag unhandled type ($type): $tag\n");
        stdout.printf(@"$tagList\n");
        return "";        
    };
}

void load_favicon (Gtk.Image image, string url, string default_icon) {
    // Set default icon first, in case loading takes long or fails
    image.set_from_icon_name (default_icon, Gtk.IconSize.DIALOG);
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
        Gdk.Pixbuf pxbuf;

        try {
            pxbuf = new Gdk.Pixbuf.from_stream_at_scale (data_stream, 48, 48, true, null);
        } catch (Error e) {
            warning ("Couldn't render image: %s (%s)",
                url ?? "unknown url",
                e.message);
            return;
        }

        image.set_from_pixbuf (pxbuf);
        image.set_size_request (48, 48);
    });
} 