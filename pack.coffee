class Node
  constructor: (@parent, x=0, y=0, w=0, h=0) ->
    @left = null
    @right = null
    @filled = false
    @vertical_split = false

    # create a div and put it in the dom
    @div = $(document.createElement('div'))
    @div[0].selected = false
    @div[0].node = this
    @div.addClass('logo')
    @div[0].onclick = ->
      toggle_selected this
    @x(x)
    @y(y)
    @w(w)
    @h(h)
    $('#unselected').append @div

  # getter/setters for position and size
  x: (args...) =>
    if args.length
      @div.css('left', args[0])
    else
      parseInt(@div.css('left'))
  y: (args...) =>
    if args.length
      @div.css('top', args[0])
    else
      parseInt(@div.css('top'))
  w: (args...) =>
    if args.length
      @div.width(args[0])
    else
      @div.width()
  h: (args...) =>
    if args.length
      @div.height(args[0])
    else
      @div.height()


  show_connections: =>
    ctx = $("#overlay")[0].getContext("2d")
    x = @x()
    y = @y()
    w = @w()
    h = @h()    
    draw_arrow_with_dots ctx, x+w/2, y+h/2, @left.x()+@left.w()/2, @left.y()+@left.h()/2, "red"
    draw_arrow_with_dots ctx, x+w/2, y+h/2, @right.x()+@right.w()/2, @right.y()+@right.h()/2, "blue"

  insert_img: (img) =>
    return @left.insert_img(img) or @right.insert_img(img)  if @left?
    return null  if @filled
    return null  unless img.fits_in(@div)
    if img.same_size_as(@div)
      this.div.append(img)
      @filled = true
      return this
  
    x = @x()
    y = @y()
    w = @w()
    h = @h()
    img_w = img.width
    img_h = img.height  
    width_diff = @w() - img.width
    height_diff = @h() - img.height

    if width_diff > height_diff
      @vertical_split = true
      @left = new Node(this, x, y, img_w, h)
      @right = new Node(this, x + img_w, y, w - img_w, h)
    else
      @vertical_split = false
      @left = new Node(this, x, y, w, img_h)
      @right = new Node(this, x, y + img_h, w, h - img_h)
    @show_connections()
    @left.insert_img img

  move_left: (d, r) =>
    # move this node and all its descendants left by d
    # PRECONDITION: this is a right child
    @x(@x() - d)
    if @x() + @w() + d is r # touching right boundary
      if @filled
        ### replace this with:
            A
           / \
         this B
        where this is moved left and B is the space opened by the move 
        ###
        @parent.right = new Node(@parent, @x(), @y(), @w() + d, @h()) # create A
        @parent.right.left = this # make this A's left child
        @parent.right.right = new Node(@parent.right, @x() + @w(), @y(), d, @h()) # create B
        @parent = @parent.right # make A this's new parent
      else # unfilled
        @w(@w() + d) # keep it anchored to right boundary
    # move descendants
    @left?.move_left(d, r)
    @right?.move_left(d, r) 

  move_up: (d, b) =>
    # move this node and all its descendants up by d
    # if an element is touching the bottom boundary b, keep it anchored there and extend it up
    # PRECONDITION: this is a right child
    @y(@y() - d)
    if @y() + @h() + d is b # touching bottom boundary
      if @filled
        ### replace this with:
            A
           / \
         this B
        where this is moved up and B is the space opened by the move 
        ###
        @parent.right = new Node(@parent, @x(), @y(), @w(), @h() + d) # create A
        @parent.right.left = this # make this A's left child
        @parent.right.right = new Node(@parent.right, @x(), @y() + @h(), @w(), d) # create B
        @parent = @parent.right # make A this's new parent
      else # unfilled
        @h(@h() + d) # keep it anchored to the bottom boundary
    # move descendants
    @left?.move_up(d, b)
    @right?.move_up(d, b)    

  extend_right: (d, r) =>
    # extend this node and all its descendants to the right by d
    # only extend a node if its right boundary is at r
    if @x() + @w() is r
      @w(@w() + d)
      @left?.extend_right(d, r)
      @right?.extend_right(d, r)

  extend_down: (d, b) =>
    # extend this node and all its descendants to the down by d
    # only extend a node if its bottom boundary is at b
    if @y() + @h() is b
      @h(@h() + d)
      @left?.extend_down(d, b)
      @right?.extend_down(d, b)

  consume_children: =>
    # consume own children and get consumed by parent if both this and sibling are empty
    # PRECONDITION: left child is unfilled with no children
    @left.div.remove()
    @right.div.remove()
    if @right.left # adopt any grandchildren
      @left = @right.left
      @left.parent = this
      @right = @right.right
      @right.parent = this
    else # delete references to consumed children
      @left = null
      @right = null
    @remove() if @parent and this is @parent.left and not @filled and not @left and not @right # remove if this is an unfilled left child with no children

  remove: =>
    # remove a node from the tree
    window_width = 800  # TODO:
    window_height = 800 # make these globals
    #return this unless @filled # not allowed to remove unfilled nodes
    if @parent
      if this is @parent.left
        sibling = @parent.right
        if @parent.vertical_split
          if sibling.filled # right sibling is filled
            # move filled sibling left by @w() and make it parent's left child
            # give parent a new right child with the space opened up by the move
            sibling.x(sibling.x() - @w())
            @parent.left = sibling
            @parent.right = new Node(@parent, @parent.x() + @parent.w() - @w(), @y(), @w(), @h())
          else # right sibling is unfilled
            # move sibling's subtree left by @w()
            sibling.move_left(@w(), @x()+@parent.w())
            # sibling now has same location and size as parent
            # have parent consume both children
            @parent.consume_children()
        else # horizontal split
          if sibling.filled # bottom sibling is filled
            # move filled sibling up by @h() and make it parent's left child
            # give parent a new right child with the space opened up by the move
            sibling.y(sibling.y() - @h())
            @parent.left = sibling
            @parent.right = new Node(@parent, @x(), @parent.y() + @parent.h() - @h(), @w(), @h())
          else # bottom sibling is unfilled
            # move sibling's subtree up by @h()
            sibling.move_up(@h(), @y()+@parent.h())
            # sibling now has same location and size as parent
            # have parent consume both children
            @parent.consume_children()
      else # this is the right child
        sibling = @parent.left
        if sibling.filled # left sibling is filled
          # leave this right where it is and unfill it
          @filled = false
        else # left sibling is unfilled (it cannot be a leaf)
          if @parent.vertical_split # left sibling is unfilled nonleaf
            # extend sibling's subtree to the right by @w()
            sibling.extend_right(@w(), @x())
          else # top sibling is unfilled nonleaf
            # extend sibling's subtree down by @h()
            sibling.extend_down(@h(), @y())
        # make sure the parent's new children know who their parent is      
      @parent.left?.parent = @parent
      @parent.right?.parent = @parent
    else # this has no parent (so it is the root node and it is exactly filled)
      @filled = false # leave this right where it is and unfill it
    @div.remove() # remove div from dom
    this # return self
        
  insert: (node) =>
    #TODO refactor to use this instead of insert_img

