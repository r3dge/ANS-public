#!/bin/bash
#sudo apt-get install tmux


#!/bin/bash

# Lancer tmux
tmux new-session -d -s mysession

# Diviser verticalement en deux vues
tmux split-window -v

# Sélectionner la première vue
tmux select-pane -t 0
tmux send-keys 'commande_pour_le_premier_panel' C-m

# Sélectionner la deuxième vue
tmux select-pane -t 1
tmux send-keys 'commande_pour_le_deuxieme_panel' C-m

# Attacher à la session tmux
tmux attach-session -t mysession

# tmux kill-session -t session_name