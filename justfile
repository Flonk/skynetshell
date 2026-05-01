default:
    @just --list

run:
    quickshell --path ./quickshell/shell

dev:
    watchexec -r -w ./quickshell/shell -e qml,js,ts,css,json,yaml,yml -- quickshell --path ./quickshell/shell

fmt:
    nix fmt

# Build all lockscreen shaders (.glsl → .frag.qsb)
shaders:
    ./quickshell/lockscreen/convert-shaders.sh

# Clean compiled shaders
shaders-clean:
    rm -rf ./quickshell/shell/shaders/

# Run greeter in test mode
greet-test:
    cd greeter && go run ./cmd/skynetgreet --test --data-dir .

# Preview GRUB theme in QEMU
grub-preview resolution="1920x1080":
    cd grub && bash preview.sh {{resolution}}
