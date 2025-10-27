# config.nu
#
# Installed by:
# version = "0.102.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# This file is loaded after env.nu and before login.nu
#
# You can open this file in your default editor using:
# config nu
#
# See `help config nu` for more options
#
# You can remove these comments if you want or leave
# them for future reference.
use ~/.config/nushell/bash-env/bash-env.nu


$env.config.buffer_editor = "nvim"
$env.config = {
    edit_mode: vi
    cursor_shape: {
      vi_insert: blink_line
      vi_normal: block
      emacs: line
    }
}


alias pmi = sudo xbps-install
alias pmiy = pmi -y
alias pmr = sudo xbps-remove
alias pmq = xbps-query -Rs
alias pmf = pmq
alias pmu = pmi -Su
alias n = nvim
alias s = sudo
alias r = ranger

$env.STARSHIP_SHELL = "nu"

def create_left_prompt [] {
    starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)'
}

# Use nushell functions to define your right and left prompt
$env.PROMPT_COMMAND = { || create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = ""

# The prompt indicators are environmental variables that represent
# the state of the prompt
$env.PROMPT_INDICATOR = ""
$env.PROMPT_INDICATOR_VI_INSERT = ": "
$env.PROMPT_INDICATOR_VI_NORMAL = "〉"
$env.PROMPT_MULTILINE_INDICATOR = "::: "


zoxide init nushell | save -f ~/.zoxide.nu
source ~/.zoxide.nu
alias cd = z
alias ct = zi
