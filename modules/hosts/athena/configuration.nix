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
        self.nixosModules.zenohd
      ];

      boot.kernelPatches = [
        {
          name = "arm64-4k-pages";
          patch = null;

          structuredExtraConfig = with lib.kernel; {
            ARM64_4K_PAGES = yes;
            ARM64_16K_PAGES = no;
            ARM64_64K_PAGES = no;
          };
        }
      ];
    };
}
