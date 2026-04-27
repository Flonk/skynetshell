default:
    @just --list

run:
    quickshell --path ./shell

dev:
    watchexec -r -w ./shell -e qml,js,ts,css,json,yaml,yml -- quickshell --path ./shell

fmt:
    nix fmt