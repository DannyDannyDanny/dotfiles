setup_locale:
	sudo ln -s -f ~/dotfiles/.locale.conf /etc/default/locale

setup_zshrc:
	ln -s -f ~/dotfiles/.zshrc ~/.zshrc

setup_alacritty_wsl:
	cp ~/dotfiles/.config/alacritty/alacritty.yml /mnt/c/Users/dnth/AppData/Roaming/alacritty/alacritty.yml

setup_alacritty:
	mkdir -p ~/.config/alacritty
	ln -s -f ~/dotfiles/.config/alacritty/alacritty.yml ~/.config/alacritty/alacritty.yml

setup_tmux_a:
	echo "configuring tmux with 'a' as prefix"
	ln -s -f ~/dotfiles/.tmux.conf ~/.tmux.conf

setup_git:
	git config --global user.name "DannyDannyDanny"
	git config --global user.email "dth@taiga.ai"
	git config --global pull.rebase false

setup_vimwiki1:
	rm -rf ~/.local/share/nvim/vimwiki/
	git clone git@github.com:DannyDannyDanny/vimwiki.git ~/vimwiki/


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

setup_editorconfig:
	ln -s -f ~/dotfiles/.editorconfig ~/.editorconfig

setup_nerdfonts:
	git clone --depth 2 https://github.com/ryanoasis/nerd-fonts/ ~/nerd-fonts
	cd ~/nerd-fonts && ./install.sh

setup_server_ip_sync:
	echo "Visit github to generate new token:"
	echo "    github.com/settings/tokens/new"
	@echo "Enter github token: "; \
	read token; \
	echo "Your token is ", $$(token)

setup_server_ip_sync_python_env:
	mkdir -p ~/.venvs
	python3 -m venv ~/.venvs/server_ip_sync
	~/.venvs/server_ip_sync/bin/pip install python-dotenv
	echo "~/.venvs/server_ip_sync/bin/python server-ip-sync.py" >> ~/deleteme-server-in-sync.txt


git_overview:
	cd ~ && find . -name .git -type d -prune

setup_server_mynetwork:
	mkdir -p ~/.ssh
	ln -s -f ~/dotfiles/.ssh/authorized_keys ~/.ssh/authorized_keys

setup_client_mynetwork:
	ssh-keygen -q -t rsa -b 4096 -f ~/.ssh/id_rsa_mynetwork -q -N ""
	cat ~/.ssh/id_rsa_mynetwork.pub >> ~/dotfiles/.ssh/authorized_keys
	echo "run\ncd ~/dotfiles && git status"
