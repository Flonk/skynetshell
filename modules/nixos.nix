{ self }:
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.programs.skynetshell.greeter;
  grubCfg = config.programs.skynetshell.grub;
  t = config.programs.skynetshell.theme;

  # Generate the ASCII config file from settings
  asciiConfigFile = pkgs.writeText "skynetgreet.conf" (
    ''
      name=${cfg.settings.name}
      effect=${cfg.settings.effect}
      exec=${cfg.settings.exec}
    ''
    + optionalString (cfg.settings.color != "") "color=${cfg.settings.color}\n"
    + "\nascii_1=\n${if t != null then t.asciiArt else builtins.readFile "${self}/ascii.txt"}\n"
  );

  # Generate theme .toml from attrset
  themeFile = pkgs.writeText "skynetgreet-theme.toml" (
    ''
      name = "${t.name}"

      [colors]
    ''
    + concatStringsSep "\n" (
      mapAttrsToList (k: v: "${k} = \"${v}\"")
        (removeAttrs t [ "name" "asciiArt" ])
    )
    + "\n"
  );

  greeterPkg = (self.packages.${pkgs.stdenv.hostPlatform.system}.greeter.overrideAttrs (old: {
    postInstall = old.postInstall + ''
      cp ${asciiConfigFile} $out/share/skynetgreet/ascii_configs/hyprland.conf
    '' + optionalString (t != null) ''
      mkdir -p $out/share/skynetgreet/themes
      cp ${themeFile} $out/share/skynetgreet/themes/theme.toml
    '';
  }));

  # Kitty config for the greeter session — no decorations,
  # themed background, custom font rendering.
  kittyConf = pkgs.writeText "skynetgreet-kitty.conf" (''
    font_family ${cfg.font.name}
    font_size ${toString cfg.font.size}
    cursor_shape block
    cursor_blink_interval 0
    enable_audio_bell no
    window_padding_width 0
    hide_window_decorations yes
    confirm_os_window_close 0
  '' + optionalString (t != null) ''
    background ${t.bg_base}
    foreground ${t.fg_primary}
  '');

  # --- GRUB theme derivation ---
  skynetGrubTheme = pkgs.runCommand "skynet-grub-theme"
    {
      nativeBuildInputs = with pkgs; [ imagemagick grub2 ];

      GRUB_BG_COLOR     = if t != null then t.bg_base      else "#141519";
      GRUB_BORDER_COLOR = if t != null then t.accent        else "#D4A645";
      GRUB_BAR_BG       = if t != null then t.bg_active     else "#1C1D24";
      GRUB_BAR_FG       = if t != null then t.fg_secondary  else "#8B92A8";
      GRUB_TEXT_COLOR    = if t != null then t.fg_primary    else "#ffffff";
      GRUB_TEXT_DIM      = if t != null then t.fg_muted      else "#555560";

      GRUB_WIDTH = toString grubCfg.resolution.width;
      GRUB_HEIGHT = toString grubCfg.resolution.height;

      GRUB_ASCII_ART = pkgs.writeText "skynet-ascii.txt"
        (if t != null then t.asciiArt else builtins.readFile "${self}/ascii.txt");
      GRUB_FONT_FAMILY = grubCfg.font.family;
      GRUB_FONT_REGULAR = grubCfg.font.regular;
      GRUB_FONT_BOLD = grubCfg.font.bold;
      GRUB_OUTPUT_DIR = "placeholder";
    }
    ''
      export GRUB_OUTPUT_DIR="$out"
      mkdir -p "$out"
      bash ${self}/grub/generate-assets.sh
    '';

in
{
  options.programs.skynetshell = {
    theme = mkOption {
      type = types.nullOr (types.submodule {
        options = {
          name       = mkOption { type = types.str; default = "theme"; };
          asciiArt   = mkOption {
            type = types.lines;
            default = builtins.readFile "${self}/ascii.txt";
            description = "ASCII art displayed by greeter and rendered into the GRUB background";
          };
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
      description = "Shared theme for greeter and GRUB. If null, hardcoded defaults are used.";
    };

    grub = {
      enable = mkEnableOption "skynetshell GRUB theme";

      resolution = {
        width = mkOption {
          type = types.int;
          default = 1920;
        };
        height = mkOption {
          type = types.int;
          default = 1080;
        };
      };

      font = {
        family = mkOption {
          type = types.str;
          default = "DejaVu Sans Mono";
          description = "Font family name used in theme.txt";
        };
        regular = mkOption {
          type = types.path;
          default = "${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSansMono.ttf";
          description = "Path to regular weight TTF";
        };
        bold = mkOption {
          type = types.path;
          default = "${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSansMono-Bold.ttf";
          description = "Path to bold weight TTF";
        };
      };

      useOSProber = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable os-prober for detecting other OSes";
      };
    };

    greeter = {
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
      };

      font = {
        name = mkOption {
          type = types.str;
          default = "monospace";
          description = "Font name for the greeter (rendered via kitty)";
        };
        size = mkOption {
          type = types.int;
          default = 18;
          description = "Font size in points for the greeter";
        };
        package = mkOption {
          type = types.nullOr types.package;
          default = null;
          description = "Font package to install (e.g. pkgs.nerd-fonts.dejavu-sans-mono)";
        };
      };
    };
  };

  config = mkMerge [
    (mkIf grubCfg.enable {
      boot.loader.grub.enable = true;
      boot.loader.grub.useOSProber = grubCfg.useOSProber;
      boot.loader.grub.theme = skynetGrubTheme;
    })

    (mkIf cfg.enable {
    # The greeter runs inside cage (a minimal kiosk Wayland compositor)
    # with kitty as the terminal emulator.  This gives full TrueType /
    # Nerd Font rendering via kitty's GPU-accelerated text pipeline —
    # something the raw Linux TTY (even with kmscon) cannot match.
    services.greetd = {
      enable = true;
      settings = {
        terminal.vt = 1;
        default_session = {
          command = "${pkgs.cage}/bin/cage -s -- ${pkgs.kitty}/bin/kitty --config=${kittyConf} ${greeterPkg}/bin/skynetgreet";
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

    environment.systemPackages = [ greeterPkg pkgs.cage pkgs.kitty ];

    # Make the greeter font available system-wide so kitty can find it
    fonts.packages = mkIf (cfg.font.package != null) [ cfg.font.package ];

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
      # Suppress kernel messages (e.g. ucsi_acpi) from printing over the greeter
      ExecStartPre = "${pkgs.util-linux}/bin/dmesg --console-off";
      ExecStopPost = "${pkgs.util-linux}/bin/dmesg --console-on";
    };
  })
  ];
}
