if not pgrep --full ssh-agent | string collect > /dev/null
	eval (ssh-agent -c)
	set -Ux SSH_AGENT_PID $SSH_AGENT_PID
	set -Ux SSH_AUTH_SOCK $SSH_AUTH_SOCK
  # ssh-add ~/.ssh/id_*_github
end

set -gx EDITOR nvim
