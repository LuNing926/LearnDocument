 ## Window、PhoneWindow、DecorView
 - 每个Activity都有一个Window，Window是抽象类
     是一个抽象概念，并不是真正的window，而是一个用于对真正的图形显示组件（Surface）做管理的 “虚拟窗口概念”。
     我们在开发过程中的意识上可以认为Window就是一个屏幕窗口，这也是Android提出Window概念的目的所在，可以更好的面向开发者理解。
 - PhoneWindow是Window的唯一实现类
     将Decoriew设置为整个应用窗口的根View。它是Android中的最基本的窗口系统，每个Activity 均会创建一个PhoneWindow对象，是Activity和整个View系统交互的接口。
 - DecorView顶层视图
     PhoneWindow中持有一个DecorView，所有view的根view。
     - DecirView的几个主要功能：
       1.Dispatch 从ViewRoot分发来的key、touch、trackball等外部事件；
       2.DecorView有一个直接的子View，我们称之为System Layout,这个View是从系统的Layout.xml中解析出的，它包含当前UI的风格，如是否带title、是否带process bar等。可以称这些属性为Window decorations。
       3.作为PhoneWindow与ViewRoot之间的桥梁，ViewRoot通过DecorView设置窗口属性。//可以这样获取 View view = getWindow().getDecorView();
     - DecorView只有一个子元素为LinearLayout。代表整个Window界面，分三块区域：
       1.通知栏
       2.标题栏:DecorView里面TitleView可以设置requestWindowFeature(Window.FEATURE_NO_TITLE)取消掉
       3.内容显示栏 ContentView: 是一个id为content的FrameLayout，在Activity使用的setContentView就是把*.xml设置在这个FrameLayout上的
 
 ## 创建方法
 从setContentView追踪window的窗口加载过程
 Activity.java -> getWindow(): PhoneWindow
 ```
 public void setContentView(@LayoutRes int layoutResID) {
        getWindow().setContentView(layoutResID);           //getWindow(): PhoneWindow
        initWindowDecorActionBar();
    }
```
PhoneWindow.java -> installDecor()创建DecorView
```
@Override
public void setContentView(int layoutResID) {
    // Note: FEATURE_CONTENT_TRANSITIONS may be set in the process of installing the window
    // decor, when theme attributes and the like are crystalized. Do not check the feature
    // before this happens.
    if (mContentParent == null) {
        installDecor();                                   // 创建DecorView
    } else if (!hasFeature(FEATURE_CONTENT_TRANSITIONS)) {
        mContentParent.removeAllViews();
    }
 
    if (hasFeature(FEATURE_CONTENT_TRANSITIONS)) {
        final Scene newScene = Scene.getSceneForLayout(mContentParent, layoutResID, getContext());
        transitionTo(newScene);
    } else {
        mLayoutInflater.inflate(layoutResID, mContentParent);    
    }
    mContentParent.requestApplyInsets();
    final Callback cb = getCallback();
    if (cb != null && !isDestroyed()) {
        cb.onContentChanged();                            // Activity中重写，处理content change
    }
    mContentParentExplicitlySet = true;
}
```
installDecorView
```
private void installDecor() {
    mForceDecorInstall = false;
    if (mDecor == null) {
        mDecor = generateDecor(-1);                       // new DecorView, 创建一个空的DecorView
        mDecor.setDescendantFocusability(ViewGroup.FOCUS_AFTER_DESCENDANTS);
        mDecor.setIsRootNamespace(true);
        if (!mInvalidatePanelMenuPosted && mInvalidatePanelMenuFeatures != 0) {
            mDecor.postOnAnimation(mInvalidatePanelMenuRunnable);
        }
     } else {
         mDecor.setWindow(this);
     }
     if (mContentParent == null) {
         mContentParent = generateLayout(mDecor);         // 根据style、feature等设置窗口的属性，根据窗口类型（No actionbar，progress等）确定layout id
    ......
```
 
 - ![笔记](https://github.com/LuNing926/LearnDocument/blob/main/Window/image/window.jpg)
 
