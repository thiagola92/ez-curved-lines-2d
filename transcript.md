# Transcript Basic Shapes

In this explainer we look at how to draw shapes with Scalable Vector Shapes 2D.

## 1
So, let's Activate the plugin using the project settings.

And draw this blue heart emoji.

## 2
To add a new ScalableVectorShape2D we just use Ctrl+A, or the context menu in the 2D viewport.

## 3
Using double click we place the first 2 points at any place we want

But any new point after that needs to be places _on_ our new shape.

## 4
We close the loop of our shape by double clicking on the end-point.

And double clicking on the end-point again breaks the loop back up.

## 5
We use right click to delete handles and points


## 6
We use Godot's Line2D as a stroke for our shape..

..and Polygon2D for the fill

## 7
We pick colors, Gradients and Textures using Godot's builtin properties; working _with_ the again is always better finding working-arounds.

## 8
A closed line in our shape is _not_ the same as a closed Line2D.

We use the closed property of Line2D for that


## Speed up ...


## 9
Use the second tab in the bottom panel to create a rectangle, rounded rectangle, circle and ellipse.

They will always be expressed mathematically expressed as Cubic Bézier Curves, as per Godot's Curve2D implementation


## Speed up ...


## 10
By using Godot's node system for drawing the shapes, we get full control of the details.

That way, we do not depend at all on the plugin for anything else than make the act of drawing and animating 2D curves easier.

Like using z-order to bring this stroke to the front.

## Thanks for watching

# Transcript Importing SVG Files

Scalable Vector Shapes 2D ships an importer for SVG files (scalable vector graphics).

The W3C spec for SVG is quite big, so only a small subset of features is supported.

Small, yet relevant, especially when it comes to curved lines and polygons.


## 1

Let's look at the import settings for a moment.

## 2

The importer gives us the option to import shapes as is, _without_ the extra drawing features of the ScalableVectorShape2D node (demonstrated in the video about drawing basic shapes).

In stead, a plain Node2D will wrap around the Godot native Polygon2D for the fill and a Line2D for the stroke

## 3

Choosing to import as ScalableVectorShape2D, it's a good idea to set an editor lock on the imported nodes.

This way their points and transforms cannot be manipulated directly, making it easier to use the ScalableVectorShape for that.

## 4

The antialiased property of Line2D and Polygon2D is flagged here.

We can also choose to import collision polygons. By default only for fills, optionally also for shapes built up of only strokes.

## 5
Just drag in an svg file anywhere into the dock to start the import process.

And the import log is filled with warnings and messages.

_including_ this helpful link to report issues.

## 6
Gradients are imported as a GradientTexture2D resource on the Polygon2D. Radial gradients are also supported.

This is however not perfectly implemented. For more details  with the importer, watch the video titled "Known Issues with the SVG Importer"

## 7
Aside from animating and manipulating shapes more easily, one more feature of the Scalable Vector Shapes plugin deserves attention: Infinite zoom

## 8
By default, svg shapes are converted and imported as a static raster image.

## 9
Although the lack of resolution / blurriness of our little rat can be overcome using mipmapping and a greater scale in the resource import tab..

..just look at the memory profile of the resulting texture.

Having a 3000 by 2000 pixels big rat, consuming 35 megabytes of video memory, caused Mobile Webkit browsers to refuse to render some resources altogether.

## Thanks for watching

# Transcript known issues with SVG Import

I love the Scalable Vector Shapes plugin; especially the SVG import.

That being said, we have to face some issues with it.

One reason is the size of the W3C spec for SVG.

Other reasons are simply time, effort and lack of mathematical skill on my part.


## 1
Let's start with the 2 most glaring omissions by importing the test-file names arc.svg

Godot's svg import implementation itself can handle arcs just fine.

Although it also omits the text elements without warning

## 2

The Scalable Vector Shapes plugin just makes them look silly :D

We have to admit its import log tries to be as transparent as possible about it.

## 3
Which is why it always rounds up with a hyperlink to the github issue page

## 4
The chair example shows a problem with certain transforms on gradients.

Like converting arcs to bezier curves, some gradient transforms proved too much for my lacking mathematics.

## 5
Luckily, this one's easily remedied manually using the fill_rotation property on the Texture2D class


## 6
Other issues are _bound_ to pop up.

I haven't even _tried_ to implement clipping, for fear of spending 2 weeks of trying to figure it out before shipping.

## Thanks for watching

# Animating

There are of course a lot of ways to go about animating, but what I used to do was quite cumbersome:

1. Draw concept art in Inkscape
2. Split up in 20-30 svg files containing various strokes and fills
3. Painstakingly import them as rasters, scale, pivot and align them all

Before even starting to work on key frame animations. Some things were still impossible because I could not animate the shape of my images.

## 1
Here we unlock the last shape we imported in one go via de Scalable Vector Shapes 2D importer dock.

...And place it over my original rasterized paw file (paw_fill.svg)

## 2
We can now change the type of the Paw_fill node from a Sprite2D to a plain Node2D.

The reason is that I want to keep the key frames on its rotation and translation properties.

## 3
The same rat has the same animation, but now with infinite zoom

## 4
One more thing to highight, just in case: this plugin used to ship a custom node called DrawablePath2D.

This button changes the type of the rat's tail to the new ScalableVectorShape2D.

## Speed up

Here I mess around with the Line2D representing the stroke. to get it to draw behind the rat's body.

As you can see, the Line's shape is still controlled by the ScalableVectorShape2D, even though it is not its direct child.
This works, because it is still assigned to its polygon property

## 5 (skip to animating-b)
The tail's shape is animated by assigning key frames in the animation player to its points and control points.

Before I had to do this using a sprite sheet, making it a lot less smooth.


# 6

You can find the rat scene under the examples folder of this addon.

## Thanks for watching!