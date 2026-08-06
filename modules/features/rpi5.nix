# modules/features/rpi5.nix
{ self, inputs, ... }:
{
  flake.nixosModules.rpi5 =
    { lib, ... }:
    {
      imports = with inputs.nixos-raspberrypi.nixosModules; [
        raspberry-pi-5.base
        raspberry-pi-5.display-vc4
      ];

      boot.loader.raspberry-pi.bootloader = "kernel";

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
