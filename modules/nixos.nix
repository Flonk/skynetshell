{ self }:
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.programs.skynetshell.greeter;

  # Generate the ASCII config file from settings
  asciiConfigFile = pkgs.writeText "skynetgreet.conf" (
    ''
      name=${cfg.settings.name}
      effect=${cfg.settings.effect}
      exec=${cfg.settings.exec}
    ''
    + optionalString (cfg.settings.color != "") "color=${cfg.settings.color}\n"
    + "\nascii_1=\n${cfg.settings.asciiArt}\n"
  );

  # Generate theme .toml from attrset
  themeFile = pkgs.writeText "skynetgreet-theme.toml" (
    ''
      name = "${cfg.theme.name}"

      [colors]
    ''
    + concatStringsSep "\n" (
      mapAttrsToList (k: v: "${k} = \"${v}\"")
        (removeAttrs cfg.theme [ "name" ])
    )
    + "\n"
  );

  greeterPkg = (self.packages.${pkgs.stdenv.hostPlatform.system}.greeter.overrideAttrs (old: {
    postInstall = old.postInstall + ''
      cp ${asciiConfigFile} $out/share/skynetgreet/ascii_configs/hyprland.conf
    '' + optionalString (cfg.theme != null) ''
      mkdir -p $out/share/skynetgreet/themes
      cp ${themeFile} $out/share/skynetgreet/themes/theme.toml
    '';
  }));

in
{
  options.programs.skynetshell.greeter = {
    enable = mkEnableOption "skynetgreet greeter for greetd";

    settings = {
      name = mkOption {
        type = types.str;
        default = "hyprland";
      };
      effect = mkOption {
        type = types.enum [ "beams" "" ];
        default = "beams";
      };
      exec = mkOption {
        type = types.str;
        description = "Command to launch after successful login (e.g. \"start-hyprland\")";
      };
      color = mkOption {
        type = types.str;
        default = "";
        description = "Optional hex color override for ASCII art (e.g. \"#89b4fa\")";
      };
      asciiArt = mkOption {
        type = types.lines;
        default = "";
        description = "Multi-line ASCII art block";
      };
    };

    theme = mkOption {
      type = types.nullOr (types.submodule {
        options = {
          name       = mkOption { type = types.str; default = "theme"; };
          bg_base    = mkOption { type = types.str; };
          bg_active  = mkOption { type = types.str; };
          primary    = mkOption { type = types.str; };
          secondary  = mkOption { type = types.str; };
          accent     = mkOption { type = types.str; };
          warning    = mkOption { type = types.str; };
          danger     = mkOption { type = types.str; };
          fg_primary   = mkOption { type = types.str; };
          fg_secondary = mkOption { type = types.str; };
          fg_muted     = mkOption { type = types.str; };
          border_focus = mkOption { type = types.str; };
        };
      });
      default = null;
      description = "Theme colors. If null, no theme is installed and hardcoded defaults are used.";
    };
  };

  config = mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = {
        terminal.vt = 1;
        default_session = {
          command = "${greeterPkg}/bin/skynetgreet";
          user = "greeter";
        };
      };
    };

    users.users.greeter = {
      isSystemUser = true;
      group = "greeter";
      home = "/var/lib/greeter";
      createHome = true;
    };
    users.groups.greeter = { };

    environment.systemPackages = [ greeterPkg ];

    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if ((action.id == "org.freedesktop.login1.power-off" ||
             action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
             action.id == "org.freedesktop.login1.reboot" ||
             action.id == "org.freedesktop.login1.reboot-multiple-sessions") &&
            subject.user == "greeter") {
          return polkit.Result.YES;
        }
      });
    '';

    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
      # Suppress kernel messages (e.g. ucsi_acpi) from printing over the greeter TUI
      ExecStartPre = "${pkgs.util-linux}/bin/dmesg --console-off";
    };
  };
}
