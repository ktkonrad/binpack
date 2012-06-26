class Node
  constructor: (@parent, x=0, y=0, w=0, h=0) ->
    @left = null
    @right = null
    @filled = false
    @vertical_split = false

    # create a div and put it in the dom
    @div = $(document.createElement('div'))
    @div[0].selected = false
    @div.addClass('logo')
    @div[0].onclick = ->
      toggle_selected this
    @div.css('left', x)
    @div.css('top', y)
    @div.width(w)
    @div.height(h)
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

  move_left: (d) =>
    # move this node and all its descendants left by d
    @x(@x()-d)
    @left?.move_left(d)
    @right?.move_left(d)    

  move_up: (d) =>
    # move this node and all its descendants left by d
    @y(@y()-d)
    @left?.move_up(d)
    @right?.move_up(d)    

  replace: (node) =>
    # replace this with node
    # don't move children
    node.parent = @parent
    if this is @parent?.left
      @parent.left = node
    else
      @parent?.right = node
    node.left = @left
    @left?.parent = node
    node.right = @right
    @right?.parent = node
    # move subtrees
    if @vertical_split
      @left?.move_left(@w())
    else
      @left?.move_up(@h())

  graft: (node) =>
    # replace this with subtree anchored at node
    node.parent = @parent
    if this is @parent?.left
      @parent.left = node
    else
      @parent?.right = node
    # move subtrees
    if @vertical_split
      @left?.move_left(@w())
    else
      @left?.move_up(@h())
    

  remove: =>
    if @left.filled
      if @right.filled
        # TODO this case sucks
      else
        left = @left.remove() # remove left child and save it for later
        @remove().insert(left) # now remove this (without left child) and insert the old left child back into the tree
    else
      left = @left.remove() # left child is unfilled so it must be a leaf
      if @right.filled
        @graft(@right) # graft right child to here
      else 
        # become unfilled and consume both children
        @filled = false
        @w(if @vertical_split then @left.w()+@right.w() else @right.w())
        @h(if @vertical_split @right.h() else @left.h()+@right.h())
        @left = null
        @right = null
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
  console.log 'toggle'
  $selected = $("#selected")
  $unselected = $("#unselected")
  $div = $(div)
  if div.selected
    $div.remove()
    $unselected.append $div
    div.selected = false
  else
    $div.remove()
    $selected.append $div
    div.selected = true

$(document).ready ->
  $unselected = $("#unselected")
  root = new Node(null, 0, 0, 800, 800)
  $(document).keypress((e) ->
    switch e.which
      when 'h'.charCodeAt(0) then $('#overlay').toggle()
      when 'a'.charCodeAt(0) then draw_one(root)
      else console.log e.which
  )

