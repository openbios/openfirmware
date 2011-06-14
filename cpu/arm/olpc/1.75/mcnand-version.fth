\ The multicast NAND updater code version
\ Use a specific git commit ID for a formal release or "test" for development.
\ With a specific ID, mcastnand.bth will download a tarball without .git stuff.
\ With "test", mcastnand.bth will clone the git head if build/multicast-nand/
\ is not already present, then you can modify the git subtree as needed.
macro: MCNAND_VERSION 3537d14318e0eac205dda2f8dcd524f24b9cabe3
\ macro: MCNAND_VERSION test
\ macro: MCNAND_VERSION HEAD
