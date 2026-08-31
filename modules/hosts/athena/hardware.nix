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
        base-dt-params.enable_uart = {
          enable = true;
          value = "1";
        };
        dt-overlays.uart3 = {
          enable = true;
          params = { };
        };
      };
    };
    systemd.services."serial-getty@ttyAMA3" = {
      wantedBy = lib.mkForce [];
      enable = false;
    };



    # # boot.kernelParams = [ "cma=256M" ];
    # boot.kernelModules = [ "mt7915e" ];
  };
}
