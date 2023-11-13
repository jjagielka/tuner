

public class Tuner.Model.TagList : Object {
    public Gst.TagList tagList { get; set; }

    public TagList (Gst.TagList tagList) {   
        this.tagList = tagList;
        stdout.printf(@"$tagList");
    }

    public string as_string(string tag) {
        var value = "";
        switch(Gst.Tags.get_type(tag)) {
            case GLib.Type.STRING:
                tagList.get_string(tag, out value);
                break;
            case GLib.Type.UINT:
                uint val;
                if(tagList.get_uint(tag, out val)) value = @"$val";
                break;
        }
        return value;
    }

}

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
            //  case GLib.Type.BOOLEAN:
            //      bool val = false;
            //      tagList.get_boolean(tag, out val);
            //      return @"$val";
        }
        
        stdout.printf(@"Tag unhandled type ($type): $tag\n");
        stdout.printf(@"$tagList\n");
        return "";        
    };
}

 