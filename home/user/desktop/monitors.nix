{ ... }:

{
  # =============================================================================
  # System Monitor Configs - Symlinked (read-only, edit in repo then rebuild)
  # =============================================================================

  # htop process viewer
  xdg.configFile."htop/htoprc".source = ../../../config/apps/htop/htoprc;
}
