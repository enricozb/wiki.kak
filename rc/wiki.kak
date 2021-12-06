# ────────────── initialization ──────────────
hook global BufCreate .*[.](md) %{
  set-option buffer filetype wiki
}

hook -group wiki-highlight global WinSetOption filetype=wiki %{
  add-highlighter window/wiki ref wiki
  hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/wiki }
}


# ────────────── configuration options ──────────────
# whether or not to use the custom syntax
declare-option bool wiki_use_custom_syntax true

# whether or not to use the recommended keymap
declare-option bool wiki_use_custom_keymap true


# ────────────── internal options ──────────────
# used to access `format.py`
declare-option -hidden str wiki_plugin_path %sh{ dirname "$kak_source" }

# shared between syntax.kak and wiki.kak
declare-option -hidden str wiki_link_regex '[^\]](\[([^\[\n]+)\])(\[[^\]\n]+\]|\([^\)\n]+\))'
declare-option -hidden str wiki_anchor_regex '[^\]](\[([^\[\n]+)\])[^\[\(:]'
declare-option -hidden str wiki_reflink_regex '\[[^\n]+\]: [^\n]*\n'

# used when visiting links
declare-option -hidden str wiki_link_kind
declare-option -hidden str wiki_link_path
declare-option -hidden str wiki_link_refid


