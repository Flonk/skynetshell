{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  packages = with pkgs; [
    bash
    bluez
    brightnessctl
    coreutils
    curl
    findutils
    gawk
    git
    gnugrep
    iproute2
    just
    libnotify
    networkmanager
    pipewire
    quickshell
    rsync
    watchexec
    wl-clipboard
    wireplumber
  ];

  shellHook = ''
    export QS_DEV_REPO_ROOT="$PWD"
  '';
}
