#!/bin/bash

# Get the current color scheme
current_scheme=$(gsettings get org.gnome.desktop.interface color-scheme)

# Get the current gnome-terminal profile id:
PROFILE_ID=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")

# Toggle between 'prefer-dark' and 'default'.
# Could use 'prefer-light'
if [ "$current_scheme" = "'prefer-dark'" ]; then
  gsettings set org.gnome.desktop.interface color-scheme 'default'
  gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/ use-theme-colors true
  jq '. + {"workbench.colorTheme": "Default Light+"}' ~/.config/Code/User/settings.json > tmp.$$.json && mv tmp.$$.json ~/.config/Code/User/settings.json
else
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/ use-theme-colors false
  jq '. + {"workbench.colorTheme": "Default Dark+"}' ~/.config/Code/User/settings.json > tmp.$$.json && mv tmp.$$.json ~/.config/Code/User/settings.json
fi

