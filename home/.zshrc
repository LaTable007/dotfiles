source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# history setup
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

# completion using arrow keys (based on history)
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward


alias ls='eza -1 -a --long --group-directories-first --icons'

# Gruvbox Dark (eza reads ~/.config/eza/theme.yml automatically; EZA_COLORS/LS_COLORS would override it, so none set here)
export FZF_DEFAULT_OPTS='--color=bg+:#3c3836,bg:#32302f,spinner:#fb4934,hl:#928374,fg:#ebdbb2,header:#928374,info:#8ec07c,pointer:#fb4934,marker:#fb4934,fg+:#ebdbb2,prompt:#fb4934,hl+:#fb4934'

# Sans cette ligne, FZF_DEFAULT_OPTS ne sert à rien : les raccourcis Ctrl-R
# (historique) et Ctrl-T (fichiers) ne sont jamais installés.
source <(fzf --zsh)

# --cmd cd remplace cd par zoxide, qui garde le comportement standard quand
# l'argument est un vrai chemin et complète par fréquence sinon.
eval "$(zoxide init zsh --cmd cd)"



export DBUS_SESSION_BUS_ADDRESS="unix:path=$DBUS_LAUNCHD_SESSION_BUS_SOCKET"

export PATH="$HOME/.config/emacs/bin:$PATH"

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# mise n'intercepte que les outils qu'il gère : tant que Python n'y est pas
# déclaré, pyenv continue de s'en occuper et les deux cohabitent sans conflit.
eval "$(mise activate zsh)"

# Wrapper officiel de yazi : sans lui, quitter yazi ramène dans le dossier de
# départ au lieu de celui où l'on a navigué.
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}


fastfetch

eval "$(starship init zsh)"
