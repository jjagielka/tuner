/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

public class Tuner.ItemBox : Tuner.WelcomeButton {

    public Model.Item station { get; construct; }
    public StationContextMenu menu { get; private set; }

    public ItemBox (Model.Item station) {
        Object (
            description: make_description (""),
            title: station.title, // make_title (station.title, station.starred),
            tag: "Category",
            station: station
        );
    }

    construct {
        get_style_context().add_class("station-button");

        this.station.notify["starred"].connect ( (sender, prop) => {
            this.title = make_title (this.station.title, this.station.starred);
        });

        icon = new UrlImage("internet-radio");
        icon.url = station.favicon_url;

        event.connect ((e) => {
            if (e.type == Gdk.EventType.BUTTON_PRESS && e.button.button == 3) {
                // Optimization:
                // Create menu on demand not on construction
                // because it is rarely used for all stations
                if (menu == null) {
                    menu = new StationContextMenu (this.station);
                    menu.attach_to_widget (this, null);
                    menu.show_all ();
                }

                menu.popup_at_pointer ();
                return true;
            }
            return false;
        });
        always_show_image = true;
    }

    private static string make_title (string title, bool starred) {
        if (!starred) return title;
        return Application.STAR_CHAR + title;
    }

    private static string make_tag (string location, string fallback) {
        if(location != "")
            return location;
        return fallback;
    }

    private static string make_description (string location) {
        if (location != "") 
            return _(location);
        else
            return location;
    }
}
