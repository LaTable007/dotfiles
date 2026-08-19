#!/bin/bash
# Installe les paquets puis déploie les dotfiles par symlinks GNU Stow.
#
# À lancer une seule fois sur une machine neuve. Stow refuse d'écraser un
# fichier existant : sauvegarder au préalable les configurations déjà en
# place (voir la section « Installation » du README). Ce script ne supprime
# rien de lui-même, c'est délibéré.
set -euo pipefail

cd "$(dirname "$0")"

command -v brew >/dev/null || { echo "Homebrew requis"; exit 1; }

echo "--- Installation des paquets ---"
brew bundle install --file=Brewfile

echo "--- Déploiement des symlinks ---"
stow --target="$HOME" --restow home

echo "--- Plugin manager tmux ---"
[ -d ~/.tmux/plugins/tpm ] || git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo "--- Thème et plugins yazi ---"
# flavors/ et plugins/ ne sont pas versionnés : ya pkg les reclone depuis
# le manifeste package.toml.
command -v ya >/dev/null && ya pkg install

echo "--- Event provider réseau ---"
# Binaire qui pousse l'événement network_update à SketchyBar. Son code est sous
# GPL : il n'est pas versionné ici, mais compilé depuis la source amont, pour ne
# pas faire entrer cette licence dans ce dépôt.
if [ ! -x "$HOME/.local/share/sketchybar/bin/network_load" ]; then
  tmp=$(mktemp -d)
  git clone --depth 1 https://github.com/FelixKratz/dotfiles.git "$tmp/upstream"
  provider="$tmp/upstream/.config/sketchybar/helpers/event_providers/network_load"
  (cd "$provider" && make)
  mkdir -p "$HOME/.local/share/sketchybar/bin"
  cp "$provider/bin/network_load" "$HOME/.local/share/sketchybar/bin/"
  rm -rf "$tmp"
fi

echo "--- Module Lua pour SketchyBar ---"
# SbarLua n'est pas distribué par Homebrew : la config sketchybar/ est en Lua
# et ne démarre pas sans ce module.
if [ ! -f ~/.local/share/sketchybar_lua/sketchybar.so ]; then
  tmp=$(mktemp -d)
  git clone https://github.com/FelixKratz/SbarLua.git "$tmp/SbarLua"
  (cd "$tmp/SbarLua" && make install)
  rm -rf "$tmp"
fi

echo "Terminé. Redémarrer la session pour appliquer."
