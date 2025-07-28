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

# cp $dark_mode_config_path $windows_terminal_settings_path
# check that all relevant files exist
windows_username=$(powershell.exe '$env:UserName' | tr -d '\r\n')
windows_terminal_settings_path="/mnt/c/Users/${windows_username}/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
dark_mode_config_path=~/dotfiles/assets/windows_terminal/dark.settings.json
light_mode_config_path=~/dotfiles/assets/windows_terminal/light.settings.json

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

if [ ! -f $dark_mode_config_path ]; then
  echo "error: windows terminal settings path missing"
  echo "expected: $windows_terminal_settings_path"
  exit 1
fi

if [ $color_scheme = 'dark' ]; then
  cp $dark_mode_config_path $windows_terminal_settings_path
  echo "going dark - opening settings"
  powershell.exe -Command "start C:\Windows\Resources\Themes\dark.theme"
  powershell.exe "timeout /t 3; taskkill /im systemsettings.exe /f"
fi

if [ $color_scheme = 'light' ]; then
  cp $light_mode_config_path $windows_terminal_settings_path
  echo "going light - opening settings"
  powershell.exe -Command "start C:\Windows\Resources\Themes\aero.theme"
  echo "closing settigns"
  powershell.exe "timeout /t 3; taskkill /im systemsettings.exe /f"
fi

echo "setting Sound Schema to None"
powershell.exe -Command "Set-ItemProperty -Path HKCU:\AppEvents\Schemes -Name '(Default)' -Value 'No Sounds'"

