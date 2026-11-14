// nekozame os: kde's default panel, on top (the wallpaper comes from nekozame-kde-defaults)
loadTemplate("org.kde.plasma.desktop.defaultPanel")

panels().forEach(function (panel) {
    panel.location = "top"
})
