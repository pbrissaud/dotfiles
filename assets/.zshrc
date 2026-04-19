autoload -Uz compinit
compinit

# pkg:brew=kubernetes-cli
source <(kubectl completion zsh)
# pkg:brew=helm
source <(helm completion zsh)
# pkg:brew=argocd
source <(argocd completion zsh)
# pkg:brew=gh
source <(gh completion -s zsh)

export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# --- Git Aliases ---
alias gs="git status"
alias gcm="git commit -m"
alias gco="git checkout"
alias lm="git checkout main && git pull --rebase"
alias gp="git push"
alias gpr="git pull --rebase"
alias gcb="git checkout -b"
alias ulc='git reset --soft HEAD~1'
alias gst="git stash"
alias pop="git stash pop"
alias gstapp="git stash apply"

# pkg:brew=bat
alias cat="bat"

# --- Git Diff with FZF ---
# pkg:brew=fzf
fd() {
  preview="git diff $@ --color=always -- {-1}"
  git diff $@ --name-only | fzf -m --ansi \
    --preview "$preview" \
    --header 'Ctrl-A: stage | Ctrl-R: unstage | Tab: multi-select' \
    --bind "ctrl-a:execute-silent(git add {+})+reload(git diff $@ --name-only)" \
    --bind "ctrl-r:execute-silent(git restore --staged {+})+reload(git diff $@ --name-only)"
}
alias gd="fd"

source $HOME/.zsh_override.zsh

# pkg:brew=zsh-autosuggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
bindkey '^[[1;3C' forward-word

# pkg:brew=mise
eval "$(mise activate zsh)"

# pkg:brew=starship
eval "$(starship init zsh)"
