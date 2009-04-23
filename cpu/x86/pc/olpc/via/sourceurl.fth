\ Make a file containing the URL of the source code

show-rebuilds?  false to show-rebuilds?   \ We don't need to see these commands

" svn info ../../../../../.. | grep URL: | cut -d ' ' -f 2 | tr \\n ' ' >sourceurl" $sh
" svnversion -n ../../../../../.. >>sourceurl" $sh

to show-rebuilds?
