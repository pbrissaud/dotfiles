autoload -Uz compinit
compinit

# pkg:kubernetes-cli
source <(kubectl completion zsh)
# pkg:helm
source <(helm completion zsh)
# pkg:argocd
source <(argocd completion zsh)
# pkg:gh
source <(gh completion -s zsh)

# pkg:go
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$(go env GOPATH):$PATH

# --- Git Aliases ---
alias gs="git status"
alias gcm="git commit -m"
alias lm="git checkout main && git pull"
alias gp="git pull && git push"
alias ulc='git reset --soft HEAD~1'
alias gst="git stash"
alias pop="git stash pop"
alias gstapp="git stash apply"

# pkg:bat
alias cat="bat"

# --- Git Diff with FZF ---
# pkg:fzf
fd() {
  preview="git diff $@ --color=always -- {-1}"
  git diff $@ --name-only | fzf -m --ansi --preview $preview
}
alias gd="fd"

source $HOME/.zsh_override.zsh

# pkg:zsh-autosuggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# pkg:starship
eval "$(starship init zsh)"