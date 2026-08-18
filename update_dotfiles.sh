#!/bin/bash
# Met à jour Homebrew et tous les paquets déclarés dans le Brewfile.
# L'ancienne version listait six paquets en dur et ignorait le reste ;
# le Brewfile est désormais la seule liste à maintenir.
set -euo pipefail

cd "$(dirname "$0")"

echo "--- Mise à jour de Homebrew ---"
brew update

echo "--- Installation des paquets manquants (Brewfile) ---"
brew bundle install --file=Brewfile

echo "--- Mise à jour des paquets installés ---"
brew upgrade

echo "--- Nettoyage ---"
brew cleanup

echo "Terminé."
