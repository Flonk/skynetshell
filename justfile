default:
    @just --list

run:
    quickshell --path ./shell

dev:
    watchexec -r -w ./shell -e qml,js,ts,css,json,yaml,yml -- quickshell --path ./shell

fmt:
    nix fmt

# Build all lockscreen shaders (.glsl → .frag.qsb)
shaders:
    ./lockscreen/convert-shaders.sh

# Clean compiled shaders
shaders-clean:
    rm -rf ./shell/shaders/
