{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  packages = with pkgs; [
    go_1_25
    grub2
    imagemagick
    just
    mtools
    OVMF.fd
    python3
    qemu
    quickshell
    watchexec
    xorriso
  ];
}
