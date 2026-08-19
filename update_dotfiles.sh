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

# Une mise à jour de SketchyBar remplace son binaire, donc sa signature. macOS
# y voit une application inconnue et l'autorisation d'envoyer des évènements
# Apple à Music tombe, ce qui casse le compteur de position du lecteur média.
# Le processus déjà lancé garde ce refus en cache et échoue en silence : sans
# redémarrage, aucune invite n'apparaît jamais. Le relancer ici force macOS à
# redemander l'autorisation, au moment où l'on est devant l'écran.
if brew services list 2>/dev/null | grep -q '^sketchybar'; then
  echo "--- Redémarrage de SketchyBar (autorisation Music) ---"
  brew services restart sketchybar
fi

echo "Terminé."
