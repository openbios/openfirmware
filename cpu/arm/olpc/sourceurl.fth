\ Make a file containing the URL of the source code

show-rebuilds?  false to show-rebuilds?   \ We don't need to see these commands

" if svn info ${BP} 2>/dev/null >/dev/null; then svn info ${BP} | grep URL: | cut -d ' ' -f 2 | tr \\n ' ' >sourceurl; svnversion -n ${BP} >>sourceurl; else git svn info | grep Root: | cut -d ':' -f 2- | tr  \\n ' ' > sourceurl ; echo -n 'r' >>sourceurl ; git svn info | grep Revision | cut -d':' -f 2 | tr -d [:space:] >>sourceurl ; fi" $sh

to show-rebuilds?
