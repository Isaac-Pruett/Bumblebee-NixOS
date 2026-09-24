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

            #
            # Clean up an existing mesh interface.
            #
            if iw dev mesh0 info >/dev/null 2>&1; then
              iw dev mesh0 mesh leave 2>/dev/null || true
              ip link set dev mesh0 nomaster 2>/dev/null || true
              iw dev mesh0 del
            fi

            #
            # Create the 802.11s interface.
            #
            iw phy ${cfg.phy} interface add mesh0 type mp

            # Remove the default managed VIF on the dedicated mesh radio.
            iw dev wlP1p1s0 del 2>/dev/null || true

            #
            # Give mesh0 a stable locally-administered MAC based on the
            # physical radio's permanent MAC.
            #
            PERM_MAC="$(cat /sys/class/ieee80211/${cfg.phy}/macaddress)"
            MESH_MAC="02:$(printf '%s' "$PERM_MAC" | cut -d: -f2-)"

            ip link set dev mesh0 address "$MESH_MAC"

            #
            # mesh0 itself should not have L3 addresses. BATMAN owns bat0.
            #
            ip addr flush dev mesh0
            ip link set dev mesh0 up

            #
            # Join the 802.11s mesh.
            #
            iw dev mesh0 mesh join ${cfg.meshId} \
              freq ${toString cfg.frequency} \
              ${cfg.channelWidth}

            #
            # Create BATMAN-adv virtual interface.
            #
            if ! ip link show bat0 >/dev/null 2>&1; then
              ip link add bat0 type batadv
            fi

            ip link set dev mesh0 master bat0

            #
            # We don't want an IPv4 address on bat0.
            #
            ip -4 addr flush dev bat0

            #
            # Bring BATMAN up.
            #
            # Linux will automatically generate an IPv6 link-local address
            # (fe80::/64) for bat0.
            #
            ip link set dev bat0 up

            #
            # Useful diagnostic output in journalctl.
            #
            ip -6 addr show dev bat0 scope link
          '';

          preStop = ''
            set +e

            ip link set dev mesh0 nomaster 2>/dev/null
            iw dev mesh0 mesh leave 2>/dev/null
            iw dev mesh0 del 2>/dev/null
            ip link del bat0 2>/dev/null
          '';
        };
      };
    };
}
