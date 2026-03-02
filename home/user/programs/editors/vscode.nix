{
  pkgs,
  ...
}:
{
  programs.vscode = {
    enable = true;

    package = (
      pkgs.vscode.override {
        commandLineArgs = [
          "--disable-gpu-compositing"
          "--disable-gpu"
        ];
      }
    );

    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = true;

      extensions = with pkgs.vscode-extensions; [
        # Python
        ms-python.python
        ms-python.vscode-pylance
        charliermarsh.ruff

        # Rust
        rust-lang.rust-analyzer

        # Git
        eamodio.gitlens

        # Docker
        ms-azuretools.vscode-docker

        # Nix
        jnoortheen.nix-ide
        bbenoist.nix
      ];

      userSettings = {
        # Terminal settings
        "terminal.integrated.fontFamily" = "'JetBrains Mono Nerd Font Mono'";
        "terminal.integrated.lineHeight" = 1.0;
        "terminal.integrated.fontLigatures.enabled" = true;
        "terminal.integrated.fontWeightBold" = "bold";

        # Editor settings
        "editor.fontFamily" =
          "'JetBrains Mono Nerd Font Mono', Menlo, Monaco, 'Courier New', monospace, 'JetBrains Mono'";
        "editor.fontSize" = 16;
        "editor.minimap.enabled" = false;
        "diffEditor.ignoreTrimWhitespace" = false;

        # Telemetry
        "redhat.telemetry.enabled" = false;

        # Docker
        "docker.extension.enableComposeLanguageServer" = false;

        # GitLens
        "gitlens.ai.model" = "vscode";

        # Claude Code
        "claudeCode.preferredLocation" = "panel";
      };
    };
  };
}
