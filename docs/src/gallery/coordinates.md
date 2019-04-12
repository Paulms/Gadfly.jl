# Coordinates

## [`Coord.cartesian`](@ref)

```@example
using Gadfly
set_default_plot_size(14cm, 8cm)
plot(sin, 0, 20, Coord.cartesian(xmin=2π, xmax=4π, ymin=-2, ymax=2))
```

## [`Coord.polar`](@ref)

```@example
using Gadfly
set_default_plot_size(14cm, 8cm)
plot(x = π/6*collect(0:11), y = 1/12*collect(1:12), Geom.point, Coord.polar())
```
