setup_alacritty:
	mkdir -p ~/.config/alacritty
	ln -s -f ~/dotfiles/.config/alacritty/alacritty.yml ~/.config/alacritty/alacritty.yml

setup_tmux_a:
	echo "configuring tmux with 'a' as prefix"
	ln -s -f ~/dotfiles/.tmux.conf ~/.tmux.conf

setup_nvim:
	mkdir -p ~/.config/nvim
	ln -s -f ~/dotfiles/.config/nvim/init.vim ~/.config/nvim/init.vim
