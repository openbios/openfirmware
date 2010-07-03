\ The multicast NAND updater code version
\ Use a specific git commit ID for a formal release or "test" for development.
\ With a specific ID, mcastnand.bth will download a tarball without .git stuff.
\ With "test", mcastnand.bth will clone the git head if build/multicast-nand/
\ is not already present, then you can modify the git subtree as needed.
macro: MCNAND_VERSION af0cadd1cbfb17ddfa7dcf299c4c3662ad7120a4
\ macro: MCNAND_VERSION test
\ macro: MCNAND_VERSION HEAD
