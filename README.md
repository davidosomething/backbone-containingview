# Backbone.ContainingView

> Backbone view with element boundary detection

## About

Handles scrolling past thresholds and element visibility given a view and its
parent view.

## Usage

#### Threshold mode

Determines if a given DOM object (el) is over an imaginary line in another DOM
object (thresholdEl).

```coffeescript
myView = new Backbone.ContainingView({
  el: '#Actual'
  thresholdEl: $('#Parent')
  threshold: 0.5
})

if myView.isOnThreshold(myView.el)
  console.log("The view is over the parent's midpoint")
```

#### Containing mode

Determines if a given DOM object (el) is contained within another DOM object
(containingEl). The definition of "contained" is visually inside the
containingEl's borders -- the el does not need to be a child of the
containingEl (e.g. an absolutely positioned el).

```coffeescript
myView = new Backbone.ContainingView({
  el: '#OverflowAutoContainer'
  containingEl: $('#Articles')
})

# where articles contains several <div class="article">
$fullyVisibleArticles = myView.findContained(myView.$('.article'))
$includingPartiallyVisible = myView.findContained(myView.$('.article'), {
  partial: true
})
```

See the source of `src/backbone-containingview.coffee` for documented
functions.

## Changelog

v0.1.0 - 2015-04-22 - Initial commit, production tested code.

