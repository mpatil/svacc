// vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
#include <errno.h>		/* errno */
#include <sys/types.h>		/* pid_t */
#include <unistd.h>		/* pipe(), fork(),... */
#include <stdlib.h>		/* exec() */
#include <sys/wait.h>		/* waitpid(), etc. */
#include <stdio.h>
#include <svdpi.h>

void closepipe(int *fds);

#define MAX_BUF_SZ  512
enum { READ = 0, WRITE = 1 };

void Popen(const char *cmd, int *rdfd, int *wrfd) {
    int fd[2];

    sys_process_pipe(cmd, fd);

    *rdfd = fd[READ];
    *wrfd = fd[WRITE];
}

int Pwrite(const svOpenArrayHandle a, int fd, int bbuf, int size) {
    int n, i;
    char unsigned *a_;
    int unsigned *a__;

    a_ = (char unsigned *) malloc(size * sizeof(char unsigned));
    a__ = (int unsigned *) svGetArrayPtr(a);

    for (i = 0; i < size; i++)
	a_[i] = a__[i + bbuf];	

    n = write(fd, a_, size);

    free(a_);
    return n;
}

int Pread(const svOpenArrayHandle a, int fd, int bbuf, int *size) {
    int n, i;
    char unsigned *a_;
    int unsigned *a__;

    a_ = (char unsigned *) malloc(*size * sizeof(char unsigned));
    a__ = (int unsigned *) svGetArrayPtr(a);

    n = read(fd, a_, *size);

    for (i = 0; i < *size; i++) {
	a__[i + bbuf] = a_[i];	
    }
    free(a_);
    return n;
}

/* Issue a warning, then die, with errno */
static void error_with_errno(const char *message) {
    printf("[PSYSTEM] : psystem: ERROR: %s : error number %i\n", message, errno);
    exit(EXIT_FAILURE);
}

void closepipe(int *fds) {
    if (close(fds[0]))
	error_with_errno("Failed closing fds[0]");
    if (close(fds[1]))
	error_with_errno("Failed closing fds[1]");
}

int sys_process_pipe(const char *cmd, int *sd) {
    int ret;
    int fd[2], pd[2];		/* Stores pipe file descriptors */

    pid_t child0_pid;

    if (pipe(fd))
	error_with_errno("fd pipe() failed");
    if (pipe(pd))
	error_with_errno("pd pipe() failed");

    //  fd[WRITE] >-fd pipe>-  fd[READ]   0 > cmd 1 >  pd[WRITE] >-pd pipe>-  pd[READ]
    //    ^                               ^       ^                           ^     
    // write data              fd[READ]=stdin   stdout=pd[WRITE]           read data          

    child0_pid = fork();
    switch (child0_pid) {
    case -1:
	error_with_errno("fork() failed");
	exit(3);
	break;
    case 0:{
	    /* Make the reading end of the left side pipe the new standard input. */
	    if (dup2(fd[READ], STDIN_FILENO) == -1)
		error_with_errno("Failed redefining standard input");

	    /* Make the writing end of the right side pipe the new standard output. */
	    if (dup2(pd[WRITE], STDOUT_FILENO) == -1)
		error_with_errno("Failed redefining standard output");

	    /* Close the original file descriptors for both ends of all the pipes. */
	    closepipe(fd);
	    closepipe(pd);

	    if ((ret = system(cmd)) == -1)
		error_with_errno(cmd);

	    /* Close the standard output. */
	    if (close(STDOUT_FILENO))
		error_with_errno("Failed closing standard output "
				 " (while cleaning up)");
	    /* Close the standard input. */
	    if (close(STDIN_FILENO))
		error_with_errno("Failed closing standard input "
				 " (while cleaning up)");
	    /* Close the standard error. */
	    if (close(STDERR_FILENO))
		error_with_errno("Failed closing standard error"
				 " (while cleaning up)");

	    _exit(EXIT_SUCCESS);
	}
	break;
    default:
	sd[WRITE] = fd[WRITE];
	sd[READ] = pd[READ];

	close(fd[READ]);
	close(pd[WRITE]);
    }

    return 0;
}
