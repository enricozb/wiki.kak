declare-option -hidden str markdown_format_file %sh{
  printf %s "python3 $(dirname $kak_source)/format.py --format"
}

hook global WinSetOption filetype=markdown %{
  require-module markdown-wiki
}

# hook global BufCreate .*[.](markdown|md|mkd|yuml) %{
#   map buffer normal <tab> ': markdown-navigate-links n<ret>'
#   map buffer normal <s-tab> ': markdown-navigate-links <lt>a-n<gt><ret>'
#   map buffer normal <ret> ': markdown-follow-link<ret>'

#   map buffer user T -docstring "insert today's iso date" 'i## <esc>! date -I<ret>'
#   map buffer user d -docstring "wiki diary index" ': markdown-diary<ret>'
#   map buffer user f -docstring "format selected text" '| fmt -w 88 -g 86<ret>'

#   map buffer normal + ': markdown-show-link<ret>' -docstring 'display hovered link'
#   map buffer normal <c-k> ': markdown-make-link<ret>'

#   set-option buffer formatcmd %opt{markdown_format_file}
# }

provide-module markdown-wiki %{
  # require-module markdown-syntax

  declare-option -hidden str markdown_diary_dir "logs/diary"
  declare-option -hidden str markdown_link_to_follow ""
  declare-option -hidden str markdown_link_line ""
  declare-option -hidden bool markdown_reference_link false
  declare-option -hidden bool markdown_at_root true

  # navigate links
  define-command -hidden -params 1 markdown-navigate-links %{
    evaluate-commands -no-hooks -save-regs / %{
      set-register / "(%opt{wiki_anchor_regex}|%opt{wiki_link_regex})"
      execute-keys "%arg{1}<a-;>ll"
  }}

  # if `markdown_link_to_follow` refers to a reference link id, then set
  # `markdown_link_to_follow to the link that it refers to
  define-command -hidden markdown-grab-reference-link %{
    evaluate-commands -draft -no-hooks -save-regs / %{

      set-register / "^\[%opt{markdown_link_to_follow}\]: ([^\n]*)"
      try %{
        execute-keys 'n'
      } catch %{
        fail "the link id '%opt{markdown_link_to_follow}' does not exist"
      }

      # select the link, save it
      execute-keys 'ghf:wwGl'
      set-option buffer markdown_link_to_follow "%reg{.}"
  }}

  define-command -hidden markdown-grab-link %{ evaluate-commands %{
    evaluate-commands -draft %{
      execute-keys 'x'
      set-option buffer markdown_link_line "%val{selection}"
    }

    # TODO: don't rely on perl...
    # this sets `markdown_link_to_follow` to the id of a link [test][1] -> 1
    # otherwise it sets it to an empty string
    set-option buffer markdown_link_to_follow %sh{
      echo -e "$kak_cursor_column\n$kak_opt_markdown_link_line" | \
      perl -e '
        my $cursor = <STDIN>;
        my $line = <STDIN>;
        while ( $line =~ /(\[[^\[]+\])(\[([^\]]+)\]|\(([^\)]+)\))/g ) {
          if (($-[1] <= $cursor - 1) && ($cursor - 1 < $+[1])) {
            if ($3 ne "") {
              print "reference:$3";
            } else {
              print "absolute:$4";
            }
          }
        }'

    }

    evaluate-commands %sh{
      if [ -z "$kak_opt_markdown_link_to_follow" ]; then
        echo "fail not a valid link"
      elif [[ "$kak_opt_markdown_link_to_follow" =~ ^reference:(.+)$ ]]; then
        echo "set-option buffer markdown_reference_link true"
        echo "set-option buffer markdown_link_to_follow '${BASH_REMATCH[1]}'"
      elif [[ "$kak_opt_markdown_link_to_follow" =~ ^absolute:(.+)$ ]]; then
        echo "set-option buffer markdown_reference_link false"
        echo "set-option buffer markdown_link_to_follow '${BASH_REMATCH[1]}'"
      else
        echo "fail 'got bad ref/abs link: $kak_opt_markdown_link_to_follow'"
      fi
    }

    # if the link is reference, replace `markdown_link_to_follow` with the
    # correct destination
    evaluate-commands %sh{
      if "$kak_opt_markdown_reference_link"; then
        echo "markdown-grab-reference-link"
      fi
    }
  }}

  define-command -hidden markdown-show-link %{ evaluate-commands %{
    markdown-grab-link
    # copy the link that's being shown
    execute-keys -with-hooks ":edit -scratch<ret>i%opt{markdown_link_to_follow}<esc>xHy:db<ret>"
    echo -markup "{green}%opt{markdown_link_to_follow}"
  }}

  define-command -hidden markdown-follow-link %{ evaluate-commands %{
    write

    markdown-grab-link

    # follow the link, which is either a website or a file
    evaluate-commands %sh{
      if [[ "$kak_opt_markdown_link_to_follow" =~ ^http* ]]; then
        nohup brave "$kak_opt_markdown_link_to_follow" >/dev/null 2>&1 & disown
        echo "echo -markup {green}[opened link in browser]"
      elif [[ "$kak_opt_markdown_link_to_follow" =~ .*\.(md|yml) ]]; then
        case "$kak_opt_markdown_link_to_follow" in
          /*) newfile="$kak_opt_markdown_link_to_follow" ;;
          *) newfile="${kak_buffile%/*.md}/$kak_opt_markdown_link_to_follow" ;;
        esac
        if [[ ! -f "$newfile" ]]; then
          mkdir -p "${newfile%/*.md}"
          made_new_dir=true
        fi
        echo "edit '$newfile'"
        if [ "$made_new_dir" = true ]; then
          echo "echo -markup {green}[made new file]"
        fi
        echo "set-option buffer markdown_at_root false"
      elif [[ "$kak_opt_markdown_link_to_follow" =~ \.html$ ]]; then
        case "$kak_opt_markdown_link_to_follow" in
          /*) newfile="$kak_opt_markdown_link_to_follow" ;;
          *) newfile="${kak_buffile%/*.md}/$kak_opt_markdown_link_to_follow" ;;
        esac
        nohup brave "$newfile" >/dev/null 2>&1 & disown
        echo "echo -markup {green}[opened html file in browser]"
      else
        nohup xdg-open "${kak_buffile%/*.md}/$kak_opt_markdown_link_to_follow" >/dev/null 2>&1 & disown
        echo "echo -markup {green}[opened file in default program]"
      fi
    }
  }}

  define-command -hidden markdown-diary %{ evaluate-commands %{
    edit "~/wiki/%opt{markdown_diary_dir}/diary.md"
    set-option buffer markdown_at_root false
  }}

  define-command markdown-make-link %{ evaluate-commands %{
    execute-keys %sh{
      if [ ${#kak_selection} = 1 ]; then
        printf "%s" "<a-i><a-w><esc>"
      fi
    }

    prompt "url: " %{
      execute-keys "i[<esc>a](%val{text})<esc>"
    }
  }}
}
