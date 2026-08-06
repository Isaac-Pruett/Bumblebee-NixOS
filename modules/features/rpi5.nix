# modules/features/rpi5.nix
{ self, inputs, ... }:
{
  flake.nixosModules.rpi5 =
    { ... }:
    {
      imports = with inputs.nixos-raspberrypi.nixosModules; [
        raspberry-pi-5.base
        raspberry-pi-5.page-size-4k
        raspberry-pi-5.display-vc4
      ];
      boot.loader.raspberry-pi.bootloader = "kernel";
    };
}
