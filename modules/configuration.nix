{ config, pkgs, lib, nixpkgs, specialArgs, ... }: with specialArgs;
{
  nix = {
    package = pkgs.nixUnstable;

    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    # reuse flakes inputs for old commands
    nixPath = [ "nixpkgs=${nixpkgs}" ];

    # always uses system's flakes instead of downloading or updating
    registry.nixpkgs.flake = nixpkgs;
  };

  networking = {
    firewall.enable = false;
    usePredictableInterfaceNames = true;
  };

  time.timeZone = "America/Sao_Paulo";

  i18n = {
    defaultLocale = "en_GB.UTF-8";
    supportedLocales = [ "en_GB.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" "pt_BR.UTF-8/UTF-8" ];
    # broken, fix later
    # extraLocaleSettings = {
    #   LC_TIME = "pt_BR.UTF-8/UTF-8";
    # };
  };

  #
  # packages
  #

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    nix-alien.overlays.default
  ];

  environment.systemPackages = with pkgs; [
    agenix.packages."${system}".default # secrets
    cachix # cache

    # shell
    fish
    fishPlugins.autopair-fish # probably not needed
    fishPlugins.colored-man-pages
    fishPlugins.done # probably never used
    fishPlugins.foreign-env # probably not needed
    fishPlugins.sponge
    fishPlugins.tide
    any-nix-shell

    # git
    git
    micro

    # compression
    p7zip
    unrar
    unzip

    # tooling
    htop
    traceroute
    killall
    neofetch
    mosh # probably never used

    # used to support languagetool in vscode
    adoptopenjdk-jre-openj9-bin-16

    # used just to setup cloudflare warp
    chromium
    xdg-utils
    desktop-file-utils

    # nix-alien
    nix-alien
    nix-index # not necessary, but recommended
    nix-index-update

    # other
    wget
    jq
    nixpkgs-fmt
    ltex-ls
  ];

  environment.shells = with pkgs; [ fish ];

  #
  # default env
  #

  environment.variables = {
    EDITOR = "micro";
    TERM = "xterm-256color";
    COLORTERM = "truecolor";
    MICRO_TRUECOLOR = "1";
  };

  #
  # services
  #

  services.timesyncd.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      passwordAuthentication = false;
      kbdInteractiveAuthentication = false;
    };
  };

  #
  # default home-manager config
  #

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = specialArgs;
  };
}