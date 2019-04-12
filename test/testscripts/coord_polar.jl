using Gadfly
set_default_plot_size(10cm, 10cm)

var1 = [:a,:b,:c,:d,:e,:a]
var2 = [1,2,1,1,1,3]
var3 = [1.0,1.0,1.0,0.3,1.0,0.5]

plot(x = var1, y = var3, color = var2, Geom.point, Coord.polar())
