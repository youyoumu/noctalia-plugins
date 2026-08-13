# Run

A launcher for running custom scripts. Type `/run` in the launcher to see
available scripts. Select one to run it in the background.

## Plugin

| Field           | Value                        |
| --------------- | ---------------------------- |
| ID              | `youyoumu/run`               |
| Entries         | Launcher provider: `scripts` |
| Launcher Prefix | `/run`                       |

## Usage

Type `/run` in the Noctalia launcher to search and run custom scripts.
Select a script to execute it in the background.

## Settings

| Setting       | Type   | Default        | Description                                                             |
| ------------- | ------ | -------------- | ----------------------------------------------------------------------- |
| `scripts_path` | `file` | `scripts.json` | Path to a JSON file describing the scripts shown by `/run`. Point it at your own file to add, remove, or modify scripts. |
