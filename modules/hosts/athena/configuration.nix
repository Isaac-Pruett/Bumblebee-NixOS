# Bumblebee-NixOS/modules/hosts/athena/configuration.nix
{ self, inputs, ... }:
{
  flake.nixosModules.athenaConfiguration =
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

        macAddress = "02:0a:52:0d:df:58";
        address = "10.42.0.1/24";
      };
    };
}
