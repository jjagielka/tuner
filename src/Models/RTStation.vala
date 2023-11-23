/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */


public delegate string Resolve(string x);

public class Tuner.Model.RTStation : Station {
    private string _url;
    private string _url_resolved = null;
    public Resolve resolve = (x) => { return x; };

    public string now_playing_url { get; set; }

    public RTStation (string id, string title, string location, string url) {
        base(id, title, location, url);
    } 

    public override string url {
        get {
            if(_url_resolved == null)
                _url_resolved = resolve(_url);
            return _url_resolved;
        }
        set {
            _url = value;
            _url_resolved = null;
        }
    }

    public override string to_string() {
        return @"[$(this.id)] $(this.title)";
    }

}
