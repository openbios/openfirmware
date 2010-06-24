\ The multicast NAND updater code version
\ Use a specific git commit ID for a formal release or "test" for development.
\ With a specific ID, mcastnand.bth will download a tarball without .git stuff.
\ With "test", mcastnand.bth will clone the git head if build/multicast-nand/
\ is not already present, then you can modify the git subtree as needed.
macro: MCNAND_VERSION d1b388bcdf01f98a7b94bb62d0d3f1403fd27d1a
\ macro: MCNAND_VERSION test
\ macro: MCNAND_VERSION HEAD
