Instructions
============
1. Clone the repo in the home directory
1a. optionally run 'dot-local/bin/initialize_environment.sh' instead of the remaining steps
2. install stow
3. cd config_stow
4. stow --dotfiles --adopt .
4a. CAUTION: This replaces all instances of stowed files on the system with symlinks. This is potentially harmful for .bashrc, so make a backup.
4b. Using --adopt may result in changes to the git repo and possible conflicts may arise.
5. mkdir ~/.vim/undo

NOTES
=====
This readme will not be symlinked to the system.
