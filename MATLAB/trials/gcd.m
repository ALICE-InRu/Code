function val = gcd (x,y)

if (x < 0) 
  val =  gcd(-x,y) 
elseif (x == 0) 
  val = y;
elseif (y < x) 
  val = gcd(y,x) 
else
  val = gcd(mod(x,y), x)
end
