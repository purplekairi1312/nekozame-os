# nekozame's colours for what picks its own instead of the terminal's: gum (the setup's
# questions, in every nekozame command) and the welcome banner. sourced by
# /etc/profile.d/nekozame-colors.sh and by the nekozame commands that ask things
PINK="#ffc0e5" PLUM="#433a55" TEXT="#ffd9ef" BLUE="#b8e4ff" LILAC="#d9b8d6"
export GUM_CONFIRM_PROMPT_FOREGROUND=$PINK
export GUM_CONFIRM_SELECTED_BACKGROUND=$PINK GUM_CONFIRM_SELECTED_FOREGROUND=$PLUM
export GUM_CONFIRM_UNSELECTED_BACKGROUND=$PLUM GUM_CONFIRM_UNSELECTED_FOREGROUND=$TEXT
export GUM_CHOOSE_HEADER_FOREGROUND=$PINK GUM_CHOOSE_CURSOR_FOREGROUND=$PINK
export GUM_CHOOSE_SELECTED_FOREGROUND=$BLUE GUM_CHOOSE_ITEM_FOREGROUND=$TEXT
export GUM_INPUT_HEADER_FOREGROUND=$PINK GUM_INPUT_PROMPT_FOREGROUND=$PINK
export GUM_INPUT_CURSOR_FOREGROUND=$PINK GUM_INPUT_PLACEHOLDER_FOREGROUND=$LILAC
# the banner in nekozame's style, whatever the accent colour (it'd pick bazzite's for it)
export MOTD_FORCE_THEME=nekozame
unset PINK PLUM TEXT BLUE LILAC
