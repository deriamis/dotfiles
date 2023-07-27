if [[ $- != *i* ]]; then
    # Shell is non-interactive. Be done now!
    return
fi

if [[ -o login ]]; then
    BASE_SHLVL=$SHLVL
else
    BASE_SHLVL=1
fi

zsh_show_shlvl_color() {
    local -a color=( 'red' 'green' 'yellow' 'blue' 'magenta' 'cyan' 'white')
    local color_id=$(( ($SHLVL - $BASE_SHLVL) % ${#color}))
    echo "${color[$color_id]}"
}

# Set up history
export HISTFILE=~/.zsh_history
export HISTSIZE=100000
export SAVEHIST=100000

# Set shell options
setopt INC_APPEND_HISTORY HIST_IGNORE_DUPS EXTENDED_HISTORY
setopt SHARE_HISTORY BANG_HIST HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS HIST_VERIFY HIST_LEX_WORDS
setopt EXTENDED_GLOB

# Location where to store temporary files specific to zsh
ZSH_CACHE_DIR=~/.cache/zsh

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="mm/dd/yyyy"

# Ensure the completions cache is available
mkdir -p "${ZSH_CACHE_DIR}/completions"

# Clone antidote if necessary.
[[ -e ${ZDOTDIR:-~}/.antidote ]] ||
  git clone https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/.antidote

zsh_plugins=${ZDOTDIR:-~}/.zsh_plugins.zsh

# Ensure the plugins conf exists
[[ -f ${zsh_plugins:r}.conf ]] || touch ${zsh_plugins:r}.conf

# Add completions
fpath+=(~/.asdf/completions ${ZDOTDIR:-~}/.antidote)
autoload -Uz $fpath[-1]/antidote

# Generate static file in a subshell when .zsh_plugins.conf is updated.
if [[ ! $zsh_plugins -nt ${zsh_plugins:r}.conf ]]; then
  (antidote bundle <${zsh_plugins:r}.conf >|$zsh_plugins)
fi

# Initialize antidote
source $zsh_plugins

# Drop-to-bash when needed
bash() {
    env -i \
        ENV_ANONYMIZE=1 \
        HOME="$HOME" \
        LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" \
        PATH="$PATH" \
        USER="$USER" \
        SHELL="$(whence -p bash)" \
        SHLVL=$SHLVL \
        $(whence -p bash) "$@"
}

# Load oh-my-posh
if command -v oh-my-posh &>/dev/null; then
    eval "$(oh-my-posh init zsh --config ~/.poshthemes/powerlevel10k_poweruser.omp.json)"
    eval "$(oh-my-posh completion zsh)"
fi

# Enable iTerm2 integrations
if [[ -e "${HOME}/.iterm2_shell_integration.${SHELL##*/}" ]]; then
  source "${HOME}/.iterm2_shell_integration.${SHELL##*/}"
fi

[[ -r ~/.shell_aliases ]] && source ~/.shell_aliases

