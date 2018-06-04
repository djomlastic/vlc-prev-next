VlcPrevNext
===========

Vlc player extension that enables playing next and previous files from the same directory.

The extension looks into directory where the current file is located, and if it finds other media files it adds
previous and next files to the playlist. The files are selected using file names in alphabetical order. Something
like what Media Player Classic Home Cinema does out of the box.

## Installation

Tested with Vlc 2.2.2, 3.0.3 Windows and Linux builds (check [notes](#notice) for known issues).

Copy VlcPrevNext.lua into:

* Linux (single user): `~/.local/share/vlc/lua/extensions/`
* Linux Flatpak (single user): `~/.var/app/org.videolan.VLC/data/vlc/lua/extensions/`
* Linux (all users): `/usr/lib/vlc/lua/extensions/`
* Linux Flatpak (all users): `/var/lib/flatpak/app/org.videolan.VLC/current/active/files/lib/vlc/lua/extensions/`
* Windows (single user): `%APPDATA%\vlc\lua\extensions\`
* Windows (all users): `%ProgramFiles%\VideoLAN\VLC\lua\extensions\`

## Usage

In Vlc's menu go to View and click on "Load prev/next file". Unfortunately you have to do this every time you start
Vlc player (that's how Vlc handles it's extensions). If Vlc is your default player and it's set to use only one
instance you can play files from your file manager (or something else) and it will work fine as long as you don't
close that Vlc instance.

### Notes

* Extension is looking for these files: ".mp4", ".mkv", ".avi", ".mov", ".mp3", ".flac", ".m4v", ".wmv", ".mpeg",
".mpg". If your file is not one of these and Vlc can play it, you can add that file extension to `media_extensions`
array (it's near the top of VlcPrevNext.lua). Or let me know and I'll do it.
* When playing last file in the directory using next button will play the first file (same goes for first file and
previous button, it plays the last file). Vlc loops it's playlist, so if the extension didn't add the first file from
the directory it would play the one before last, then the last again...
* UI Freezing. With Vlc 2.2.2 UI can freeze sometimes, the player keeps playing but the UI becomes unresponsive
(so you have to force-quit eventually). This is hard to debug because it's random, there are no errors or warrnings
logged, everything except the UI keeps working as usual. From what I was able to find out, this is related to a bug
with 2.x.x versions that happens when Vlc calls some functions in plugin's life cycle. From my experience this didn't
happen very often, sometimes not at all for days, but you'll have to try. I didn't have this issue with 3.0.3.