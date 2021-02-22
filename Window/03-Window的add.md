- 窗口结构.md中setContentView->installDecor->generate DecorView->generateLayout mContentParent
  最终调用WindowManager.addView将窗口添加上去，这篇文档看看addView做了什么。
  根据之前的分析，addView的最终实现在WindowManagerGlobal中，也包括updateViewLayout和removeView
  
### frameworks/base/core/java/android/view/WindowManagerGlobal.java
- 首先会对参数view、params和display进行检查。然后创建了ViewRootImp并赋值给root，将root存入到ArrayList<ViewRootImpl>类型的mRoots中，除了mRoots，mViews和mParams也是ArrayList类型的，分别用于存储窗口的view对象和WindowManager.LayoutParams类型的wparams对象。之后调用了ViewRootImpl的setView方法。
```
public void addView(View view, ViewGroup.LayoutParams params,
    Display display, Window parentWindow, int userId) {
    ......参数检查
    root = new ViewRootImpl(view.getContext(), display);
    view.setLayoutParams(wparams);
    mViews.add(view);
    mRoots.add(root);
    mParams.add(wparams);

    // do this last because it fires off messages to start doing things
    try {
        root.setView(view, wparams, panelParentView, userId);
    } catch (RuntimeException e) {
    ......
}
```
### frameworks/base/core/java/android/view/ViewRootImpl.java
- setView首先一些准备工作，然后调用mWindowSession.addToDisplayAsUser，返回res，后半部分都是对res异常状态的处理。
  mWindowSession是IWindowSession类型的，它是一个Binder对象，用于进行进程间通信，IWindowSession是Client端的代理，它的Server端的实现为Session，此前包含ViewRootImpl在内的代码逻辑都是运行在本地进程的，而Session的addToDisplay方法则运行在WMS所在的进程。
```
public void setView(View view, WindowManager.LayoutParams attrs, View panelParentView, int userId) {
     ......
     res = mWindowSession.addToDisplayAsUser(mWindow, mSeq, mWindowAttributes,
         getHostVisibility(), mDisplay.getDisplayId(), userId, mTmpFrame,
         mAttachInfo.mContentInsets, mAttachInfo.mStableInsets,
         mAttachInfo.mDisplayCutout, inputChannel,
         mTempInsets, mTempControls);
     ......
```
### frameworks/base/services/core/java/com/android/server/wm/Session.java
- Session的addToDisplay方法调用到WindowManagerService.addWindow，并将自身也就是Session，作为参数传了进去，每个应用程序进程都会对应一个Session，WMS会用ArrayList来保存这些Session。
  这样剩下的工作就交给WMS来处理，在WMS中会为这个添加的窗口分配Surface，并确定窗口显示次序，可见负责显示界面的是画布Surface，而不是窗口本身。
  WMS会将它所管理的Surface交由SurfaceFlinger处理，SurfaceFlinger会将这些Surface混合并绘制到屏幕上。
```
@Override
public int addToDisplayWithoutInputChannel(IWindow window, int seq, WindowManager.LayoutParams attrs,
        int viewVisibility, int displayId, Rect outContentInsets, Rect outStableInsets,
        InsetsState outInsetsState) {
    return mService.addWindow(this, window, seq, attrs, viewVisibility, displayId,
        new Rect() /* outFrame */, outContentInsets, outStableInsets,
        new DisplayCutout.ParcelableWrapper() /* cutout */, null /* outInputChannel */,
        outInsetsState, mDummyControls, UserHandle.getUserId(mUid));
```
### frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java
- 每个display对应一个DisplayContent，RootWindowContainer内部的childs保存所有的DisplayContent，getDisplayContentOrCreate获取不到就new一个。
- DisplayContent构造方法中会创建很多变量，窗口动画、窗口方向、鼠标事件、触摸事件、输入事件、壁纸等，各种和屏幕相关的类。
- 创建WindowState，它代表一个真正的Window。WindowState中的mClientViewRootImpl中的w对象，用于和客户端对话
- win.openInputChannel给window添加InputChannel
- win.attach调回Session
```
 public int addWindow(Session session, IWindow client, int seq,
     LayoutParams attrs, int viewVisibility, int displayId, Rect outFrame, Rect outContentInsets, Rect outStableInsets,
     DisplayCutout.ParcelableWrapper outDisplayCutout, InputChannel outInputChannel, InsetsState outInsetsState, InsetsSourceControl[] outActiveControls, int requestUserId) {
     ......
     final DisplayContent displayContent = getDisplayContentOrCreate(displayId, attrs.token);
     ......
     final WindowState win = new WindowState(this, session, client, token, parentWindow,
         appOp[0], seq, attrs, viewVisibility, session.mUid, userId，session.mCanAddInternalSystemWindow);
     ......
     if  (openInputChannels) {
          win.openInputChannel(outInputChannel);
     }
     ......
     win.attach();
 }
 private DisplayContent getDisplayContentOrCreate(int displayId, IBinder token) {
     if (token != null) {
         final WindowToken wToken = mRoot.getWindowToken(token);
         if (wToken != null) {
             return wToken.getDisplayContent(); 
         }
     }
     return mRoot.getDisplayContentOrCreate(displayId);
}
 ```
 ### frameworks/base/services/core/java/com/android/server/wm/WindowState.java
 ```
 void attach() {
    if (DEBUG) Slog.v(TAG, "Attaching " + this + " token=" + mToken);
        mSession.windowAddedLocked(mAttrs.packageName);
    }
}
```
### frameworks/base/services/core/java/com/android/server/wm/Session.java
- 创建SurfaceSession，SurfaceSession是java层的一个对SurfaceFlinger的客户端SurfaceComposerClient的包装，能够直接和SurfaceFlinger对话
```
void windowAddedLocked(String packageName) {
513        mPackageName = packageName;
514        mRelayoutTag = "relayoutWindow: " + mPackageName;
515        if (mSurfaceSession == null) {
516            if (DEBUG) {
517                Slog.v(TAG_WM, "First window added to " + this + ", creating SurfaceSession");
518            }
519            mSurfaceSession = new SurfaceSession();
520            ProtoLog.i(WM_SHOW_TRANSACTIONS, "  NEW SURFACE SESSION %s", mSurfaceSession);
521            mService.mSessions.add(this);
522            if (mLastReportedAnimatorScale != mService.getCurrentAnimatorScale()) {
523                mService.dispatchNewAnimatorScaleLocked(this);
524            }
525        }
526        mNumWindow++;
527    }
```
### frameworks/base/core/java/android/view/SurfaceSession.java
- 开始和surface的通信了
```
/** Create a new connection with the surface flinger. */
37    @UnsupportedAppUsage
38    public SurfaceSession() {
39        mNativeClient = nativeCreate();
40    }
```
### frameworks/base/core/jni/android_view_SurfaceSession.cpp
- nativeCreate创建了SurfaceComposerClient，SurfaceFlinger在java层的client
```
static jlong nativeCreate(JNIEnv* env, jclass clazz) {
44    SurfaceComposerClient* client = new SurfaceComposerClient();
45    client->incStrong((void*)nativeCreate);
46    return reinterpret_cast<jlong>(client);
47}
```
