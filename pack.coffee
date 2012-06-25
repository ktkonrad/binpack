class Node
  constructor: (@parent, x=0, y=0, w=0, h=0) ->
    @left = null
    @right = null
    @filled = false
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

  x: =>
    parseInt(@div.css('left'))
  y: =>
    parseInt(@div.css('top'))
  w: =>
    @div.width()
  h: =>
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
      @left = new Node(this, x, y, img_w, h)
      @right = new Node(this, x + img_w, y, w - img_w, h)
    else
      @left = new Node(this, x, y, w, img_h)
      @right = new Node(this, x, y + img_h, w, h - img_h)
    @show_connections()
    @left.insert_img img


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
  root = new Node(null, 0, 0, $unselected.width(), $unselected.height())
  $(document).keypress((e) ->
    switch e.which
      when 'h'.charCodeAt(0) then $('#overlay').toggle()
      when 'a'.charCodeAt(0) then draw_one(root)
      else console.log e.which
  )

