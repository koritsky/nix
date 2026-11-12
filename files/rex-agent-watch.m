#import <AppKit/AppKit.h>
#import <signal.h>
#import <unistd.h>

static void launchctl(NSString *action, NSString *domain, NSString *path) {
  NSTask *task = [NSTask new];
  task.executableURL = [NSURL fileURLWithPath:@"/bin/launchctl"];
  task.arguments = @[ action, domain, path ];
  if ([action isEqualToString:@"bootout"]) {
    task.standardError = [NSFileHandle fileHandleWithNullDevice];
  }
  NSError *error = nil;
  if (![task launchAndReturnError:&error]) {
    NSLog(@"Could not run launchctl: %@", error);
    exit(1);
  }
  [task waitUntilExit];
  if ([action isEqualToString:@"bootstrap"] && task.terminationStatus != 0) {
    exit(1);
  }
}

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    if (argc != 2) {
      fprintf(stderr, "Usage: %s JOBS_DIRECTORY\n", argv[0]);
      return 64;
    }
    NSString *directory = @(argv[1]);
    NSString *domain = [NSString stringWithFormat:@"gui/%u", getuid()];
    NSError *error = nil;
    NSArray *files =
        [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory
                                                            error:&error];
    if (!files) {
      NSLog(@"Could not read forwarding jobs: %@", error);
      return 1;
    }
    NSMutableArray<NSString *> *jobs = [NSMutableArray array];
    for (NSString *file in files) {
      if ([file.pathExtension isEqualToString:@"plist"]) {
        [jobs addObject:[directory stringByAppendingPathComponent:file]];
      }
    }
    void (^stop)(void) = ^{
      for (NSString *path in jobs) {
        launchctl(@"bootout", domain, path);
      }
    };
    stop();
    __block BOOL active = NO;
    void (^refresh)(void) = ^{
      BOOL running = NO;
      for (NSRunningApplication *app in
           [NSRunningApplication runningApplicationsWithBundleIdentifier:
                                     @"com.superlogical.rex"]) {
        if (!app.terminated)
          running = YES;
      }
      if (running == active)
        return;
      NSLog(@"%@ SSH agent forwarding", running ? @"Starting" : @"Stopping");
      if (running) {
        for (NSString *path in jobs) {
          launchctl(@"bootstrap", domain, path);
        }
      } else {
        stop();
      }
      active = running;
    };
    NSNotificationCenter *center =
        [NSWorkspace sharedWorkspace].notificationCenter;
    for (NSNotificationName name in @[
           NSWorkspaceDidLaunchApplicationNotification,
           NSWorkspaceDidTerminateApplicationNotification
         ]) {
      [center addObserverForName:name
                          object:nil
                           queue:[NSOperationQueue mainQueue]
                      usingBlock:^(NSNotification *notification) {
                        NSRunningApplication *app =
                            notification.userInfo[NSWorkspaceApplicationKey];
                        if ([app.bundleIdentifier
                                isEqualToString:@"com.superlogical.rex"])
                          refresh();
                      }];
    }
    signal(SIGTERM, SIG_IGN);
    dispatch_source_t termination = dispatch_source_create(
        DISPATCH_SOURCE_TYPE_SIGNAL, SIGTERM, 0, dispatch_get_main_queue());
    dispatch_source_set_event_handler(termination, ^{
      stop();
      exit(0);
    });
    dispatch_resume(termination);
    refresh();
    [[NSRunLoop mainRunLoop] run];
  }
}
