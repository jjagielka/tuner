/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

using Gee;

public class Tuner.Window : Gtk.ApplicationWindow {

    public GLib.Settings settings { get; construct; }
    public Gtk.Stack stack { get; set; }
    public PlayerController player { get; construct; }

    private DirectoryController _directory;
    private RadioTimesController _radiotimes;
    private HeaderBar headerbar;
    private Granite.Widgets.SourceList source_list;
    
    public const string WindowName = "Tuner";
    public const string ACTION_PREFIX = "win.";
    public const string ACTION_PAUSE = "action_pause";
    public const string ACTION_QUIT = "action_quit";
    public const string ACTION_HIDE = "action_hide";
    public const string ACTION_ABOUT = "action_about";
    public const string ACTION_DISABLE_TRACKING = "action_disable_tracking";
    public const string ACTION_ENABLE_AUTOPLAY = "action_enable_autoplay";

    private signal void refresh_favourites ();

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_PAUSE, on_toggle_playback },
        { ACTION_QUIT , on_action_quit },
        { ACTION_ABOUT, on_action_about },
        { ACTION_DISABLE_TRACKING, on_action_disable_tracking, null, "false" },
        { ACTION_ENABLE_AUTOPLAY, on_action_enable_autoplay, null, "false" }
    };

    static construct {
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("com/github/louis77/tuner/Application.css");
        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default (), 
            provider, 
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }

    public Window (Application app, PlayerController player) {
        Object (
            application: app, 
            player: player,
            settings: Application.instance.settings
        );

        application.set_accels_for_action (ACTION_PREFIX + ACTION_PAUSE, {"<Control>5"});
        application.set_accels_for_action (ACTION_PREFIX + ACTION_QUIT, {"<Control>q"});
        application.set_accels_for_action (ACTION_PREFIX + ACTION_QUIT, {"<Control>w"});
    }

    construct {
        this.set_icon_name("com.github.louis77.tuner");

        headerbar = new HeaderBar ();
        set_titlebar (headerbar);
        set_title (WindowName);

        player.state_changed.connect (handleplayer_state_changed);
        player.station_changed.connect (headerbar.update_from_station);
        player.title_changed.connect ((title) => {
            headerbar.subtitle = title;
        });
        player.volume_changed.connect ((volume) => {
            headerbar.volume_button.value = volume;
        });
        headerbar.volume_button.value_changed.connect ((value) => {
            player.volume = value;
        });

        adjust_theme();
        settings.changed.connect( (key) => {
            if (key == "theme-mode") {
                warning("theme-mode changed");
                adjust_theme();
                
            }
        });

        var granite_settings = Granite.Settings.get_default ();
        granite_settings.notify.connect( (key) => {
                warning("theme-mode changed");
                adjust_theme();
        });

        add_action_entries (ACTION_ENTRIES, this);

        window_position = Gtk.WindowPosition.CENTER;
        set_default_size (800, 540);
        change_action_state (ACTION_DISABLE_TRACKING, settings.get_boolean ("do-not-track"));
        change_action_state (ACTION_ENABLE_AUTOPLAY, settings.get_boolean ("auto-play"));
        move (settings.get_int ("pos-x"), settings.get_int ("pos-y"));

        set_geometry_hints (null, Gdk.Geometry() {min_height = 440, min_width = 600}, Gdk.WindowHints.MIN_SIZE);
        resize (settings.get_int ("window-width"), settings.get_int ("window-height"));

        delete_event.connect (e => {
            return before_destroy ();
        });

        var stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        
        var data_file = Path.build_filename (Application.instance.data_dir, "favorites.json");
        var store = new Model.StationStore (data_file);
        _directory = new DirectoryController (store);
        _radiotimes = new RadioTimesController (store);

        var primary_box = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);

        var display_category = new Granite.Widgets.SourceList.ExpandableItem (_("Display"));
        display_category.collapsible = false;
        display_category.expanded = true;

        var selections_category = new Granite.Widgets.SourceList.ExpandableItem (_("Selections"));
        selections_category.collapsible = false;
        selections_category.expanded = true;

        var searched_category = new Granite.Widgets.SourceList.ExpandableItem (_("Library"));
        searched_category.collapsible = false;
        searched_category.expanded = true;

        var genres_category = new Granite.Widgets.SourceList.ExpandableItem (_("Genres"));
        genres_category.collapsible = true;
        genres_category.expanded = true;
        
        source_list = new Granite.Widgets.SourceList ();
        
        // Display Box
        var display_item = new Granite.Widgets.SourceList.Item (_("Display"));
        display_item.icon = new ThemedIcon ("playlist-queue");
        display_category.add (display_item);
        
        var display_box = new DisplayBox();
        display_box.realize.connect(() => { 
            player.station_changed.connect (display_box.update_from_station);
            player.info_changed.connect (display_box.update_from_info);
            display_box.update_from_station(player.station);
            display_box.update_from_info (player.player.media_info);
        });

        var display_name = "display";
        display_item.set_data<string> ("stack_child", display_name);
        stack.add_named (display_box, display_name);
        
        // Tags Box
        var tags_item = new Granite.Widgets.SourceList.Item (_("Tags"));
        tags_item.icon = new ThemedIcon ("playlist-queue");
        display_category.add (tags_item);
        
        var tags_box = new TagsBox();
        tags_box.realize.connect(() => { 
            player.station_changed.connect(tags_box.update_from_station);
            player.info_changed.connect (tags_box.update_from_info);
            tags_box.update_from_info(player.player.media_info);
            tags_box.update_from_station(player.station);
        });

        var tags_name = "tags";
        tags_item.set_data<string> ("stack_child", tags_name);
        stack.add_named (tags_box, tags_name);

        // Discover Box
        var item1 = new Granite.Widgets.SourceList.Item (_("Discover"));
        item1.icon = new ThemedIcon ("face-smile");
        selections_category.add (item1);

        var c1 = create_content_box ("discover", item1,
                            _("Discover Stations"), "media-playlist-shuffle-symbolic",
                            _("Discover more stations"),
                            stack, source_list);
        var s1 = _directory.load_random_stations(20);
        c1.realize.connect (() => {
            try {
                var slist = new StationList.with_stations (s1.next ());
                slist.selection_changed.connect (handle_station_click);
                slist.favourites_changed.connect (handle_favourites_changed);
                c1.content = slist;
            } catch (SourceError e) {
                c1.show_alert ();
            }
        });
        c1.action_activated.connect (() => {
            try {
                var slist = new StationList.with_stations (s1.next ());
                slist.selection_changed.connect (handle_station_click);
                slist.favourites_changed.connect (handle_favourites_changed);
                c1.content = slist;
            } catch (SourceError e) {
                c1.show_alert ();
            }
        });

        // Trending Box
        var item2 = new Granite.Widgets.SourceList.Item (_("Trending"));
        item2.icon = new ThemedIcon ("playlist-queue");
        selections_category.add (item2);
                
        var c2 = create_content_box ("trending", item2,
                            _("Trending in the last 24 hours"), null, null,
                            stack, source_list);
        var s2 = _directory.load_trending_stations(40);
        c2.realize.connect (() => {
            try {
                var slist = new StationList.with_stations (s2.next ());
                slist.selection_changed.connect (handle_station_click);
                slist.favourites_changed.connect (handle_favourites_changed);
                c2.content = slist;
            } catch (SourceError e) {
                c2.show_alert ();
            }

        });

        // Popular Box
        var item3 = new Granite.Widgets.SourceList.Item (_("Popular"));
        item3.icon = new ThemedIcon ("playlist-similar");
        selections_category.add (item3);
                                
        var c3 = create_content_box ("popular", item3,
                            _("Most-listened over 24 hours"), null, null,
                            stack, source_list);
        var s3 = _directory.load_popular_stations(40);
        c3.realize.connect (() => {
            try {
                var slist = new StationList.with_stations (s3.next ());
                slist.selection_changed.connect (handle_station_click);
                slist.favourites_changed.connect (handle_favourites_changed);
                c3.content = slist;
            } catch (SourceError e) {
                c3.show_alert ();
            }
        });

        // Country-specific stations list
        var item4 = new Granite.Widgets.SourceList.Item (_("Your Country"));
        item4.icon = new ThemedIcon ("emblem-web");
        ContentBox c_country;
        c_country = create_content_box ("my-country", item4,
                            _("Your Country"), null, null,
                            stack, source_list, true);
        var c_slist = new StationList ();
        c_slist.selection_changed.connect (handle_station_click);
        c_slist.favourites_changed.connect (handle_favourites_changed);

        LocationDiscovery.country_code.begin ((obj, res) => {
            string country;
            try {
                country = LocationDiscovery.country_code.end(res);
            } catch (GLib.Error e) {
                // GeoLocation Service might not be available
                // We don't do anything about it
                return;
            }

            var country_name = Model.Countries.get_by_code (country);
            item4.name = country_name;
            c_country.header_label.label = _("Top 100 in") + " " + country_name;
            var s_country = _directory.load_by_country (100, country);
            selections_category.add (item4);
            c_country.realize.connect (() => {
                try {
                    var stations = s_country.next ();
                    c_slist.stations = stations;
                    warning (@"Length of country stations: $(stations.size)");
                    c_country.content = c_slist;
                } catch (SourceError e) {
                    c_country.show_alert ();
                }
            });
        });
 
        // Favourites Box
        var item5 = new Granite.Widgets.SourceList.Item (_("Starred by You"));
        item5.icon = new ThemedIcon ("starred");
        searched_category.add (item5);
        var c4 = create_content_box ("starred", item5,
                            _("Starred by You"), null, null,
                            stack, source_list, true);
        
        var slist = new StationList.with_stations (_directory.get_stored ());
        slist.selection_changed.connect (handle_station_click);
        slist.favourites_changed.connect (handle_favourites_changed);
        c4.content = slist;

        // Search Results Box
        var item6 = new Granite.Widgets.SourceList.Item (_("Recent Search"));
        item6.icon = new ThemedIcon ("folder-saved-search");
        searched_category.add (item6);
        var c5 = create_content_box ("searched", item6,
                            _("Search"), null, null,
                            stack, source_list, true);

        // Excluded Countries Box
        /* not finished yet 
        var item7 = new Granite.Widgets.SourceList.Item (_("Excluded Countries"));
        item7.icon = new ThemedIcon ("folder-saved-search");
        searched_category.add (item7);
        var c6 = create_content_box ("excluded_countries", item7,
            _("Excluded Countries"), null, null,
            stack, source_list, true);
        c6.content = new CountryList ();
        */
        
        // Genre Boxes
        foreach (var genre in Model.genres ()) {
            var item8 = new Granite.Widgets.SourceList.Item (_(genre.name));
            item8.icon = new ThemedIcon ("playlist-symbolic");
            genres_category.add (item8);
            var cb = create_content_box (genre.name, item8, 
                genre.name, null, null, stack, source_list);
            var tags = new ArrayList<string>.wrap (genre.tags);
            var ds = _directory.load_by_tags (tags);
            cb.realize.connect (() => {
                try {
                    var slist1 = new StationList.with_stations (ds.next ());
                    slist1.selection_changed.connect (handle_station_click);
                    slist1.favourites_changed.connect (handle_favourites_changed);
                    cb.content = slist1;
                } catch (SourceError e) {
                    cb.show_alert ();
                }
            });
        }

        headerbar.star_clicked.connect ( (starred) => {
            player.station.toggle_starred ();
        });

        refresh_favourites.connect ( () => {
            var _slist = new StationList.with_stations (_directory.get_stored ()); 
            _slist.selection_changed.connect (handle_station_click);
            _slist.favourites_changed.connect (handle_favourites_changed);
            c4.content = _slist;
        });

        source_list.root.add (display_category);
        source_list.root.add (selections_category);
        source_list.root.add (searched_category);
        source_list.root.add (genres_category);

        source_list.ellipsize_mode = Pango.EllipsizeMode.NONE;
        source_list.selected = source_list.get_first_child (selections_category);
        source_list.item_selected.connect  ((item) => {
            var selected_item = item.get_data<string> ("stack_child");
            stack.visible_child_name = selected_item;
        });

        // show as first
        stack.realize.connect(() => {
            var selected_item = source_list.selected.get_data<string> ("stack_child");
            stack.visible_child_name = selected_item;
        });

        headerbar.searched_for.connect ( (text) => {
            stdout.printf(@"headerbar.search_for.connect: $text\n");
            if (text.length > 0) {
                string mytext = text;
                var s5 = _directory.load_search_stations (mytext, 100); 
                // KUBA
                stdout.printf(@"Search: $text\n");
                var test = _radiotimes.load_search_stations (mytext, 100);
                // KUBA
                try {
                    var stations = test.next ();
                    if (stations == null || stations.size == 0) {
                        c5.show_nothing_found ();
                    } else {
                        var _slist = new StationList.with_stations (stations);
                        _slist.selection_changed.connect (handle_station_click);
                        _slist.favourites_changed.connect (handle_favourites_changed);
                        c5.content = _slist;
                    }
                } catch (SourceError e) {
                    c5.show_alert ();
                }    
            }
        });

        headerbar.search_focused.connect (() => {
            stack.visible_child_name = "searched";
        });

        primary_box.pack1 (source_list, false, false);
        primary_box.pack2 (stack, true, false);
        add (primary_box);
        show_all ();

        // Auto-play
        if (settings.get_boolean("auto-play")) {
            warning (@"Auto-play enabled");
            var last_played_station = settings.get_string("last-played-station");
            warning (@"Last played station is: $last_played_station");

            var source = _directory.load_station_uuid (last_played_station);

            try {
                foreach (var station in source.next ()) {
                    handle_station_click(station);
                    break;
                }  
            } catch (SourceError e) {
                warning ("Error while trying to autoplay, aborting...");
            }

        }
    }

    private ContentBox create_content_box (
             string name,
             Granite.Widgets.SourceList.Item item,
             string full_title,
             string? action_icon_name,
             string? action_tooltip_text,
             Gtk.Stack stack,
             Granite.Widgets.SourceList source_list,
             bool enable_count = false) {
        item.set_data<string> ("stack_child", name);
        var c = new ContentBox (
            null,
            full_title,
            null,
            action_icon_name,
            action_tooltip_text
        );
        c.map.connect (() => {
            source_list.selected = item;
        });
        if (enable_count) {
            c.content_changed.connect (() => {
                if (c.content == null) return;
                var count = c.content.item_count;
                item.badge = @"$count";
            });
        }
        stack.add_named (c, name);

        return c;
    }
    
    private static void adjust_theme() {
        var theme = Application.instance.settings.get_string("theme-mode");
        warning(@"current theme: $theme");
        
        var gtk_settings = Gtk.Settings.get_default ();
        var granite_settings = Granite.Settings.get_default ();
        if (theme != "system") {
            gtk_settings.gtk_application_prefer_dark_theme = (theme == "dark");
        } else {
            gtk_settings.gtk_application_prefer_dark_theme = (granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK);
        }
    }

    private void on_action_quit () {
        close ();
    }

    private void on_action_about () {
        var dialog = new AboutDialog (this);
        dialog.present ();
    }

    public void handle_station_click (Tuner.Model.Station station) {
        info (@"handle station click for $(station.title)");
        _directory.count_station_click (station);
        player.station = station;

        warning (@"storing last played station: $(station.id)");
        settings.set_string("last-played-station", station.id);

        set_title (WindowName+": "+station.title);
    }

    public void handle_favourites_changed () {
        refresh_favourites ();
    }

    public void on_toggle_playback() {
        info ("Stop Playback requested");
        player.play_pause ();
    }

    public void on_action_disable_tracking (SimpleAction action, Variant? parameter) {
        var new_state = !settings.get_boolean ("do-not-track");
        action.set_state (new_state);
        settings.set_boolean ("do-not-track", new_state);
        debug (@"on_action_disable_tracking: $new_state");
    }

    public void on_action_enable_autoplay (SimpleAction action, Variant? parameter) {
        var new_state = !settings.get_boolean ("auto-play");
        action.set_state (new_state);
        settings.set_boolean ("auto-play", new_state);
        debug (@"on_action_enable_autoplay: $new_state");
    }    

    public void handleplayer_state_changed (Gst.PlayerState state) {
        switch (state) {
            case Gst.PlayerState.BUFFERING:
                debug ("player state changed to Buffering");
                Gdk.threads_add_idle (() => {
                    headerbar.set_playstate (HeaderBar.PlayState.PAUSE_ACTIVE);
                    return false;
                });
                break;;
            case Gst.PlayerState.PAUSED:
                debug ("player state changed to Paused");
                Gdk.threads_add_idle (() => {
                    if (player.can_play()) {
                        headerbar.set_playstate (HeaderBar.PlayState.PLAY_ACTIVE);
                    } else {
                        headerbar.set_playstate (HeaderBar.PlayState.PLAY_INACTIVE);
                    }
                    return false;
                });
                break;;
            case Gst.PlayerState.PLAYING:
                debug ("player state changed to Playing");
                Gdk.threads_add_idle (() => {
                    headerbar.set_playstate (HeaderBar.PlayState.PAUSE_ACTIVE);
                    return false;
                });
                break;;
            case Gst.PlayerState.STOPPED:
                debug ("player state changed to Stopped");
                Gdk.threads_add_idle (() => {
                    if (player.can_play()) {
                        headerbar.set_playstate (HeaderBar.PlayState.PLAY_ACTIVE);
                    } else {
                        headerbar.set_playstate (HeaderBar.PlayState.PLAY_INACTIVE);
                    }
                    return false;
                });
                break;
        }

        return;
    }

    public bool before_destroy () {
        int width, height, x, y;

        get_size (out width, out height);
        get_position (out x, out y);

        settings.set_int ("pos-x", x);
        settings.set_int ("pos-y", y);
        settings.set_int ("window-height", height);
        settings.set_int ("window-width", width);

        if (player.current_state == Gst.PlayerState.PLAYING) {
            hide_on_delete();
            var notification = new GLib.Notification("Playing in background");
            notification.set_body("Click here to resume window. To quit Tuner, pause playback and close the window.");
            notification.set_default_action("app.resume-window");
            Application.instance.send_notification("continue-playing", notification);
            return true;
        }

        return false;
    }

}
