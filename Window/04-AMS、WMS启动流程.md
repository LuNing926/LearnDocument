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
  ActivityManagerService 准备工作线程，准备Android 四大组件相关的数据结构;
  3.1中启动AMS之前先启动了ATMS，并作为参数传给了AMS；
  这里调用了ATMS.initialize,初始化
```
public ActivityManagerService(Context systemContext, ActivityTaskManagerService atm) {
2558        LockGuard.installLock(this, LockGuard.INDEX_ACTIVITY);
2559        mInjector = new Injector(systemContext);
2560        mContext = systemContext;
2561
2562        mFactoryTest = FactoryTest.getMode();
2563        mSystemThread = ActivityThread.currentActivityThread();
2564        mUiContext = mSystemThread.getSystemUiContext();
2565
2566        Slog.i(TAG, "Memory class: " + ActivityManager.staticGetMemoryClass());
2567
2568        mHandlerThread = new ServiceThread(TAG,
2569                THREAD_PRIORITY_FOREGROUND, false /*allowIo*/);
2570        mHandlerThread.start();
2571        mHandler = new MainHandler(mHandlerThread.getLooper());
2572        mUiHandler = mInjector.getUiHandler(this);
    ...... 
2651        mActivityTaskManager = atm;
2652        mActivityTaskManager.initialize(mIntentFirewall, mPendingIntentController,
2653                DisplayThread.get().getLooper());
2654        mAtmInternal = LocalServices.getService(ActivityTaskManagerInternal.class);
    ......
2711    }
```
- 3.3 AMS setSystemProcess()
  AMS 通过 setSystemProcess 把System_Server 进程加入到AMS 的进程管理中。加载 framework-res.apk
```
public void setSystemProcess() {
2100        try {
2101            ServiceManager.addService(Context.ACTIVITY_SERVICE, this, /* allowIsolated= */ true,
2102                    DUMP_FLAG_PRIORITY_CRITICAL | DUMP_FLAG_PRIORITY_NORMAL | DUMP_FLAG_PROTO);
2103            ServiceManager.addService(ProcessStats.SERVICE_NAME, mProcessStats);
2104            ServiceManager.addService("meminfo", new MemBinder(this), /* allowIsolated= */ false,
2105                    DUMP_FLAG_PRIORITY_HIGH);
2106            ServiceManager.addService("gfxinfo", new GraphicsBinder(this));
2107            ServiceManager.addService("dbinfo", new DbBinder(this));
2108            if (MONITOR_CPU_USAGE) {
2109                ServiceManager.addService("cpuinfo", new CpuBinder(this),
2110                        /* allowIsolated= */ false, DUMP_FLAG_PRIORITY_CRITICAL);
2111            }
2112            ServiceManager.addService("permission", new PermissionController(this));
2113            ServiceManager.addService("processinfo", new ProcessInfoService(this));
2114            ServiceManager.addService("cacheinfo", new CacheBinder(this));
2115
2116            ApplicationInfo info = mContext.getPackageManager().getApplicationInfo(
2117                    "android", STOCK_PM_FLAGS | MATCH_SYSTEM_ONLY);
2118            mSystemThread.installSystemApplicationInfo(info, getClass().getClassLoader());
2119
2120            synchronized (this) {
2121                ProcessRecord app = mProcessList.newProcessRecordLocked(info, info.processName,
2122                        false,
2123                        0,
2124                        new HostingRecord("system"));
2125                app.setPersistent(true);
2126                app.pid = MY_PID;
2127                app.getWindowProcessController().setPid(MY_PID);
2128                app.maxAdj = ProcessList.SYSTEM_ADJ;
2129                app.makeActive(mSystemThread.getApplicationThread(), mProcessStats);
2130                addPidLocked(app);
2131                mProcessList.updateLruProcessLocked(app, false, null);
2132                updateOomAdjLocked(OomAdjuster.OOM_ADJ_REASON_NONE);
2133            }
2134        } catch (PackageManager.NameNotFoundException e) {
2135            throw new RuntimeException(
2136                    "Unable to find android system package", e);
2137        }
2138
2139        // Start watching app ops after we and the package manager are up and running.
2140        mAppOpsService.startWatchingMode(AppOpsManager.OP_RUN_IN_BACKGROUND, null,
2141                new IAppOpsCallback.Stub() {
2142                    @Override public void opChanged(int op, int uid, String packageName) {
2143                        if (op == AppOpsManager.OP_RUN_IN_BACKGROUND && packageName != null) {
2144                            if (getAppOpsManager().checkOpNoThrow(op, uid, packageName)
2145                                    != AppOpsManager.MODE_ALLOWED) {
2146                                runInBackgroundDisabled(uid);
2147                            }
2148                        }
2149                    }
2150                });
2151
2152        final int[] cameraOp = {AppOpsManager.OP_CAMERA};
2153        mAppOpsService.startWatchingActive(cameraOp, new IAppOpsActiveCallback.Stub() {
2154            @Override
2155            public void opActiveChanged(int op, int uid, String packageName, boolean active) {
2156                cameraActiveChanged(uid, active);
2157            }
2158        });
2159    }
```
- 3.4 installSystemProviders
  在startOtherServices 安装 SettingProvider
```
1016    private void startOtherServices(@NonNull TimingsTraceAndSlog t) {
    ......
1122            mActivityManagerService.installSystemProviders();
    ......
1172            mActivityManagerService.setWindowManager(wm);
    ......
    }
```
- 3.5 setWindowManager
  如上
- 3.6 systemReady
  各种服务启动完毕后，systemReady. 在systemReady 中先启动SystemUI, 然后启动Launcher.
