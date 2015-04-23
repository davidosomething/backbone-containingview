do ($ = window.jQuery, _ = window._, Backbone = window.Backbone)->

  # ContainingView
  # This is a Backbone View with methods and properties to calculate if child
  # elements are in the DOM and in the viewport relative to this view's
  # containing element.
  Backbone.ContainingView = Backbone.View.extend

    # @property {object} containingEl reference to DOM object that contains the
    #           children of this ContainingView. It may not necessarily be the
    #           same as the view's el. The els contained by a ContainingView
    #           are not required to be children of the containingEl -- see
    #           detachedEls in @findContained
    containingEl:   null
    $containingEl:  null

    # @property {boolean} _isThresholdElContainingEl is a flag, when true then
    #           change thresholdEl whenever containingEl changes. They should
    #           be the same when true.
    _isThresholdElContainingEl: true

    # @property {object} thresholdEl DOM object to calculate threshold against
    #                    make sure the thresholdEl is NOT a scrolling element
    thresholdEl: null
    $thresholdEl: null

    # @property {boolean} _thresholdMode whether to bind threshold related
    #           events This is unneeded on leftrailview for instance since
    #           active state is linked to active article in reading pane. In
    #           reading pane it is true.
    _thresholdMode: false

    # @property {number} _threshold fraction from zero (top) to 1 (bottom) of
    #           screen
    threshold: 0

    # @property {int} _thresholdY computed value based on a threshold fraction
    #           when an element should be considered active in the
    #           ContainingView E.g. 0.5 means element at middle of screen is
    #           active
    _thresholdY: 0

    ############################################################################

    # initialize
    #
    # @param {object} options
    # @option options {integer} threshold Optional
    # @option options {integer} thresholdY Optional
    # @option options {object} containingEl DOM element
    initialize: (options = {})->
      @threshold = options.threshold if options.threshold
      @_thresholdMode = @threshold? or @_thresholdY?

      # init thresholdEl
      # options.thresholdEl overrides instance property
      @setThresholdElement(options.thresholdEl) if options.thresholdEl

      # if instance property existed or was just set, don't change it when
      # changing containing element too
      @_isThresholdElContainingEl = false if @thresholdEl

      # init containingEl
      # also init thresholdEl if wasn't init via specified option above
      @setContainingElement(options.containingEl or @el)
      return @

    # autoupdate
    #
    # Only for threshold
    # call super within the child view's render so threshold line gets set
    #
    autoupdate: ->
      return unless @_thresholdMode
      $(window).on('resize orientationchange', @updateThreshold)
      @updateThreshold()
      return @

    ############################################################################
    # Setters
    ############################################################################

    # updateThreshold
    #
    # Set private thresholdY to integer based on getThresholdY calculation
    #
    # @return {integer}
    updateThreshold: =>
      @_thresholdY = @getThresholdY()
      return @_thresholdY

    # setThresholdEl
    #
    # @param {object} el DOM object or jQuery
    # @return {object} DOM
    setThresholdElement: (el)->
      if el instanceof jQuery
        @$thresholdEl = el
        @thresholdEl = el.get(0)
      else
        @thresholdEl = el
        @$thresholdEl = $(el)
      return @thresholdEl

    # setContainingElement
    #
    # Analog to setElement, also updates the @_rect private property
    # Use this to update the @containingEl properly
    # Use the optional flag to also setElement -- so you can use this function
    # as a complete replacement for @setElement
    #
    # @param {object} el DOM object or jQuery
    # @param {boolean} alsoSetElement
    # @return {object} DOM
    setContainingElement: (el, alsoSetElement = false)->
      if el instanceof jQuery
        @$containingEl = el
        @containingEl = el.get(0)
      else
        @containingEl = el
        @$containingEl = $(el)
      @setThresholdElement(el) if @_isThresholdElContainingEl
      @setElement(@$containingEl) if alsoSetElement
      return @containingEl

    ############################################################################
    # Getters
    ############################################################################

    # getThresholdY
    #
    # Returns, (does not set) a _thresholdY line pixel value relative to
    # containingEl
    #
    # @param {number} threshold fraction from 0.0 (top) to 1.0 (bottom)
    # @return {integer)
    getThresholdY: (threshold = @threshold)=>
      offsetTop = 0
      offsetTop = @$thresholdEl.offset().top if @$thresholdEl.length > 0
      return parseInt( (@$thresholdEl.height() * threshold) + offsetTop, 10)

    # getEls
    #
    # Given selectors returns jQuery collection of els matching
    #
    # @param {string} selector OPTIONAL -- might use just detachedEls
    # @param {object} options
    # @option options {string,object} detachedEls selector or jQuery object of
    #                 detached els to check. e.g. tethered els could be
    #                 contained but might not be children
    # @return {object} jquery collection
    getEls: (selector, options = {})->
      if selector
        $els = @$(selector)
      else
        $els = jQuery()
      $els = $els.add(options.detachedEls) if options.detachedEls?.length
      return $els

    # rect
    #
    # @return {object} TextRectangle
    rect: (el = @containingEl)->
      return el.getBoundingClientRect()

    ############################################################################
    # Visibility
    ############################################################################

    # isRectVisible
    #
    # TextRectangle suggests element is not visible
    #
    # By design this does not check if height is zero (or rect top and bottom
    # are zero) so elements hidden by collapsing height are still considered
    # visible
    #
    # @param {object} rect TextRectangle from a DOM object's
    #        getBoundingClientRect
    # @return {boolean}
    isRectVisible: (rect)->
      return false if @isBottomAboveContainer(rect)
      return false if @isTopBelowWindow(rect)
      return false if rect.left is 0 and rect.right is 0
      return true

    # isBottomAboveContainer
    #
    # Scrolled the el above container so it's not visible
    # assumes the container has overflow:hidden
    # This is a condition for element visible
    #
    #    +----+
    #    | el |
    #    +----+
    # += viewport =+
    # |            |
    # +============+
    #
    # @param {object} rect TextRectangle from a DOM object's
    #        getBoundingClientRect
    # @return {boolean}
    isBottomAboveContainer: (rect)->
      return rect.bottom < @$thresholdEl.offset().top

    # isTopBelowWindow
    #
    # Scrolled (or haven't scrolled container) such that the el is
    # This is a condition for element visible
    #
    # += window =+
    # |          |
    # +==========+
    #   +----+
    #   | el |
    #   +----+
    #
    # @param {object} rect TextRectangle from a DOM object's
    #        getBoundingClientRect
    # @return {boolean}
    isTopBelowWindow: (rect)->
      return rect.top > $(window).height()

    ############################################################################
    # Position
    ############################################################################

    # isAtTop
    #
    # NOTE this first arg is "el", not "rect"
    # Need to account for when containingEl is not at top itself
    # e.g. a pushdown in the thresholdEl forced the containingEl down
    #
    # +----------- Win ----------+
    # | +===== thresholdEl ====+ | <-- e.g. #notTheHeader, scrolling el
    # | |    ## PUSHDOWN ##    | |
    # | | +-- containingEl --+ | | <-- e.g. .readingpane, non-scrolling
    # | | |     ## el ##     | | |
    #
    # @param {object} el DOM object
    # @return {boolean}
    isAtTop: (el)->

      elRect = el.getBoundingClientRect()

      # account for el margin top
      elTop = elRect.top - parseInt($(el).css('margin-top'), 10)

      if @_thresholdMode
        if @$containingEl.offset().top > 0  # containingEl was pushed down
          containingElTop = @containingEl.getBoundingClientRect().top
          return elTop - containingElTop is 0

      return elTop is 0

    ############################################################################
    # Threshold
    ############################################################################

    # isOnThreshold
    #
    #  +------- Win -------+ win.top
    #  |  +--- el ---+     | elRect.top
    #  |-------------------| _thresholdY
    #  |  |          |     |
    #  |  +----------+     | elRect.Bottom
    #  +-------------------+
    #
    # @param {object} DOM el
    # @return {bool} El is visible and over the line
    isOnThreshold: (el)->
      elRect = @rect(el)

      return false if not @isRectVisible(elRect)

      # e.g. for ReadingPane if there's a pushdown then the
      return true if @isAtTop(el)

      # @TODO
      # Unaccounted case last child of the containing view needs height such
      # that it and any thin siblings above it can cross the threshold,
      # otherwise they can never be activated.

      # @TODO
      # There exists an unaccounted case where the el is not at top but is
      # above the threshold -- it will never be activated since it will always
      # be above the threshold. -- E.g. very thin article 1 and article 2
      #
      #  +------- Win -------+ win.top
      #  |  +--- el ---+     | elRect.top
      #  |  |          |     | <---- ACTIVATED when isAtTop (ok)
      #  |  +----------+     | elRect.Bottom
      #  |  +--- el ---+     | elRect.top
      #  |  |          |     | <---- NEVER ACTIVATED (noooooooo)
      #  |  +----------+     | elRect.Bottom
      #  |-------------------| _thresholdY
      #  |  +--- el ---+     | elRect.top
      #  |  |          |     | <---- ACTIVATED on scroll over threshold
      #  |  +----------+     | elRect.Bottom
      #  +-------------------+
      #

      # account for when containing el is not at top of thresholdEl
      containingElOffset = @$containingEl.offset().top
      # it was at top of threshold and threshold is scrolled down a bit (so the
      # offset of this el is negative since its top is above thresholdEl top)
      containingElOffset = 0 if containingElOffset < 0

      # Bottom offset - inlcude the containingEl margin - fixes jitter in
      # collections
      bottomOffset = 0

      # @TODO break up into functions
      isAboveThreshold = elRect.top <= @_thresholdY + containingElOffset

      elBottom = elRect.bottom + bottomOffset
      isBelowThreshold = elBottom >= @_thresholdY + containingElOffset
      return isAboveThreshold and isBelowThreshold

    ############################################################################
    # Containment
    ############################################################################

    # findContained
    #
    # @param {object} jQuery els
    # @param {object} options
    # @option options {boolean} partial allow partial matches
    # @option options {boolean} window check if in window too
    # @return {object} jQuery object
    findContained: ($els, options = {})->
      return jQuery() unless $els.length

      options = _.defaults options, {
        partial: false
        window: true
      }

      if options.window
        windowRect = {
          top: 0
          left: 0
          right: $(window).width()
          bottom: $(window).height()
        }

      $containedEls = $els.filter (index, el)=>
        isContained = @isContained(el, options)
        return isContained if not options.window

        # @TODO rip this out
        isInWindow = @isContained(el, {
          partial: options.partial
          containerRect: windowRect
        })
        return isContained and isInWindow

      return $containedEls

    # isContained
    #
    # This does NOT check for visibility -- just that the given object is in
    # the viewport. So if an object has visibility:hidden or opacity: 0 it could
    # still return true.
    #
    # @param {object} el DOM object
    # @param {object} options
    # @option options {boolean} partial
    # @option options {boolean} containerRect
    # @return {boolean}
    isContained: (el, options = {})->
      # need a valid $el
      return false if not el

      # if el is not in body, it's not visible
      return false unless document.body.contains(el)

      # hidden $el is not visible
      $el = $(el)
      return false if $el.css('display') is 'none'

      elRect = @rect(el)

      options = _.defaults options, {
        partial: false
        containerRect: @rect()
      }
      containerRect = options.containerRect

      # TextRectangle suggests element is not visible
      return false unless @isRectVisible(elRect, containerRect)
      return false unless @isRectHorizontallyContained(elRect)

      isPartialMatched = options.partial is true
      isPartiallyContained = @isRectPartiallyContained(elRect, containerRect)
      if isPartialMatched and isPartiallyContained
        return true

      return @isRectFullyContained(elRect, containerRect)

    # isRectHorizontallyContained
    #
    # @param {object} rect TextRectangle from a DOM object's
    #        getBoundingClientRect
    # @return {boolean}
    isRectHorizontallyContained: (rect)->
      # disregard the left value -- assuming no X scrolling
      return rect.right >= 0

    # isRectFullyContained
    #
    # += viewport =+
    # |  +----+    |
    # |  | el |    |
    # |  +----+    |
    # +============+
    #
    # @param {object} rect TextRectangle from a DOM object's
    #        getBoundingClientRect
    # @return {boolean}
    isRectFullyContained: (rect, containerRect = @rect())->
      return false unless @isRectBelowTop(rect, containerRect)
      return false unless @isRectAboveBottom(rect, containerRect)
      return true

    # isRectPartiallyContained
    #
    #    +----+
    # += viewport =+
    # |  | el |    |
    # |  +----+    |
    # |            |
    # |    or      |
    # |            |
    # |  +----+    |
    # +============+
    #    | el |
    #    +----+
    #
    # @param {object} rect TextRectangle from a DOM object's
    #        getBoundingClientRect
    # @return {boolean}
    isRectPartiallyContained: (rect, containerRect = @rect())->
      return true if @isRectTopContained(rect, containerRect)
      return true if @isRectBottomContained(rect, containerRect)
      return false

    # isRectTopContained
    #
    # Top of el is below top of container and above bottom of container
    #
    # @param {object} rect TextRectangle from a DOM object's
    #        getBoundingClientRect
    # @return {boolean}
    isRectTopContained: (rect, containerRect = @rect())->
      isRectTopAboveBottom = rect.top <= containerRect.bottom
      return @isRectBelowTop(rect, containerRect) and isRectTopAboveBottom

    # isRectBottomContained
    #
    # Bottom of el is above bottom of container and below top of container
    #
    # @param {object} rect TextRectangle from a DOM object's
    #        getBoundingClientRect
    # @return {boolean}
    isRectBottomContained: (rect, containerRect = @rect())->
      isRectBottomBelowTop = rect.bottom >= containerRect.top
      return @isRectAboveBottom(rect, containerRect) and isRectBottomBelowTop

    # isRectAboveBottom
    #
    # Bottom of el is inclusively above bottom of container -- doesn't matter
    # if it was scrolled up out of view.
    #
    #  |  +----+    |
    #  |  | el |    |
    #  += viewport =+
    #
    # @param {object} rect TextRectangle from a DOM object's
    #        getBoundingClientRect
    # @return {boolean}
    isRectAboveBottom: (rect, containerRect = @rect())->
      return rect.bottom <= containerRect.bottom

    # isRectBelowTop
    #
    # Top of el is inclusively below top of container -- doesn't matter if it
    # was scrolled down out of view.
    #
    #  += viewport =+
    #  |  +----+    |
    #  |  | el |    |
    #
    # @param {object} rect TextRectangle from a DOM object's
    #        getBoundingClientRect
    # @return {boolean}
    isRectBelowTop: (rect, containerRect = @rect())->
      return rect.top >= containerRect.top

