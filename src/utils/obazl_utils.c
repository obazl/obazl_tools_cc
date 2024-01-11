#include <errno.h>
#include <dirent.h>
#include <spawn.h>
#include <stdbool.h>

#if EXPORT_INTERFACE
#include <stdio.h>
#endif

#ifdef __linux__
#include <linux/limits.h>
#else
#include <limits.h>
#endif

#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#include "liblogc.h"
#include "utstring.h"
#include "_obazl_utils.h"

int obazl_utils_verbosity = 0;
int obazl_utils_log_writes      = 0;

EXPORT int spawn_cmd_with_stdout(char *executable, int argc, char *argv[])
{
#if defined(DEBUG_fastbuild)
    log_trace("spawn_cmd_with_stdout");
#endif
    if (obazl_utils_verbosity > obazl_utils_log_writes) {
        UT_string *cmd_str;
        utstring_new(cmd_str);
        for (int i =0; i < argc; i++) {
            utstring_printf(cmd_str, "%s ", (char*)argv[i]);
        }
        /* log_info("%s", utstring_body(cmd_str)); */
        /* log_info("obazl:"); */
        printf(YEL "EXEC: " CMDCLR);
        printf("%s ", utstring_body(cmd_str));
        printf(CRESET "\n");
    }

    /* if (dry_run) return 0; */

    pid_t pid;
    int rc;

    extern char **environ;

    errno = 0;
    rc = posix_spawnp(&pid, executable, NULL, NULL, argv, environ);

    if (rc == 0) {
#if defined(DEBUG_fastbuild)
        /* log_trace("posix_spawn child pid: %i\n", pid); */
#endif
        errno = 0;
        int waitrc = waitpid(pid, &rc, WUNTRACED);
        if (waitrc == -1) {
            perror("spawn_cmd waitpid error");
            /* log_error("spawn_cmd"); */
            /* posix_spawn_file_actions_destroy(&action); */
            return -1;
        } else {
#if defined(DEBUG_fastbuild)
        /* log_trace("waitpid rc: %d", waitrc); */
#endif
            // child exit OK
            if ( WIFEXITED(rc) ) {
                // terminated normally by a call to _exit(2) or exit(3).
#if defined(DEBUG_fastbuild)
                /* log_trace("WIFEXITED(rc)"); */
                /* log_trace("WEXITSTATUS(rc): %d", WEXITSTATUS(rc)); */
#endif
                /* log_debug("WEXITSTATUS: %d", WEXITSTATUS(rc)); */
                /* "widow" the pipe (delivers EOF to reader)  */
                /* close(stdout_pipe[1]); */
                /* dump_pipe(STDOUT_FILENO, stdout_pipe[0]); */
                /* close(stdout_pipe[0]); */

                /* /\* "widow" the pipe (delivers EOF to reader)  *\/ */
                /* close(stderr_pipe[1]); */
                /* dump_pipe(STDERR_FILENO, stderr_pipe[0]); */
                /* close(stderr_pipe[0]); */

                fflush(stdout);
                fflush(stderr);
                return EXIT_SUCCESS;
            }
            else if (WIFSIGNALED(rc)) {
                // terminated due to receipt of a signal
                /* log_error("WIFSIGNALED(rc)"); */
                /* log_error("WTERMSIG: %d", WTERMSIG(rc)); */
                /* log_error("WCOREDUMP?: %d", WCOREDUMP(rc)); */
                return -1;
            } else if (WIFSTOPPED(rc)) {
                /* process has not terminated, but has stopped and can
                   be restarted. This macro can be true only if the
                   wait call specified the WUNTRACED option or if the
                   child process is being traced (see ptrace(2)). */
                /* log_error("WIFSTOPPED(rc)"); */
                /* log_error("WSTOPSIG: %d", WSTOPSIG(rc)); */
                return -1;
            }
        }
        /* else { */
        /*     log_error("spawn_cmd: stopped or terminated child pid: %d", */
        /*               waitrc); */
        /*     /\* posix_spawn_file_actions_destroy(&action); *\/ */
        /*     return -1; */
        /* } */
    } else {
        /* posix_spawnp rc != 0; does not set errno */
        /* log_fatal("spawn_cmd error rc: %d, %s", rc, strerror(rc)); */
        /* posix_spawn_file_actions_destroy(&action); */
        return rc;
    }
    //  should not reach here?
    /* log_error("BAD FALL_THROUGH"); */
    return rc;
}

EXPORT void mkdir_r(const char *dir) {
    /* log_debug("mkdir_r %s", dir); */
    char tmp[512];
    char *p = NULL;
    size_t len;

    snprintf(tmp, sizeof(tmp),"%s",dir);
    len = strlen(tmp);
    if (tmp[len - 1] == '/')
        tmp[len - 1] = 0;
    for (p = tmp + 1; *p; p++)
        if (*p == '/') {
            *p = 0;
            mkdir(tmp, S_IRWXU);
            *p = '/';
        }
    mkdir(tmp, S_IRWXU);
}

EXPORT int copyfile(char *fromfile, char *tofile)
{
    char ch;// source_file[20], target_file[20];

    FILE *source = fopen(fromfile, "r");
    if (source == NULL) {
        fprintf(stderr, "copyfile fopen fail on fromfile: %s\n", fromfile);
        exit(EXIT_FAILURE);
    }
    FILE *target = fopen(tofile, "w");
    if (target == NULL) {
        fclose(source);
        fprintf(stderr, "copyfile fopen fail on tofile: %s\n", tofile);
        exit(EXIT_FAILURE);
    }
    while ((ch = fgetc(source)) != EOF)
        fputc(ch, target);
/* #if defined(DEBUG_fastbuild) */
/*         printf("File copy successful: %s -> %s.\n", */
/*                fromfile, tofile); */
/* #endif */
    fclose(source);
    fclose(target);
    if (obazl_utils_verbosity > obazl_utils_log_writes)
        fprintf(INFOFD, GRN "INFO" CRESET " cp template to %s\n", tofile);
    return 0;
}

EXPORT void copy_template(char *runfiles_root, char *buildfile, char *to_file) {
    UT_string *src;
    utstring_new(src);
    utstring_printf(src,
                    "%s/external/obazl/templates/%s",
                    /* "%s/obazl/templates/%s", */
                    /* utstring_body(runfiles_root), */
                    runfiles_root,
                    buildfile);
    int rc = access(utstring_body(src), F_OK);
    if (rc != 0) {
        log_error("not found: %s", utstring_body(src));
        fprintf(stderr, "not found: %s\n", utstring_body(src));
        return;
    }

    /* if (debug) { */
    /*     log_debug("copying %s to %s\n", */
    /*               utstring_body(src), */
    /*               utstring_body(to_file)); */
    /* } */
    errno = 0;
    rc = copyfile(utstring_body(src),
                  to_file);
    if (rc != 0) {
        log_error("copyfile: %s", strerror(errno));
        fprintf(stderr, "ERROR copyfile: %s", strerror(errno));
        log_error("Exiting");
        fprintf(stderr, "Exiting\n");
        exit(EXIT_FAILURE);
    }
}

