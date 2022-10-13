Go to `about:config` and make changes:

```
gfx.webrender.all: true
general.smoothScroll.msdPhysics.enabled: true
general.smoothScroll.msdPhysics.continuousMotionMaxDeltaMS: 12
general.smoothScroll.msdPhysics.motionBeginSpringConstant: 125
general.smoothScroll.msdPhysics.regularSpringConstant: 100
mousewheel.min_line_scroll_amount: 42
mousewheel.default.delta_multiplier_y: 10
```

> [source](https://www.reddit.com/r/firefox/comments/mq9g52/linux_firefox_performancemacos_like_mouse_wheel/)

## other firefox config

* new tabs open next to current tab
  * `browser.tabs.insertAfterCurrent = true`
