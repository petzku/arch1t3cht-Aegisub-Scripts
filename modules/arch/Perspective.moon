haveDepCtrl, DependencyControl, depctrl = pcall require, 'l0.DependencyControl'

local amath

if haveDepCtrl
    depctrl = DependencyControl {
        name: "Perspective",
        version: "0.2.3",
        description: [[Math functions for dealing with perspective transformations.]],
        author: "arch1t3cht",
        url: "https://github.com/TypesettingTools/arch1t3cht-Aegisub-Scripts",
        moduleName: 'arch.Perspective',
        {
            {"arch.Math", version: "0.1.8", url: "https://github.com/TypesettingTools/arch1t3cht-Aegisub-Scripts",
            feed: "https://raw.githubusercontent.com/TypesettingTools/arch1t3cht-Aegisub-Scripts/main/DependencyControl.json"},
        }
    }

    amath = depctrl\requireModules!
else
    amath = require"arch.Math"

{:Point, :Matrix} = amath

-- compatibility with Lua >= 5.2
unpack = unpack or table.unpack


local Quad

-- Quadrilateral (usually in 2D space) described by its four corners, in clockwise or counter-clockwise direction.
-- Internally, we always use numbering that's counter-clockwise in the cartesian plane, which is clockwise on a 2D screen.
class Quad extends Matrix
    new: (...) =>
        super(...)
        assert(@height == 4)

    -- Computes the intersection point of the diagonals.
    -- Doubles as a generic function to intersect to lines in 2D space.
    midpoint: =>
        la = Matrix(@[3] - @[1], @[4] - @[2])\transpose!\preim(@[4] - @[1])
        return @[1] + la[1] * (@[3] - @[1])


    --------------------
    -- Collection of functions describing the perspective transformation between this quad and a 1x1 square.
    -- These were originally computed from cross-ratios and run through Mathematica to combine all the fractions,
    -- which makes it work in such "edge" cases as two sides of the quad being parallel.
    -- They were then dumped from Mathematica in InputForm and inserted here without much postprocessing,
    -- except for sometimes putting common denominators in an extra variable
    --------------------

    -- Helper functions to wrap code dumped from Mathematica
    -- returns x1, x2, x3, x4, y1, y2, y3, y4
    unwrap: => @[1][1], @[2][1], @[3][1], @[4][1], @[1][2], @[2][2], @[3][2], @[4][2]

    -- translates x1, y1 to 0, 0 and returns x2, x3, x4, y2, y3, y4
    unwrap_rel: =>
        @ = @ - @[1]
        return @[2][1], @[3][1], @[4][1], @[2][2], @[3][2], @[4][2]


    -- Perspective transform mapping the quad to a unit square
    xy_to_uv: (xy) =>
        assert(@width == 2)
        x2, x3, x4, y2, y3, y4 = @unwrap_rel!
        x, y = unpack(xy - @[1])

        u = -(((x3*y2 - x2*y3)*(x4*y - x*y4)*(x4*(-y2 + y3) + x3*(y2 - y4) + x2*(-y3 + y4)))/(x3^2*(x4*y2^2*(-y + y4) + y4*(x*y2*(y2 - y4) + x2*(y - y2)*y4)) + x3*(x4^2*y2^2*(y - y3) + 2*x4*(x2*y*y3*(y2 - y4) + x*y2*(-y2 + y3)*y4) + x2*y4*(x2*(-y + y3)*y4 + 2*x*y2*(-y3 + y4))) + y3*(x*x4^2*y2*(y2 - y3) + x2*x4^2*(y2*y3 + y*(-2*y2 + y3)) - x2^2*(x4*y*(y3 - 2*y4) + x4*y3*y4 + x*y4*(-y3 + y4)))))
        v = ((x2*y - x*y2)*(x4*y3 - x3*y4)*(x4*(y2 - y3) + x2*(y3 - y4) + x3*(-y2 + y4)))/(x3*(x4^2*y2^2*(-y + y3) + x2*y4*(2*x*y2*(y3 - y4) + x2*(y - y3)*y4) - 2*x4*(x2*y*y3*(y2 - y4) + x*y2*(-y2 + y3)*y4)) + x3^2*(x4*y2^2*(y - y4) + y4*(x2*(-y + y2)*y4 + x*y2*(-y2 + y4))) + y3*(x*x4^2*y2*(-y2 + y3) + x2*x4^2*(2*y*y2 - y*y3 - y2*y3) + x2^2*(x4*y*(y3 - 2*y4) + x4*y3*y4 + x*y4*(-y3 + y4))))

        return Point(u, v)

    -- Perspective transform mapping a unit square to the quad
    uv_to_xy: (uv) =>
        assert(@width == 2)
        x2, x3, x4, y2, y3, y4 = @unwrap_rel!
        u, v = unpack(uv)

        d = (x4*((-1 + u + v)*y2 + y3 - v*y3) + x3*(y2 - u*y2 + (-1 + v)*y4) + x2*((-1 + u)*y3 - (-1 + u + v)*y4))
        x = (v*x4*(x3*y2 - x2*y3) + u*x2*(x4*y3 - x3*y4)) / d
        y = (v*y4*(x3*y2 - x2*y3) + u*y2*(x4*y3 - x3*y4)) / d

        return Point(x, y) + @[1]

    -- Derivative (i.e. Jacobian) of uv_to_xy at the given point
    d_uv_to_xy: (uv) =>
        assert(@width == 2)
        x2, x3, x4, y2, y3, y4 = @unwrap_rel!
        u, v = unpack(uv)

        d = (x4*((-1 + u + v)*y2 + y3 - v*y3) + x3*(y2 - u*y2 + (-1 + v)*y4) + x2*((-1 + u)*y3 - (-1 + u + v)*y4))^2

        dxdu = (x2*(x4*y3 - x3*y4)*(x4*((-1 + u + v)*y2 + y3 - v*y3) + x3*(y2 - u*y2 + (-1 + v)*y4) + x2*((-1 + u)*y3 - (-1 + u + v)*y4)) + (x3*y2 - x4*y2 + x2*(-y3 + y4))*(v*x4*(x3*y2 - x2*y3) + u*x2*(x4*y3 - x3*y4))) / d
        dxdv = (x4*(x3*y2 - x2*y3)*(x4*((-1 + u + v)*y2 + y3 - v*y3) + x3*(y2 - u*y2 + (-1 + v)*y4) + x2*((-1 + u)*y3 - (-1 + u + v)*y4)) - (x4*(y2 - y3) + (-x2 + x3)*y4)*(v*x4*(x3*y2 - x2*y3) + u*x2*(x4*y3 - x3*y4))) / d
        dydu = ((-1 + v)*x3^2*y2*(y2 - y4)*y4 + y3*((-1 + v)*x4^2*y2*(y2 - y3) + v*x2^2*(y3 - y4)*y4 + x2*x4*y2*(-y3 + y4)) + x3*y2*(2*(-1 + v)*x4*y3*y4 - (-1 + 2*v)*x2*(y3 - y4)*y4 + x4*y2*(y3 + y4 - 2*v*y4))) / d
        dydv = ((x3*y2 - x2*y3)*y4*(-(x4*y2) - x2*y3 + x4*y3 + x3*(y2 - y4) + x2*y4) + u*(x4^2*y2*y3*(-y2 + y3) + 2*x3*x4*y2*(y2 - y3)*y4 + y4*(2*x2*x3*y2*(y3 - y4) + x3^2*y2*(-y2 + y4) + x2^2*y3*(-y3 + y4)))) / d

        return Matrix({{dxdu, dxdv}, {dydu, dydv}})

    -- Derivative (i.e. Jacobian) of xy_to_uv at the given point
    d_xy_to_uv: (xy) =>
        assert(@width == 2)
        x2, x3, x4, y2, y3, y4 = @unwrap_rel!
        x, y = unpack(xy)

        d = (x3*(x4^2*y2^2*(-y + y3) + x2*y4*(2*x*y2*(y3 - y4) + x2*(y - y3)*y4) - 2*x4*(x2*y*y3*(y2 - y4) + x*y2*(-y2 + y3)*y4)) + x3^2*(x4*y2^2*(y - y4) + y4*(x2*(-y + y2)*y4 + x*y2*(-y2 + y4))) + y3*(x*x4^2*y2*(-y2 + y3) + x2*x4^2*(2*y*y2 - y*y3 - y2*y3) + x2^2*(x4*y*(y3 - 2*y4) + x4*y3*y4 + x*y4*(-y3 + y4))))^2

        dudx = ((x3*y2 - x2*y3)*(x4*y2 - x2*y4)*(x4*y3 - x3*y4)*(x4*y*(y2 - y3) + x3*(y - y2)*y4 + x2*(-y + y3)*y4)*(x4*(-y2 + y3) + x3*(y2 - y4) + x2*(-y3 + y4))) / d
        dvdx = -((x3*y2 - x2*y3)*(x4*y2 - x2*y4)*(x4*y3 - x3*y4)*(-(x3*x4*y2) + x*x4*(y2 - y3) + x2*x4*y3 + x*(-x2 + x3)*y4)*(x4*(-y2 + y3) + x3*(y2 - y4) + x2*(-y3 + y4))) / d
        dudy = ((x3*y2 - x2*y3)*(x4*y2 - x2*y4)*(x4*y3 - x3*y4)*(x4*y2*(y - y3) + x2*y*(y3 - y4) + x3*y2*(-y + y4))*(x4*(y2 - y3) + x2*(y3 - y4) + x3*(-y2 + y4))) / d
        dvdy = ((x3*y2 - x2*y3)*(x4*y2 - x2*y4)*(-(x4*y3) + x3*y4)*(x4*(-y2 + y3) + x3*(y2 - y4) + x2*(-y3 + y4))*(x*(x3*y2 - x4*y2 - x2*y3 + x2*y4) + x2*(x4*y3 - x3*y4))) / d

        return Matrix({{dudx, dudy}, {dvdx, dvdy}})

