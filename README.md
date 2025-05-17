# Scalable Vector Shapes 2D plugin for Godot 4.4

Scalable Vector Shapes 2D lets you do 2 things:
1. Draw seamless vector shapes using a Path Editor inspired by the awesome [Inkscape](https://inkscape.org/)
2. Import [.svg](https://inkscape.org/) files as seamless vector shapes in stead of as raster images

*__Important sidenote__: _This plugin only supports a small - yet relevant - subset of the huge [SVG Specification](https://www.w3.org/TR/SVG/struct.html)_

## Looking for EZ Curved Lines 2D?
The renamed plugin deprecates the old `DrawablePath2D` custom node in favor of `ScalableVectorShape2D`. A Conversion button is provided.

The reason is that `ScalableVectorShape2D` inherits directly from `Node2D` giving much more control to the plugin over how you can draw.

## Reaching out / Contributing
If you have feedback on this project, feel free to post an [issue](https://github.com/Teaching-myself-Godot/ez-curved-lines-2d/issues) on github, or to:

Contact me on bluesky: [@zucht2.bsky.social](https://bsky.app/profile/zucht2.bsky.social).

If you'd like to improve on the code yourself, ideally use a fork and make a pull request.

This stuff makes me zero money, so you can always branch of in your own direction if you're in a hurry.

# Table of Contents

- [Scalable Vector Shapes 2D plugin for Godot 4.4](#scalable-vector-shapes-2d-plugin-for-godot-44)
	- [Looking for EZ Curved Lines 2D?](#looking-for-ez-curved-lines-2d)
	- [Reaching out / Contributing](#reaching-out--contributing)
- [Table of Contents](#table-of-contents)
- [Drawing Shapes in Godot](#drawing-shapes-in-godot)
- [Using the `.svg` importer](#using-the-svg-importer)
- [Animating](#animating)
	- [Add keyframes in an animation player](#add-keyframes-in-an-animation-player)
	- [Performance impact](#performance-impact)
- [Ye Olde `DrawablePath2D` Examples](#ye-olde-drawablepath2d-examples)
- [Attributions](#attributions)
- [Wishlist / Roadmap](#wishlist--roadmap)
	- [Must have (MVP)](#must-have-mvp)
	- [Should have](#should-have)
	- [Could have](#could-have)
	- [Would be nice (if I learn how to)](#would-be-nice-if-i-learn-how-to)

# Drawing Shapes in Godot

# Using the `.svg` importer

# Animating

You can use the `Update Curve at Runtime` checkbox to enable dynamic changing of your curved shapes at runtime.

![update curve at runtime](./addons/curved_lines_2d/screenshots/update-runtime.png)

## Add keyframes in an animation player

You can then add an `AnimationPlayer` node to your scene, create a new animation and create keyframes for your `Curve > Points` (in the inspector):

![animating](./addons/curved_lines_2d/screenshots/animating.png)


## Performance impact
Animating curve points at runtime does, however, impact performance of your game, because calculating segments is an expensive operation.

Also, the old [OpenGL / Compatibility]() rendering engine seems to perform noticably better for these operations in 2D than the [Vulkan / Forward+]() mode.

Under `Tesselation settings` you can lower `Max Stages` or bump up `Tolerance Degrees` to reduce curve smoothness and increase performance.


# Ye Olde `DrawablePath2D` Examples

Wondering where my beautiful rat, the leopard and butterfly net went?

I felt the installation started to become too cluttered, so I pruned them in this new release. Of course feel free to look them up in the [1.3.0.zip](https://github.com/Teaching-myself-Godot/ez-curved-lines-2d/archive/refs/tags/1.3.0.zip) / [1.3.0 source](https://github.com/Teaching-myself-Godot/ez-curved-lines-2d/tree/1.3.0/addons/curved_lines_2d/examples)


# Attributions

Lot's of thanks go out to those who helped me out getting started:
- This plugin was first inspired by [Mark Hedberg's blog on rendering curves in Godot](https://www.hedberggames.com/blog/rendering-curves-in-godot).
- The suggestion to support both `Polygon2D` and `CollisionPolygon2D` was done by [GeminiSquishGames](https://github.com/GeminiSquishGames), who's pointers inspired me to go further
- The SVG Importer code was adapted from the script hosted on github in the [pixelriot/SVG2Godot](https://github.com/pixelriot/SVG2Godot) repository


# Wishlist / Roadmap

I tend to keep a personal list of checkboxes on the bottom of my readme's to help structure my milestones. Given time, space (and money??) I should start converting this into issues, or a CHANGELOG / RELEASE_NOTES. I guess

## Must have (MVP)

- [x] Rectangle to path converter (incl. rx and ry)
- [x] Circle and ellipse to path converter
- [x] Polygon and polyline to path converter
- [x] Code clean up (Circle2D replaced by path conversion)
- [x] Set node-position to path center (reset and remember node transforms, get center of computed points, set subtract center from curve points, reapply transforms)
- [x] Style support: opacity, stroke-opacity,
- [x] styles from style named attributes (i.e. stroke-width, stroke, etc)
- [x] Style support: paint-order
- [x] Show warnings and hints for unsupported stuff: unhandled nodes, arcs
- [x] Quadratic bezier curves
- [x] Linear Gradient Fill polygons
- [x] Radial Gradient Fill polygons (partial)
- [x] Inherit style from parent node (&lt;g&gt;)
- [x] Import option: collision polygon
- [x] Import option: lock nodes
- [x] Import option: Keep Bezier Curves in DrawablePath2D (hides/shows lock nodes)


## Should have
- [x] Better path attribute string parsing (support leading and trailing whitespace, newlines)
- [x] It should be easier to select ScalableVectorShape2D in the 2D editor window
- [x] Set 'offset' from editor, repositioning path around this new position (hijack the offset-button?)
- [x] Draw a more subtle path in stead of hiding the Path2D
- [x] Draw handles for ScalableVectorShape2D bezier manipulation (like inkscape)
- [x] Make handles interactable with mouse, closed shapes should merge begin- and endpoint (like inkscape does)
- [x] BUG FIXES: missing / empty curve
- [x] Right click removes a (control-) point from the selected shape
- [x] Show a hint on closest point on curve if distance to that point is smaller that N pixels (N=15)
- [x] Determine on which curve segment that point resides
- [x] Double click adds a point to the selected shape's curve at either on-segment hint-point (if present) or mouse position
- [x] Show closed curve start and end index as follows: (0 ∞ N)
- [x] Show gui-hints next to mouse pointer ("double click adds node, hold shift does X, etc")
- [x] Draw unselected curve
- [x] Toggle closed curve on double click
- [x] Drag to change segment curve using quadratic bezier
- [x] Convert DrawablePath2D's to ScalableVectorShape2D's with button
- [x] Update SVG importer settings
- [x] Rename dock to "Scalable Vector Shapes 2D"
- [x] Add a Show/Hide GUI hints toggle in edit dock
- [x] Enable/Disable editing toggle in edit dock
- [x] Create Rect and Ellipse in editor tab in dock
- [x] Ditch old examples
- [ ] Updated manual in README
- [ ] Record new explainers (keep them short this time! let them read the docs, fgs :D)
- [ ] New name for the plugin: Scalable Vector Shapes 2D


## Could have
- [ ] Curve local to scene in edit dock
- [ ] More options in edit tab of dock (fill props/gradient? stroke props?)
- [ ] Import inkscape pivot point to override the centered position with
- [ ] Support Arc operations from `svg` by drawing __lots__ of extra points [see: would be nice](#would-be-nice-if-i-learn-how-to)
- [ ] Apply paint-order to imported CollisionPolygon2D (treat it as a guide)
- [ ] Add button to editor to call center node position func
- [ ] Helper nodes for gradient from-, stop- and to-handles
- [ ] SVG Import log: add button to select node with problem
- [ ] SVG Import log: show/hide different log levels, clear log

## Would be nice (if I learn how to)
- [ ] New icon for ScalableVectorShape2D node
- [ ] Import `<text>` (with embedded fonts? reference to ttf with a dialog?)
- [ ] Arcs to cubic bezier curve conversion
- [ ] Gradient fills for Line2D strokes (would probably require a shader)
- [ ] Fix certain gradient transforms (skew, rotate, fx/fy/fr) [see: chair.svg](./addons/curved_lines_2d/tests/chair.svg)
- [ ] Pattern fills
- [ ] Undo/Redo SVG Import (Undo = delete SvgImport node)
