using Gadfly
set_default_plot_size(20cm, 10cm)

var1 = [:a,:b,:c,:d,:e,:a]
var2 = [1,2,1,1,1,3]
var3 = [2.0,1.5,1.0,0.5,1.0,1.8]
var4 = [0,pi/4,pi/2,3*pi/4,5*pi/4,6*pi/4]

p1 = plot(x = var1, y = var3, color = var2, Geom.point, Coord.polar())
p2 = plot(x = var4, y = var3, color = var2, Geom.point, Coord.polar(ymin=0.2))
hstack(p1, p2)
