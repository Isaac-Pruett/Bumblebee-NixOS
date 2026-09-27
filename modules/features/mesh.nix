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
          description = "Wi-Fi PHY used for the dedicated mesh radio.";
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
          gawk
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
            gawk
          ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };

          script = ''
            set -euo pipefail

            PHY="${cfg.phy}"
            PHY_INDEX="''${PHY#phy}"

            iw reg set US
            modprobe batman-adv

            # Helper: list all netdevs belonging to this PHY.
            get_phy_interfaces() {
              iw dev | awk -v phy="phy#$PHY_INDEX" '
                $1 == phy {
                  in_phy = 1
                  next
                }

                /^phy#/ {
                  in_phy = 0
                }

                in_phy && $1 == "Interface" {
                  print $2
                }
              '
            }

            # Clean up an existing mesh0 from a previous service run.
            if iw dev mesh0 info >/dev/null 2>&1; then
              iw dev mesh0 mesh leave 2>/dev/null || true
              ip link set dev mesh0 nomaster 2>/dev/null || true
              iw dev mesh0 del
            fi

            # Create our 802.11s interface.
            iw phy "$PHY" interface add mesh0 type mp

            # This PHY is dedicated to the mesh.
            #
            # Remove any other netdev that may have been automatically
            # created for this radio, regardless of its predictable
            # interface name.
            for IFACE in $(get_phy_interfaces); do
              if [ "$IFACE" != "mesh0" ]; then
                iw dev "$IFACE" del 2>/dev/null || true
              fi
            done

            # Derive a stable locally-administered MAC for mesh0 from the
            # permanent MAC of the selected physical radio.
            PERM_MAC="$(cat "/sys/class/ieee80211/$PHY/macaddress")"
            MESH_MAC="02:$(printf '%s' "$PERM_MAC" | cut -d: -f2-)"

            ip link set dev mesh0 address "$MESH_MAC"

            # mesh0 is only BATMAN's lower-layer transport interface.
            # It should not carry IP configuration itself.
            ip -4 addr flush dev mesh0
            ip -6 addr flush dev mesh0

            ip link set dev mesh0 up


            # Join the 802.11s mesh.
            iw dev mesh0 mesh join ${lib.escapeShellArg cfg.meshId} \
              freq ${toString cfg.frequency} \
              ${cfg.channelWidth}

            #
            # Create BATMAN-adv virtual interface.
            #
            if ! ip link show bat0 >/dev/null 2>&1; then
              ip link add bat0 type batadv
            fi

            ip link set dev mesh0 master bat0

            ip -4 addr flush dev bat0


            # Bringing bat0 up causes Linux to automatically create an
            # IPv6 link-local address in fe80::/64.
            ip link set dev bat0 up

            # Show resulting address in the systemd journal.
            echo "BATMAN mesh started"
            echo "mesh0 MAC: $MESH_MAC"
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
