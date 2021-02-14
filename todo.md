# kak-wiki todo

## Bugs
- use only POSIX features
- formatting with an invalid relative link crashes the formatter
- show whether a link is broken, using a highlighter
- any reference to a link regex should be in a kakoune option
- consolidate highlighting and next-link link regexes

## Features
- `=` should auto-format everything. Line-width, links, etc.
- better link following:
  - if link points to file that exists in filesystem
    - use xdg with an exception for http://*
    - otherwise open with browser
  - when following a link save the open buffer before following.
- when creating a new file/directory because of a link follow, either:
  - prompt first to make sure that that is what is desired.
  - have two keybindings, one for link-follow and one for link-create
- add a way to jump to headings?
- add an option to the link formatter that only modifies the link i'm
  currently on
- deduplicate links when doing reference links
- Have a good way to copy a link
- make a `w` alias to fzf into a wiki page. It would be nice to have a flag
  that also opens the intermediate pages
- format and un-format reference links
- add per-link functionality, to swap it's reference and absolute form
