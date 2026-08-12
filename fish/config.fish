if status is-interactive
# Commands to run in interactive sessions can go here
set fish_greeting
end
set -x STARSHIP_CONFIG ~/.config/starship/starship.toml
starship init fish | source
set -U fish_user_paths $fish_user_paths ~/.local/bin

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/bdw/.lmstudio/bin
# End of LM Studio CLI section

alias ls "eza -l --icons"

alias gtrep "cd ~/Repositories"
alias gtdl "cd ~/Downloads"
alias gthome "cd ~"
alias cls "clear"

bind \b backward-kill-word
