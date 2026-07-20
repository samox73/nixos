{ ... }: {
  # Everforest-themed notification popups; colors mirror kitty/waybar/rofi.
  xdg.configFile."mako/config".text = ''
    sort=-time
    layer=overlay
    anchor=top-right
    outer-margin=12
    margin=8
    padding=14,18
    width=380
    height=120

    font=JetBrainsMonoNL Nerd Font Mono 11
    text-alignment=left
    default-timeout=7000

    background-color=#2d353bee
    text-color=#d3c6aa
    border-color=#a7c080
    border-size=2
    border-radius=14

    icons=1
    max-icon-size=48
    icon-location=left
    icon-border-radius=10

    progress-color=source #a7c08066

    [urgency=low]
    border-color=#475258
    text-color=#859289

    [urgency=critical]
    border-color=#e67e80
    progress-color=source #e67e8066
    default-timeout=0

    [app-name="Spotify"]
    border-color=#7fbbb3
  '';
}
