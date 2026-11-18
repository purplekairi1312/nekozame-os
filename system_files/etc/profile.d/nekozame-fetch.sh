# fastfetch is nekozame-fetch (the nekozame logo and colours)
alias fastfetch='/usr/bin/nekozame-fetch'
alias neofetch='/usr/bin/nekozame-fetch'

# the logo above the welcome banner, wherever you log in (a terminal, ssh, the text console):
# the picture where the terminal shows images, in text everywhere else. not in scripts or
# ssh commands, and gone with the banner (ujust toggle-user-motd)
if [ -z "${NEKOZAME_LOGO_SHOWN:-}" ] && [ -z "${USERMOTDSOURCED:-}" ] && [ -t 1 ] &&
    case $- in *i*) true ;; *) false ;; esac && [ ! -e "$HOME/.config/no-show-user-motd" ]; then
    NEKOZAME_LOGO_SHOWN=1
    /usr/bin/nekozame-fetch --logo
fi
