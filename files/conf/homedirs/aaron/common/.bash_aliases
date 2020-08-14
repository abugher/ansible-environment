if ls --color=auto >&/dev/null 2>&1; then
  alias ls='ls -N --color=auto'
  alias l="ls -N --color=auto -1tr"
else
  alias l="ls -N -1tr"
fi
unset ls
alias grep='grep --color=auto'
#alias startx='/usr/bin/startx & disown; exit'
alias startx='exec /usr/bin/startx'
alias i='mplayer -cache 5000 -cache-min 20 -osdlevel 3 -fs'
alias o='~/code/o'
alias judge='~/bin/judge'
alias ait='~/bin/ait'
alias notehack='~/bin/notehack'
#alias g='git pull && git add . && git add -u . && git commit && ~/bin/git_tag_increment patch && git push && git push --tags; git tag | tail -n 1'
#alias gg='git pull && git add . && git add -u . && git commit && ~/bin/git_tag_increment minor && git push && git push --tags; git tag | tail -n 1'
#alias ggg='git pull && git add . && git add -u . && git commit && ~/bin/git_tag_increment major && git push && git push --tags; git tag | tail -n 1'
alias gg='g minor'
alias ggg='g major'
alias a='time ansible-playbook'
alias symtag='~/bin/symtag'
alias porntag='~/bin/symtag -c ~/.symtagrc_porntag'
alias preview='~/bin/review -c ~/.symtagrc_porntag'
#alias m='mplayer --volume 0 -fs --osd-level 3'
alias m='mpv "$(l | tail -n 1)"'
alias indra='~/bin/indra'
alias pianobar='timeout 9h pianobar'
alias gdc='git diff --cached'
alias ding='mpv --volume=70 /usr/share/sounds/gnome/default/alerts/glass.ogg'
alias dp='dw 5 | pass add -m'
alias tdome='tt++ ~/.tdome.tt'
alias G='g; cd ~/code/sensitive; g; cd -; cd ~/code/control_center; g; cd -'
alias mutt=~/.mutt.d/bin/mutt
