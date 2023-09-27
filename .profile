# Ensure we always have a minimal TERM set
if [[ -z $TERM ]]; then
  export TERM=xterm-256color
  export COLORTERM=truecolor
fi

# Utility functions
set_title() {
  echo -e "\e]0;$*\007"
}

ssh() {
  set_title $*
  if [[ $SHELL =~ /?zsh$ ]]; then
    $(whence -p ssh) -2 $*
  else
    $(which ssh) -2 $*
  fi
  set_title $HOST
}

ciphers() {
  local OPENSSL=$(which openssl)

  local IFS=':'
  ciphers=( $(${OPENSSL} ciphers 'ALL:eNULL') )
  unset IFS

  for cipher in "${ciphers[@]}"; do
    echo -n "Testing ${cipher}... "

    local IFS=$'\n'
    result=( $(openssl s_client -cipher "${cipher}" -connect ${1:-localhost}:${2:-443} 2>&1 < /dev/null) )
    unset IFS

    if [[ "${result[*]}" =~ "Cipher is ${cipher}" ]]; then
      echo "YES"
    elif [[ "${result[*]}" =~ ":error:" ]]; then
      error=$(cut -d: -f6 <<< "${result[1]}")
      echo "NO (${error})"
    else
      echo "FAILURE (${result[1]})"
    fi
  done
}

tapme() {
  # Run a command, log the output, and display a notification when done. Use it
  # like so:
  #   tapme sleep 10
  declare -a notify_cmd
  declare -a icons
  local status
  local icon
  local logfile
  local message
  local title="Command finished"

  case "$(uname -s)" in
    Linux)
      icons=(terminal error)
      if ! command -v notify-send &>/dev/null; then
        echo "notify-send is not installed" >&2
        return 1
      fi
      ;;
    Darwin)
      if ! command -v terminal-notifier &>/dev/null; then
        echo "terminal-notifier is not installed" >&2
        return 1
      fi
      icons=(✅ ❌)
      ;;
    *)
      echo "Unknown platform $(uname -s), don't know how to notify" >&2
      return 1
      ;;
  esac

  if command -v mktemp --version &>/dev/null; then
    # This is GNU mktemp
    logfile=$(mktemp -t tapme.log.XXXXXXXX)
  else
    # This is a BSD(ish) mktemp
    logfile=$(mktemp -t tapme.log)
  fi

  message="Output is available in ${logfile}"

  echo "\$ ${*}" > "${logfile}"
  echo >> "${logfile}"

  "${@}" &>> "${logfile}"
  res=$?

  echo
  echo "Return code: ${res}" >> "${logfile}"

  (( res == 0 )) && icon="${icons[0]}" || icon="${icons[1]}"
  case "$(uname -s)" in
    Linux)
      notify_cmd=( notify-send --urgency=low -i "${icon}" "${title}" "${message}")
      ;;
    Darwin)
      notify_cmd=(
      terminal-notifier
      -title "${icon} ${title}"
      -subtitle "Exited with return code ${res}"
      -message "${message}"
      -execute "open -t ${logfile}"
    )
    ;;
esac

  "${notify_cmd[@]}" || true
  return ${res}
}

# Add some XDG_* variables that don't get set
if [[ -x /usr/bin/loginctl ]]; then
  export XDG_SESSION_ID=$(loginctl -l -P Sessions show-user "${USER}")
  export XDG_VTNR=$(loginctl -l -P VTNr show-session ${XDG_SESSION_ID})
  export XDG_SEAT=$(loginctl -l -P Seat show-session ${XDG_SESSION_ID})
fi

# Set up GPG SSH Agent
if [[ $(uname -s) == Darwin ]]; then
  export SSH_AUTH_SOCK="${HOME}/.ssh/agent.sock"
else
  export GPG_TTY="$(tty)"
  export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  gpgconf --launch gpg-agent
fi

export PATH MANPATH INFOPATH

# Activate Homebrew
if [[ -d /opt/homebrew ]]; then
  export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
  export HOMEBREW_REPOSITORY="/opt/homebrew";
  PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}";
  MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:";
  INFOPATH="/opt/homebrew/share/info${INFOPATH+:$INFOPATH}";
