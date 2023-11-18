/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

using Gee;

public class Tuner.DisplayBox : Gtk.Box {
    private const string DEFAULT_ICON_NAME = "internet-radio-symbolic";

    private Gtk.Label _title;
    private UrlImage _favicon_image;
    private Gtk.Label _station_name_label;

    private Gtk.Label _organization;
    private Gtk.Label _homepage;
    private Gtk.Label _genre;

    public DisplayBox () {
        Object (
            orientation: Gtk.Orientation.HORIZONTAL,
            spacing: 0
        );

        var vBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        set_center_widget(vBox);

        var content = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
        vBox.set_center_widget(content);

        
        _station_name_label = new HeaderLabel(_("Radio"));
        content.pack_start(_station_name_label);
        
        var hBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
        
        _favicon_image = new UrlImage(DEFAULT_ICON_NAME);
        hBox.pack_start(_favicon_image);
        
        _title = new Gtk.Label(_("Playing"));
        _title.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        hBox.pack_start(_title);

        content.pack_start(hBox);

        var tagsBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 2);
        _organization = row(tagsBox, "Organization:");
        _homepage = row(tagsBox, "Homepage:");
        _genre = row(tagsBox, "Genre:");
        content.pack_start(tagsBox);
    }

    public void update_from_station(Model.Station station) {
        _station_name_label.set_label(station.title);
        _favicon_image.url = station.favicon_url;
    }

    public void update_from_info(Gst.PlayerMediaInfo info) {
        unowned var streamlist = info.get_audio_streams ();
        foreach (var stream_info in streamlist) {
            var get_tag = TagListGetter(stream_info.get_tags());

            _title.set_label(get_tag(Gst.Tags.TITLE));
            _organization.set_label(get_tag(Gst.Tags.ORGANIZATION));
            _homepage.set_label(get_tag(Gst.Tags.HOMEPAGE));
            _genre.set_label(get_tag(Gst.Tags.GENRE));
        }
    }

    private Gtk.Label row(Gtk.Box parent, string label) {
        var row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
        row.set_homogeneous(true);
        
        var _label = new Gtk.Label(label);
        _label.halign = Gtk.Align.START;
        _label.xalign = 0;
        row.pack_start(_label);

        var valueLabel = new Gtk.Label("");
        valueLabel.halign = Gtk.Align.START;
        valueLabel.xalign = 0;
        row.pack_start(valueLabel);
        parent.pack_start(row);

        return valueLabel;
    }   
}
