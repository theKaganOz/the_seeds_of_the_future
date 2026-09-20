#!/bin/bash
# Run this from the project root before opening Godot, or instead of typing
# out git pull by hand each time. Doesn't touch Godot itself — just gets
# the repo in sync and reminds you what to do next.

set -e

if ! git diff --quiet || ! git diff --cached --quiet; then
	echo "You have uncommitted local changes. Commit or stash them first:"
	echo "  git add -A && git commit -m \"...\""
	echo "then re-run this script."
	exit 1
fi

echo "Pulling latest..."
git pull

echo ""
echo "Done. If Godot is closed: just open the project normally."
echo "If Godot is already open: Project > Reload Current Project."
