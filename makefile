setup_alacritty:
	mkdir -p ~/.config/alacritty
	ln -s -f ~/dotfiles/.config/alacritty/alacritty.yml ~/.config/alacritty/alacritty.yml

setup_tmux_a:
	echo "configuring tmux with 'a' as prefix"
	ln -s -f ~/dotfiles/.tmux.conf ~/.tmux.conf

setup_git:
	git config --global user.email "DannyDannyDanny"
	git config --global user.name "dth@taiga.ai"


setup_vimwiki1:
	rm -rf ~/.local/share/nvim/vimwiki/
	git clone git@github.com:DannyDannyDanny/vimwiki.git ~/.local/share/nvim/vimwiki/


setup_vimwiki2:
	rm -rf ~/methodology/
	git clone git@github.com:DannyDannyDanny/methodology.git ~/methodology/


setup_vimwiki3:
	rm -rf ~/administration/
	git clone git@github.com:taigacompany/administration.git ~/administration/


setup_nvim: setup_vimwiki1 setup_vimwiki2 setup_vimwiki3
	echo "configuring nvim"
	mkdir -p ~/.config/nvim
	ln -s -f ~/dotfiles/.config/nvim/init.vim ~/.config/nvim/init.vim

setup_music:
	mkdir -p ~/.config/mpd/playlists/
	mkdir -p ~/.mpd
	ln -s -f ~/dotfiles/.config/mpd/mpd.conf ~/.config/mpd/mpd.conf
	mkdir -p ~/.config/ncmpcpp/
	ln -s -f ~/dotfiles/.config/ncmpcpp/config ~/.config/ncmpcpp/config
