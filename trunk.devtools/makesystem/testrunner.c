// Copyright (c) 2005 Kreatel Communications AB. All Rights Reserved.
// Copyright (c) 2008 Motorola, Inc. All Rights Reserved.
// Copyright (c) 2014-2015 ARRIS Enterprises, Inc. All rights reserved.
//
// This program is confidential and proprietary to ARRIS Enterprises, Inc.
// (ARRIS), and may not be copied, reproduced, modified, disclosed to others,
// published or used, in whole or in part, without the express prior written
// permission of ARRIS.

#include <fcntl.h>
#include <net/if.h>
#include <sched.h>
#include <signal.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

static pid_t ChildPid = -1;

void Log(const char* type, const char* format, va_list args)
{
  struct timeval tv;
  gettimeofday(&tv, NULL);
  struct tm* tm = localtime(&tv.tv_sec);

  fprintf(stderr, "%02d:%02d:%02d.%03ld testrunner %s: ",
          tm->tm_hour, tm->tm_min, tm->tm_min, tv.tv_usec / 1000, type);
  vfprintf(stderr, format, args);
  fprintf(stderr, "\n");
}

void Error(const char* format, ...) __attribute__ ((format (printf, 1, 2)));
void Error(const char* format, ...)
{
  va_list ap;
  va_start(ap, format);
  Log("Error", format, ap);
  va_end(ap);
}

void Warning(const char* format, ...) __attribute__ ((format (printf, 1, 2)));
void Warning(const char* format, ...)
{
  va_list ap;
  va_start(ap, format);
  Log("Warning", format, ap);
  va_end(ap);
}

void SigTermHandler(int signum)
{
  // Kill the child process group
  if (ChildPid > 0) {
    if (kill(-ChildPid, signum) < 0) {
      Error("failed to send signal %d to child: %m", signum);
    }
  }
}

void SigChildHandler(int __attribute__((unused)) signum)
{
  int status;
  pid_t pid = waitpid(-1, &status, WNOHANG);
  if (pid < 0) {
    Error("failed to wait on child: %m");
    exit(1);
  }
  else if (pid == 0) {
    // No child had changed state
    return;
  }

  if (WIFEXITED(status)) {
    exit(WEXITSTATUS(status));
  }
  else if (WIFSIGNALED(status)) {
    Error("process was killed by signal %d (%s)",
          WTERMSIG(status), strsignal(WTERMSIG(status)));
  }
  else {
    Error("process exited by unknown reason");
  }

  exit(1);
}

bool WriteIdMap(const char* file, unsigned int from, unsigned int to)
{
  int fd = open(file, O_WRONLY);
  if (fd == -1) {
    Error("could not open %s: %m", file);
    return false;
  }

  bool result = true;
  char* idMap;
  const int length = asprintf(&idMap, "%u %u 1", from, to);
  if (write(fd, idMap, length) != length) {
    Error("could not write id mapping to %s: %m", file);
    result = false;
  }

  free(idMap);
  close(fd);
  return result;
}

bool CreateNewNetworkNamespace()
{
  // Get the effective UID/GID here to be able to map them to root after the
  // call to unshare (which changes the EUID/EGID).
  const uid_t realEuid = geteuid();
  const gid_t realEgid = getegid();

  if (unshare(CLONE_NEWNET | CLONE_NEWUSER) != 0) {
    Error("failed to create new namespace: %m");
    return false;
  }

  // Change our user id to root in the new user namespace
  if (!WriteIdMap("/proc/self/uid_map", 0, realEuid)
      || !WriteIdMap("/proc/self/gid_map", 0, realEgid)) {
    return false;
  }

  int fd = socket(AF_INET, SOCK_DGRAM, 0);
  if (fd == -1) {
    Error("could not create socket: %m");
    return false;
  }

  // Bring up the loopback interface
  struct ifreq req;
  strcpy(req.ifr_name, "lo");
  req.ifr_flags = IFF_UP | IFF_LOOPBACK | IFF_RUNNING;
  if (ioctl(fd, SIOCSIFFLAGS, &req) != 0) {
    Error("could not start loopback interface: %m");
    close(fd);
    return false;
  }

  close(fd);

  // Make user non-root again
  unshare(CLONE_NEWUSER);

  return true;
}

void Sleep(unsigned int seconds)
{
  while (seconds > 0) {
    seconds = sleep(seconds);
  }
}

int main(int argc, char* argv[])
{
  if (argc < 4) {
    fprintf(stderr, "Usage: %s WARNINGTIME KILLTIME COMMAND [ARGS]\n", argv[0]);
    return 1;
  }

  // Setup signal handlers
  signal(SIGHUP, SigTermHandler);
  signal(SIGINT, SigTermHandler);
  signal(SIGTERM, SigTermHandler);
  signal(SIGCHLD, SigChildHandler);

  ChildPid = fork();
  if (ChildPid < 0) {
    Error("could not fork process: %m");
  }
  else if (ChildPid == 0) {
    if (getenv("USE_NETNS") != NULL && !CreateNewNetworkNamespace()) {
      _exit(1);
    }

    // Create a new process group for child
    setpgrp();

    // Reset signal handlers
    signal(SIGHUP, SIG_DFL);
    signal(SIGINT, SIG_DFL);
    signal(SIGTERM, SIG_DFL);

    close(STDIN_FILENO);

    char* args[argc - 2];
    for (int i = 0; i < argc - 3; ++i) {
      args[i] = argv[i + 3];
    }
    args[argc - 3] = NULL;
    execvp(args[0], args);
    Error("could not exec program %s", args[0]);
    _exit(1);
  }
  else {
    // Parent
    Sleep(atoi(argv[1]));
    Warning("process takes too long time to to run (%s s)", argv[1]);
    Sleep(atoi(argv[2]) - atoi(argv[1]));
    Error("process did not finish within time limit (%s s)", argv[2]);

    signal(SIGCHLD, SIG_DFL);
    if (kill(-ChildPid, SIGKILL) < 0) {
      Error("failed to send SIGKILL to child: %m");
    }
    wait(NULL);
  }

  return 1;
}
