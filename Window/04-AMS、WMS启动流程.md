## AMS、WMS启动流程

### AMS启动
- Android系统中的进程分为两种，应用进程和系统进程。
  ActivityThread就是应用进程的主线程，Android系统的应用进程启动后首先运行ActivityThread的main函数，ActivityThread和AMS进行通信，调度和执行应用进程的四大组件。
- SystemServer是Android的系统进程，由于系统进程中也有一些Activity和系统资源，为了保证调用方式统一，系统进程也需要ActivityThread和Context等Android运行环境。
  所以SystemServer也是一个特殊的应用进行。
  
#### 一 Zygote fork SystemServer 进程
- Zygote fork SystemServer 的过程如下：
  ZygoteInit#forkSystemServer
  ZygoteInit#handleSystemServerProcess
  ZygoteInit#zygoteInit
  RuntimeInit#applicationInit
  RuntimeInit#findStaticMain
- 1.1 Zygote fork SystemServer 进程
  ZygoteInit#forkSystemServer 配置system_server 的参数，uid gid 进程显示的名字等，然后调用native 的fork, 在子进程中调用handleSystemServerProcess
- 1.2 System_service 进程启动，准备加载的ClassLoader
- 1.3 RuntimeInit 初始化，进一步的准备初始化的环境
- 1.4 通过findStaticMain 方法反射调用System_Server 的main 方法
#### 二 SystemServer进程
- 2.1 SystemServer 启动，然后运行 run 方法
```
/**
411     * The main entry point from zygote.
412     */
413    public static void main(String[] args) {
414        new SystemServer().run();
415    }
416
417    public SystemServer() {
418        // Check for factory test mode.
419        mFactoryTestMode = FactoryTest.getMode();
420
421        // Record process start information.
422        // Note SYSPROP_START_COUNT will increment by *2* on a FDE device when it fully boots;
423        // one for the password screen, second for the actual boot.
424        mStartCount = SystemProperties.getInt(SYSPROP_START_COUNT, 0) + 1;
425        mRuntimeStartElapsedTime = SystemClock.elapsedRealtime();
426        mRuntimeStartUptime = SystemClock.uptimeMillis();
427        Process.setStartTimes(mRuntimeStartElapsedTime, mRuntimeStartUptime);
428
429        // Remember if it's runtime restart(when sys.boot_completed is already set) or reboot
430        // We don't use "mStartCount > 1" here because it'll be wrong on a FDE device.
431        // TODO: mRuntimeRestart will *not* be set to true if the proccess crashes before
432        // sys.boot_completed is set. Fix it.
433        mRuntimeRestart = "1".equals(SystemProperties.get("sys.boot_completed"));
434    }
```
- 2.2 System_Server 的run 方法
  开始首先配置 VM 参数
  Binder 参数
  Loop.prepareMainLooper
  创建系统Context createSystemContext
  启动系统的各种服务，包括AMS。startBootstrapServices() startCoreServices() startOtherServices()
  Looper.Loop();
```
private void run() {
    try {
    ......
504            SystemProperties.set("persist.sys.dalvik.vm.lib.2", VMRuntime.getRuntime().vmLibrary());
505
506            // Mmmmmm... more memory!
507            VMRuntime.getRuntime().clearGrowthLimit();
508
    ......
524            // Ensure binder calls into the system always run at foreground priority.
525            BinderInternal.disableBackgroundScheduling(true);
526
527            // Increase the number of binder threads in system_server
528            BinderInternal.setMaxThreads(sMaxBinderThreads);
530            // Prepare the main looper thread (this thread).
531            android.os.Process.setThreadPriority(
532                    android.os.Process.THREAD_PRIORITY_FOREGROUND);
533            android.os.Process.setCanSelfBackground(false);
534            Looper.prepareMainLooper();
535            Looper.getMainLooper().setSlowLogThresholdMs(
536                    SLOW_DISPATCH_THRESHOLD_MS, SLOW_DELIVERY_THRESHOLD_MS);
537
538            SystemServiceRegistry.sEnableServiceNotFoundWtf = true;
539
540            // Initialize native services.
541            System.loadLibrary("android_servers");
542
543            // Allow heap / perf profiling.
544            initZygoteChildHeapProfiling();
545
546            // Debug builds - spawn a thread to monitor for fd leaks.
547            if (Build.IS_DEBUGGABLE) {
548                spawnFdLeakCheckThread();
549            }
550
551            // Check whether we failed to shut down last time we tried.
552            // This call may not return.
553            performPendingShutdown();
554
555            // Initialize the system context.
556            createSystemContext();
    ......
593        // Start services.
594        try {
595            t.traceBegin("StartServices");
596            startBootstrapServices(t);            //接3.1
597            startCoreServices(t);
598            startOtherServices(t);
599        } catch (Throwable ex) {
600            Slog.e("System", "******************************************");
601            Slog.e("System", "************ Failure starting system services", ex);
602            throw ex;
603        } finally {
604            t.traceEnd(); // StartServices
605        }
606
607        StrictMode.initVmDefaults(null);
    ......
627        // Loop forever.
628        Looper.loop();
629        throw new RuntimeException("Main thread loop unexpectedly exited");
630    }
```
- 三 AMS 运行
- 3.1 mSystemServiceManager.startService
  接2.2,SystemServer.run中startBootstrapServices 通过mSystemServiceManager 启动ActivityManagerService。
```
710    private void startBootstrapServices(@NonNull TimingsTraceAndSlog t) {
    ......
761        // Activity manager runs the show.
762        t.traceBegin("StartActivityManager");
763        // TODO: Might need to move after migration to WM.
764        ActivityTaskManagerService atm = mSystemServiceManager.startService(
765                ActivityTaskManagerService.Lifecycle.class).getService();
766        mActivityManagerService = ActivityManagerService.Lifecycle.startService(
767                mSystemServiceManager, atm);
768        mActivityManagerService.setSystemServiceManager(mSystemServiceManager);
769        mActivityManagerService.setInstaller(installer);
770        mWindowManagerGlobalLock = atm.getGlobalLock();
771        t.traceEnd();
    ......
```
- 3.2 启动ActivityManagerService
  ctivityManagerService 准备工作线程，准备Android 四大组件相关的数据结构;
- 3.3 AMS setSystemProcess()
- 3.4 installSystemProviders
- 3.5 setWindowManager
- 3.6 systemReady
