purpose: Common instructions for fetching and building CForth

\ The macros CFORTH_VERSION and CFORTH_BUILD_DIR must be set externally

\ Don't re-fetch the cforth source, thus preventing overwrites of development modifications.
\ If you change cforth-version.fth to specify a different cforth source version, you must
\ manually delete the old cforth subtree.

" ${CFORTH_BUILD_DIR}/Makefile" expand$ $file-exists?  0=  [if]
   " ${CFORTH_VERSION}" expand$ " modify" $=  [if]
      " git clone -q git+ssh://dev.laptop.org/git/users/wmb/cforth" expand$ $sh
   [else]
      " ${CFORTH_VERSION}" expand$ " clone" $=  [if]
         " git clone -q git://dev.laptop.org/users/wmb/cforth" expand$ $sh
      [else]   
         " wget -q -O - http://dev.laptop.org/git/users/wmb/cforth/snapshot/cforth-${CFORTH_VERSION}.tar.gz | tar xfz -" expand$ $sh
         " mv cforth-${CFORTH_VERSION} cforth" expand$ $sh
         " wget -q -O - http://dev.laptop.org/git/users/wmb/cforth/patch | head -1 | cut -f 2 -d ' ' >>${CFORTH_BUILD_DIR}/version" expand$ $sh
         \ " echo -n const char cforth_version[] = '""' >${CFORTH_BUILD_DIR}/cforth_version.c" expand$ $sh
         \ " wget -q -O - http://dev.laptop.org/git/users/wmb/cforth/patch | head -1 | cut -f 2 -d ' ' >>${CFORTH_BUILD_DIR}/cforth_version.c" expand$ $sh
         \ " echo '"";' >>${CFORTH_BUILD_DIR}/cforth_version.c" expand$ $sh
      [then]
   [then]
[then]

" (cd ${CFORTH_BUILD_DIR}; make --no-print-directory)" expand$ $sh

\ If the above make changed either cforth.img or shim.img, copy the new one into this directory,
\ thus triggering a rebuild of the OFW .rom file

" cforth.img" modtime  " ${CFORTH_BUILD_DIR}/cforth.img" expand$ modtime <  [if]
   " (cp ${CFORTH_BUILD_DIR}/cforth.img .)" expand$ $sh
[then]

" shim.img" modtime  " ${CFORTH_BUILD_DIR}/shim.img" expand$ modtime <  [if]
   " (cp ${CFORTH_BUILD_DIR}/shim.img .)" expand$ $sh
[then]
