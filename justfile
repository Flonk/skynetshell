default:
    @just --list

run:
    quickshell --path ./shell

dev:
    ./scripts/quickshell-dev

dev-no-watch:
    ./scripts/quickshell-dev --no-watch

sync-from-live:
    QS_DEV_SKIP_WATCH=1 ./scripts/quickshell-dev --sync-only

fmt:
    nix fmt