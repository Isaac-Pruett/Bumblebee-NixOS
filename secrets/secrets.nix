let
  isaac = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICu6nS96uOLf4wQ+W6Uncnjh276dffhewG9zxeqQ7YSi";

  bumblebee = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMfKhs3kyoU51LlAc6Ac3zG+UpyihbEUv+C+vLbJ/vlc root@bumblebee";

  ares = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/1QTkednAKhEUI13qV04T8RUCttp2r1KvneORSTWgm root@ares";
in
{
  "wireless.env.age".publicKeys = [
    isaac
    bumblebee
    ares
  ];

  "tailscale-authkey.age".publicKeys = [
    isaac
    bumblebee
    ares
  ];
}
