{ pkgs, ... }:
{
  languages.python = {
    enable = true;
    package = pkgs.python312;
    venv.enable = true;
    venv.requirements = "";
  };

  # uv is the recommended Python package manager
  # debugpy is required for Python debugging in Neovim
  packages = [
    pkgs.uv
    pkgs.python312Packages.debugpy
    pkgs.python312Packages.isort 
    pkgs.python312Packages.pytest
    pkgs.python312Packages.debugpy 
  ];

  enterShell = ''
    echo "🐍 Python devenv environment loaded"
    echo "Python: $(python --version)"
    echo ""
    echo "Neovim integration:"
    echo "  - pyright LSP: Automatically configured"
    echo "  - ruff: Linting & formatting"
    echo "  - debugpy: Debugger"
    echo ""
    echo "Open any .py file in nvim to start coding!"
  '';
}
