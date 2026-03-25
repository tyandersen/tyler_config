source ~/.zsh-prompt
autoload -Uz compinit && compinit -u

WORDCHARS=${WORDCHARS//\/}

export PATH="/opt/homebrew/bin:$PATH"

# This might be hold-over cruft from the previous intel (before apple silicon)
alias perl="arch -arm64 /usr/bin/perl"

alias ls='ls -G'

# Tihs might be completely outdated and unnecessary. Verify
alias java_jre='/Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin/Contents/Home/bin/java'

alias grep='grep --color'
