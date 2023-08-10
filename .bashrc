# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return;;
esac

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

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	    # We have color support; assume it's compliant with Ecma-48
	    # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	    # a case would tend to support setf rather than setaf.)
	    color_prompt=yes
    else
	    color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# Don't load the fancy stuff if we've dropped to Bash for copypasta purposes
if [[ $ENV_ANONYMIZE != 1 ]]; then
    # enable programmable completion features (you don't need to enable
    # this, if it's already enabled in /etc/bash.bashrc and /etc/profile
    # sources /etc/bash.bashrc).
    if ! shopt -oq posix; then
        if [ -f /usr/share/bash-completion/bash_completion ]; then
            . /usr/share/bash-completion/bash_completion
        elif [ -f /etc/bash_completion ]; then
            . /etc/bash_completion
        fi
        if [ -f ~/.asdf/completions/asdf.bash ]; then
            . ~/.asdf/completions/asdf.bash
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

    # Enable iTerm2 integrations
    if [[ -e "${HOME}/.iterm2_shell_integration.${SHELL##*/}" ]]; then
      source "${HOME}/.iterm2_shell_integration.${SHELL##*/}"
    fi
fi

[[ -r ~/.shell_aliases ]] && source ~/.shell_aliases

