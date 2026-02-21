Instructions
============
1. Clone the repo in the home directory
2. install stow
3. cd config_stow
4. stow --adopt .
4.a. CAUTION: This replaces all instances of stowed files on the system with symlinks. This is potentially harmful for .bashrc, so make a backup.
4.b. Using --adopt may result in changes to the git repo and possible conflicts may arise.
5. mkdir ~/.vim/undo

NOTES
=====
This stow assumes the home directory is where the global .gitconfig file is. Manually symlink .gitconfig if the intended global config location is elsewhere.

This readme will not be symlinked to the system.
