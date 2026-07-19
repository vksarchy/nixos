{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.workstation.ai;
in
{
  options.workstation.ai = {
    enable = lib.mkEnableOption "AI coding & local LLM tools";

    grok = lib.mkEnableOption "Grok Build (xAI)" // {
      default = true;
    };
    code-cursor = lib.mkEnableOption "Code Cursor" // {
      default = true;
    };
    lmstudio = lib.mkEnableOption "LM Studio" // {
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      lib.optionals cfg.grok [
        inputs.llm-agents.packages.${pkgs.system}.grok
      ]
      ++ lib.optionals cfg.code-cursor [
        pkgs.code-cursor
      ]
      ++ lib.optionals cfg.lmstudio [
        pkgs.lmstudio
      ];
  };
}
