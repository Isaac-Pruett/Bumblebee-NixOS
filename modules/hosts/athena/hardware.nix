# hosts/athena/hardware.nix
{ self, lib, ... }:
{
  flake.nixosModules.athenaHardware =
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

          pciex1.enable = true;
        };

        dt-overlays.uart3 = {
          enable = true;
          params = { };
        };
      };
    };

    # boot.kernelParams = [ "cma=256M" ];
    boot.kernelModules = [ "mt7915e" ];


    hardware.deviceTree.overlays = [
      {
        name = "pcie-32bit-dma-pi5";
        dtsFile =
          "${pkgs.raspberrypifw}/share/raspberrypi/boot/overlays/pcie-32bit-dma-pi5.dtbo";
      }
    ];

    systemd.services."serial-getty@ttyAMA3" = {
      wantedBy = lib.mkForce [];
      enable = false;
    };


  };
}
