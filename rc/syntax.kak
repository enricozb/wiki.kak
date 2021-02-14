provide-module wiki-syntax %{
  declare-option -hidden str wiki_link_regex '[^\]](\[([^\[\n]+)\])(\[[^\]\n]+\]|\([^\)\n]+\))'
  declare-option -hidden str wiki_anchor_regex '[^\]](\[([^\[\n]+)\])[^\[\(:]'
  declare-option -hidden str wiki_reflink_regex '\[[^\n]+\]: [^\n]*\n'


  add-highlighter -override shared/markdown regions

  add-highlighter shared/markdown/inline default-region regions
  add-highlighter shared/markdown/inline/text default-region group

  # code fences
  evaluate-commands %sh{
    languages="
      awk c cabal clojure coffee cpp css cucumber d diff dockerfile fish
      gas go haml haskell html ini java javascript json julia kak kickstart
      latex lisp lua makefile markdown moon objc perl pug python ragel
      ruby rust sass scala scss sh swift toml tupfile typescript yaml sql
    "
    for lang in ${languages}; do
      printf 'add-highlighter shared/markdown/%s region -match-capture ^(\h*)```\h*(%s|\{=%s\}))\\b ^(\h*)``` regions\n' "${lang}" "${lang}" "${lang}"
      printf 'add-highlighter shared/markdown/%s/ default-region fill meta\n' "${lang}"
      [ "${lang}" = kak ] && ref=kakrc || ref="${lang}"
      printf 'add-highlighter shared/markdown/%s/inner region ```\h*(%s|\{=%s\})\\b\K (?=```) ref %s\n' "${lang}" "${lang}" "${lang}" "${ref}"
    done
  }

  add-highlighter shared/markdown/codeblock region -match-capture \
      ^(\h*)```\h* \
      ^(\h*)```\h*$ \
      fill meta

  # header style variations
  add-highlighter shared/markdown/inline/text/ regex ^(#)\h*([^#\n]*) 1:comment 2:rgb:d33682+bu
  add-highlighter shared/markdown/inline/text/ regex ^(##)\h*([^#\n]*) 1:comment 2:rgb:d33682+b
  add-highlighter shared/markdown/inline/text/ regex ^(###[#]*)\h*([^#\n]*) 1:comment 2:rgb:d33682

  # lists
  add-highlighter shared/markdown/inline/text/unordered-list regex ^\h*([-+*])\s 1:bullet
  add-highlighter shared/markdown/inline/text/ordered-list   regex ^\h*(\d+[.)])\s 1:bullet

  # inline code
  add-highlighter shared/markdown/inline/code region ` ` fill string

  # emphasis
  add-markdown-light-emphasis-highlighters *
  add-markdown-light-emphasis-highlighters _
  add-markdown-strong-emphasis-highlighters *
  add-markdown-strong-emphasis-highlighters _

  # reference links
  add-highlighter shared/markdown/inline/text/ regex %opt{wiki_reflink_regex} 0:comment

  # block quotes
  add-highlighter shared/markdown/inline/text/ regex ^\h*(>[^\n]*)+ 0:comment

  # matches [hello](link) and [hello][ref] links
  add-highlighter shared/markdown/inline/text/link regex %opt{wiki_link_regex} 1:comment 2:link 3:comment

  # matches [hello] style anchors
  add-highlighter shared/markdown/inline/text/anchor regex %opt{wiki_anchor_regex} 1:comment 2:value
}

define-command -hidden add-markdown-light-emphasis-highlighters -params 1 %{
  add-highlighter "shared/markdown/inline/light-emphasis%arg{1}" region \
    -recurse "(^|(?<=\s))[%arg{1}][^%arg{1}\s]" \
             "(^|(?<=\s))[%arg{1}](?=[^%arg{1}\s])" \
             "[^%arg{1}\s][%arg{1}]((?=\s)|$)" \
    regions

  add-highlighter "shared/markdown/inline/light-emphasis%arg{1}/inner" default-region fill italic

  # nesting strong emphasis inside of light emphasis
  add-highlighter "shared/markdown/inline/light-emphasis%arg{1}/strong-emphasis" region \
    -match-capture \
    -recurse (?:^|(?<=\s))(\*\*|__)[^_*\s] \
             (?:^|(?<=\s))(\*\*|__)[^_*\s] \
             [^_*\s](\*\*|__)(?:(?=\s)|$) \
    fill bold
}

define-command -hidden add-markdown-strong-emphasis-highlighters -params 1 %{
  add-highlighter "shared/markdown/inline/strong-emphasis%arg{1}" region \
      -recurse "(^|(?<=\s))[%arg{1}]{2}[^%arg{1}\s]" \
               "(^|(?<=\s))[%arg{1}]{2}(?=[^%arg{1}\s])" \
               "[^%arg{1}\s][%arg{1}]{2}((?=\s)|$)" \
    regions

  add-highlighter "shared/markdown/inline/strong-emphasis%arg{1}/inner" default-region fill bold

  # nesting light emphasis inside of strong emphasis
  add-highlighter "shared/markdown/inline/strong-emphasis%arg{1}/light-emphasis" region \
    -match-capture \
    -recurse (?:^|(?<=\s))(\*|_)[^_*\s] \
             (?:^|(?<=\s))(\*|_)[^_*\s] \
             [^_*\s](\*|_)(?:(?=\s)|$) \
    fill italic
}
