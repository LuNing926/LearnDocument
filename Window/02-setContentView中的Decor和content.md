- 上篇文档介绍到Window是个抽象概念，唯一实现类是PhoneWindow，PhoneWindow通过install DecorView添加布局，
  这篇文档看看DecorView是怎么install的，install过程是怎么确定窗口属性和样式的，最后又是怎么添加到屏幕上的。
  
- Activity.java: onCreate
```
public void setContentView(@LayoutRes int layoutResID) {
       getWindow().setContentView(layoutResID);           //getWindow(): PhoneWindow
       initWindowDecorActionBar();
   }
```
PhoneWindow.java: installDecor()
```
@Override
public void setContentView(int layoutResID) {
    ......
    if (mContentParent == null) {
        installDecor();                                   // 创建DecorView
    } else if (!hasFeature(FEATURE_CONTENT_TRANSITIONS)) {
        mContentParent.removeAllViews();
    }
    ......
```
DecorView: installDecorView()
```
private void installDecor() {
    mForceDecorInstall = false;
    if (mDecor == null) {
        mDecor = generateDecor(-1);                       // new DecorView, 创建一个空的DecorView
        ......
     } else {
         mDecor.setWindow(this);
     }
     if (mContentParent == null) {
         mContentParent = generateLayout(mDecor);         // 根据style、feature等设置窗口的属性，根据窗口类型（No actionbar，progress等）确定layout id
    ......
```

## DecorView的install
- 首先new一个DecorView，这里的DecorView其实是空的，没有内容，后面会通过应用设置的样式、属性为其选择布局文件，填充内容。
```
mDecor = generateDecor(-1);

protected DecorView generateDecor() {
        return new DecorView(getContext(), -1);
    }
```
- 真正有用的是generateLayout,根据style、feature等设置窗口的属性，根据窗口类型（No actionbar，progress等）确定layout id
```
protected ViewGroup generateLayout(DecorView decor) {
        // Apply data from current theme.
        //根据当前设置的主题来加载默认布局
        TypedArray a = getWindowStyle();
        //如果你在theme中设置了window_windowNoTitle，则这里会调用到，其他方法同理，
        //这里是根据你在theme中的设置去设置的
        if (a.getBoolean(R.styleable.Window_windowNoTitle, false)) {
            requestFeature(FEATURE_NO_TITLE);
        } else if (a.getBoolean(R.styleable.Window_windowActionBar, false)) {
            // Don't allow an action bar if there is no title.
            requestFeature(FEATURE_ACTION_BAR);
        }
        //是否有设置全屏
        if (a.getBoolean(R.styleable.Window_windowFullscreen, false)) {
            setFlags(FLAG_FULLSCREEN, FLAG_FULLSCREEN & (~getForcedWindowFlags()));
        }
        
        //其他加载资源
        ...
        
        //加载窗口布局，确定一个layout
        int layoutResource;
        int features = getLocalFeatures();
        // System.out.println("Features: 0x" + Integer.toHexString(features));
        if ((features & (1 << FEATURE_SWIPE_TO_DISMISS)) != 0) {
            layoutResource = R.layout.screen_swipe_dismiss;
        } ... //省略其他判断方法
        } else {
            // Embedded, so no decoration is needed.
            layoutResource = R.layout.screen_simple;
            // System.out.println("Simple!");
        }

        mDecor.startChanging();
        //选择对应布局创建添加到DecorView中，这个布局文件中有一个id="@android:id/content的FrameLayout，就是Decor的内容展示框
        View in = mLayoutInflater.inflate(layoutResource, null);
        decor.addView(in, new ViewGroup.LayoutParams(MATCH_PARENT, MATCH_PARENT));
        mContentRoot = (ViewGroup) in;
        ViewGroup contentParent = (ViewGroup)findViewById(ID_ANDROID_CONTENT);       //ID_ANDROID_CONTENT->id="@android:id/content
        ...
        return contentParent;
    }
```
