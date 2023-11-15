/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

public class Tuner.Model.Station : Object {
    public string id { get; set; }
    public string title { get; set; }
    //  public string url { get; set; }
    public string location { get; set; }
    public bool starred { get; set; }
    public string homepage { get; set; }
    public string codec { get; set; }
    public int bitrate { get; set; }

    public string? favicon_url { get; set; }
    public uint clickcount = 0;

    private string _url;
    private string _url_resolved = null;

    public Station (string id, string title, string location, string url) {
        Object ();

        this.id = id;
        this.title = title;
        this.location = location;
        this.url = url;
        this.starred = starred;
    }

    public string url { 
        get {
            stdout.printf(@"get: $(_url)\n");
            //  stdout.printf(@"-> $(http_get(_url))\n");
            if(_url_resolved == null)
                _url_resolved = http_get(_url);
            return _url_resolved;
        }

        set {
            _url = value;
        }
    }    
    public void toggle_starred () {
        this.starred = !this.starred;
    }

    public string to_string() {
        return @"[$(this.id)] $(this.title)";
    }

}
