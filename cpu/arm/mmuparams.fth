\ Defined by CPU core
[ifdef] pagesize
h# 1000 to pagesize
d# 12   to pageshift
[else]
h# 1000 constant pagesize
d# 12   constant pageshift
[then]

h# 10.0000 constant /section
h# 4000 constant /page-table
