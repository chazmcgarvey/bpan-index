bpan-index
==========

The [BPAN](https://github.com/bpan-org/bpan#readme) Package Index


## Synopsis

This video shows how a BPAN publish is done from the command line.
The ([`bashplus` package](https://github.com/bpan-org/bashplus#bashplus))
author runs:

* `bpan bump --push` - Prepare/Push BPAN package's the next version
* `bpan publish` - Submit the new version to the BPAN Index updater
* A comment is posted to [this GitHub issue](
  https://github.com/bpan-org/bpan-index/issues/1)
* That triggers a [GitHub Actions workflow](
  https://github.com/bpan-org/bpan-index/actions/runs/3119660793/jobs/5059761235)
  to:
  * Verify that the BPAN Package is OK
  * If OK, update the [BPAN Index](
    https://github.com/bpan-org/bpan-index/blob/main/index.ini)
  * Notify the author of Success 👍 or Failure 👎
* This actual [`bashplus` 0.1.17](
  https://github.com/bpan-org/bashplus/tree/0.1.17) publish is logged [here](
  https://github.com/bpan-org/bpan-index/issues/1#issuecomment-1257059529)

![BPAN Publish Flow](img/bpan-publish.gif)


## Description

This repo contains the [BPAN Package Index](
https://github.com/bpan-org/bpan-index/blob/main/index.ini) that BPAN uses to
find its packages, and the [BPAN Author Index](
https://github.com/bpan-org/bpan-index/blob/main/author.ini) of registered BPAN
package authors.

It also contains the GHA workflows that manage the updating of the indexes.

The BPAN Index is how the BPAN CLI client finds BPAN packages to for people to
install.


## Registration

Register and Publish requests are posted by the BPAN CLI commands:

* bpan register --author    Register to become a BPAN author
* bpan register --package   Register a new package (first publish)
* bpan publish              Publish subsequent BPAN package versions

Package Registration is a one time event for each new author and package.
It submits a Pull Request to this repository and you'll need to wait for a
maintainer to merge it.

Package Publishing on the other hand is fully automated by GitHub Actions.
When you run `bpan publish` it will:

* Check to make sure your package looks good
* Issue a triggering comment
* Print the URL to the comment so you can watch and wait
* Trigger a GitHub Actions workflow
* This will do more checks on your package
* If the package looks good it will update the BPAN index
* If not, you can follow a link to the log to see what's up
* In either case you should be notified of the result


## Testing 'bpan register' and 'bpan publish'

To set up a BPAN Publishing Testing Environment:

* Fork the 'bpan-org/bpan' repo to '<user>'
  * Clone the forked 'bpan' repo
  * Run 'source bpan/.rc' to use 'bpan' from the fork
  * bpan config --global index.bpan.repo-url https://github.com/<user>/bpan-index

* Copy this repo (bpan-org/bpan-index) repo to '<user>/bpan-index'
  * Note: You can't "fork" this repo because forks can't use GitHub Issues
* Create a GitHub Issue #1 for the copied bpan-index repo

* In a BPAN package directory:
  * Make a change and commit it
  * bpan bump --publish


## Copyright and License

Copyright 2022 by Ingy döt Net

This is free software, licensed under:

The MIT (X11) License
