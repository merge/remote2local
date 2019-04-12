# rsync backup solution
This is an rsync-based backup solution for a large, remote directory tree.

## features
* history is preserved: incremental (daily) backups (using hardlinks)
* fast over slow connections (compression; recognize moved files at the remote source)
* robust error handling (interrupted connection or user errors)

## how to install
download a release tarball

	tar -xf <tarball>
	sudo make install

## how to use

	remote2local.sh -c <configfile> [-q] [-r <nr_of_retries>]
		-c	path to config file, see example for the settings
		-q	quiet. print less
		-r	number of retries until remote is reachable. 0 for inifitely
		-h	print this help text

## how to uninstall
download a release tarball

	tar -xf <tarball>
	sudo make uninstall

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
