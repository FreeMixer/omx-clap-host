#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# The README is the pitch and the install from the packages; how to build from source is BUILDING.md's. Every command the
# README shows (a fenced or indented block, an inline `span`) is read, and one that builds is refused.
#   readme-build.sh <README.md> <BUILDING.md>
set -eu
export LC_ALL=C

readme=$1
building=$2

# the commands a document shows, one per line: fenced and indented blocks, then every inline span, a leading $ or sudo dropped
commands() {
    awk '
        /^[ \t]*```/ { fenced = !fenced; next }
        fenced || /^(    |\t)/ { print; next }
        { line = $0; while (match(line, /`[^`]+`/)) { print substr(line, RSTART + 1, RLENGTH - 2); line = substr(line, RSTART + RLENGTH) } }
    ' "$1" | sed -e 's/^[[:space:]]*//' -e 's/^\$[[:space:]]*//' -e 's/^sudo[[:space:]]*//'
}
builds='^(make|gmake|meson|cmake|ninja|rpmbuild|dpkg-buildpackage|debuild|\./configure|autoreconf|(cc|gcc|clang)[[:space:]]|(p?npm|yarn)[[:space:]]+(run[[:space:]]+)?build|cargo[[:space:]]+build)([[:space:]]|$)'

# a control that can see presence: the build has its home, and the pattern finds it there, or a clean README proves nothing
commands "$building" | grep -E -q "$builds" || { echo "FAIL $building shows no build command: the check could not see one"; exit 1; }

found=$(commands "$readme" | grep -E "$builds" || true)
[ -z "$found" ] || { echo "$found"; echo "FAIL $readme shows a build command; it belongs in $building"; exit 1; }
echo "ok   $readme shows no build command, $building does"
