# TODO:
#   add functions that format and unformat reference links
#   add per-link functionality, to swap it's reference and absolute form
#   copy reference link functionality

declare-option -hidden str markdown_format_file %sh{
  printf %s "python3 $(dirname $kak_source)/markdown_links.py --format"
}

hook global WinSetOption filetype=markdown %{
  require-module markdown-wiki
}

hook global BufCreate .*[.](markdown|md|mkd) %{
  map buffer normal <tab> ': markdown-navigate-links n<ret>'
  map buffer normal <s-tab> ': markdown-navigate-links <lt>a-n<gt><ret>'
  map buffer normal <ret> ': markdown-follow-link<ret>'
  map buffer normal <backspace> ': markdown-unfollow-link<ret>'

  map buffer user T -docstring "insert today's iso date" 'i## <esc>! date -I<ret>'
  map buffer user d -docstring "wiki diary index" ': markdown-diary<ret>'
  map buffer user f -docstring "format selected text" '| fmt -w 90 -g 88<ret>'

  map buffer normal + ': markdown-show-link<ret>' -docstring 'display hovered link'
  map buffer normal <c-k> ': markdown-make-link<ret>'

  set-option buffer formatcmd %opt{markdown_format_file}
}

provide-module markdown-wiki %{ evaluate-commands -no-hooks %{
  declare-option -hidden str markdown_diary_dir "logs/diary"
  declare-option -hidden str markdown_link_to_follow ""
  declare-option -hidden str markdown_link_line ""
  declare-option -hidden bool markdown_reference_link false
  declare-option -hidden bool markdown_at_root true

  declare-option -hidden str markdown_reference_link_regex \
    '\[[^\n]+\]: [^\n]*\n'
  declare-option -hidden str markdown_link_regex \
    '[^\]](\[([^\[\n]+)\])(\[[^\]\n]+\]|\([^\)\n]+\))'
  declare-option -hidden str markdown_anchor_regex \
    '[^\]](\[([^\[\n]+)\])[^\[\(:]'

  # fix _ * highlighters
  remove-highlighter shared/markdown/inline/text/regex_^\[[^\]\n]*\]:\h*([^\n]*)_1:link
  remove-highlighter shared/markdown/inline/text/regex_(?<!\*)(\*([^\s*]|([^\s*](\n?[^\n*])*[^\s*]))\*)(?!\*)_1:italic
  remove-highlighter shared/markdown/inline/text/regex_(?<!_)(_([^\s_]|([^\s_](\n?[^\n_])*[^\s_]))_)(?!_)_1:italic
  remove-highlighter shared/markdown/inline/text/regex_(?<!\*)(\*\*([^\s*]|([^\s*](\n?[^\n*])*[^\s*]))\*\*)(?!\*)_1:bold
  remove-highlighter shared/markdown/inline/text/regex_(?<!_)(__([^\s_]|([^\s_](\n?[^\n_])*[^\s_]))__)(?!_)_1:bold

  add-highlighter shared/markdown/inline/text/ regex \s(?<!\*)(\*([^\s*]|([^\s*](\n?[^\n*])*[^\s*]))\*)(?!\*)\s 1:italic
  add-highlighter shared/markdown/inline/text/ regex \s(?<!_)(_([^\s_]|([^\s_](\n?[^\n_])*[^\s_]))_)(?!_)\s 1:italic
  add-highlighter shared/markdown/inline/text/ regex \s(?<!\*)(\*\*([^\s*]|([^\s*](\n?[^\n*])*[^\s*]))\*\*)(?!\*)\s 1:bold
  add-highlighter shared/markdown/inline/text/ regex \s(?<!_)(__([^\s_]|([^\s_](\n?[^\n_])*[^\s_]))__)(?!_)\s 1:bold

  # header style variations
  add-highlighter shared/markdown/inline/text/ regex ^#\h*([^#\n]*) 1:rgb:d33682+bu
  add-highlighter shared/markdown/inline/text/ regex ^##\h*([^#\n]*) 1:rgb:d33682+b
  add-highlighter shared/markdown/inline/text/ regex ^###[#]*\h*([^#\n]*) 1:rgb:d33682

  # block quotes
  add-highlighter shared/markdown/inline/text/ regex ^\h*(>[^\n]*)+ 0:comment

  # listblock marker fix for links immediately following a list bullet
  remove-highlighter shared/markdown/listblock/marker
  add-highlighter shared/markdown/listblock/marker region \A [-*] fill bullet

  # matches [hello](link) and [hello][ref] links
  add-highlighter shared/markdown/inline/text/link regex \
    %opt{markdown_link_regex} 1:comment 2:link 3:comment

  # matches [hello] style anchors
  add-highlighter shared/markdown/inline/text/anchor regex \
    %opt{markdown_anchor_regex} 1:comment 2:value

  # matches reference links
  add-highlighter shared/markdown/inline/text/ regex \
    %opt{markdown_reference_link_regex} 0:comment

  # navigate links
  define-command -hidden -params 1 markdown-navigate-links %{
    evaluate-commands -no-hooks -save-regs / %{
      set-register / "(%opt{markdown_anchor_regex}|%opt{markdown_link_regex})"
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
      set-option buffer markdown_link_line %val{selection}
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
        echo "set-option buffer markdown_link_to_follow ${BASH_REMATCH[1]}"
      elif [[ "$kak_opt_markdown_link_to_follow" =~ ^absolute:(.+)$ ]]; then
        echo "set-option buffer markdown_reference_link false"
        echo "set-option buffer markdown_link_to_follow ${BASH_REMATCH[1]}"
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
      elif [[ "$kak_opt_markdown_link_to_follow" =~ .*\.md ]]; then
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

  define-command -hidden markdown-unfollow-link %{ evaluate-commands %sh{
    echo "write -sync"
    if [ "$kak_opt_markdown_at_root" == "true" ]; then
      echo "quit"
    else
      echo "delete-buffer"
    fi
  }}

  define-command -hidden markdown-diary %{ evaluate-commands %{
    edit "~/wiki/%opt{markdown_diary_dir}/diary.md"
    set-option buffer markdown_at_root false
  }}

  define-command markdown-format %{ evaluate-commands -draft %{
    execute-keys '%|python3 ~/.config/kak/markdown_links.py --format<ret>'
  }}

  define-command markdown-make-link %{ evaluate-commands %{
    execute-keys <a-i><a-w><esc>
    prompt "url: " %{
      execute-keys "i[<esc>a](%val{text})<esc>"
    }
  }}
}}
