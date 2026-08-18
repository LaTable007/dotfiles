# Inventaire des paquets Homebrew de la machine.
# Régénérer : brew bundle dump --describe --force --file=Brewfile
# Installer  : brew bundle install --file=Brewfile
# Vérifier   : brew bundle check --file=Brewfile

# --- Taps ---------------------------------------------------------------
tap "felixkratz/formulae", "https://github.com/FelixKratz/homebrew-formulae", trusted: true
tap "nikitabobko/tap"

# --- Fenêtrage et barre de statut ---------------------------------------
# AeroSpace is an i3-like tiling window manager for macOS
cask "nikitabobko/tap/aerospace", trusted: true
# Custom macOS statusbar with shell plugin, interaction and graph support
brew "felixkratz/formulae/sketchybar", trusted: true
# A window border system for macOS
brew "felixkratz/formulae/borders"
# Utility to hide menu bar items
cask "hiddenbar"
# Tool that provides consistent, highly configurable symbols for apps
cask "sf-symbols"
cask "font-hack-nerd-font"
cask "font-sf-mono"
cask "font-sf-pro"
cask "font-sketchybar-app-font"

# --- Sondes lues par les items SketchyBar -------------------------------
# Sudoless performance monitoring for Apple Silicon processors
brew "macmon"
# Outputs current CPU temperature for OSX
brew "osx-cpu-temp"
# Change macOS audio source from the command-line
brew "switchaudio-osx"
# Retrieves currently playing media, and simulates media actions
brew "nowplaying-cli"
# Change macOS display brightness from the command-line
brew "brightness"

# --- Terminal, shell et outils CLI --------------------------------------
# Terminal emulator that uses platform-native UI and GPU acceleration
cask "ghostty"
# Cross-shell prompt for astronauts
brew "starship"
# Fish-like fast/unobtrusive autosuggestions for zsh
brew "zsh-autosuggestions"
# Fish shell like syntax highlighting for zsh
brew "zsh-syntax-highlighting"
# Terminal multiplexer
brew "tmux"
# Pluggable terminal workspace, with terminal multiplexer as the base feature
brew "zellij"
# Modern, maintained replacement for ls
brew "eza"
# Clone of cat(1) with syntax highlighting and Git integration
brew "bat"
# Command-line fuzzy finder written in Go
brew "fzf"
# Simple, fast and user-friendly alternative to find
brew "fd"
# Search tool like grep and The Silver Searcher
brew "ripgrep"
# Shell extension to navigate your filesystem faster
brew "zoxide"
# Like neofetch, but much faster because written mostly in C
brew "fastfetch"
# Lightweight and flexible command-line JSON processor
brew "jq"
# Official tldr client written in Rust
brew "tlrc"
# Organize software neatly under a single directory tree (e.g. /usr/local)
brew "stow"

# --- Éditeur ------------------------------------------------------------
# Ambitious Vim-fork focused on extensibility and agility
brew "neovim"
# Parser generator tool
brew "tree-sitter-cli"
# Powerful, lightweight programming language
brew "lua"
# Powerful, lightweight programming language
brew "lua@5.4"
# Package manager for the Lua programming language
brew "luarocks"

# --- Git ----------------------------------------------------------------
# GitHub command-line tool
brew "gh"
# Open-source GitLab command-line tool
brew "glab"
# Syntax-highlighting pager for git and diff output
brew "git-delta"
# Simple terminal UI for git commands
brew "lazygit"

# --- Chaîne de développement --------------------------------------------
# Cross-platform make
brew "cmake"
# Fast and user friendly build system
brew "meson"
# GNU compiler collection
brew "gcc"
# Open-source, cross-platform JavaScript runtime environment
brew "node"
# Python version management
brew "pyenv"
# Interpreted, interactive, object-oriented programming language
brew "python@3.12"
# Container runtimes on MacOS (and Linux) with minimal setup
brew "colima"
# Pack, ship and run any application as a lightweight container
brew "docker", link: false
# Isolated development environments using Docker
brew "docker-compose"

# --- Bibliothèques graphiques et multimédia -----------------------------
# OpenType text shaping engine
brew "harfbuzz"
# Framework for layout and rendering of i18n text
brew "pango"
# Library to render SVG files using Cairo
brew "librsvg"
# Icons for the GNOME project
brew "adwaita-icon-theme"
# Message bus system, providing inter-application communication
brew "dbus"
# Protocol definitions and daemon for D-Bus at-spi
brew "at-spi2-core"
# Toolkit for creating graphical user interfaces
brew "gtk+3"
# Common components for zathura
brew "girara"
# C/C++ and Java libraries for Unicode and globalization
brew "icu4c@76"
# OpenGL Extension Wrangler Library
brew "glew"
# Multi-platform library for OpenGL applications
brew "glfw"
# SDL2 compatibility layer that uses SDL3 behind the scenes
brew "sdl2-compat"
# Simple and easy-to-use library to learn videogames programming
brew "raylib"
# Multi-media library with bindings for multiple languages
brew "sfml"
# Play, record, convert, and stream select audio and video codecs
brew "ffmpeg"
# Tools and libraries to manipulate images in many formats
brew "imagemagick-full", link: true
# Interpreter for PostScript and PDF
brew "ghostscript"
# PDF rendering library (based on the xpdf-3.0 code base)
brew "poppler"
# Tool to create intelligent and beautiful documentation
brew "sphinx-doc"
# Validating, recursive, caching DNS resolver
brew "unbound"

# --- Divers -------------------------------------------------------------
# Terminal-based AI coding assistant
cask "claude-code"
# Mesh VPN based on WireGuard
cask "tailscale-app"
