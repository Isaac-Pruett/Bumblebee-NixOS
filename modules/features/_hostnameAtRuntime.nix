# modules/features/base.nix
{ self, ... }:
{
  flake.nixosModules.hostnameAtRuntime =
    { pkgs, hostname, ... }:
    {

      systemd.services.drone-hostname = {
        description = "Set hostname from drone ID";
        wantedBy = [ "multi-user.target" ];
        before = [ "network-pre.target" ];
        wants = [ "network-pre.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        script = ''
          if [ -f /boot/drone-id ]; then
            name="$(${pkgs.coreutils}/bin/tr -d '\n\r ' < /boot/drone-id)"
            ${pkgs.systemd}/bin/hostnamectl --transient hostname "$name"
          fi
        '';
      };
    };
}
