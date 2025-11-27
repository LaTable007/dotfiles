#!/bin/bash

# =========================================================
# Script pour mettre à jour les applications et les paquets
# des dotfiles en utilisant Homebrew (brew).
# =========================================================

echo "✨ Démarrage de la mise à jour des dotfiles/applications avec Homebrew..."

# 1. Mise à jour de Homebrew lui-même
echo ""
echo "--- 1. Mise à jour de Homebrew ---"
brew update

# 2. Mise à jour des applications spécifiques (Casks)
# Nous utilisons 'cask' pour les applications GUI comme Ghostty.
echo ""
echo "--- 2. Mise à jour de ghostty ---"
brew upgrade --cask ghostty || { echo "⚠️ Erreur lors de la mise à jour de ghostty."; }

# 3. Mise à jour des formules spécifiques (Programmes CLI/librairies)
# Remarque : sketchybar et aerospace peuvent être des formules ou des services gérés
# différemment, mais 'brew upgrade' les gère généralement.
echo ""
echo "--- 3. Mise à jour de aerospace ---"
brew upgrade --cask nikitabobko/tap/aerospace || { echo "⚠️ Erreur lors de la mise à jour de aerospace."; }

echo ""
echo "--- 4. Mise à jour de sketchybar ---"
brew upgrade sketchybar || { echo "⚠️ Erreur lors de la mise à jour de sketchybar."; }

# 4. Mise à jour des polices (Fonts)
# Assurez-vous d'utiliser le nom exact de la police dans brew.
# Remplacer 'font-nom_de_votre_police' par le nom réel de votre police.
# Exemple pour une police Nerd Font : font-hack-nerd-font
echo ""
echo "--- 5. Mise à jour de sketchybarfont ---"
brew upgrade --cask font-sketchybar-app-font || { echo "⚠️ Erreur lors de la mise à jour de sketchybar-app-font."; }
# Alternative si les polices sont gérées par Cask :
# brew upgrade --cask $(brew list --cask | grep 'font')

echo ""
echo "--- 6. Mise à jour de starship ---"
brew upgrade starship || { echo "⚠️ Erreur lors de la mise à jour de starship."; }

# 5. Nettoyage de Homebrew
echo ""
echo "--- 7. Nettoyage et Finalisation ---"
brew cleanup

echo ""
echo "✅ Mise à jour terminée ! Vos dotfiles et applications sont synchronisés."
