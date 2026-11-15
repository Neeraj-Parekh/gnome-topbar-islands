import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import St from 'gi://St';

import {Extension, gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

/*
 * Top Bar Islands
 *
 * The stylesheet makes the panel itself transparent and paints the left and
 * right clusters as two translucent islands.  By default the panel still
 * reserves its height as a top strut, so maximized windows start below the bar.
 *
 * Overlay mode (~/.config/topbar-islands/overlay) removes the panel's strut so
 * windows can use the full screen height.  The panel actor itself becomes
 * non-reactive, which lets clicks in the empty middle reach the window below;
 * the left and right clusters are made reactive again so their buttons
 * (Activities, clock, status menus) keep working.
 *
 * Clock mode (~/.config/topbar-islands/clock-hidden) hides the date/time
 * cluster and leaves a chevron button beside the clock (the leftmost item of
 * the right island when collapsed).  Clicking the chevron expands the clock
 * again.  Both flags are watched with a file monitor, so the helper scripts
 * apply changes live without reloading the extension and without the shell's
 * unsafe mode.
 *
 * GNOME imports an extension module once per session: a changed extension.js
 * only takes effect after the next login.
 */

const CONFIG_DIR = GLib.build_filenamev([
    GLib.get_user_config_dir(),
    'topbar-islands',
]);
const OVERLAY_FLAG = GLib.build_filenamev([CONFIG_DIR, 'overlay']);
const CLOCK_FLAG = GLib.build_filenamev([CONFIG_DIR, 'clock-hidden']);

function flagExists(path) {
    return GLib.file_test(path, GLib.FileTest.EXISTS);
}

function readFlagValue(path) {
    try {
        const [, contents] = GLib.file_get_contents(path);
        if (!contents)
            return false;
        return new TextDecoder().decode(contents).trim() === '1';
    } catch (e) {
        return false;
    }
}

function writeFlagValue(path, value) {
    GLib.mkdir_with_parents(CONFIG_DIR, 0o755);
    GLib.file_set_contents(path, value ? '1\n' : '0\n');
}

export default class TopBarIslandsExtension extends Extension {
    enable() {
        Main.panel.add_style_class_name('topbar-islands');

        this._panelData = null;
        this._overlayEnabled = false;
        this._savedStruts = true;
        this._savedReactive = Main.panel.reactive;
        this._savedChildReactive = new Map();

        this._dateActor = null;
        this._monitor = null;
        this._monitorId = 0;
        this._sessionModeId = 0;

        this._toggleButton = this._createToggleButton();
        this._placeToggleButton();

        this._applyClockState();

        // The panel re-shows every indicator on a session mode change (for
        // example after unlocking), so reapply the user's clock choice.
        this._sessionModeId = Main.sessionMode.connect(
            'updated', () => this._applyClockState());

        this._watchConfig();
        this._applyOverlayState();
    }

    _getRightBox() {
        if (Main.panel._rightBox)
            return Main.panel._rightBox;
        return Main.panel.get_children().find(
            child => child.get_name() === 'panelRight') ?? null;
    }

    _placeToggleButton() {
        const rightBox = this._getRightBox();
        if (!rightBox || !this._toggleButton)
            return;

        // Sit immediately after the date menu when both share the right box,
        // otherwise at the left edge of the right island.
        const dateActor = this._dateActor;
        if (dateActor && dateActor.get_parent() === rightBox) {
            const index = rightBox.get_children().indexOf(dateActor);
            rightBox.set_child_at_index(this._toggleButton, index + 1);
        } else {
            rightBox.set_child_at_index(this._toggleButton, 0);
        }
    }

    _createToggleButton() {
        const button = new St.Button({
            style_class: 'panel-button topbar-islands-clock-toggle',
            reactive: true,
            can_focus: true,
            track_hover: true,
        });
        button.child = new St.Icon({
            icon_name: 'pan-end-symbolic',
            style_class: 'system-status-icon',
        });
        button.connect('clicked', () => {
            const hidden = !readFlagValue(CLOCK_FLAG);
            writeFlagValue(CLOCK_FLAG, hidden);
            this._applyClockState();
        });
        return button;
    }

    _applyClockState() {
        const hidden = readFlagValue(CLOCK_FLAG);

        const dateMenu = Main.panel.statusArea.dateMenu;
        this._dateActor = dateMenu?.container ?? dateMenu ?? null;
        if (this._dateActor)
            this._dateActor.visible = !hidden;

        if (this._toggleButton) {
            const icon = this._toggleButton.child;
            if (icon) {
                // Collapsed: chevron points left, toward the clock it shows.
                // Expanded: chevron points right, away from the clock it hides.
                icon.icon_name = hidden
                    ? 'pan-start-symbolic'
                    : 'pan-end-symbolic';
            }
            this._toggleButton.accessible_name = hidden
                ? _('Show date and time')
                : _('Hide date and time');
        }

        this._placeToggleButton();
    }

    _watchConfig() {
        try {
            GLib.mkdir_with_parents(CONFIG_DIR, 0o755);
            const dir = Gio.File.new_for_path(CONFIG_DIR);
            this._monitor = dir.monitor_directory(
                Gio.FileMonitorFlags.NONE, null);
            this._monitorId = this._monitor.connect('changed', () => {
                this._applyClockState();
                this._applyOverlayState();
            });
        } catch (e) {
            console.error(`topbar-islands: cannot watch ${CONFIG_DIR}: ${e}`);
        }
    }

    _applyOverlayState() {
        const wanted = flagExists(OVERLAY_FLAG);
        if (wanted === this._overlayEnabled)
            return;
        if (wanted)
            this._enableOverlay();
        else
            this._disableOverlay();
    }

    _enableOverlay() {
        const lm = Main.layoutManager;
        try {
            this._panelData = lm._trackedActors.find(
                data => data.actor === lm.panelBox);
            if (this._panelData) {
                this._savedStruts = this._panelData.affectsStruts;
                this._panelData.affectsStruts = false;
            }

            Main.panel.reactive = false;
            for (const child of Main.panel.get_children()) {
                const name = child.get_name();
                this._savedChildReactive.set(child, child.reactive);
                child.reactive = name === 'panelLeft' || name === 'panelRight';
            }

            this._overlayEnabled = true;
            lm._updateRegions();
        } catch (e) {
            console.error(`topbar-islands overlay: ${e}`);
        }
    }

    _disableOverlay() {
        const lm = Main.layoutManager;
        try {
            if (this._panelData)
                this._panelData.affectsStruts = this._savedStruts;

            Main.panel.reactive = this._savedReactive;
            for (const [child, reactive] of this._savedChildReactive)
                child.reactive = reactive;
            this._savedChildReactive.clear();

            this._overlayEnabled = false;
            lm._updateRegions();
        } catch (e) {
            console.error(`topbar-islands overlay: ${e}`);
        }
        this._panelData = null;
    }

    disable() {
        if (this._monitorId) {
            this._monitor.disconnect(this._monitorId);
            this._monitorId = 0;
        }
        if (this._monitor) {
            this._monitor.cancel();
            this._monitor = null;
        }

        if (this._sessionModeId) {
            Main.sessionMode.disconnect(this._sessionModeId);
            this._sessionModeId = 0;
        }

        if (this._dateActor)
            this._dateActor.visible = true;
        this._dateActor = null;

        if (this._toggleButton) {
            this._toggleButton.destroy();
            this._toggleButton = null;
        }

        this._disableOverlay();

        Main.panel.remove_style_class_name('topbar-islands');
    }
}
