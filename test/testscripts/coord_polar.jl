using Gadfly
set_default_plot_size(12cm, 10cm)

var1 = [:a,:b,:c,:d,:e,:a]
var2 = [1,2,1,1,1,3]
var3 = [1.0,1.0,1.0,0.3,1.0,0.5]

plot(x = var1, y = var3, color = var2, Geom.point, Coord.polar())

var4 = [0,pi/4,pi/4,3*pi/4,5*pi/4,6*pi/4]

plot(x = var4, y = var3, color = var2, Geom.point, Coord.polar())

var5 = rand(20)*2*π
var6 = rand(20)
var7 = rand(20)

plot(x = var5, y = var6, color = var7, Geom.point, Coord.polar())
plot(x = var5, y = var6, color = var7, Geom.point)
