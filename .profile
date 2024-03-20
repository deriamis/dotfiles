# On recent versions of Mac, the new multithreading restrictions are absolutely
# monstrous. We have to disable the safety features if we want to remain sane.
if [[ $(uname -s) == Darwin ]]; then
  OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
  export OBJC_DISABLE_INITIALIZE_FORK_SAFETY
fi

# Ensure we always have a minimal TERM set
if [[ -z $TERM ]]; then
  export TERM=xterm-256color
  export COLORTERM=truecolor
fi

# Utility functions
if [[ ${INSIDE_EMACS} == 'vterm' ]]; then
  vterm_printf() {
    if [[ -n ${TMUX} && ( ${TERM%%-*} == tmux || ${TERM%%-*} == screen ) ]]; then
          # Tell tmux to pass the escape sequences through
          printf "\ePtmux;\e\e]%s\007\e\\" "$1"
      elif [[ ${TERM%%-*} == screen ]]; then
          # GNU screen (screen, screen-256color, screen-256color-bce)
          printf "\eP\e]%s\007\e\\" "$1"
      else
          printf "\e]%s\e\\" "$1"
      fi
  }

  vterm_cmd() {
      local vterm_elisp
      vterm_elisp=""
      while (( $# > 0 )); do
          vterm_elisp="$vterm_elisp""$(printf '"%s" ' "$(printf "%s" "$1" | sed -e 's|\\|\\\\|g' -e 's|"|\\"|g')")"
          shift
      done
      vterm_printf "51;E$vterm_elisp"
  }

  find_file() {
      vterm_cmd find-file "$(realpath "${@:-.}")"
  }

  say() {
      vterm_cmd message "%s" "$*"
  }

  clear_scrollback() {
    vterm_vmd clear_scrollback
    tput clear
  }

  vterm_set_directory() {
    if [[ -n ${SSH_CLIENT} || -n ${SSH_TTY} ]]; then
      vterm_cmd update-pwd "/-:""$USER""@""$HOSTNAME"":""$PWD/"
    else
        vterm_cmd update-pwd "$PWD/"
    fi
  }
fi

set_title() {
  if [[ $SHELL =~ /?zsh$ ]]; then
    print -Pn "\e]2;$*:%2~\a"
  else
    echo -e "\e]0;$*\007"
  fi
}

ssh() {
  set_title "$*"
  if [[ $SHELL =~ /?zsh$ ]]; then
    $(whence -p ssh) -2 "$@"
  else
    $(which ssh) -2 "$@"
  fi
  # shellcheck disable=SC2154
  set_title "${HOST}"
}

ciphers() {
  local OPENSSL
  local IFS

  OPENSSL=$(which openssl)

  local output_re
  local cipher
  local cipher

  IFS=':'
  read -ra ciphers < <(${OPENSSL} ciphers 'ALL:eNULL')
  unset IFS

  for cipher in "${ciphers[@]}"; do
    echo -n "Testing ${cipher}... "

    local IFS=$'\n'
    read -ra result < <(openssl s_client -cipher "${cipher}" -connect "${1:-localhost}:${2:-443}" 2>&1 < /dev/null)
    unset IFS

    output_re="Cipher is ${cipher}"
    if [[ ${result[*]} =~ ${output_re} ]]; then
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
  return "${res}"
}

MISE_PATH="${HOME}/.local/share/mise/bin"

# Add some XDG_* variables that don't get set
if [[ -x /usr/bin/loginctl ]]; then
  XDG_SESSION_ID=$(loginctl -l -P Sessions show-user "${USER}")
  XDG_VTNR=$(loginctl -l -P VTNr show-session "${XDG_SESSION_ID}")
  XDG_SEAT=$(loginctl -l -P Seat show-session "${XDG_SESSION_ID}")
  export XDG_SESSION_ID XDG_VTNR XDG_SEAT
fi

# Activate Homebrew
if [[ -d /opt/homebrew ]]; then
  HOMEBREW_PREFIX="/opt/homebrew";
  HOMEBREW_CELLAR="${HOMEBREW_PREFIX}/Cellar";
  HOMEBREW_REPOSITORY="${HOMEBREW_PREFIX}";
  HOMEBREW_PATH="${HOMEBREW_PREFIX}/bin:${HOMEBREW_PREFIX}/sbin";
  HOMEBREW_MANPATH="${HOMEBREW_PREFIX}/share/man";
  HOMEBREW_INFOPATH="${HOMEBREW_PREFIX}/share/info";
  export HOMEBREW_PREFIX HOMEBREW_CELLAR HOMEBREW_REPOSITORY HOMEBREW_PATH HOMEBREW_MANPATH HOMEBREW_INFOPATH
fi

# Add MacPorts to $PATH
if [[ -d /opt/local ]]; then
  MACPORTS_PATH="/opt/local/bin:/opt/local/sbin:/opt/local/libexec/gnubin"
  MACPORTS_MANPATH="/opt/local/share/man"
  MACPORTS_INFOPATH="/opt/local/share/info"
  export MACPORTS_PATH MACPORTS_MANPATH MACPORTS_INFOPATH
fi

PATH="${MISE_PATH}:${MACPORTS_PATH+:$MACPORTS_PATH}${HOMEBREW_PATH+:$HOMEBREW_PATH}${PATH+:$PATH}"
MANPATH="${MACPORTS_MANPATH+:$MACPORTS_MANPATH}${HOMEBREW_MANPATH+:$HOMEBREW_MANPATH}${MANPATH+:$MANPATH}"
INFOPATH="${MACPORTS_INFOPATH+:$MACPORTS_INFOPATH}${HOMEBREW_INFOPATH+:$HOMEBREW_INFOPATH}${INFOPATH+:$INFOPATH}"

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Add Android SDK to $PATH
if [[ -d ~/.local/share/android_sdk/cmdline-tools/latest ]]; then
  export ANDROID_HOME=~/.local/share/android_sdk
  PATH="${HOME}/.local/share/android_sdk/cmdline-tools/latest/bin:${PATH}"
fi

# Set up Yarn packager for NPM
if [[ -d ~/.config/yarn/global/node_modules/.bin ]]; then
  PATH="$HOME/.config/yarn/global/node_modules/.bin:${PATH}"
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
  source "${HOME}/.cargo/env"
fi

# Set up Roswell lisp scripting environment
if [[ -d ~/.roswell/bin ]] && command -v ros &>/dev/null; then
  PATH="${HOME}/.roswell/bin:${PATH}"
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

# Add kubectl-krew to PATH
if [[ -d ~/.krew/bin ]]; then
  PATH="${HOME}/.krew/bin:${PATH}"
fi

# Set up the Travis gem
if [[ -f ${HOME}/.travis/travis.sh ]]; then
  source "${HOME}/.travis/travis.sh"
fi

# Configure VTerm scrollback clearing
if [[ $SHELL =~ /?zsh$ ]]; then
  if [[ "$INSIDE_EMACS" = 'vterm' ]]; then
    alias clear='vterm_printf "51;Evterm-clear-scrollback";tput clear'
  fi
else
  if [[ "$INSIDE_EMACS" = 'vterm' ]]; then
    function clear() {
        vterm_printf "51;Evterm-clear-scrollback";
        tput clear;
    }
  fi
fi

if [[ -e ${HOME}/.private_env ]]; then
  source "${HOME}/.private_env"
fi
