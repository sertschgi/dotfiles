$env.config.show_banner = false

$env.config.buffer_editor = "nvim"
$env.config = {
    edit_mode: vi
    cursor_shape: {
      vi_insert: blink_line
      vi_normal: block
      emacs: line
    }
}

source ~/.config/nushell/themes/gyokuro.nu

alias pmi = sudo xbps-install
alias pmiy = pmi -y
alias pmr = sudo xbps-remove
alias pmq = xbps-query -Rs
alias pmf = pmq
alias pmu = pmi -Su
alias pmc = sudo xbps-remove -oO
alias n = nvim
alias s = sudo
alias r = ranger

source ~/.zoxide.nu
alias cd = z
alias ct = zi
alias c = cd
