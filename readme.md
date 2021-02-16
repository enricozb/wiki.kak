# wiki.kak

Organize your life and find things quickly with markdown.

## Main features:
- navigate quickly through links in a file
- refer to other markdown files on your filesystem
- open files that kakoune can't open in the correct program
  - open urls in your default browser
  - open pdfs in your default pdf viewer 
  - etc...
- format all links as reference links to remove clutter
- a better (optional) markdown syntax highlighter

### Demo
Here's a demo of the link navigation and manipulation features:
[![asciicast](https://asciinema.org/a/391505.svg)][1]

## Installation
Using [plug.kak][2], add the following to your `kakrc`:
```
plug "enricozb/wiki.kak"
```
Then, follow the [default programs][3] section to set up `xdg` to open text
files in kakoune.

See the [configuration][4] section for any customization options.

### Dependencies
The following must be installed to have all of the features of wiki.kak:
- python 3+
- xdg-open

## Keys
By default, the following keys are set:
```
map buffer normal <tab>   ': wiki-next-link<ret>'
map buffer normal <s-tab> ': wiki-prev-link<ret>'
map buffer normal <ret>   ': wiki-open-link<ret>'
map buffer normal +       ': wiki-yank-link<ret>'
map buffer normal <minus> ': wiki-inline-link<ret>'
map buffer normal <c-k>   ': wiki-make-link<ret>'
map buffer normal <space> ': wiki-toggle-checkbox<ret>'
```
These can be customized with the `wiki_use_custom_keymap` option, see 
[keys and syntax highlighting][5].

## Commands
- **wiki-next-link** goes to the next link
- **wiki-prev-link** goes to the previous link
- **wiki-open-link** opens the link in the default program, see
  [default program][6] for setting this up
- **wiki-yank-link** yanks the link to the clipboard, and also displays the
  link in the status line
- **wiki-inline-link** converts the reference link the cursor is currently on
  to an inline link
- **wiki-make-link** prompt the user for a url and make a link out of the
  current selection, expanding to a word if the selection is a single character
- **wiki-toggle-checkbox** toggle the checkbox on the current line

## Configuration
### Default Programs
wiki.kak uses [xdg-open][7] to open links that kakoune can't open. If you have
a system without `xdg-open`, please raise an issue and I'll prioritize a
`wiki_use_xdg_open` configuration option.

The following lines are recommended in your `~/.local/share/applications/defaults.list`:
```
[Default Applications]
text/plain=kak.desktop
inode/empty=kak.desktop
application/csv=kak.desktop
application/json=kak.desktop
application/octet-stream=kak.desktop
```
These tell `xdg-open` to use `kak` when opening _text-like_ files.
Only the first one is strictly required, but the `application/octet-stream` is
strongly recommended, as some non-ascii text files are seen as an octet stream.

### Keys and Syntax Highlighting
The recommended configuration is the default configuration. It sets up the
keys specified in [keys][8], and also uses the custom markdown syntax
highlighter. To turn each of these off, the following options can be set:
```
plug "enricozb/wiki.kak" %{
  set-option global wiki_use_custom_syntax false
  set-option global wiki_use_custom_keymap false
}
```

## Bugs
Please raise an issue for any missing features or bugs you encounter.

## To Do
See [todo][9].


[1]: https://asciinema.org/a/391505
[2]: https://github.com/robertmeta/plug.kak
[3]: #default-programs
[4]: #configuration
[5]: #keys-and-syntax-highlighting
[6]: #default-program
[7]: https://linux.die.net/man/1/xdg-open
[8]: #keys
[9]: todo.md
