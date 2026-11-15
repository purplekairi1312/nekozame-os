// nekozame os: kde's default panel, on top (the wallpaper comes from nekozame-kde-defaults)
loadTemplate("org.kde.plasma.desktop.defaultPanel")

panels().forEach(function (panel) {
    panel.location = "top"
    panel.height = 40  // whole pixels at 1.25x, 1.35x (the deck), 1.5x and 2x
})
