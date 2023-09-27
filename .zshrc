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

# Set up RTX (Python, Ruby, Node.js)
if command -v rtx &>/dev/null; then
  _evalcache rtx activate zsh >/dev/null

  # Ruby programming language
  if rtx which ruby &>/dev/null; then
      PATH="$(gem env | grep 'USER INSTALLATION DIRECTORY' | /usr/bin/awk -F': ' '{print $2}')/bin:$PATH"
  fi

  # Perl programming language
  if rtx which perl &>/dev/null; then
    if perl -e "use local::lib" &>/dev/null; then
      _evalcache perl -I ~/perl5/lib/perl5/ -Mlocal::lib >/dev/null
    fi
  fi

  # Erlang
  if rtx which erl &>/dev/null; then
    export KERL_BUILD_DOCS=yes
  fi

# Set up ASDF (Python, Ruby, Node.js)
elif [[ -e ~/.asdf/asdf.sh ]]; then
  source ~/.asdf/asdf.sh

    # Java programming language
    if [[ -d ~/.asdf/plugins/java ]]; then
      source ~/.asdf/plugins/java/set-java-home.zsh
    fi

    # Ruby programming language
    if [[ -d ~/.asdf/plugins/ruby ]]; then
      PATH="$(gem env | grep 'USER INSTALLATION DIRECTORY' | /usr/bin/awk -F': ' '{print $2}')/bin:$PATH"
    fi

    # Perl programming language
    if [[ -d ~/.asdf/plugins/perl ]]; then
      if perl -e "use local::lib" &>/dev/null; then
        _evalcache perl -I ~/perl5/lib/perl5/ -Mlocal::lib >/dev/null
      fi
    fi

    # Erlang
    if [[ -d ~/.asdf/plugins/erlang ]]; then
      export KERL_BUILD_DOCS=yes
    fi
fi

# Load oh-my-posh
if command -v oh-my-posh &>/dev/null; then
    _evalcache oh-my-posh init zsh --config ~/.poshthemes/powerlevel10k_poweruser.omp.json >/dev/null
    _evalcache oh-my-posh completion zsh >/dev/null
fi

# Load rtx completions
if command -v rtx &>/dev/null; then
    _evalcache rtx completion zsh >/dev/null
fi

# Load lefthook completions
if command -v lefthook &>/dev/null; then
    _evalcache lefthook completion zsh >/dev/null
fi

# Load pmv completions
if command -v pmv &>/dev/null; then
    _evalcache pmv completion zsh >/dev/null
fi

# Load k9s completions
if command -v k9s &>/dev/null; then
    _evalcache k9s completion zsh >/dev/null
fi

# Load eksctl completions
if command -v eksctl &>/dev/null; then
    _evalcache eksctl completion zsh >/dev/null
fi

# Load kubectl completions
if command -v kubectl &>/dev/null; then
    _evalcache kubectl completion zsh >/dev/null
fi

# Enable dircolors scheme
if [[ -r ~/.dircolors ]] && command -v dircolors &>/dev/null; then
  _evalcache dircolors -b ~/.dircolors >/dev/null
fi

# Enable iTerm2 integrations
if [[ -e ~/.iterm2_shell_integration.zsh ]]; then
    source ~/.iterm2_shell_integration.zsh >/dev/null
fi

[[ -r ~/.shell_aliases ]] && source ~/.shell_aliases

