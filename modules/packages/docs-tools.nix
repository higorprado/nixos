# Document and diagram tooling packages
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Document/PDF processing
    ghostscript

    # LaTeX engine
    tectonic

    # Diagram generation
    mermaid-cli

    # Document conversion
    pandoc
  ];
}
