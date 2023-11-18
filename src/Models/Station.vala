/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

 public class Tuner.Model.Item : Object {
    public string title { get; set; }
    public virtual string  url { get; set; }
    public string favicon_url { get; set; }
    public string id { get; set; }
    public bool starred { get; set; }
    public void toggle_starred () {
        this.starred = !this.starred;
    }    
    
    public string homepage { get; set; }
    public string location { get; set; }
    public Gee.ArrayList<Item>? children;
    
    public virtual string to_string() {
        return @"[$(this.url)] $(this.title)";
    }    
}

public class Tuner.Model.Station : Item {
    public string codec { get; set; }
    public int bitrate { get; set; }

    public uint clickcount = 0;

    public Station (string id, string title, string location, string url) {
        Object ();

        this.id = id;
        this.title = title;
        this.location = location;
        this.url = url;
        this.starred = starred;
    } 

    public override string to_string() {
        return @"[$(this.id)] $(this.title)";
    }
}
