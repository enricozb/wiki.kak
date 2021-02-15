# kak-wiki todo


## Bugs
- use only POSIX features
  - this might be done already
- formatting with an invalid relative link crashes the formatter


## Features
- checkboxes
- following links to headings
- `=` should auto-format everything. Line-width, links, etc.
  - there should be a way to revert to inline links.
- when creating a new file/directory because of a link follow, either:
  - prompt first to make sure that that is what is desired.
  - have two keybindings, one for link-follow and one for link-create
- add a way to jump to headings?
- add an option to the link formatter that only modifies the link i'm
  currently on
  - half of this is done with **wiki-inline-link**
- deduplicate links when doing reference links
- Have a good way to copy a link
- make a `w` alias to fzf into a wiki page. It would be nice to have a flag
  that also opens the intermediate pages
- show whether a link is broken, using a highlighter
- add an `wiki_use_xdg_open` configuration option.
