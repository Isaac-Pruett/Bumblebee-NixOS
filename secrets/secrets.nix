let
  isaac = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICu6nS96uOLf4wQ+W6Uncnjh276dffhewG9zxeqQ7YSi";

  athena = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN4qPmDE8UBIBEqijaf9yntrp/WKD4vLg3dnXOKFWQaz root@athena";
in
{
  "wireless.env.age".publicKeys = [ isaac athena ];
  "tailscale-authkey.age".publicKeys = [ isaac athena ];
}