draw_arrow_with_dots = (ctx, fromx, fromy, tox, toy, color="black") ->
  # console.log "drawing arrow from (" + fromx + "," + fromy + ") to (" + tox + "," + toy + ")"
  headlen = 10
  angle = Math.atan2(toy - fromy, tox - fromx)
  ctx.lineWidth = 3
  draw_dot ctx, fromx, fromy
  draw_dot ctx, tox, toy
  ctx.beginPath()
  ctx.strokeStyle = color
  ctx.moveTo fromx, fromy
  ctx.lineTo tox, toy
  ctx.lineTo tox - headlen * Math.cos(angle - Math.PI/6), toy - headlen * Math.sin(angle - Math.PI/6)
  ctx.moveTo tox, toy
  ctx.lineTo tox - headlen * Math.cos(angle + Math.PI/6), toy - headlen * Math.sin(angle + Math.PI/6)
  ctx.stroke()

draw_dot = (ctx, x, y) ->
  radius = 5
  ctx.strokeStyle = "black"
  ctx.fillStyle = "black"
  ctx.beginPath()
  ctx.arc x, y, radius, 0, 2 * Math.PI, false
  ctx.fill()
  ctx.stroke()

draw_one = (root) ->
  unselected = $("#unselected")
  num_images = 371
  im = new Image()
  im.onload = ->
    scale = Math.sqrt(@height * @width / 10000)
    @width /= scale
    @height /= scale

    node = root.insert_img(this)
    if node
      console.log "drawing #{@src} at (#{node.x()},#{node.y()}) to (#{node.x()+node.w()}, #{node.y()+node.h()})"
    else
      console.log @src + " didn't fit - " + @width + " by " + @height

  im.src = "images/" + Math.floor(Math.random() * num_images) + ".png"
  console.log im.src

Object::fits_in = (div) ->
  div.width() >= @width and div.height() >= @height

Object::same_size_as = (div) ->
  div.width() is @width and div.height() is @height

toggle_selected = (div) ->
  return unless div.node.filled
  console.log 'toggle'
  $selected = $("#selected")
  $unselected = $("#unselected")
  $div = $(div)
  if div.selected
    $div.remove()
    div.selected = false
    root.node.insert_img $div.children()[0]
  else
    div.node.remove()
    div.selected = true
    $selected.append(div)

$(document).ready ->
  $unselected = $("#unselected")
  root = new Node(null, 0, 0, 800, 800)
  root.div[0].id = "root"
  $(document).keypress((e) ->
    switch e.which
      when 'h'.charCodeAt(0) then $('#overlay').toggle()
      when 'a'.charCodeAt(0) then draw_one(root)
      else console.log e.which
  )

