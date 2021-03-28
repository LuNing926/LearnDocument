
## Window的属性

### 主要属性

Window的属性有很多种，与应用开发最密切的有三种，它们分别是Type(Window的类型)、Flag(Window的标志)和SoftInputMode（软键盘相关模式）。

### window Type

WindowManager定义了3种window Type：
 1. **应用窗口** ：对应于一个Activity。加载Activity由AMS完成，创建一个应用窗口只能在Activity内部完成；
Activity就是一个典型的应用程序窗口，应用程序窗口包含的类型如下所示。
注释1处的Type表示应用程序窗口类型初始值，注释2处的Type表示应用程序窗口类型结束值，也就是说应用程序窗口的Type值范围为1到99，这个数值的大小涉及到窗口的层级，
WMS进行窗口叠加的时候会按照该int常量的大小分配不同层，int值越大层位置越靠上面。
frameworks/base/core/java/android/view/WindowManager.java

 ```javascript
public static final int FIRST_APPLICATION_WINDOW = 1;//1
public static final int TYPE_BASE_APPLICATION   = 1;//窗口的基础值，其他的窗口值要大于这个值
public static final int TYPE_APPLICATION        = 2;//普通的应用程序窗口类型
public static final int TYPE_APPLICATION_STARTING = 3;//应用程序启动窗口类型，用于系统在应用程序窗口启动前显示的窗口。
public static final int TYPE_DRAWN_APPLICATION = 4;
public static final int LAST_APPLICATION_WINDOW = 99;//2
```



 2. **子窗口** ：它不能独立的存在，需要附着在其他窗口才可以，PopupWindow就属于子窗口。子窗口的类型定义如下所示：
 子窗口的Type值范围为1000到1999
  ```javascript
 public static final int FIRST_SUB_WINDOW = 1000;//子窗口类型初始值
 public static final int TYPE_APPLICATION_PANEL = FIRST_SUB_WINDOW;
 public static final int TYPE_APPLICATION_MEDIA = FIRST_SUB_WINDOW + 1;
 public static final int TYPE_APPLICATION_SUB_PANEL = FIRST_SUB_WINDOW + 2;
 public static final int TYPE_APPLICATION_ATTACHED_DIALOG = FIRST_SUB_WINDOW + 3;
 public static final int TYPE_APPLICATION_MEDIA_OVERLAY  = FIRST_SUB_WINDOW + 4; 
 public static final int TYPE_APPLICATION_ABOVE_SUB_PANEL = FIRST_SUB_WINDOW + 5;
 public static final int LAST_SUB_WINDOW = 1999;//子窗口类型结束值
 ```

3. **系统窗口** ：不需要对应任何Activity，应用程序不能创建系统窗口；
Toast、输入法窗口、系统音量条窗口、系统错误窗口都属于系统窗口。系统窗口的类型定义如下所示：
系统窗口的类型值有接近40个，这里只列出了一小部分， 系统窗口的Type值范围为2000到2999。
  ```javascript
 public static final int FIRST_SYSTEM_WINDOW     = 2000;//系统窗口类型初始值
 public static final int TYPE_STATUS_BAR         = FIRST_SYSTEM_WINDOW;//系统状态栏窗口
 public static final int TYPE_SEARCH_BAR         = FIRST_SYSTEM_WINDOW+1;//搜索条窗口
 public static final int TYPE_PHONE              = FIRST_SYSTEM_WINDOW+2;//通话窗口
 public static final int TYPE_SYSTEM_ALERT       = FIRST_SYSTEM_WINDOW+3;//系统ALERT窗口
 public static final int TYPE_KEYGUARD           = FIRST_SYSTEM_WINDOW+4;//锁屏窗口
 public static final int TYPE_TOAST              = FIRST_SYSTEM_WINDOW+5;//TOAST窗口
 ...
 
 public static final int LAST_SYSTEM_WINDOW      = 2999;//系统窗口类型结束值
 ```


### window Flag


## window SoftInputMode