screen_z = 312.5

an_xshift = { 0, 0.5, 1, 0, 0.5, 1, 0, 0.5, 1 }
an_yshift = { 1, 1, 1, 0.5, 0.5, 0.5, 0, 0, 0 }

-- Transforms the given list of points in a relative coordinate system according to the given .ass tags.
-- If no list of points is given, a rectangle with the given dimensions is used.
-- The width and height parameters should contain the raw dimensions of the line to be transformed. These are used for alignment.
-- Thus, when transforming a shape with \an7, width and height can be zero. When transforming text, they should be whatever aegisub.text_extents returned.
-- The table t is supposed to be a table of tags as returned by ASSFoundation, but any table with the same keys and .value or .x/.y
-- fields for the respective tags works.
transformPoints = (t, width, height, points=nil) ->
    if points == nil
        points = Quad {
            {0, 0},
            {width, 0},
            {width, height},
            {0, height},
        }
    else
        points = Matrix(points)

    pos = Point(t.position.x, t.position.y)
    org = Point(t.origin.x, t.origin.y)

    -- Shearing
    points *= Matrix({
        {1, t.shear_x.value},
        {t.shear_y.value, 1},
    })\t!

    -- Translate to alignment point
    an = t.align.value
    points -= Point(width * an_xshift[an], height * an_yshift[an])

    -- Apply scaling
    points *= (Matrix.diag(t.scale_x.value, t.scale_y.value) / 100)

    -- Translate relative to origin
    points += pos - org

    -- Rotate ZXY
    points ..= 0
    points *= Matrix.rot2d(math.rad(-t.angle.value))\onSubspace(3)\t!
    points *= Matrix.rot2d(math.rad(-t.angle_x.value))\onSubspace(1)\t!
    points *= Matrix.rot2d(math.rad(t.angle_y.value))\onSubspace(2)\t!

    -- Project
    points = Matrix [ (screen_z / (p\z! + screen_z)) * p\project(2) for p in *points ]

    -- Move to origin
    points += org
    return points


