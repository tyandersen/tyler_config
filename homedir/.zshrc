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

# SSH agent: start if needed, keep symlink stable for tmux
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval $(ssh-agent -s) > /dev/null
    ssh-add 2> /dev/null
fi
if [ -n "$SSH_AUTH_SOCK" ] && [ "$SSH_AUTH_SOCK" != "$HOME/.ssh/auth_sock" ]; then
    ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/auth_sock"
fi
export SSH_AUTH_SOCK="$HOME/.ssh/auth_sock"

# Claude is here
export PATH="$HOME/.local/bin:$PATH"
