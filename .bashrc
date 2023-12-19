# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [[ -n ${force_color_prompt} ]]; then
    if command -v tput &>/dev/null && tput setaf 1 >&/dev/null; then
      # We have color support; assume it's compliant with Ecma-48
      # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
      # a case would tend to support setf rather than setaf.)
      color_prompt=yes
    else
      color_prompt=
    fi
fi

if [[ ${color_prompt} == yes ]]; then
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# Add homedir binaries to $PATH
[[ -d ${HOME}/bin ]] && PATH="${HOME}/bin:${PATH}"
[[ -d ${HOME}/.local/bin ]] && PATH="${HOME}/.local/bin:${PATH}"

# Don't load the fancy stuff if we've dropped to Bash for copypasta purposes
# shellcheck disable=SC2154
if [[ $ENV_ANONYMIZE != 1 ]]; then
    # enable programmable completion features (you don't need to enable
    # this, if it's already enabled in /etc/bash.bashrc and /etc/profile
    # sources /etc/bash.bashrc).
    if ! shopt -oq posix; then
        if [[ -f /usr/share/bash-completion/bash_completion ]]; then
            source /usr/share/bash-completion/bash_completion
        elif [[ -f /etc/bash_completion ]]; then
            source /etc/bash_completion
        fi
        if [[ -f ${HOME}/.asdf/completions/asdf.bash ]]; then
            source "${HOME}/.asdf/completions/asdf.bash"
        fi
    fi

    # Set up RTX (Python, Ruby, Node.js)
    if command -v rtx &>/dev/null; then
      eval "$(rtx activate bash)"
      eval "$(rtx completion bash)"

      # Set up the GO programming language
      if rtx which go &>/dev/null; then
        export GOPATH="${HOME}/go"
        export GOBIN="${HOME}/.local/share/go/bin"
        [[ -d ${GOPATH}/bin ]] && PATH="${GOPATH}/bin:${PATH}"
        [[ -d ${GOBIN} ]] && PATH="${GOBIN}:${PATH}"
      fi

      # Ruby programming language
      if rtx which ruby &>/dev/null; then
          PATH="$(gem env | grep 'USER INSTALLATION DIRECTORY' | /usr/bin/awk -F': ' '{print $2}')/bin:$PATH"
      fi

      # Perl programming language
      if rtx which perl &>/dev/null; then
        if perl -e "use local::lib" &>/dev/null; then
          eval "$(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)" >/dev/null
        fi
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
    elif [[ -e ${HOME}/.asdf/asdf.sh ]]; then
        source "${HOME}/.asdf/asdf.sh"

        # Java programming language
        if [[ -d ${HOME}/.asdf/plugins/java ]]; then
          source "${HOME}/.asdf/plugins/java/set-java-home.bash"
        fi

        # Ruby programming language
        if [[ -d ~/.asdf/plugins/ruby ]]; then
          PATH="$(gem env | grep 'USER INSTALLATION DIRECTORY' | /usr/bin/awk -F': ' '{print $2}')/bin:$PATH"
        fi

        # Perl programming language
        if [[ -d ~/.asdf/plugins/perl ]]; then
          if perl -e "use local::lib" &>/dev/null; then
            eval "$(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)" >/dev/null
          fi
        fi

        # Erlang
        if [[ -d ~/.asdf/plugins/erlang ]]; then
          export KERL_BUILD_DOCS=yes
        fi
    fi

    # Load oh-my-posh
    if command -v oh-my-posh &>/dev/null; then
        eval "$(oh-my-posh init bash --config ~/.poshthemes/powerlevel10k_poweruser.omp.json)"
        eval "$(oh-my-posh completion bash)"
    fi

    # Load lefthook completions
    if command -v lefthook &>/dev/null; then
        eval "$(lefthook completion bash)"
    fi

    # Load pmv completions
    if command -v pmv &>/dev/null; then
        eval "$(pmv completion bash)"
    fi

    # Load k9s completions
    if command -v k9s &>/dev/null; then
        eval "$(k9s completion bash)"
    fi

    # Load eksctl completions
    if command -v eksctl &>/dev/null; then
        eval "$(eksctl completion bash)"
    fi

    # Load kubectl completions
    if command -v kubectl &>/dev/null; then
        eval "$(kubectl completion bash)"
    fi

    # Enable dircolors scheme
    if [[ -r ~/.dircolors ]] && command -v dircolors &>/dev/null; then
      eval "$(dircolors -b ~/.dircolors)"
    fi

    # Initialize the Fuzzy Finder
    if [[ -f ${HOME}/.fzf.bash ]]; then
      source "${HOME}/.fzf.bash"
    fi

    # Enable iTerm2 integrations
    if [[ -e ${HOME}/.iterm2_shell_integration.bash ]]; then
        source "${HOME}/.iterm2_shell_integration.bash"
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
        eval "$(batpipe)"
    elif [[ -x $(which lesspipe.sh) ]]; then
      LESSOPEN="|$(which lesspipe.sh) %s"
      LESS_ADVANCED_PREPROCESSOR=1
      export LESSOPEN LESS_ADVANCED_PREPROCESSOR
    fi

    if command -v bat &>/dev/null; then
      export MANPAGER="sh -c 'col -bx | bat -l man -p'"
      export MANROFFOPT="-c"
      function help() {
        if [[ -z $* ]]; then
          builtin help
          return $?
        fi
        "$@" --help 2>&1 | bat --plain --language=help
      }
      unalias help &>/dev/null
    fi
fi

if [[ -r ${HOME}/.shell_aliases ]]; then
    source "${HOME}/.shell_aliases"
fi
