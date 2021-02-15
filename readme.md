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
[![asciicast](https://asciinema.org/a/391505.svg)](https://asciinema.org/a/391505)

## Installation
Using [plug.kak][1], add the following to your `kakrc`:
```
plug "enricozb/wiki.kak"
```
See the [configuration][2] section for customization.

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
```
These can be customized with the `wiki_use_custom_keymap` option, see 
[keys and syntax highlighting][3].

## Commands
- **wiki-next-link** goes to the next link
- **wiki-prev-link** goes to the previous link
- **wiki-open-link** opens the link in the default program, see
  [default program][4] for setting this up
- **wiki-yank-link** yanks the link to the clipboard, and also displays the
  link in the status line
- **wiki-inline-link** converts the reference link the cursor is currently on
  to an inline link
- **wiki-make-link** prompt the user for a url and make a link out of the
  current selection, expanding to a word if the selection is a single character

## Configuration
### Default Programs
wiki.kak uses [xdg-open][5] to open links that kakoune can't open. If you have
a system without `xdg-open`, please raise an issue and I'll prioritize a
`wiki_use_xdg_open` configuration option.

### Keys and Syntax Highlighting
The recommended configuration is the default configuration. It sets up the
keys specified in [keys][6], and also uses the custom markdown syntax
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
See [todo][7].


[1]: https://github.com/robertmeta/plug.kak
[2]: #configuration
[3]: #keys-and-syntax-highlighting
[4]: #default-program
[5]: https://linux.die.net/man/1/xdg-open
[6]: #keys
[7]: todo.md
