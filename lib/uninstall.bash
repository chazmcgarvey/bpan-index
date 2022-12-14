uninstall:help() (
  cat <<'...'
Uninstall BPAN Packages

# Synopsis

Some 'bpan uninstall ...' commands:

```
$app uninstall getopt-bash
$app uninstall bpan-org/getopt-bash
$app uninstall bpan-org/getopt-bash=0.1.0
$app uninstall github:bpan-org/getopt-bash=0.1.0
```
...
)

uninstall:main() (
  [[ $# -gt 0 ]] ||
    error "'$app $cmd' requires one or more packages"

  source-once bpan/pkg

  for target do
    pkg:parse-id "$target"
    path=$pkg_host/$pkg_owner/$pkg_name/$pkg_version
    name=$pkg_id=$pkg_version
    if [[ -d $BPAN_INSTALL/src/$path ]]; then
      say-y "Uninstalling '$name':"
      uninstall:package "$path" "$name"
    else
      say-r "'$name' is not installed"
    fi
  done
)

uninstall:package() (
  path=$1 name=$2

  cd "$BPAN_INSTALL" || exit

  while read -r line; do
    link=${line%% -> *}
    link=${link##* }
    file=${line##* -> }
    [[ $link ]] || continue
    file=${file##*../src/}
    say -w "- Unlink $link -> $file"
    unlink "$link"
  done <<< "$(
    find bin lib man share -type l -print0 2>/dev/null |
      xargs -r -0 ls -l |
      grep -F "$path"
  )"
  say +w "- Removing package src/$path/"
  rm -fr "src/$path/"

  while true; do
    # shellcheck disable=2046
    set -- $(find bin lib man share src -empty 2>/dev/null)
    [[ $# -gt 0 ]] || break
    rmdir "$@"
  done
)
