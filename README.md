# Noctalia Plugins

<p align="center">
  <img src="https://assets.noctalia.dev/noctalia-logo.svg?v=2" alt="Noctalia Logo" style="width: 192px" />
</p>

---

My personal collection of Noctalia plugins.

## Editor setup

`noctalia.d.luau` declares the whole plugin API (`noctalia.*`, `barWidget.*`,
`shortcut.*`, `launcher.*`, `desktopWidget.*`, `panel.*`, `ui.*`, and the entry
callbacks) so you get autocomplete and typo diagnostics. Type annotations are a
runtime no-op — the Luau VM compiles them away — so this only affects your editor.

1. Install [luau-lsp](https://github.com/JohnnyMorganz/luau-lsp) (VS Code
   extension or standalone language server).
2. Point it at the definitions. This repo ships a `.vscode/settings.json` that
   already does so; for another editor add `noctalia.d.luau` to luau-lsp's
   `types.definitionFiles`.
3. `.luaurc` sets `languageMode` to `nonstrict`, matching the `--!nonstrict`
   directive every plugin file starts with — the right fit for these
   dynamically-typed scripts (full autocomplete and real type/typo diagnostics,
   without strict-mode noise about always-present optional values).
