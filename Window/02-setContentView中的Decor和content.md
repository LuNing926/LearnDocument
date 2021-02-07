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

