#define ISUPPER(c)  ((c) >= 'A' && (c) <= 'Z')
#define TOLOWER(c)  ((c) - 'A' + 'a')

int strcmp(const char *s, const char *t);
int strncmp(const char *s, const char *t, size_t len);
int strcasecmp(const char *s, const char *t);
int strncasecmp(const char *s, const char *t, size_t len);
int strlen(const char *s);
int strnlen(const char *s, size_t maxlen);
char *strcpy(char *to, const char *from);
char *strncpy(char *to, const char *from, size_t maxlen);
char *strcat(char *to, const char *from);
char *strchr(char *s, int c);
char *strctok(char *s, const char sep);
char *strstr(const char *haystack, const char *needle);
char *strcasestr(const char *haystack, const char *needle);
void *memchr(const void *s, int c, size_t len);
void *memcpy(void *dest, const void *src, size_t n);
int memcmp(const void *s1, const void *s2, size_t n);
void *memset(void *s, int c, size_t n);
int toupper(int c);