-- Given a quad on screen and the width and height of the text, returns in t (again an ASSFoundation tags table)
-- the tag values that will transform this text to the given quad.
-- If center = true, the center of the quad will be used as \org. If not, the \org set in t will be used.
tagsFromQuad = (t, quad, width, height, center=false) ->
    quad = Quad(quad) if quad.__class != Quad
    if center
        center = quad\midpoint!
        t.origin.x = center\x!
        t.origin.y = center\y!

    -- Normalize to center
    org = Point(t.origin.x, t.origin.y)
    quad -= org

    -- Find a parallelogram projecting to the quad
    z24 = Matrix({ quad[2] - quad[3], quad[4] - quad[3] })\t!\preim(quad[1] - quad[3])
    zs = Point(1, z24[1], z24\sum! - 1, z24[2])
    quad ..= screen_z
    quad = Matrix.diag(zs) * quad

    -- Normalize so the origin has z=screen_z
    orgla = Matrix({Point(0, 0, screen_z), quad[1] - quad[2], quad[1] - quad[4]})\t!\preim(quad[1])
    quad /= orgla[1]

    quad -= Matrix[{0, 0, screen_z} for i=1,4]

    -- Find the rotations
    n = (quad[2] - quad[1])\cross(quad[4] - quad[1])
    roty = math.atan2(n\x!, n\z!)
    roty += math.pi if n\z! < 0
    ry = Matrix.rot2d(roty)\onSubspace(2)
    n = Point(ry * n)
    rotx = math.atan2(n\y!, n\z!)
    rx = Matrix.rot2d(rotx)\onSubspace(1)

    quad *= ry\t!
    quad *= rx\t!

    ab = quad[2] - quad[1]
    rotz = math.atan2(ab\y!, ab\x!)
    rotz += math.pi if ab\x! < 0
    rz = Matrix.rot2d(-rotz)\onSubspace(3)

    quad *= rz\t!

    -- We now have a horizontal parallelogram in the 2D plane, so find the shear and the dimensions
    ab = quad[2] - quad[1]
    ad = quad[4] - quad[1]
    rawfax = ad\x! / ad\y!

    quadwidth = ab\length!
    quadheight = math.abs(ad\y!)
    scalex = quadwidth / width
    scaley = quadheight / height

    -- Find \pos
    an = t.align.value
    pos = org + (quad[1]\project(2) + Point(quadwidth * an_xshift[an], quadheight * an_yshift[an]))

    -- Set all the new tags
    t.position.x = pos\x!
    t.position.y = pos\y!
    t.angle.value = math.deg(-rotz)
    t.angle_x.value = math.deg(rotx)
    t.angle_y.value = math.deg(-roty)
    t.scale_x.value = 100 * scalex
    t.scale_y.value = 100 * scaley
    t.shear_x.value = rawfax * scaley / scalex
    t.shear_y.value = 0


lib = {
    :Quad,
    :transformPoints,
    :tagsFromQuad,
}

if haveDepCtrl
    lib.version = depctrl
    return depctrl\register lib
else
    return lib
