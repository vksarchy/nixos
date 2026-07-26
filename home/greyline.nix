{
  inputs,
  ...
}:
{
  imports = [ inputs.greyline.homeManagerModules.default ];

  # Live multi-timezone world map wallpaper (niri → swww backend).
  # Conflicts with Noctalia's wallpaper manager — disable that while trying this:
  #   noctalia settings → Wallpaper → off
  services.greyline = {
    enable = true;
    backend = "swww";
    # niri has no sway-session.target; bind to the generic graphical session.
    target = "graphical-session.target";
    fontFamily = "Inter";
    settings = {
      theme = "dark";
      format = "24h";
      twilight = {
        bands = true;
        darkness = "subtle";
      };
      # System tz is Asia/Kolkata (modules/baseline.nix)
      home = {
        tz = "auto";
        column_highlight = true;
      };
      city = [
        {
          name = "Chennai";
          lat = 13.08;
          lon = 80.27;
          tz = "Asia/Kolkata";
        }
        {
          name = "London";
          lat = 51.51;
          lon = -0.13;
          tz = "Europe/London";
        }
        {
          name = "New York";
          lat = 40.71;
          lon = -74.01;
          tz = "America/New_York";
        }
        {
          name = "Tokyo";
          lat = 35.68;
          lon = 139.69;
          tz = "Asia/Tokyo";
        }
        {
          name = "Singapore";
          lat = 1.35;
          lon = 103.82;
          tz = "Asia/Singapore";
        }
        {
          name = "San Francisco";
          lat = 37.77;
          lon = -122.42;
          tz = "America/Los_Angeles";
        }
      ];
    };
  };
}
