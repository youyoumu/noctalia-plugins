# Audio Output Name

A bar widget that shows the name of the current audio output device.

Parses `wpctl status` to detect the active PipeWire sink and displays its
human-readable description. Click to cycle through available outputs.

## Plugin

| Field   | Value                                |
| ------- | ------------------------------------ |
| ID      | `youyoumu/audio-output-name`         |
| Entries | Widget: `widget`; Service: `service` |

## Usage

Add the `widget` widget from the Add-widget picker. The widget displays
the name of the active PipeWire audio output. Click the widget to cycle
through available outputs.

## Settings

| Setting | Type    | Default                    | Description                         |
| ------- | ------- | -------------------------- | ----------------------------------- |
| `glyph` | `glyph` | `bluetooth-device-speaker` | Glyph shown before the output name. |
