#!/usr/bin/env bash

source test/init

P=test/bin-pkg-bash
rm -fr "$P"

quiet=()
quiet=(--quiet)

test-create-package() {
  local dir=$1

  note "mkdir '$dir' && cd '$dir' && bpan --quiet init --bin --config=Meta"
  (
    mkdir -p "$dir"
    cd "$dir" || exit
    bpan "${quiet[@]}" init --bin --config=Meta
  )
}

test-create-package "$P"

cd "$P" || exit

git add .
git commit --quiet --message='First commit'

old_version=$(bpan config package.version)

is "$old_version" 0.0.0 \
  "Initial version is %W"

bpan "${quiet[@]}" bump >/dev/null

new_version=$(bpan config package.version)

is "$new_version" 0.1.0 \
  "Bumped version is %W"

ok "$(! grep -q $'\t' .bpan/config)" \
  "Config file has no tab characters"

echo >> License
git commit --quiet --all --message='Add a line to License file'

bpan "${quiet[@]}" bump >/dev/null

new_version=$(bpan config package.version)

is "$new_version" 0.1.1 \
  "Bumped version is %W"

ok "$(! grep -q $'\t' .bpan/config)" \
  "Config file has no tab characters"

done-testing
