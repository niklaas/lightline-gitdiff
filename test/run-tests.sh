#!/usr/bin/env sh

DIR=$(dirname "$0")
cd "$DIR" || exit

vim -Nu vimrc -Es -c 'Vader! *'
