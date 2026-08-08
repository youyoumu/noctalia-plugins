#!/usr/bin/env bash

luau-lsp analyze --definitions=@noctalia=noctalia.d.luau --ignore=noctalia.d.luau --ignore=".luau_modules/**" "${1:-./}"
