function Rect(x, y, w, h)
{
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
}

Rect.prototype.fits_in = function(outer)
{
    return outer.w >= this.w && outer.h >= this.h;
}

Rect.prototype.same_size_as = function(other)
{
    return this.w == other.w && this.h == other.h;
}

function Node()
{
    this.left = null;
    this.right = null;
    this.rect = null;
    this.filled = false;
}

Node.prototype.insert_rect = function(rect)
{
    if(this.left != null)
        return this.left.insert_rect(rect) || this.right.insert_rect(rect);

    if(this.filled)
        return null;

    if(!rect.fits_in(this.rect))
        return null;

    if(rect.same_size_as(this.rect))
    {
        this.filled = true;
        return this;
    }

    this.left = new Node();
    this.right = new Node();

    var width_diff = this.rect.w - rect.w;
    var height_diff = this.rect.h - rect.h;

    var me = this.rect;

    if(width_diff > height_diff)
    {
        // split literally into left and right, putting the rect on the left.
        this.left.rect = new Rect(me.x, me.y, rect.w, me.h);
        this.right.rect = new Rect(me.x + rect.w, me.y, me.w - rect.w, me.h);
    }
    else
    {
        // split into top and bottom, putting rect on top.
        this.left.rect = new Rect(me.x, me.y, me.w, rect.h);
        this.right.rect = new Rect(me.x, me.y + rect.h, me.w, me.h - rect.h);
    }

    return this.left.insert_rect(rect);
}

var random_choice = function(n, m){
    // choose a random subset of n integer from [0, m)
    // not optimally efficient
    var arr = [];
    for(var i = 0; i < m; i++) arr.push(i);
    for(var j, x, i = m; i; j = parseInt(Math.random() * i), x = arr[--i], arr[i] = arr[j], arr[j] = x);
    return arr.slice(0,n);
};

$(document).ready(function() {
    var logos = $('#bin');
    var start_node = new Node();
    start_node.rect = new Rect(0, 0, logos.width(), logos.height());

    var num_images = 371;
    var num_to_display = 40;
    var images_to_display = random_choice(num_to_display, num_images);
    var images = [];

    for(var i = 0 ; i < num_to_display ; i++) {
        images[i] = new Image();
        images[i].onload = function() {
            var scale = this.height / 60; // scale to height 60px
            this.width /= scale;
            this.height /= scale;
            this.onclick = function() {this.style.display="none"};
            var rect = new Rect(0, 0, this.width, this.height);
            node = start_node.insert_rect(rect);
            if(node) {
                var r = node.rect;
                console.log('drawing ' + this.src + ' at (' + r.x + ',' + r.y + ')' + ' to (' + (r.x + this.width) + ',' + (r.y + this.height) + ')' );
                this.style = 'left:' + r.x + '; top: ' + r.y;
                logos.append(this);
            }
            else {
                console.log(this.src + " didn't fit - " + this.width + ' by ' + this.height);
            }
        };
        images[i].src = 'images/' + images_to_display[i] + '.png';
        console.log(images[i].src);
    }
});