/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

public class Tuner.HeaderBar : Gtk.HeaderBar {

    private const string DEFAULT_ICON_NAME = "internet-radio-symbolic";
    public enum PlayState {
        PAUSE_ACTIVE,
        PAUSE_INACTIVE,
        PLAY_ACTIVE,
        PLAY_INACTIVE
    }

    public Gtk.Button play_button { get; set; }


    public Gtk.VolumeButton volume_button;

    private Gtk.Button star_button;
    private bool _starred = false;
    private Model.Station _station;
    private Gtk.Label _title_label;
    private RevealLabel _subtitle_label;
    private UrlImage _favicon_image;

    public signal void star_clicked (bool starred);
    public signal void searched_for (string text);
    public signal void search_focused ();
    
    private int search_delay = 250; // search delay in milliseconds (ms)
    private uint delayed_changed_id;
    private string searchentry_text = "";

    private void reset_timeout(){
        if(delayed_changed_id > 0)
            Source.remove(delayed_changed_id);
        delayed_changed_id = Timeout.add(search_delay, timeout);
    }

    private bool timeout(){
        // perform search
        searched_for (searchentry_text);
        delayed_changed_id = 0;
        return false;
    }

    construct {
        show_close_button = true;

        var station_info = new Gtk.Grid ();
        station_info.width_request = 200;
        station_info.column_spacing = 10;

        _title_label = new Gtk.Label (_("Choose a station"));
        _title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
        _title_label.ellipsize = Pango.EllipsizeMode.MIDDLE;
        _subtitle_label = new RevealLabel ();
        _favicon_image = new UrlImage(DEFAULT_ICON_NAME);

        station_info.attach (_favicon_image, 0, 0, 1, 2);
        station_info.attach (_title_label, 1, 0, 1, 1);
        station_info.attach (_subtitle_label, 1, 1, 1, 1);

        custom_title = station_info;
        play_button = new Gtk.Button ();
        play_button.valign = Gtk.Align.CENTER;
        play_button.action_name = Window.ACTION_PREFIX + Window.ACTION_PAUSE;
        pack_start (play_button);

        var prefs_button = new Gtk.MenuButton ();
        prefs_button.image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
        prefs_button.valign = Gtk.Align.CENTER;
        prefs_button.sensitive = true;
        prefs_button.tooltip_text = _("Preferences");
        prefs_button.popover = new Tuner.PreferencesPopover();;
        pack_end (prefs_button);

        var searchentry = new Gtk.SearchEntry ();
        searchentry.valign = Gtk.Align.CENTER;
        searchentry.placeholder_text = _("Station name");
        searchentry.changed.connect (() => {
            searchentry_text = searchentry.text;
            reset_timeout();
        });
        searchentry.focus_in_event.connect ((e) => {
            search_focused ();
            return true;
        });
        pack_end (searchentry);

        star_button = new Gtk.Button.from_icon_name (
            "non-starred",
            Gtk.IconSize.LARGE_TOOLBAR
        );
        star_button.valign = Gtk.Align.CENTER;
        star_button.sensitive = true;
        star_button.tooltip_text = _("Star this station");
        star_button.clicked.connect (() => {
            star_clicked (starred);
        });

        pack_start (star_button);

        volume_button = new Gtk.VolumeButton ();
        volume_button.value = Application.instance.settings.get_double ("volume");
        volume_button.value_changed.connect ((value) => {
            Application.instance.settings.set_double ("volume", value);
        });
        pack_start (volume_button);
        

        set_playstate (PlayState.PAUSE_INACTIVE);
    }

    public new string title {
        get {
            return _title_label.label;
        }
        set {
            _title_label.label = value;
        }
    }

    public new string subtitle {
        get {
            return _subtitle_label.label;
        }
        set {
            _subtitle_label.label = value;
        }
    }

    public UrlImage favicon {
        get {
            return _favicon_image;
        }
        set {
            _favicon_image = value;
        }
    }

    public void handle_station_change () {
        starred = _station.starred;
    }

    public void update_from_station (Model.Station station) {
        if (_station != null) {
            _station.notify.disconnect (handle_station_change);
        }
        _station = station;
        _station.notify.connect ( (sender, property) => {
            handle_station_change ();
        });
        title = station.title;
        subtitle = _("Playing");
        favicon.url = station.favicon_url;
        starred = station.starred;
    }

    private bool starred {
        get {
            return _starred;
        }

        set {
            _starred = value;
            if (!_starred) {
                star_button.image = new Gtk.Image.from_icon_name ("non-starred",    Gtk.IconSize.LARGE_TOOLBAR);
            } else {
                star_button.image = new Gtk.Image.from_icon_name ("starred",    Gtk.IconSize.LARGE_TOOLBAR);
            }
        }
    }

    public void set_playstate (PlayState state) {
        switch (state) {
            case PlayState.PLAY_ACTIVE:
                play_button.image = new Gtk.Image.from_icon_name (
                    "media-playback-start-symbolic",
                    Gtk.IconSize.LARGE_TOOLBAR
                );
                play_button.sensitive = true;
                star_button.sensitive = true;
                break;
            case PlayState.PLAY_INACTIVE:
                play_button.image = new Gtk.Image.from_icon_name (
                    "media-playback-start-symbolic",
                    Gtk.IconSize.LARGE_TOOLBAR
                );
                play_button.sensitive = false;
                star_button.sensitive = false;
                break;
            case PlayState.PAUSE_ACTIVE:
                play_button.image = new Gtk.Image.from_icon_name (
                    "media-playback-stop-symbolic",
                    Gtk.IconSize.LARGE_TOOLBAR
                );
                play_button.sensitive = true;
                star_button.sensitive = true;
                break;
            case PlayState.PAUSE_INACTIVE:
                play_button.image = new Gtk.Image.from_icon_name (
                    "media-playback-stop-symbolic",
                    Gtk.IconSize.LARGE_TOOLBAR
                );
                play_button.sensitive = false;
                star_button.sensitive = false;
                break;
        }
    }

}
