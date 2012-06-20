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

var random_color = function()
{
    var color = [0, 0, 0]
    for(var i = 0; i <= 2; i++)
    {
        if(Math.random() < 0.66666)
            color[i] = 32 + parseInt(Math.random() * 192);
    }
    return 'rgb('+color[0]+','+color[1]+','+color[2]+')';
}

var canvas = $('#bin')[0];
var total_area = canvas.width * canvas.height;
var filled_area = 0;
var start_node = new Node();
start_node.rect = new Rect(0, 0, canvas.width, canvas.height);

g_max_rect_size = 25;

var ctx = canvas.getContext('2d');

var timeout_id = null;

var percentfull_el = document.getElementById('percentfull');
var pixelstogo_el = document.getElementById('pixelstogo');

g_delay = 100;

var iteration = function() {
    var color = random_color();

    var rect = new Rect(0, 0, // x/y don't matter here; it has no position yet
        Math.min(Math.floor(1 + Math.random() * g_max_rect_size), g_max_rect_size),
        Math.min(Math.floor(1 + Math.random() * g_max_rect_size), g_max_rect_size));

    var node = start_node.insert_rect(rect);
    if(node)
    {
        var r = node.rect;
        ctx.fillStyle = random_color();
        ctx.fillRect(r.x, r.y, r.w, r.h);
        filled_area += r.w * r.h;
    }
    if(total_area - filled_area)
        setTimeout(iteration, g_delay);
};
setTimeout(iteration, 0);
