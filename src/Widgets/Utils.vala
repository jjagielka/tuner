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

