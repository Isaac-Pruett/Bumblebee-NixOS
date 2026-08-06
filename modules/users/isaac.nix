{ self, ... }:

{
  flake.nixosModules.isaac =
    { pkgs, ... }:
    {
      users.users.isaac = {
        isNormalUser = true;
        description = "Isaac";
        shell = pkgs.zsh;
        extraGroups = [
          "wheel"
          "networkmanager"
          "dialout"
          "gpio"
        ];
        hashedPassword = "$y$j9T$347eNzn/hAlwANwJKIWt8/$VykLNHB6zt3uB2Z4d2VbrXDAIQZM/h4tBh65yGRHhV9";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICu6nS96uOLf4wQ+W6Uncnjh276dffhewG9zxeqQ7YSi isaac"
        ];
      };

      home-manager.users.isaac = {
        home.username = "isaac";
        home.homeDirectory = "/home/isaac";
        home.stateVersion = "25.11";

        home.packages = with pkgs; [
          git
          helix
          btop
          # uv
          tailscale
          pciutils
          tmux
          gh
        ];

        programs.zsh = {
          enable = true;
          enableCompletion = true;
          autosuggestion.enable = true;
          syntaxHighlighting.enable = true;
          shellAliases = rec {
            update = "sudo nixos-rebuild switch --flake .#";
            rebuild = update;
          };

        };
      };
    };
}
