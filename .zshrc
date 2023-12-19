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
      HOME="${HOME}" \
      LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" \
      PATH="/usr/local/bin:/usr/bin${_PATH+:$_PATH}" \
      MANPATH="/usr/share/man:/usr/local/share/man${_MANPATH+:$_MANPATH}:" \
      INFOPATH="/usr/share/info:/usr/local/share/info${_INFOPATH+:$_INFOPATH}" \
      USER="${USER}" \
      SHELL="$(whence -p bash)" \
      SHLVL=$(( SHLVL - 1 )) \
      TERM="${TERM}" \
      $(whence -p bash) "$@"
}

# Add homedir binaries to $PATH
[[ -d ~/bin ]] && PATH="$HOME/bin:$PATH"
[[ -d ~/.local/bin ]] && PATH="$HOME/.local/bin:$PATH"

# Set up RTX (Python, Ruby, Node.js)
if command -v rtx &>/dev/null; then
  _evalcache rtx activate zsh >/dev/null
  _evalcache rtx completion zsh >/dev/null

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

  # Set up the GO programming language
  if rtx which go &>/dev/null; then
    export GOPATH="${HOME}/go"
    export GOBIN="${HOME}/.local/share/go/bin"
    [[ -d ${GOPATH}/bin ]] && PATH="${GOPATH}/bin:${PATH}"
    [[ -d ${GOBIN} ]] && PATH="${GOBIN}:${PATH}"
  fi

  # Erlang
  if rtx which erl &>/dev/null; then
    export KERL_BUILD_DOCS=yes
  fi

  # NeoVim
  if rtx which nvim &>/dev/null; then
    alias vim='nvim'
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

# Initialize the Fuzzy Finder
if [[ -f ~/.fzf.zsh ]]; then
  source ~/.fzf.zsh
fi

# Enable iTerm2 integrations
if [[ -e ~/.iterm2_shell_integration.zsh ]]; then
    source ~/.iterm2_shell_integration.zsh >/dev/null
fi

# Set up GPG SSH Agent
if [[ $(uname -s) == Darwin ]]; then
  export SSH_AUTH_SOCK="${HOME}/.ssh/agent.sock"
else
  GPG_TTY="$(tty)"
  SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  export GPG_TTY SSH_AUTH_SOCK
  gpgconf --launch gpg-agent
fi

# Set up Teleport
if command -v tsh &>/dev/null; then
  export TELEPORT_ADD_KEYS_TO_AGENT=no
fi

# Add .NET to $PATH
if command -v dotnet &>/dev/null; then
  DOTNET_BIN=$(which dotnet)
  export DOTNET_ROOT="${DOTNET_BIN%/bin/*}"
  if [[ -d ~/.dotnet/tools ]]; then
    PATH="${HOME}/.dotnet/tools:${PATH}"
  fi
fi

# Set up the OCaml programming language
if command -v opam &>/dev/null; then
  export OPAM_SWITCH_PREFIX='/Users/deriamis/.opam/default'
  export CAML_LD_LIBRARY_PATH='/Users/deriamis/.opam/default/lib/stublibs:/Users/deriamis/.opam/default/lib/ocaml/stublibs:/Users/deriamis/.opam/default/lib/ocaml'
  export OCAML_TOPLEVEL_PATH='/Users/deriamis/.opam/default/lib/toplevel'
  PATH="/Users/deriamis/.opam/default/bin${PATH+:$PATH}"
fi

# Make less more friendly for non-text input files, see lesspipe(1)
if command -v batpipe &>/dev/null; then
  _evalcache batpipe
elif [[ -x $(which lesspipe.sh) ]]; then
  LESSOPEN="|$(which lesspipe.sh) %s"
  LESS_ADVANCED_PREPROCESSOR=1
  export LESSOPEN LESS_ADVANCED_PREPROCESSOR
fi

if command -v bat &>/dev/null; then
  function help() {
    if [[ -z $* ]]; then
      run-help
      return $?
    fi
    "$@" --help 2>&1 | bat --plain --language=help
  }
  unalias help &>/dev/null
fi

if command -v batman &>/dev/null; then
  export MANROFFOPT="-c"
fi

if [[ -r ${HOME}/.custom_env ]]; then
  source "${HOME}/.custom_env"
fi

if [[ -r ~/.shell_aliases ]]; then
  source ~/.shell_aliases
fi
