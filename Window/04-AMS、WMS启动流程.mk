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
- 2.2 System_Server 的run 方法
- 三 AMS 运行
- 3.1 mSystemServiceManager.startService
- 3.2 启动ActivityManagerService
- 3.3 AMS setSystemProcess()
- 3.4 installSystemProviders
- 3.5 setWindowManager
- 3.6 systemReady
