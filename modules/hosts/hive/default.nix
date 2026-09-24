{ self, inputs, ... }:
let
  hostname = import ../../../hostname.nix;
  specialArgs = {
    inherit (inputs) nixos-raspberrypi;
    inherit hostname;
  };
in
{
  flake.nixosConfigurations = {
    hive = inputs.nixos-raspberrypi.lib.nixosSystem {
      inherit specialArgs;
      modules = [
        inputs.agenix.nixosModules.default
        inputs.home-manager.nixosModules.home-manager
        self.nixosModules.hiveConfiguration
        self.nixosModules.hiveHardware
      ];
    };

    hive-installer = inputs.nixos-raspberrypi.lib.nixosInstaller {
      inherit specialArgs;
      modules = [
        inputs.agenix.nixosModules.default
        inputs.home-manager.nixosModules.home-manager
        self.nixosModules.hiveConfiguration
      ];
    };
  };

  flake.packages.aarch64-linux.sd-image =
    self.nixosConfigurations.hive-installer.config.system.build.sdImage;
  flake.packages.x86_64-linux.sd-image =
    self.nixosConfigurations.hive-installer.config.system.build.sdImage;
}
