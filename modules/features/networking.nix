{ self, ... }:
{
  flake.nixosModules.networking =
    {
      config,
      pkgs,
      hostname,
      lib,
      ...
    }:
    let
      wirelessSecret = config.age.secrets."wireless-env".path;
      tailscaleKey = config.age.secrets."tailscale-authkey".path;
    in
    {
      age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      networking.hostName = hostname;
      networking.networkmanager.enable = lib.mkForce false;
      age.secrets."wireless-env".file = ../../secrets/wireless.env.age;
      age.secrets."tailscale-authkey".file = ../../secrets/tailscale-authkey.age;

      systemd.services.wpa_supplicant = {
        preStart = ''
          for i in $(seq 1 30); do
            if [ -e ${config.age.secrets."wireless-env".path} ]; then
              exit 0
            fi
            echo "waiting for wireless-env secret..."
            sleep 1
          done

          echo "wireless-env secret did not appear"
          exit 1
        '';

        restartTriggers = [
          config.age.secrets."wireless-env".file
        ];
      };

      networking.wireless = {
        enable = true;
        secretsFile = wirelessSecret;
        networks."Hogsmeade_5G".pskRaw = "ext:HOGSMEADE_5G_PSK";
      };

      services.tailscale.enable = true;

      systemd.services.tailscale-autoconnect = {
        description = "Automatically connect to Tailscale";
        after = [
          "network-online.target"
          "tailscaled.service"
        ];
        wants = [ "network-online.target" ];
        requires = [ "tailscaled.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig.Type = "oneshot";

        script = ''
          status="$(${pkgs.tailscale}/bin/tailscale status -json | ${pkgs.jq}/bin/jq -r .BackendState || true)"
          if [ "$status" = "Running" ]; then
            exit 0
          fi

          ${pkgs.tailscale}/bin/tailscale up --auth-key "$(< ${tailscaleKey})"
        '';
      };
    };
}
