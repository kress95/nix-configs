{ config, pkgs, lib, specialArgs, ... }:
with lib;
with specialArgs;
let
  cfg = config.module.fish;
  bin = "${config.programs.fish.package}/bin/fish";
in
{
  imports = [
    ../bash
  ];

  options.module.fish = {
    enable = mkEnableOption "fish module";
    wsl = {
      enable = mkEnableOption "fish wsl module";
      desktop = mkOption { type = types.nullOr types.str; };
      windir = mkOption { type = types.nullOr types.str; };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      module.bash.enable = true;

      home.file =
        {
          ".profile".text = ''
            if [[ $(ps --no-header --pid=$PPID --format=comm) != "fish" && -z "$BASH_EXECUTION_STRING" ]]
            then
              exec ${bin}
            fi
          '';
        };

      programs.fish = {
        enable = true;
        shellAliases = {
          "ns" = "nix search nixpkgs";
        };
        shellInit =
          let
            wsl =
              if cfg.wsl.enable then
                "set -g w \"${cfg.wsl.desktop}/\""
              else
                "";
          in
          ''
            set -g SHELL "${bin}"
            ${(builtins.readFile ./shell_init.fish)}
          '';
        plugins = [
          { name = "autopair-fish"; src = pkgs.fishPlugins.autopair-fish.src; }
          { name = "colored-man-pages"; src = pkgs.fishPlugins.colored-man-pages.src; }
          { name = "done"; src = pkgs.fishPlugins.done.src; } # probably never used
          { name = "foreign-env"; src = pkgs.fishPlugins.foreign-env.src; } # probably not needed
          { name = "sponge"; src = pkgs.fishPlugins.sponge.src; }
          { name = "tide"; src = pkgs.fishPlugins.tide.src; }
        ];
      };
    })

    (mkIf (cfg.enable && cfg.wsl.enable) {
      programs.fish = {
        functions = {
          code = ''
            if count $argv >/dev/null
              set here (realpath -m $argv[1])
            else
              set here $PWD
            end
            if test -d $here
              powershell "code --folder-uri=vscode-remote://ssh-remote+localhost$here"
            else
              powershell "code --file-uri=vscode-remote://ssh-remote+localhost$here"
            end
          '';
          explorer = ''
            if count $argv >/dev/null
              set here (realpath -m $argv[1])
            else
              set here $PWD
            end
            # TODO: check if $here is a drive letter
            set here (string replace -a '/' '\\' "//${nixosConfig.networking.hostName}.localhost/${distro}$here")
            ${cfg.wsl.windir}/explorer.exe $here
          '';
        };
      };
    })
  ];
}
