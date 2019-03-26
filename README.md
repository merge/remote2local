# rsync backup solution
This is an rsync-based backup solution for a large, remote directory tree.
* incremental backup using hardlinks: `--link-dest` pointing to the last backup
* Recognize renamings: The second `--fuzzy` option should compare a source file
to all of `--link-dest`. `--delete-delay` or `--delete-after` is needed when
using `--fuzzy`.

## how to use
`./backup.sh -c <configfile>`

## TODO
* support resume
* add script to duplicate locally

## offtopic
### ssh server behind any NAT
#### tor hidded service at source
* install tor; set torrc for port 22
* `mkdir /var/lib/tor/ssh; chmod 700`
* `chown debian-tor`
* restart and get the hostname
* set sshd without password, ...
* include own key.pub in `authorized_keys`

#### client
have tor installed and ssh configured:


	Host <remote>
		User
		IdentityFile
		HostName xyz.onion
		proxyCommand ncat --proxy 127.0.0.1:9050 --proxy-type socks5 %h %p


### vnc support session
`ssh -t -L 5900:localhost:5900 <remote> 'x11vnc -localhost -display :0'`
`vncviewer -encodings "copyrect tight zrle hextile" localhost:0`
