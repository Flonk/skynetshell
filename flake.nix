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
          runtimeTools = with pkgs; [
            bash
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
          devRuntimeTools =
            runtimeTools
            ++ (with pkgs; [
              git
              rsync
              watchexec
            ]);
        in
        {
          default = pkgs.writeShellApplication {
            name = "skynetshell";
            runtimeInputs = runtimeTools;
            text = ''
              exec quickshell --path ${self}/shell "$@"
            '';
          };

          quickshell-dev = pkgs.writeShellApplication {
            name = "quickshell-dev";
            runtimeInputs = devRuntimeTools;
            text = ''
              repo_root="${self}"
              if [ -n "''${QS_DEV_REPO_ROOT:-}" ] && [ -d "''${QS_DEV_REPO_ROOT}/scripts" ]; then
                repo_root="''${QS_DEV_REPO_ROOT}"
              elif [ -d "$HOME/repos/personal/skynetshell/scripts" ]; then
                repo_root="$HOME/repos/personal/skynetshell"
              fi

              export QS_DEV_REPO_ROOT="$repo_root"
              exec bash "$repo_root/scripts/quickshell-dev" "$@"
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
              bluez
              brightnessctl
              git
              just
              rsync
              libnotify
              networkmanager
              pipewire
              quickshell
              watchexec
              wl-clipboard
              wireplumber
            ];
          };
        }
      );
    };
}
