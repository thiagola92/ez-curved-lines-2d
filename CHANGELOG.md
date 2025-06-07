# Changelog


## 2.4.3 - 2025-06-07

### Changed
- Fixed a preloading + busy device bug in inspector plugin load script

## 2.4.2 - 2025-06-05

### Added
- Batch insert key frame button for entire curve
- Batch insert key frame button for entire gradient
- Key frame button for stroke width
- Key frame button for fill stroke color
- Key frame button for fill color

### Changed
- Fixes ordering bug of gradient stop color buttons
- Reconnects import svg button to file dialog in svg importer panel

## 2.3.2 - 2025-05-31

### Added
- Adds gradient fill toggle to the inspector form
- Adds gradient stop color buttons to the inspector form
- Adds gradient start- and end handle to 2D editor
- Adds stop color handles to 2D editor
- Implements paint-order correctly in SVG importer
- Better tooltips for SVG importer
- Warning message for unsupported clipping (using 'm'- / 'M'-operator) in SVG importer

### Changed
- Bugfix: resizes the gradient texture when the bounding box changes
- Regression fix: all the SVG importer settings in the SVG importer form work again

## 2.2.1 - 2025-05-28

### Added
- Adds easier to use forms for Stroke, Fill and Collision shape to the `ScalableVectorShape2D` inspector
- Adds project settings for defaults like stroke width, stroke and fill colors, and paint order
- Separates the point numbers from the hint labels
- Saves project settings for enabling and disabling hints and viewport editing
- Shows a preview of the shape which is about to be added via the bottom panel
- Explanatory tooltips for all the fields and options that are not self-explanatory enough


## 2.1.3 - 2025-05-24

### Added
- Undo/Redo for strokes (`Line2D`) fills (`Polygon2D`) and collisions (`CollisionPolygon2D`) added with the `Generate` button in the inspector
- After Undo of creating a new shape from the bottom panel, its parent node is automatically selected again
- Resize a shape without using the `scale` property using `Shift+mousewheel`, for more pixel perfect alignment


### Changed
- Fix: after adding point on line with double click, the correct point is removed again with undo
- Fix: when a curve is closed, it stroke (the `Line2D` assigned to the `line`-property) is also closed and vice-versa
- Fix: closing a shape now works by simply adding a segement between the last and first point

## 2.1.0 - 2025-05-21

### Added
- Use `Ctrl+click` to add points to a shape faster
- Undo/Redo support for shapes from the bottom panel

### Changed
- Shapes from the bottom panel are added as child of the selected node
- When no node is selected, shapes from the bottom panel are added in the center of the viewport
- Batched Undo/Redo for all mouse drag operations
- Tooltip and ability to copy link with right click on `LinkButton` to external content


## 2.0.0 - 2025-05-19

### Added

- Custom node `ScalableVectorShape2D` introduced, enabling editing of its `Curve2D` using the mouse similar to the popular open source vector drawing program [Inkscape](https://inkscape.org/)
- Add a circle, ellipse or rectangle from the bottom panel directly
- Ability to Undo/Redo many drawing operations
- A more comprehensive manual in the [README](./README.md)

### Changed

- The custom node `DrawablePath2D` was deprecated in favor of `ScalableVectorShape2D`


## 1.3.0 - 2025-05-10

_Last stable release of EZ Curved Lines 2D_

This shipped 2 things:

- An SVG file importer, which transforms shapes into native Godot nodes
- The custom node `DrawablePath2D`, which extends from Godot's `Path2D` to use its built-in `Curve2D` editor