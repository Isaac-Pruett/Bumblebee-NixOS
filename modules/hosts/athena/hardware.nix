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

    # --- MT7915 (AW7915-NP1) experiment, kernel 6.18.34 ---
    # EXPECTED OUTCOME: probe failure with -12 (ENOMEM). This is a
    # deliberate bench test to get first-party evidence on this
    # kernel before deciding whether to pin an older kernel or
    # abandon the PCIe path. See dmesg triage notes below.

    hardware.deviceTree = {
      enable = true;
      overlays = [
        {
          name = "pcie1-dma-ranges-30bit";
          dtsText = ''
            /dts-v1/;
            / {
              compatible = "brcm,bcm2712";
              fragment@0 {
                target = <0xffffffff>;
                __overlay__ {
                  #address-cells = <0x03>;
                  #size-cells = <0x02>;
                  dma-ranges = <0x2000000 0x00 0x00 0x00 0x00 0x00 0x80000000>;
                };
              };
              __fixups__ {
                pcie1 = "/fragment@0:target:0";
              };
            };
          '';
        }
      ];
    };

    boot.kernelParams = [
      "cma=256M"
      "iommu.strict=0"
      "iommu.passthrough=0"
      "dma_debug=off"
    ];

    boot.kernelModules = [ "mt7915e" ];
  };
}
