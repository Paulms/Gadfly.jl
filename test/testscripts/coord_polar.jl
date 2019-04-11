using Gadfly
set_default_plot_size(21cm, 8cm)

var1 = [:a,:b,:c,:d,:e,:a]
var2 = [1,1,1,1,1,2]
var3 = [2.6,3.7,5.7,9.1,2.0,9.0]

plot(x = var1, y = var3, color = var2, Geom.point, Coord.polar())
