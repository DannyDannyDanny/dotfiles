color_scheme=$1

# write a file with the current theme here:
nvim_color_theme_path=~/.local/share/nvim_color_scheme

# validate user input
if [[ "$color_scheme" != "dark" && "$color_scheme" != "light" ]]; then
  echo "Error: Color scheme must be 'dark' or 'light'" >&2
  exit 1
else
  echo $color_scheme > $nvim_color_theme_path
fi

# check that all relevant files exist
windows_username=$(powershell.exe '$env:UserName' | tr -d '\r\n')
dark_mode_config_path=~/python-projects/24_alacritty_windows_setup/gruvbox_material_medium_dark.toml
light_mode_config_path=~/python-projects/24_alacritty_windows_setup/gruvbox_material_medium_light.toml
if [ ! -f $light_mode_config_path ]; then
  echo "error: light_mode_config_path missing"
  echo "expected: $light_mode_config_path"
  exit 1
fi

if [ ! -f $dark_mode_config_path ]; then
  echo "error: dark_mode_config_path missing"
  echo "expected: $dark_mode_config_path"
  exit 1
fi

windows_alacritty_config_path="/mnt/c/Users/${windows_username}/AppData/Roaming/alacritty/alacritty.toml"
echo 'overwriting windows alacritty config' 

if [ $color_scheme = 'dark' ]; then
  echo "going dark"
  cp $dark_mode_config_path $windows_alacritty_config_path

  # explorer, browser etc
  powershell.exe -Command "Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0"
  # taskbar and start menu
  powershell.exe -Command "Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 0"
fi

if [ $color_scheme = 'light' ]; then
  echo "going light"
  cp $light_mode_config_path $windows_alacritty_config_path

  # explorer, browser etc
  powershell.exe -Command "Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 1"
  # taskbar and start menu
  powershell.exe -Command "Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 1"
fi