fi

# Add MacPorts to $PATH
if [[ -d /opt/local ]]; then
  PATH="/opt/local/bin:/opt/local/sbin:/opt/local/libexec/gnubin${PATH+:$PATH}"
  MANPATH="/opt/local/share/man${MANPATH+:$MANPATH}"
  INFOPATH="/opt/local/share/info${INFOPATH+:$INFOPATH}"
fi

if command -v bat &>/dev/null; then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  export MANROFFOPT="-c"
  help() {
    "$@" --help 2&>1 | bat --plain --language=help
  }
fi

# Add .NET to $PATH
if [[ -d /opt/local/share/dotnet ]]; then
  export DOTNET_ROOT="/opt/local/share/dotnet"
fi
if [[ -d ~/.dotnet/tools ]]; then
  PATH="${HOME}/.dotnet/tools:$PATH"
fi

# Set up Yarn packager for NPM
if [[ -d ~/.config/yarn/global/node_modules/.bin ]]; then
  PATH="$HOME/.config/yarn/global/node_modules/.bin:$PATH"
fi
if [[ -d ~/.yarn/bin ]]; then
  PATH="$HOME/.yarn/bin:$PATH"
fi

# Set up rebar3 for Erlang
if [[ -x ~/.cache/rebar3/bin/rebar3 ]]; then
  PATH="${HOME}/.cache/rebar3/bin:${PATH}"
fi

# Set up cargo for Rust
if [[ -d ~/.cargo ]]; then
  source ~/.cargo/env
fi

# Set up the GO programming language
if command -v go &>/dev/null; then
  export GOPATH="${HOME}/go"
  export GOBIN="${HOME}/.local/share/go/bin"
  [[ -d ${GOPATH}/bin ]] && PATH="${GOPATH}/bin:${PATH}"
  [[ -d ${GOBIN} ]] && PATH="${GOBIN}:${PATH}"
fi

# Set up Roswell lisp scripting environment
if [[ -d ~/.roswell/bin ]] && command -v ros &>/dev/null; then
  PATH="${HOME}/.roswell/bin:${PATH}"
fi

# Set up the OCaml programming language
if command -v opam &>/dev/null; then
  export OPAM_SWITCH_PREFIX='/Users/deriamis/.opam/default'
  export CAML_LD_LIBRARY_PATH='/Users/deriamis/.opam/default/lib/stublibs:/Users/deriamis/.opam/default/lib/ocaml/stublibs:/Users/deriamis/.opam/default/lib/ocaml'
  export OCAML_TOPLEVEL_PATH='/Users/deriamis/.opam/default/lib/toplevel'
  PATH="/Users/deriamis/.opam/default/bin${PATH+:$PATH}"
fi

# Set up Haskell
if [[ -d ~/.ghcup/bin ]]; then
  PATH="${HOME}/.ghcup/bin:$PATH:"
fi
if [[ -d ~/.cabal/bin ]]; then
  PATH="${HOME}/.cabal/bin:$PATH"
fi

# Set up Teleport
if command -v tsh &>/dev/null; then
  export TELEPORT_ADD_KEYS_TO_AGENT=no
fi

# Add Rancher Desktop to PATH
if [[ -d ~/.rd/bin ]]; then
  PATH="${HOME}/.rd/bin:$PATH"
fi

# Add homedir binaries to $PATH
[[ -d ~/bin ]] && PATH="$HOME/bin:$PATH"
[[ -d ~/.local/bin ]] && PATH="$HOME/.local/bin:$PATH"

# Make less more friendly for non-text input files, see lesspipe(1)
if [[ -x $(which lesspipe.sh) ]]; then
  export LESSOPEN="|/opt/local/bin/lesspipe.sh %s"
  export LESS_ADVANCED_PREPROCESSOR=1
fi

# Set up the Travis gem
if [[ -f $HOME/.travis/travis.sh ]]; then
  source $HOME/.travis/travis.sh
fi

# Initialize the Fuzzy Finder
if [[ -f ~/.fzf.${SHELL##*/} ]]; then
  source ~/.fzf.${SHELL##*/}
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

if [[ -e ~/.private_env ]]; then
  source ~/.private_env
fi

