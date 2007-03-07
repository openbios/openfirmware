purpose: Default values for some configuration variables

headers
" disk net                                                                                                                                                                                                                                                       "
d# 256 config-string  boot-device

"                                                                                                                                                                                                                                                                "
d# 256 config-string  boot-file

" net                               "
d# 256  config-string  diag-device

"                    "
d# 128  config-string  diag-file
false  config-flag  watchdog-reboot?
true   config-flag  auto-boot?
" boot                "
d# 64   config-string  boot-command


