# math_library
library of high level synthesizable mathematical functions for example multiplication, division and sin/cos functionalities
The modules are delivered as packages that contain the record definition. The modules only require the multiplier_pkg and the <module>_pkg.vhd. The units are created by instantiating the <module>_record type signal and corresponding create_<module> procedure.
All of the modules are tested with intel cyclone 10lp, efinix titanium and xilinx artix 7 fpgas
  
The modules are simulated using ghdl and vunit

I have also written blog posts on the design of the arithmetic modules.

Multiplier :

https://hardwaredescriptions.com/math-be-fruitful-and-multiply/

division : 

https://hardwaredescriptions.com/conquer-the-divide/

Sine and cosine :

https://hardwaredescriptions.com/category/vhdl-integer-arithmetic/sine-and-cosine/

Square root :

https://www.embeddedrelated.com/showarticle/1558.php
