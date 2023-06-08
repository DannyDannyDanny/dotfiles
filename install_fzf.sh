#!/bin/bash

# Install fzf
echo >&2 "====================================================================="
echo >&2 " >> installing fzf"
FZF_VERSION=0.40.0
curl -L https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz | tar xzC /bin
