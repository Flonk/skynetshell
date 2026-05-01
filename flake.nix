{
  description = "SKYNET shell (quickshell bar + lockscreen) and greeter (greetd TUI)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = lib.genAttrs systems;
      nixosModule = import ./modules/nixos.nix { inherit self; };
      homeManagerModule = import ./modules/home-manager.nix { inherit self; };
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
              exec quickshell --path ${self}/quickshell/shell "$@"
            '';
          };

          greeter = pkgs.buildGoModule rec {
            pname = "skynetgreet";
            version = "1.0.7";

            src = ./greeter;

            vendorHash = "sha256-UeCAZ+I2dxh/i5JeszuZ/KzbPB/iT4PEKI/XelLcxyA=";

            ldflags = [
              "-X main.Version=${version}"
              "-X main.GitCommit=${self.rev or "dev"}"
              "-X main.BuildDate=1970-01-01"
              "-X main.dataDir=${placeholder "out"}/share/skynetgreet"
            ];

            subPackages = [ "cmd/skynetgreet" ];
            buildVcsInfo = false;

            postInstall = ''
              mkdir -p $out/share/skynetgreet/ascii_configs
              cp -r ascii_configs/* $out/share/skynetgreet/ascii_configs/
            '';

            meta = with pkgs.lib; {
              description = "Graphical console greeter for greetd with ASCII art and themes";
              license = licenses.gpl3Only;
              platforms = platforms.linux;
              mainProgram = "skynetgreet";
            };
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
              go_1_25
              grub2
              imagemagick
              just
              mtools
              OVMF.fd
              python3
              qemu
              quickshell
              qt6.qtshadertools
              watchexec
              xorriso
            ];
          };
        }
      );

      nixosModules.default = nixosModule;
      homeManagerModules.default = homeManagerModule;
    };
}
