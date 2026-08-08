test:
    lune run .tools/test.luau

typecheck:
    .tools/typecheck.sh

validate-plugins:
    .github/workflows/validate-plugins.py

update-catalog:
    .github/workflows/update-catalog.py
