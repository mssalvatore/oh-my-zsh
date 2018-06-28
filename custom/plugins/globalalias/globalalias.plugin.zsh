globalias() {
   if [[ $LBUFFER =~ ' g.*' ]] && ! [[ $LBUFFER =~ ' grep' ]]; then
     zle _expand_alias
   fi
   zle self-insert
}

zle -N globalias

bindkey " " globalias
bindkey "^ " magic-space           # control-space to bypass completion
bindkey -M isearch " " magic-space # normal space during searches
