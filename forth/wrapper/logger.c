// See license at end of file

/*
 * Tools for creating log files containing information about the
 * files upon which the compilation of a particular Forth dictionary
 * file depends.
 */

#ifdef WIN32
#include <windows.h>
#endif
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#ifndef USE_STDIO
#include <sys/types.h>
#include <sys/stat.h>
#endif
#include <time.h>
#ifdef MAJC
#include <sys/unistd.h>
#else
#include <unistd.h>
#endif

#ifndef MAXPATHLEN
#define MAXPATHLEN 256
#endif

#define MAXLINE 256
char info[MAXLINE];		/* A place to create log records */

/* Returns the portion of filename after the directories and volume names */
char *basename(char *filename)
{
    char c, *p;
    for (p = filename + strlen(filename); p != filename; --p) {
        if ( (c = p[-1]) == '/' || c == '\\' || c == ':')
	    break;
    }
    return (p);
}

/*
 * Returns the portion of 'filename' up to the last ".xxx" extension.
 * The returned string may be overwritten by subsequent calls to rootname.
 */
char *rootname(char *filename)
{
    static char name[MAXPATHLEN];
    char *p;

    for (p = filename + strlen(filename); p != filename; ) {
        if ( *--p == '.') {
            strncpy(name, filename, p-filename);
            name[p-filename] = '\0';
	    return (name);
        }
    }

    return(filename);
}


/* Log records are maintained as a linked list. */
typedef struct node { struct node *link; char info[1]; } node;
typedef struct list { node *first; node *last; } list;

list infiles = { NULL, NULL };	/* List of log records for input files */
list envvars = { NULL, NULL };	/* List of log records for env vars */
list misc    = { NULL, NULL };	/* List of log records for other things */

/* Adds the current info record to the end of 'list' */
void record(list *list)
{
    node *new;
    new = (node *)malloc(strlen(info) + sizeof(node *) + 1);
    strcpy(new->info, info);
    new->link = NULL;
    if (list->last != NULL)
	list->last->link = new;
    list->last = new;
    if (list->first == NULL)
	list->first = new;
}

/* Finds a specific node in the list */
node *findnode(list *list, char *s)
{
    node *n;
    int len;

    len = strlen(s);
    for (n = list->first; n != NULL; n = n->link) {
        if (strncmp(n->info, s, len) == 0)
            return(n);
    }
    return((node *)0);
}

/* Writes the data from each node of 'list' to the 'logfile' */
void fputlist(list *list, FILE *logfile)
{
    node *n;
    for (n = list->first; n != NULL; n = n->link)
        fputs(n->info, logfile);
}

/*
 * Writes a log file of all information accumulated to date.
 * 'filename' is the name of the Forth output file.  The name
 * of the log file is derived from filename by replacing its
 * extension with ".log".
 */
void log_output(char *filename, long size)
{
    FILE *logfile;
    char logfilename[MAXPATHLEN];
    time_t ntime;

    /* Derive the log file name from the input filename */
    strcpy(logfilename, rootname(basename(filename)));
    strcat(logfilename, ".log");

    if (NULL == (logfile = fopen(logfilename, "w")))
        return;

    time(&ntime);
#ifdef USE_STDIO
    sprintf(info, "time: %x  %s", ntime, ctime(&ntime));
    /* ctime automatically appends a newline */
    (void) fprintf(logfile, "out: %s  %ld  %x  %s",
		   filename, size, ntime, ctime(&ntime));
#else
    sprintf(info, "time: %lx  %s", ntime, ctime(&ntime));
    /* ctime automatically appends a newline */
    (void) fprintf(logfile, "out: %s  %ld  %lx  %s",
		   filename, size, ntime, ctime(&ntime));
#endif

    fputlist(&misc, logfile);
    fputlist(&envvars, logfile);
    fputlist(&infiles, logfile);
    fclose(logfile);
}

/*
 * Creates a log record for the input file 'filename'.
 * The record is of the form:
 *   in: file-name file-modification-date file-size
 */
