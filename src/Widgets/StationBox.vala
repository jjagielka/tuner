/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

public class Tuner.StationBox : Tuner.WelcomeButton {

    public Model.Station station { get; construct; }
    public StationContextMenu menu { get; private set; }

    public StationBox (Model.Station station) {
        Object (
            description: make_description (station.location),
            title: make_title (station.title, station.starred),
            tag: make_tag (station.codec, station.bitrate),
            //  icon: new UrlImage("internet-radio"), // if create here then constructor fails
            station: station
        );
    }

    construct {
        get_style_context().add_class("station-button");

        this.station.notify["starred"].connect ( (sender, prop) => {
            this.title = make_title (this.station.title, this.station.starred);
        });

        // TODO Use a AsyncQueue with limited threads
        //  new Thread<int>("station-box", realize_favicon);

        icon = new UrlImage("internet-radio", station.id);
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

    private static string make_tag (string codec, int bitrate) {
        var tag = codec;
        if (bitrate > 0)
        {
            tag = tag + " " + bitrate.to_string() + "k";
        }

        return tag;
    }

    private static string make_description (string location) {
        if (location.length > 0) 
            return _(location);
        else
            return location;
    }
}
