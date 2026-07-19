{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.workstation.hermes;
in
{
  options.workstation.hermes = {
    enable = lib.mkEnableOption "Hermes AI agent gateway service";

    model = lib.mkOption {
      type = lib.types.str;
      default = "deepseek/deepseek-v4-pro";
      description = "Default LLM model for Hermes";
    };

    customProviders = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      description = "Custom provider definitions (e.g., Grok proxy) added to settings.custom_providers";
    };

    addToCli = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Put hermes CLI on system PATH and share state with the gateway service";
    };

    container = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run Hermes in an Ubuntu container (allows apt/pip installs by the agent)";
    };

    enableObsidianCron = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the Nightly Dreaming cron job for Obsidian dream logs";
    };
  };

  config = lib.mkIf cfg.enable {
    services.hermes-agent = {
      enable = true;
      addToSystemPackages = cfg.addToCli;
      settings.model.default = cfg.model;
      settings.custom_providers = lib.mkIf (cfg.customProviders != []) cfg.customProviders;

      # Run as the interactive user so it can access ~/Obsidian, ~/vimwiki, etc.
      user = "sid";
      group = "users";
      createUser = false;

      # Include messaging deps for Discord support
      extraDependencyGroups = [ "messaging" ];

      container.enable = cfg.container;
      container.hostUsers = lib.optionals cfg.container [ "sid" ];

      # Point at the existing .env with API keys
      environmentFiles = [ "/home/sid/.hermes/.env" ];

      # Default-deny gateway access. Authorized Discord users are listed in
      # DISCORD_ALLOWED_USERS inside ~/.hermes/.env (kept out of this repo).
      environment.GATEWAY_ALLOW_ALL_USERS = "false";
    };
  };
}
