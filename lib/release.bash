# TODO redirect from https://bpan.org/release-requests
release_html_index_url=https://github.com/bpan-org/bpan-index
release_api_repo_url=https://api.github.com/repos/bpan-org/bpan-index
release_api_request_url=$release_api_repo_url/issues/1/comments

release:options() (
  echo "c,check     Just run preflight checks. Don't release"
)

release:main() (
  if +in-gha; then
    release:gha-main "$@"
    return
  fi

  release:get-env

  release:check-release

  $option_check && return

  release:trigger-release
)

release:get-env() {
  git:in-repo ||
    error "Not in a git repo"
  [[ -f .bpan/config ]] ||
    error "Not in a BPAN package repo"

  token=$(config:get bpan.user.token) || true
  if [[ -z $token || $token == ___ ]]; then
    error "Missing or invalid bpan.user.token in $BPAN_ROOT/config"
  fi

  url=$(git config remote.origin.url) ||
    error "Can't find 'remote.origin.url' in .git/config"

  regex='^git@github.com:(.+)/(.+)$'
  [[ $url =~ $regex ]] ||
    error "'$url' does not match '$regex'"

  user=${BASH_REMATCH[1]}
  repo=${BASH_REMATCH[2]}
  repo=${repo%.git}

  package=github:$user/$repo

  if [[ $package == github:bpan-org/bpan ]]; then
    error "Can't release '$package'. Not a package."
  fi

  version=$(config:get bpan.version) ||
    error "Can't find 'bpan.version' in .bpan/config"

  [[ $(git tag --list "$version") == "$version" ]] ||
    error "Version '$version' is not a git tag"

  commit=$(git rev-parse "$version")
  [[ ${#commit} -eq 40 ]] ||
    error "Can't get git commit for tag '$version'"

  release_html_package_url=https://github.com/$user/$repo/tree/$version
}

release:check-release() (
  # XXX make various assertions
  # assert config has token

  say -y "Running tests"
  bpan test
  echo
)

release:trigger-release() (
  json="{\
\"package\":\"$package\",\
\"version\":\"$version\",\
\"commit\":\"$commit\"\
}"

  release:post-request "\
<!-- $json -->

##### Requesting BPAN Package Release for [$package $version]\
($release_html_package_url)
<details><summary>Details</summary>

* **Package**: $package
* **Version**: $version
* **Commit**:  $commit
* **Changes**:
$(
  read -r b a <<<"$(
    git config -f Changes --get-regexp '^version.*date' |
      head -n2 |
      cut -d. -f2-4 |
      xargs
  )"
  git log --pretty --format='%s' "$a".."$b"^ |
    xargs -I{} echo '  * {}'
)

</details>
"

  say -g "Release for '$package' version '$version' requested"
  echo
  say -y "  $url"
)

release:post-request() {
  body=$1
  body=${body//$'"'/\\'"'}
  body=${body//$'\n'/\\n}

  url=$(
    $option_verbose && set -x
    curl \
      --silent \
      --request POST \
      --header "Accept: application/vnd.github+json" \
      --header "Authorization: Bearer $token" \
      $release_api_request_url \
      --data "{\"body\":\"$body\",
               \"package\": \"$package\",
               \"version\": \"$version\",
               \"commit\":  \"$commit\"}" |
    grep '"html_url"' |
    head -n1 |
    cut -d'"' -f4
  ) || true

  [[ $url ]] ||
    error "Release request failed"
}



#------------------------------------------------------------------------------
# GHA support
#------------------------------------------------------------------------------

release:gha-main() (
  ok=false

  +trap release:gha-post-status

  release:gha-get-env

  release:gha-check-release

  release:gha-update-index

  ok=true
)

release:gha-get-env() {
  index_file=index.ini

  set -x
  package=$gha_request_package
  version=$gha_request_version
  commit=$gha_request_commit
  comment_body=$gha_event_comment_body

  set +x
  comment_body+="\

* [Review Release and Update Index]($gha_job_html_url)
"
  release:gha-update-comment-body "$comment_body"
  $option_debug && set -x

  if [[ ${BPAN_INDEX_UPDATE_TESTING-} ]]; then
    v=$(git config -f "$index_file" "pkg.$package.version")
    test_version=${v%.*}.$(( ${v##*.} + 1 ))
  fi
}

release:gha-check-release() {
  config=package/.bpan/config
  [[ -f $config ]] ||
    die "Package '$package' has no '.bpan/config' file"

  : "Check new version is greater than indexed one"
  indexed_version=$(git config -f "$index_file" "pkg.$package.version")
  if [[ ${BPAN_INDEX_UPDATE_TESTING-} ]]; then
    +version-gt "$test_version" "$indexed_version" ||
      die "'$package' version '$version' not greater than '$indexed_version'"
  else
    +version-gt "$version" "$indexed_version" ||
      die "'$package' version '$version' not greater than '$indexed_version'"
  fi

  : "Check that requesting user is package author"
  author_github=$(config_file=$config config:get author.github) ||
    die "No author.github entry in '$package' config"
  [[ $author_github == "$gha_triggering_actor" ]] ||
    die "Request from '$triggering_actor' should be from '$author_github'"

  : "Check that request commit matches actual version commit"
  actual_commit=$(git -C package rev-parse "$version") || true
  [[ $actual_commit == "$commit" ]] ||
    die "'$commit' is not the actual commit for '$package' tag '$version'"

  : "Run the package's test suite"
  make -C package test ||
    die "$package v$version failed tests"
}

release:gha-update-index() (
  [[ ${#commit} -eq 40 ]] ||
    die "Can't get commit for '$package' v$version"

  if [[ ${BPAN_INDEX_UPDATE_TESTING-} ]]; then
    git config -f "$index_file" "pkg.$package.version" "$test_version"
    git config -f "$index_file" "pkg.$package.v${test_version//./-}" "$commit"
  else
    git config -f "$index_file" "pkg.$package.version" "$version"
    git config -f "$index_file" "pkg.$package.v${version//./-}" "$commit"
  fi

  perl -pi -e 's/\t//' "$index_file"

  git config user.email "update-index@bpan.org"
  git config user.name "BPAN Update Index"

  git commit -a -m "Update $package=$version"

  git diff HEAD^

  git log -1

  git push
)

# Add the GHA job url to the request comment:
release:gha-update-comment-body() (
  $option_debug &&
    echo "+ release:gha-update-comment-body ..."

  content=$1
  content=${content//\"/\\\"}
  content=${content//$'\n'/\\n}

  curl \
    --silent \
    --request PATCH \
    --header "Accept: application/vnd.github+json" \
    --header "$(git config http.https://github.com/.extraheader)" \
    "$gha_event_comment_url" \
    --data "{\"body\":\"$content\"}" \
  >/dev/null
)


# React thumbs-up or thumbs-down on request comment:
release:gha-post-status() (
  [[ ${gha_event_comment_reactions_url} ]] || return

  set +x
  if $ok; then
    thumb='+1'

    line_num=$(
      git diff HEAD^ |
        grep '@' |
        head -n1 |
        cut -d+ -f2 |
        cut -d, -f1
    )
    line_num=$(( ${line_num:-0} + 1 ))

    comment_body+="\
* [Release Successful - \
Index Updated]($release_html_index_url/blob/main/index.ini#L$line_num)
"
  else
    thumb='-1'
    comment_body+="\
* [Release Failed - See Logs]($gha_job_html_url)
"
  fi

  release:gha-update-comment-body "$comment_body"
  $option_debug && set -x

  auth_header=$(
    git config http.https://github.com/.extraheader
  )

  curl \
    --silent \
    --request POST \
    --header "Accept: application/vnd.github+json" \
    --header "$(git config http.https://github.com/.extraheader)" \
    "$gha_event_comment_reactions_url" \
    --data "{\"content\":\"$thumb\"}" \
  >/dev/null
)