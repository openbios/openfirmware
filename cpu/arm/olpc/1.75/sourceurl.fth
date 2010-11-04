\ Make a file containing the URL of the source code

show-rebuilds?  false to show-rebuilds?   \ We don't need to see these commands

" if svn info ${BP} 2>/dev/null >/dev/null; then svn info ${BP} | grep URL: | cut -d ' ' -f 2 | tr \\n ' ' >sourceurl; svnversion -n ${BP} >>sourceurl; else git log -1 | grep git-svn-id: >sourceurl; fi" $sh

to show-rebuilds?
