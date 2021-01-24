import argparse
import re
import sys

def parse_args():
  parser = argparse.ArgumentParser()
  group = parser.add_mutually_exclusive_group()
  group.add_argument("--format", action="store_true")

  return parser.parse_args()


def format_links():
  link_reference_pattern = re.compile(r'^\[([^\n]+)\]: ([^\n]*)$')
  link_pattern = re.compile(r'\[([^\[]+)\](\[([^\]]+)\]|\(([^\)]+)\))')

  rel_links = {}

  lines = []
  links = []
  count = 1

  for line in sys.stdin:
    # if this line is a reference link, we shouldn't print it back out.
    reference_match = link_reference_pattern.match(line)
    if reference_match:
      rel_links[reference_match.group(1)] = reference_match.group(2)
      continue

    # this stores information about links on this line
    positions = []

    for match in link_pattern.finditer(line):
      name, _, rel_link, abs_link = match.groups()
      kind = 'rel' if rel_link else 'abs'

      positions.append(match.span() + (name, count))
      if kind == 'rel':
        links.append((kind, rel_link))
      else:
        links.append((kind, abs_link))

      count += 1

    line_chars = list(line)
    for (start, end, name, link_id) in reversed(positions):
      line_chars[start:end] = list("[{}][{}]".format(name, link_id))

    lines.append("".join(line_chars))

  print("".join(lines), end="")

  if links:
    # Add a newline if the last line is not whitespace
    if lines[-1].strip() != "":
      print()
    i = 1
    for kind, link in links:
      if kind == 'rel':
        print("[{}]: {}".format(i, rel_links[link]))
      else:
        print("[{}]: {}".format(i, link.strip()))
      i += 1


def main():
  args = parse_args()

  if args.format:
    format_links()


if __name__ == "__main__":
  main()
