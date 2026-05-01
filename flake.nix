{
  description = "Standalone quickshell config extracted from flo's dotfiles";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.writeShellApplication {
            name = "skynetshell";
            runtimeInputs = with pkgs; [
              bluez
              brightnessctl
              coreutils
              curl
              findutils
              gawk
              gnugrep
              iproute2
              libnotify
              networkmanager
              pipewire
              quickshell
              wl-clipboard
              wireplumber
            ];
            text = ''
              exec quickshell --path ${self}/shell "$@"
            '';
          };
        }
      );

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/skynetshell";
        };
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              just
              quickshell
              qt6.qtshadertools
              watchexec
            ];
          };
        }
      );
    };
}
