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

作者：刘望舒
链接：https://www.jianshu.com/p/aadfb70f25e2
来源：简书
著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。
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
```
