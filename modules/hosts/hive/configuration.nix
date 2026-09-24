# Bumblebee-NixOS/modules/hosts/hive/configuration.nix
{ self, inputs, ... }:
{
  flake.nixosModules.hiveConfiguration =
    { lib, ... }:
    {
      nixpkgs.config.allowUnfree = true;

      imports = [
        self.nixosModules.rpi5
        self.nixosModules.base
        self.nixosModules.networking
        self.nixosModules.home
        self.nixosModules.isaac
        self.nixosModules.mesh
        # self.nixosModules.zenohd
      ];

      bumblebee.mesh = {
        enable = true;

        phy = "phy0";
        meshId = "bumblebee";

        frequency = 5745;
        channelWidth = "80MHz";

      };
    };
}