void log_input(char *filename, int fd)
{
#ifdef USE_STDIO
    /* Avoid duplicate entries */
    sprintf(info, "in: %s", filename);
    if (findnode(&infiles, info) != (node *)0)
	return;

    sprintf(info, "in: %s\n", filename);
    record(&infiles);
#else
    struct stat stbuf;

    /* Avoid duplicate entries */
    sprintf(info, "in: %s", filename);

    if (findnode(&infiles, info) != (node *)0)
	return;

    if (0 != fstat(fd,&stbuf))
        return;

    /* ctime automatically appends a newline */
    sprintf(info, "in: %s  %ld  %lx  %s",
	    filename, (long)stbuf.st_size, (long)stbuf.st_mtime, ctime(&stbuf.st_mtime));

    record(&infiles);
#endif
}

/*
 * If 'str' contains any shell metacharacters, return a version of it
 * enclosed in " characters, with any embedded " characters escaped with \.
 * Otherwise return 'str' verbatim.
 */
char *quotestr(char *str)
{
    char *p, *o;
    int needs_quoting = 0;

    static char result[MAXLINE];

    for (p = str; *p; p++) {
        switch (*p) {
            case '\'':  case '\"':
	    case ' ':  case '|':  case '>':  case '<':
	    case '(':  case ')':  case '&':  case '*':
	    case '?':  case '$':  case '#':  case ';':
	    case '[':  case ']':  case '!':  case '^':
                needs_quoting = 1;
                break;
            default:
                break;
        }
    }
    if (!needs_quoting)
        return(str);

    o = result;
    *o++ = '"';
		  
    for (p = str; *p; p++) {
       if (*p == '"')		/* Escape any embedded " characters */
          *o++ = '\\';
       *o++ = *p;
    }
    *o++ = '"';
    *o = '\0';

    return(result);
}

/* Create log records telling the hostname, build time, and command line */
void log_command_line(char *cmd, char *dictfile, int fd, int argc, char *argv[])
{
    int i;
#ifdef notdef
    struct stat stbuf;
#endif
    char cwdbuf[MAXPATHLEN*2];

#ifdef __unix__
#ifdef MAJC
    char *hostname = "some_MAJC_machine";
#else
    char hostname[64];
    (void) gethostname(hostname, 64);
#endif
#endif

#ifdef DOS
    char *hostname = "some_NT_machine";
#endif

#ifdef WIN32
    char hostname[MAX_COMPUTERNAME_LENGTH+1];
    long hostnamelen = MAX_COMPUTERNAME_LENGTH+1;
    (void) GetComputerName(hostname, &hostnamelen);
#endif

#ifdef MACOS
    char *hostname = "some_Macintosh";
#endif

#ifdef USE_STDIO
    char *hostname = "some_machine";
#endif


#ifdef notdef
    sprintf(info, "command: %s\n", cmd);
    record(&misc);

    fstat(fd,&stbuf);
    /* ctime automatically appends a newline */
    sprintf(info, "dictionary: %s  %ld  %lx  %s",
	    dictfile, stbuf.st_size, stbuf.st_mtime, ctime(&stbuf.st_mtime));
    record(&misc);
#endif

    strcpy(info, "command:");
    for(i = 0; i < argc; i++) {
        strcat(info, " ");
        strcat(info, quotestr(argv[i]));
    }
    strcat(info, "\n");
    record(&misc);

    sprintf(info, "host: %s\n", hostname);
    record(&misc);

    getcwd(cwdbuf, 128);
    sprintf(info, "cwd: %s\n", cwdbuf);
    record(&misc);
}

/*
 * Creates a log record for the environment variable 'name', unless one
 * already exists. The record is of the form:
 *   env: name value
 */
void log_env(char *name, char *value)
{
    char matchbuf[40];
    int len;
    node *n;

    /* Log only the first use of each environment variable */
    sprintf(matchbuf, "env: %s ", name);
    len = strlen(matchbuf);
    for (n = envvars.first; n != NULL; n = n->link)
	if (strncmp(matchbuf, n->info, len) == 0)
            return;

    sprintf(info, "env: %s %s\n", name, value);
    record(&envvars);
}

// LICENSE_BEGIN
// Copyright (c) 2006 FirmWorks
// 
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// LICENSE_END
