source ~/.zsh-prompt
autoload -Uz compinit && compinit -u

WORDCHARS=${WORDCHARS//\/}

export PATH="/opt/homebrew/bin:$PATH"


alias perl="arch -arm64 /usr/bin/perl"
alias ls='ls -G'
alias java_jre='/Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin/Contents/Home/bin/java'
alias grep='grep --color'
