# modules/features/mesh.nix
{ self, ... }:
{
  flake.nixosModules.mesh =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.bumblebee.mesh;
    in
    {
      options.bumblebee.mesh = {
        enable = lib.mkEnableOption "Bumblebee BATMAN-adv mesh";

        phy = lib.mkOption {
          type = lib.types.str;
          default = "phy0";
        };

        meshId = lib.mkOption {
          type = lib.types.str;
          default = "bumblebee";
        };

        frequency = lib.mkOption {
          type = lib.types.int;
          default = 5745;
        };

        channelWidth = lib.mkOption {
          type = lib.types.str;
          default = "80MHz";
        };

        macAddress = lib.mkOption {
          type = lib.types.str;
        };

        address = lib.mkOption {
          type = lib.types.str;
        };
      };

      config = lib.mkIf cfg.enable {
        boot.kernelModules = [ "batman-adv" ];

        environment.systemPackages = with pkgs; [
          batctl
          iw
          iproute2
        ];

        networking.dhcpcd.denyInterfaces = [
          "mesh0"
          "bat0"
        ];

        systemd.services.batman-mesh = {
          description = "802.11s + BATMAN-adv mesh";
          wantedBy = [ "multi-user.target" ];

          after = [ "systemd-modules-load.service" ];
          wants = [ "systemd-modules-load.service" ];

          path = with pkgs; [
            batctl
            iw
            iproute2
            kmod
            coreutils
          ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };

          script = ''
            set -euo pipefail

            iw reg set US
            modprobe batman-adv

            if iw dev mesh0 info >/dev/null 2>&1; then
              iw dev mesh0 mesh leave 2>/dev/null || true
              ip link set dev mesh0 nomaster 2>/dev/null || true
              iw dev mesh0 del
            fi

            iw phy ${cfg.phy} interface add mesh0 type mp

            # Remove the default managed VIF on the dedicated mesh radio.
            iw dev wlP1p1s0 del 2>/dev/null || true

            ip link set dev mesh0 address ${cfg.macAddress}
            ip addr flush dev mesh0
            ip link set dev mesh0 up

            iw dev mesh0 mesh join ${cfg.meshId} \
              freq ${toString cfg.frequency} \
              ${cfg.channelWidth}

            if ! ip link show bat0 >/dev/null 2>&1; then
              ip link add bat0 type batadv
            fi

            ip link set dev mesh0 master bat0
            ip link set dev bat0 up

            ip addr flush dev bat0
            ip addr add ${cfg.address} dev bat0
          '';

          preStop = ''
            set +e

            ip addr flush dev bat0 2>/dev/null
            ip link set dev mesh0 nomaster 2>/dev/null
            iw dev mesh0 mesh leave 2>/dev/null
            iw dev mesh0 del 2>/dev/null
            ip link del bat0 2>/dev/null
          '';
        };
      };
    };
}
