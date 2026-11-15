# Top Bar Islands - theme

This directory contains the same island styling as the extension, written for
a GNOME Shell theme instead of an extension.

- `islands.css` styles `#panel`, `#panelLeft`, `#panelRight` and the panel
  buttons. It paints the transparent panel, the two translucent islands, white
  labels/icons, and the hover/selected washes.

## What a theme can and cannot do

A shell theme can reproduce the **look**:

- transparent panel strip
- two rounded translucent islands
- flat white items with a hover wash

A shell theme cannot reproduce the extension's behaviour:

- removing the panel strut so windows use the full screen height
- click-through in the empty middle
- the expand/contract chevron for the date and time
- the layout presets

For those, install the extension instead (recommended).

## Use it

The snippet is not a complete shell theme. Add it to an existing theme.

1. Copy your theme's `gnome-shell` directory to `~/.themes/<name>/`:

       mkdir -p ~/.themes/islands/gnome-shell
       cp -a /usr/share/themes/Yaru/gnome-shell/. ~/.themes/islands/gnome-shell/

2. Copy `islands.css` into it and import it at the end of `gnome-shell.css`:

       cp islands.css ~/.themes/islands/gnome-shell/
       printf '\n@import url("islands.css");\n' >> ~/.themes/islands/gnome-shell/gnome-shell.css

3. Select the theme. On Ubuntu, the User Themes extension provides the
   setting:

       gsettings set org.gnome.shell.extensions.user-theme name 'islands'

   Without the User Themes extension, a shell theme can only be replaced
   system-wide, which is not recommended.

4. Undo by selecting the previous theme:

       gsettings set org.gnome.shell.extensions.user-theme name 'Yaru'

The panel background in most themes is set with a gradient or an image. The
snippet uses `!important` on the backgrounds so it wins regardless of the
theme's specificity. If an island does not appear, check that the theme's
`gnome-shell.css` does not style `#panelLeft`/`#panelRight` with `!important`
after the import.
