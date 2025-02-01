bootstrap-dev-env:
  distrobox assemble create --replace --file https://raw.githubusercontent.com/hnatekmarorg/workstation/refs/heads/main/distrobox.conf
  distrobox enter workstation -- yadm clone git@github.com:hnatekmarorg/dotfiles.git -f

enter-workstation:
  distrobox enter workstation