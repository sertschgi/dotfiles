# env.nu
#
# Installed by:
# version = "0.102.0"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.


use std/util "path add"

# bash-env
path add ("~/.config/nushell/bash-env-json" | path expand)

use "bash-env/bash-env.nu"

# pnpm
$env.PNPM_HOME = ([$env.HOME, ".local/share/pnpm"] | path join)
$env.PATH = ($env.PATH | split row (char esep) | prepend $env.PNPM_HOME )

# miniconda
bash-env /opt/miniconda3/etc/profile.d/conda.sh | load-env
use ("~/.config/nushell/nu_scripts/modules/virtual_environments/conda.nu" | path expand)

# android
path add "~/Android/Sdk/platform-tools"
bash-env /etc/profile.d/jdk.sh | load-env
$env.ANDROID_SDK_ROOT = "~/Android/Sdk"
