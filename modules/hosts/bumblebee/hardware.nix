# hosts/bumblebee/hardware.nix
{ self, lib, ... }:
{
  flake.nixosModules.bumblebeeHardware =
    { pkgs, lib, ... }:
    {
      fileSystems."/" = {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
      };

      fileSystems."/boot/firmware" = {
        device = "/dev/disk/by-label/FIRMWARE";
        fsType = "vfat";
        neededForBoot = true;
      };

      hardware.enableRedistributableFirmware = true;

      hardware.raspberry-pi.config = {
        all = {
          base-dt-params = {
            enable_uart = {
              enable = true;
              value = "1";
            };

            pciex1 = {
              enable = true;
              value = "on";
            };
          };

          dt-overlays = {
            uart3 = {
              enable = true;
              params = { };
            };

            pcie-32bit-dma-pi5 = {
              enable = true;
              params = { };
            };
          };
        };
      };

      boot.kernelModules = [ "mt7915e" ];

      systemd.services."serial-getty@ttyAMA3" = {
        wantedBy = lib.mkForce [ ];
        enable = false;
      };
    };
}
