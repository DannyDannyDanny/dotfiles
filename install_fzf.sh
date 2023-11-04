#!/bin/bash
set -e
FZF_VERSION=0.40.0

# Install fzf
echo >&2 "====================================================================="
echo >&2 " >> installing fzf"
echo >&2 " >>> downloading"
curl -LO https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz

echo >&2 " >>> extracting"
tar xfv fzf-${FZF_VERSION}-linux_amd64.tar.gz

echo >&2 " >>> moving fzf to /bin"
sudo mv fzf /bin
