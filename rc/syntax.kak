provide-module wiki-syntax %{
  declare-option -hidden str wiki_link_regex '[^\]](\[([^\[\n]+)\])(\[[^\]\n]+\]|\([^\)\n]+\))'
  declare-option -hidden str wiki_anchor_regex '[^\]](\[([^\[\n]+)\])[^\[\(:]'
  declare-option -hidden str wiki_reflink_regex '\[[^\n]+\]: [^\n]*\n'


  add-highlighter shared/wiki regions

  add-highlighter shared/wiki/inline default-region regions
  add-highlighter shared/wiki/inline/text default-region group

  # code fences
  evaluate-commands %sh{
    languages="
      awk c cabal clojure coffee cpp css cucumber d diff dockerfile fish
      gas go haml haskell html ini java javascript json julia kak kickstart
      latex lisp lua makefile wiki moon objc perl pug python ragel
      ruby rust sass scala scss sh swift toml tupfile typescript yaml sql
    "
    for lang in ${languages}; do
      printf 'add-highlighter shared/wiki/%s region -match-capture ^(\h*)```\h*(%s|\{=%s\}))\\b ^(\h*)``` regions\n' "${lang}" "${lang}" "${lang}"
      printf 'add-highlighter shared/wiki/%s/ default-region fill meta\n' "${lang}"
      [ "${lang}" = kak ] && ref=kakrc || ref="${lang}"
      printf 'add-highlighter shared/wiki/%s/inner region ```\h*(%s|\{=%s\})\\b\K (?=```) ref %s\n' "${lang}" "${lang}" "${lang}" "${ref}"
    done
  }

  add-highlighter shared/wiki/codeblock region -match-capture \
      ^(\h*)```\h* \
      ^(\h*)```\h*$ \
      fill meta

  # header style variations
  add-highlighter shared/wiki/inline/text/ regex ^(#)\h*([^#\n]*) 1:comment 2:rgb:d33682+bu
  add-highlighter shared/wiki/inline/text/ regex ^(##)\h*([^#\n]*) 1:comment 2:rgb:d33682+b
  add-highlighter shared/wiki/inline/text/ regex ^(###[#]*)\h*([^#\n]*) 1:comment 2:rgb:d33682

  # lists
  add-highlighter shared/wiki/inline/text/unordered-list regex ^\h*([-+*])\s 1:bullet
  add-highlighter shared/wiki/inline/text/ordered-list   regex ^\h*(\d+[.)])\s 1:bullet

  # inline code
  add-highlighter shared/wiki/inline/code region ` ` fill string

  # emphasis
  add-wiki-light-emphasis-highlighters *
  add-wiki-light-emphasis-highlighters _
  add-wiki-strong-emphasis-highlighters *
  add-wiki-strong-emphasis-highlighters _

  # reference links
  add-highlighter shared/wiki/inline/text/ regex %opt{wiki_reflink_regex} 0:comment

  # block quotes
  add-highlighter shared/wiki/inline/text/ regex ^\h*(>[^\n]*)+ 0:comment

  # matches [hello](link) and [hello][ref] links
  add-highlighter shared/wiki/inline/text/link regex %opt{wiki_link_regex} 1:comment 2:link 3:comment

  # matches [hello] style anchors
  add-highlighter shared/wiki/inline/text/anchor regex %opt{wiki_anchor_regex} 1:comment 2:value
}

define-command -hidden add-wiki-light-emphasis-highlighters -params 1 %{
  add-highlighter "shared/wiki/inline/light-emphasis%arg{1}" region \
    -recurse "(^|(?<=\s))[%arg{1}][^%arg{1}\s]" \
             "(^|(?<=\s))[%arg{1}](?=[^%arg{1}\s])" \
             "[^%arg{1}\s][%arg{1}]((?=\s)|$)" \
    regions

  add-highlighter "shared/wiki/inline/light-emphasis%arg{1}/inner" default-region fill italic

  # nesting strong emphasis inside of light emphasis
  add-highlighter "shared/wiki/inline/light-emphasis%arg{1}/strong-emphasis" region \
    -match-capture \
    -recurse (?:^|(?<=\s))(\*\*|__)[^_*\s] \
             (?:^|(?<=\s))(\*\*|__)[^_*\s] \
             [^_*\s](\*\*|__)(?:(?=\s)|$) \
    fill bold
}

define-command -hidden add-wiki-strong-emphasis-highlighters -params 1 %{
  add-highlighter "shared/wiki/inline/strong-emphasis%arg{1}" region \
      -recurse "(^|(?<=\s))[%arg{1}]{2}[^%arg{1}\s]" \
               "(^|(?<=\s))[%arg{1}]{2}(?=[^%arg{1}\s])" \
               "[^%arg{1}\s][%arg{1}]{2}((?=\s)|$)" \
    regions

  add-highlighter "shared/wiki/inline/strong-emphasis%arg{1}/inner" default-region fill bold

  # nesting light emphasis inside of strong emphasis
  add-highlighter "shared/wiki/inline/strong-emphasis%arg{1}/light-emphasis" region \
    -match-capture \
    -recurse (?:^|(?<=\s))(\*|_)[^_*\s] \
             (?:^|(?<=\s))(\*|_)[^_*\s] \
             [^_*\s](\*|_)(?:(?=\s)|$) \
    fill italic
}
