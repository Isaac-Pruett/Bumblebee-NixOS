# hosts/athena/hardware.nix
{ self, lib, ... }:
{
  flake.nixosModules.athenaHardware =
  { pkgs, ... }:
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


    hardware.raspberry-pi.config = {
      all = {
        base-dt-params.enable_uart = {
          enable = true;
          value = "1";
        };

        dt-overlays.uart3 = {
          enable = true;
          params = {
            # ctsrts = {
            #   enable = true;
            #   value = "on";
            # };
          };
        };
      };
    };




    systemd.services."serial-getty@ttyAMA3" = {
      wantedBy = lib.mkForce [];
      enable = false;
    };

    boot.kernelParams = lib.mkForce [ "console=tty1" ];





  };
}
