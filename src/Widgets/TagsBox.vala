/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

public class Tuner.TagsBox : Gtk.Box {
    private const string DEFAULT_ICON_NAME = "internet-radio-symbolic";

    private Gtk.ListStore store; 

    public TagsBox () {
        Object (
            orientation: Gtk.Orientation.VERTICAL,
            spacing: 0
        );
        
        pack_start(new HeaderLabel("Tag list"), false, false); 
        pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false);
        pack_start(make_tree_view(), true, true); 
    }

    public void update_from_station (Model.Station station) {
        //  header_label.set_label(station.title);
        //  load_favicon (image, station.favicon_url, DEFAULT_ICON_NAME);
    }

    public void update_from_info (Gst.PlayerMediaInfo info) {  
        
        unowned var streamlist = info.get_audio_streams ();

        var global_tags = info.get_tags();
        if(global_tags != null)
            stdout.printf(@"Global: $global_tags\n");

        foreach (var stream_info in streamlist) {
            populateTags(stream_info.get_tags());
        }
    }
    
    private void populateTags(Gst.TagList? tags) {
        store.clear();

        if(tags == null)
            return;

        Gtk.TreeIter iter = Gtk.TreeIter();
        var get_tag = TagListGetter(tags);
        
        tags.foreach((l, tag)=>{
            store.append(out iter);
            store.set(iter, 0, tag, 1, get_tag(tag), -1);        
        });
    }

    construct {
        get_style_context ().add_class ("color-dark");
    }

    private void column (Gtk.TreeView tree, string name, int index) {
        var c = new Gtk.TreeViewColumn.with_attributes(name, new Gtk.CellRendererText(), "text", index);
        c.resizable = true;
        tree.append_column(c);
    }

    private Gtk.TreeView make_tree_view() {
        Gtk.TreeView tree;
        store = new Gtk.ListStore(2, GLib.Type.STRING, GLib.Type.STRING);
        tree = new Gtk.TreeView.with_model(store);
        column(tree, "Name", 0);
        column(tree, "Value", 1);
        return tree;
    }
 }
 