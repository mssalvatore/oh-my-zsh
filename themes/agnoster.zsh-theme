# vim:ft=zsh ts=2 sw=2 sts=2
#
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://github.com/Lokaltog/powerline-fonts).
# Make sure you have a recent version: the code points that Powerline
# uses changed in 2012, and older versions will display incorrectly,
# in confusing ways.
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'

### Git Status Icons/Symbols
# Git info.
ZSH_THEME_GIT_PROMPT_PREFIX=""
ZSH_THEME_GIT_PROMPT_SUFFIX=""

# Git status.
ZSH_THEME_GIT_PROMPT_ADDED="+"
ZSH_THEME_GIT_PROMPT_DELETED="−"
ZSH_THEME_GIT_PROMPT_MODIFIED="*"
ZSH_THEME_GIT_PROMPT_RENAMED=">"
ZSH_THEME_GIT_PROMPT_UNMERGED="="
ZSH_THEME_GIT_PROMPT_UNTRACKED="?"
ZSH_THEME_GIT_PROMPT_STASHED="S"
ZSH_THEME_GIT_PROMPT_AHEAD="↑"
ZSH_THEME_GIT_PROMPT_BEHIND="↓"

# Git sha.
ZSH_THEME_GIT_PROMPT_SHA_BEFORE="["
ZSH_THEME_GIT_PROMPT_SHA_AFTER="]"

# Special Powerline characters

() {
  local LC_ALL="" LC_CTYPE="en_US.UTF-8"
  # NOTE: This segment separator character is correct.  In 2012, Powerline changed
  # the code points they use for their special characters. This is the new code point.
  # If this is not working for you, you probably have an old version of the
  # Powerline-patched fonts installed. Download and install the new version.
  # Do not submit PRs to change this unless you have reviewed the Powerline code point
  # history and have new information.
  # This is defined using a Unicode escape sequence so it is unambiguously readable, regardless of
  # what font the user is viewing this source code in. Do not replace the
  # escape sequence with a single literal character.
  # Do not change this! Do not make it '\u2b80'; that is the old, wrong code point.
  SEGMENT_SEPARATOR=$'\ue0b0'
  SEGMENT_SEPARATOR_RIGHT=$'\ue0b2'
}

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# Begin a segment
# Takes 3 arguments, background, foreground, text.
# rendering default background/foreground.
prompt_segment_right() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  #echo -n " $SEGMENT_SEPARATOR_RIGHT%{$fg%} "
  echo -n " %{%F{$1}%}$SEGMENT_SEPARATOR_RIGHT%{$bg%}%{$fg%} "
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

prompt_end_right() {
  echo -n "%{%k%}"
  echo -n "%{%f%}"
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)$USER@%m"
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {

  local PL_BRANCH_CHAR
  () {
    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
    PL_BRANCH_CHAR=$'\ue0a0'         # 
  }

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    local ref dirty mode repo_path
    repo_path=$(git rev-parse --git-dir 2>/dev/null)

    if [[ $NO_GIT_PROMPT_STATUS -ne 1 ]]; then
      local git_status="$(git_prompt_status)"
    fi

    if [[ -n $git_status ]]; then
        git_status="[$git_status]"
    fi

    local dirty_regex="[$ZSH_THEME_GIT_PROMPT_DELETED$ZSH_THEME_GIT_PROMPT_ADDED$ZSH_THEME_GIT_PROMPT_MODIFIED$ZSH_THEME_GIT_PROMPT_RENAMED$ZSH_THEME_GIT_PROMPT_UNMERGED$ZSH_THEME_GIT_PROMPT_UNTRACKED]+" 
    if $(echo "$git_status" | grep -E "$dirty_regex" &> /dev/null); then
      dirty="true"
    fi

    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
    if [[ -n $dirty ]]; then
      prompt_segment yellow black
    else
      prompt_segment green black
    fi

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
    fi

    echo -n "${ref/refs\/heads\//$PL_BRANCH_CHAR }$git_status${mode}"
  fi
}

prompt_hg() {
  local rev status
  if $(hg id >/dev/null 2>&1); then
    if $(hg prompt >/dev/null 2>&1); then
      if [[ $(hg prompt "{status|unknown}") = "?" ]]; then
        # if files are not added
        prompt_segment red white
        st='±'
      elif [[ -n $(hg prompt "{status|modified}") ]]; then
        # if any modification
        prompt_segment yellow black
        st='±'
      else
        # if working copy is clean
        prompt_segment green black
      fi
      echo -n $(hg prompt "☿ {rev}@{branch}") $st
    else
      st=""
      rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
      branch=$(hg id -b 2>/dev/null)
      if `hg st | grep -q "^\?"`; then
        prompt_segment red black
        st='±'
      elif `hg st | grep -q "^[MA]"`; then
        prompt_segment yellow black
        st='±'
      else
        prompt_segment green black
      fi
      echo -n "☿ $rev@$branch" $st
    fi
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue black '%~'
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
    prompt_segment blue black "(`basename $virtualenv_path`)"
  fi
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
#  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
#  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"

  [[ -n "$symbols" ]] && prompt_segment black default "$symbols"
}

# Status:
# - was there an error
# - are there background jobs?
prompt_status_right() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{black}%}⚙"

  [[ -n "$symbols" ]] && prompt_segment_right white white "$symbols"
}

function prompt_time_right {
    local time="%* "
    prompt_segment_right green black $time;
}

toggle_prompt_git_status() {
  if [[ $NO_GIT_PROMPT_STATUS -ne 1 ]]; then
    export NO_GIT_PROMPT_STATUS=1
  else
    export NO_GIT_PROMPT_STATUS=""
  fi
}

## Main prompt
build_prompt() {
  prompt_status
  #prompt_virtualenv
  prompt_context
  prompt_dir
  prompt_git
  prompt_hg
  prompt_end
}

build_prompt_right() {
    prompt_vim_right
    prompt_status_right
    prompt_time_right
}


#Global VIM_PROMPT variable
VIM_PROMPT="NORMAL"
function prompt_vim_right {
    local mode="${${KEYMAP/vicmd/$VIM_PROMPT}/(main|viins)/}"
    [[ -n $mode ]] && prompt_segment_right red white "$mode"
}

function zle-line-init zle-keymap-select {
    RETVAL=$?
    RPS1="$(build_prompt_right)"
    zle reset-prompt
}

PROMPT='%{%f%b%k%}$(build_prompt) '

#Setup Right Prompt
zle -N zle-line-init
zle -N zle-keymap-select