# ────────────── commands ──────────────
provide-module wiki %{
  evaluate-commands %sh{
    if [ "$kak_opt_wiki_use_custom_syntax" = true ]; then
      printf "%s\n" "require-module wiki-syntax"
    fi
  }

  define-command wiki-next-link -docstring "navigate to the next wiki link" %{
    evaluate-commands -no-hooks -save-regs / %{
      set-register / "(%opt{wiki_anchor_regex}|%opt{wiki_link_regex})"
      execute-keys "n<a-;>ll"
    }
  }

  define-command wiki-prev-link -docstring "navigate to the previous wiki link" %{
    evaluate-commands -no-hooks -save-regs / %{
      set-register / "(%opt{wiki_anchor_regex}|%opt{wiki_link_regex})"
      execute-keys "<a-n><a-;>ll"
    }
  }

  define-command -hidden wiki-grab-link -docstring "set wiki_link_path to the value of this link, dereferencing if necessary" %{
    # detect whether the link is inline or reference, and get its path
    try %{
      evaluate-commands -draft %{
        # select the character immediately after the first ']' in a link: '(' or '['
        execute-keys "<a-i>[ll"
        execute-keys %sh{
          if [ "$kak_selection" = "(" ]; then
            printf "%s" "<a-i>("
            printf "%s" ": set-option buffer wiki_link_kind inline<ret>"
            printf "%s" ": set-option buffer wiki_link_path %val{selection}<ret>"
          elif [ "$kak_selection" = "[" ]; then
            printf "%s" "<a-i>["
            printf "%s" ": set-option buffer wiki_link_kind reference<ret>"
            printf "%s" ": set-option buffer wiki_link_path %val{selection}<ret>"
          else
            printf "%s" ": fail<ret>"
          fi
        }
      }
    } catch %{
      fail "invalid link"
    }

    # if the link is a reference, grab the link from the first line with [<id>]: <link>
    try %{
      execute-keys -draft %sh{
        if [ "$kak_opt_wiki_link_kind" = reference ]; then
          printf "%s" ": set-option buffer wiki_link_refid '$kak_opt_wiki_link_path'<ret>"
          printf "%s" "/^\h*\Q[$kak_opt_wiki_link_path]: <ret>lGl"
          printf "%s" ': set-option buffer wiki_link_path "%val{selection}"<ret>'
        fi
      }
    }
  }

  define-command wiki-open-link -docstring "open the link in the default program" %{
    wiki-grab-link

    evaluate-commands %sh{
      # if link is likely a url, open it with xdg
      case "$kak_opt_wiki_link_path" in
        http:* | https:*)
          nohup xdg-open "$kak_opt_wiki_link_path" >/dev/null 2>&1 & disown
          printf "echo -markup {green}%s\n" "opened link in default browser"
          exit 0
        ;;

        # if the path is absolute, do nothing. If it is relative, make it relative to the parent directory of buffile
        /*) true ;;
        *) kak_opt_wiki_link_path="$(dirname "$kak_buffile")/$kak_opt_wiki_link_path" ;;
      esac

      # if the file exists, open it with kakoune if it ends with .md, otherwise open it in the default program.
      # if the default program is kakoune, edit it in a new buffer.
      if [ -f "$kak_opt_wiki_link_path" ]; then
        printf "%s\n" "echo -debug 'opening $kak_opt_wiki_link_path'"

        if expr "$kak_opt_wiki_link_path" : '.*\.md' 1>/dev/null; then
          printf "%s\n" "edit '$kak_opt_wiki_link_path'"
        elif [ $(xdg-mime query default $(xdg-mime query filetype "$kak_opt_wiki_link_path")) = kak.desktop ]; then
          printf "%s\n" "edit '$kak_opt_wiki_link_path'"
        else
          nohup xdg-open "$kak_opt_wiki_link_path" >/dev/null 2>&1 & disown
        fi

      # if the file does not exist, open it in kakoune only if it ends with *.md
      else
        case "$kak_opt_wiki_link_path" in
          *.md)
            mkdir -p "$(dirname "$kak_opt_wiki_link_path")"
            printf "%s\n" "edit '$kak_opt_wiki_link_path'"
            printf "%s\n" "echo -markup {green}created new file"
          ;;

          *) printf "%s\n" "fail 'link does not exist and doesn''t match *.md'" ;;
        esac
      fi
    }
  }

  define-command wiki-yank-link -docstring "yank and display the link's value" %{
    wiki-grab-link
    execute-keys -with-hooks ": edit -scratch<ret>i%opt{wiki_link_path}<esc>xHy:db<ret>"
    echo -markup "{green}%opt{wiki_link_path}"
  }

  define-command wiki-make-link -docstring "prompt for a url and create a link with the current selection" %{
    execute-keys %sh{
      if [ "${#kak_selection}" = 1 ]; then
        printf "%s" "<a-i><a-w><esc>"
      fi
    }

    prompt "url: " %{ execute-keys "i[<esc>a](%val{text})<esc>" }
  }

  define-command wiki-inline-link -docstring "turn a reference link to an inline one" %{
    wiki-grab-link
    evaluate-commands %sh{
      if [ "$kak_opt_wiki_link_kind" != reference ]; then
        printf "%s" "fail 'link must be reference'"
      fi
    }

    # delete the reference link
    execute-keys -draft "/\Q[%opt{wiki_link_refid}]: <ret>xd"

    # replace the reference id with the link path
    evaluate-commands -draft %{
      execute-keys "t]ll<a-i>["
      execute-keys -draft "lr)"
      execute-keys -draft "<a-;>hr("
      execute-keys -draft "c%opt{wiki_link_path}<esc>"
    }
  }

  define-command wiki-toggle-checkbox -docstring "toggle a checkbox on and off" %{
    try %{
      evaluate-commands -draft %{
        execute-keys "xs^\h*- \[.\]<ret>h"
        execute-keys %sh{
          if [ "$kak_selection" = " " ]; then
            printf "%s" "rx"
          else
            printf "%s" "r<space>"
          fi
        }
      }
    } catch %{
      fail "no checkbox on this line"
    }
  }
}


# ────────────── keys  ──────────────
hook global BufSetOption filetype=wiki %{
  require-module wiki

  evaluate-commands %sh{
    printf "%s\n" "map buffer normal <tab>   ': wiki-next-link<ret>'"
    printf "%s\n" "map buffer normal <s-tab> ': wiki-prev-link<ret>'"
    printf "%s\n" "map buffer normal <ret>   ': wiki-open-link<ret>'"
    printf "%s\n" "map buffer normal +       ': wiki-yank-link<ret>'"
    printf "%s\n" "map buffer normal <minus> ': wiki-inline-link<ret>'"
    printf "%s\n" "map buffer normal <c-k>   ': wiki-make-link<ret>'"
    printf "%s\n" "map buffer normal ';'     ': wiki-toggle-checkbox<ret>'"
  }

  set-option buffer formatcmd "python3 %opt{wiki_plugin_path}/format.py --format"
}
