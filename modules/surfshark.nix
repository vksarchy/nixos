{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.workstation.surfshark;
in
{
  options.workstation.surfshark = {
    enable = lib.mkEnableOption "Surfshark VPN via WireGuard";
    privateKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to agenix-decrypted Surfshark private key";
      example = config.age.secrets.surfshark-key.path or "/run/agenix/surfshark-key";
    };
    endpoint = lib.mkOption {
      type = lib.types.str;
      description = "Surfshark WireGuard server host:port";
      example = "us-nyc.prod.surfshark.com:51820";
    };
    serverPublicKey = lib.mkOption {
      type = lib.types.str;
      description = "Surfshark server WireGuard public key";
      example = "gNulCx0s1X2cG3JkLmNpQrStUvWxYzAbCdEfGhIjKlMn=";
    };
    address = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "10.14.0.2/16" ];
      description = "WireGuard interface address(es) assigned by Surfshark";
    };
    dns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "162.252.172.57"
        "149.154.159.92"
      ];
      description = "Surfshark DNS servers";
    };
    allowedIPsAsExceptions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "192.168.0.0/24" ];
      description = "Subnets to route outside the VPN tunnel (LAN, etc.)";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.wireguard-tools ];

    networking.wg-quick.interfaces.wg-surfshark = {
      address = cfg.address;
      dns = cfg.dns;
      privateKeyFile = cfg.privateKeyFile;

      peers = [
        {
          publicKey = cfg.serverPublicKey;
          allowedIPs = [ "0.0.0.0/0" ];
          endpoint = cfg.endpoint;
          persistentKeepalive = 25;
        }
      ];

       postUp = ''
        IFACE=$(${pkgs.iproute2}/bin/ip route show default | head -n1 | ${pkgs.gawk}/bin/awk '{print $5}')
        ${pkgs.iproute2}/bin/ip route show dev $IFACE proto kernel | while read subnet _; do
          ${pkgs.iproute2}/bin/ip route add $subnet dev $IFACE || true
        done
      '';
      preDown = ''
        IFACE=$(${pkgs.iproute2}/bin/ip route show default | head -n1 | ${pkgs.gawk}/bin/awk '{print $5}')
        ${pkgs.iproute2}/bin/ip route show dev $IFACE proto kernel | while read subnet _; do
          ${pkgs.iproute2}/bin/ip route del $subnet dev $IFACE || true
        done
      '';  
    };
  };
}
