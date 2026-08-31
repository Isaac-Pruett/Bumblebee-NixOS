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

    boot.kernelParams = [ "cma=256M" ];
    boot.kernelModules = [ "mt7915e" ];


    hardware.deviceTree.overlays = [
      {
        name = "pciex1-32bit-dma";
        dtsText = ''
          /dts-v1/;
          /plugin/;

          / {
            compatible = "brcm,bcm2712";

            fragment@0 {
              target = <0xffffffff>;
              __overlay__ {
                #address-cells = <0x03>;
                #size-cells = <0x02>;

                /* Permit DMA addresses 0x00000000–0x7fffffff. */
                dma-ranges =
                  <0x03000000 0x00 0x00 0x00 0x00 0x00 0x80000000>;
              };
            };

            __fixups__ {
              pciex1 = "/fragment@0:target:0";
            };
          };
        '';
      }
    ];

    systemd.services."serial-getty@ttyAMA3" = {
      wantedBy = lib.mkForce [];
      enable = false;
    };


  };
}

