use std/util "path add"

# starship
$env.STARSHIP_CONFIG = ("~/.config/starship/config.toml" | path expand)
$env.PROMPT_INDICATOR_VI_INSERT = ""
$env.PROMPT_INDICATOR_VI_NORMAL = ""
$env.PROMPT_MULTILINE_INDICATOR = ""
$env.PROMPT_INDICATOR = ""

# bash-env
path add ("./bash-env-json" | path expand)
use "bash-env/bash-env.nu"

# pnpm
$env.PNPM_HOME = ([$env.HOME, ".local/share/pnpm"] | path join)
$env.PATH = ($env.PATH | split row (char esep) | prepend $env.PNPM_HOME )

# miniconda
bash-env /opt/miniconda3/etc/profile.d/conda.sh | load-env
use "./nu_scripts/modules/virtual_environments/nu_conda_2/conda.nu"

# android
path add "~/Android/Sdk/platform-tools"
bash-env /etc/profile.d/jdk.sh | load-env
$env.ANDROID_SDK_ROOT = "~/Android/Sdk"

# custom scripts
use "./custom_scripts/ecad.nu"
