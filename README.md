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
