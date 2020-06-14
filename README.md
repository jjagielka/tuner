# ![icon](docs/logo_01.png) Tuner

## Minimalist radio station player

[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.louis77.tuner)

Discover and Listen to random radio stations while you work.

![Screenshot 01](docs/screen_05.png?raw=true)

## Motivation

I love listening to radio while I work. There are tens of tousands of cool internet radio stations available, however I find it hard to "find" new stations by using filters and genres. As of now, this little app takes away all the filtering and just presents me with new radio stations every time I use it.

While I hacked on this App, I discovered so many cool and new stations, which makes it even more enjoyable. I hope you enjoy it too.

## Features

- Uses radio-browser.info catalog
- Presents a random selection of stations
- Sends a click count to radio-browser.info on station click
- Sends a vote count to radio-browser.info when you star a station
- DBus integration to pause/resume playing and show station info

## Upcoming

- List stations you starred
- More selection screens (Trending, Most Popular, Country-specific)
- Community-listening: see what other users are listening to right now
- Other ideas? Create an issue!

## Dependencies

```bash
granite
gtk+-3.0
gstreamer-1.0
gstreamer-player-1.0
libsoup-2.4
json-glib-1.0
libgee-0.8
meson
vala
```

## Building

Simply clone this repo, then:

```bash
meson build && cd build
meson configure -Dprefix=/usr
sudo ninja install
```

## Credits

- [faleksandar.com](https://faleksandar.com/) for icons and colors
- [radio-browser.info](http://www.radio-browser.info) for providing a free radio station directory
- [elementary.io](https://elementary.io) for making Linux enjoyable on the desktop
- [Vala](https://wiki.gnome.org/Projects/Vala) - a great programming language

## Disclaimer

Tuner uses the community-drive radio station catalog radio-browser.info. Tuner
is not responsible for the stations shown or the actual streaming audio content.

