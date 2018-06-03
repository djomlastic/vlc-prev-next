VlcPrevNext
===========

Vlc player extension that enables playing next and previous files from the same directory.

The extension looks into directory where the current file is located, and if it finds other media files it adds
previous and next files to the playlist. The files are selected using file names in alphabetical order. Something
like what Media Player Classic Home Cinema does out of the box.

## Installation

Tested with Vlc 2.2.2, 3.0.3 Windows builds and Vlc 2.2.2 Linux build.

Copy VlcPrevNext.lua into:

* Linux (single user): `~/.local/share/vlc/lua/extensions/`
* Linux (all users): `/usr/lib/vlc/lua/extensions/`
* Windows (single user): `%APPDATA%\vlc\lua\extensions\`
* Windows (all users): `%ProgramFiles%\VideoLAN\VLC\lua\extensions\`

## Usage

In Vlc's menu go to View and click on "Load prev/next file". Unfortunately you have to do this every time you start
Vlc player (that's how Vlc handles it's extensions). If Vlc is your default player and it's set to use only one
instance you can play files from your file manager (or something else) and it will work fine as long as you don't
close that Vlc instance.

### Notice

Extension is looking for these files: ".mp4", ".m4v", ".avi", ".wmv", ".mkv", ".mov", ".mpeg", ".mpg". If your file
is not one of these and Vlc can play it, you can add that file extension to `media_extensions` array (it's near the
top of VlcPrevNext.lua).