#!/usr/bin/env bash

# GHA local composite action to parse the BPAN index update request's JSON
# into output variables for use by other workflow steps.

json=$(
  echo "$gha_event_comment_body" |
    head -n1 |
    perl -pe 's/^<!--\s*(.*)\s*-->$/$1/
                or die "Bad JSON in request comment:\n$_"' |
    jq .
)

package=$(jq -r .package <<< "$json")
version=$(jq -r .version <<< "$json")
commit=$( jq -r .commit  <<< "$json")

name=${package#github:}
owner=${name%%/*}
repo=${name#*/}

echo "::set-output name=package::$package"
echo "::set-output name=owner::$owner"
echo "::set-output name=repo::$repo"
echo "::set-output name=version::$version"
echo "::set-output name=commit::$commit"
