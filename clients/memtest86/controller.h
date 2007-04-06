#ifndef MEMTEST_CONTROLLER_H
#define MEMTEST_CONTROLLER_H

void find_controller(void);
void poll_errors(void);
void set_ecc_polling(int val);

#endif /* MEMTEST_CONTROLLER_H */
