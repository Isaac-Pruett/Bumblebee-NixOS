{
  self,
  inputs,
  lib,
  ...
}:
{
  flake.nixosModules.zenohd =
    { pkgs, ... }:
    let
      serial_conn = "/dev/ttyAMA3";
      baudrate = "115200";

      version = "1.9.0";

      craneLib = inputs.crane.mkLib pkgs;

      src = pkgs.fetchFromGitHub {
        owner = "eclipse-zenoh";
        repo = "zenoh";
        rev = "1.9.0";
        hash = "sha256-sFHUphFu5a+buSa3GQvSmGo8SFtn3V5ZqTOnWMPlvs8=";

      };

      cargoExtraArgs = "--bin zenohd --no-default-features --features transport_tcp,transport_udp,transport_serial";

      cargoArtifacts = craneLib.buildDepsOnly {
        pname = "zenoh-deps";
        inherit src;
        inherit cargoExtraArgs;
      };

      zenohd = craneLib.buildPackage {
        pname = "zenohd";
        version = "1.9.0";
        inherit src cargoArtifacts;

        inherit cargoExtraArgs;
        doCheck = false;
      };

    in
    {
      environment.systemPackages = [ zenohd ];

      systemd.services."serial-getty@ttyAMA0".enable = false;
      systemd.services."serial-getty@ttyAMA3".enable = false;

      # systemd.services.zenohd-serial = {
      #   wantedBy = [ "multi-user.target" ];
      #   after = [ "network.target" ];
      #   serviceConfig = {
      #     ExecStart = "${zenohd}/bin/zenohd --no-multicast-scouting -l serial/${serial_conn}#baudrate=${baudrate}";
      #     Restart = "always";
      #     SupplementaryGroups = [ "dialout" ];
      #   };
      # };
    };
}
