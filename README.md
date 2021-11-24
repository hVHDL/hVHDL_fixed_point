# math_library
library of high level synthesizable mathematical functions for example multiplication, division and sin/cos functionalities
The modules are delivered as packages that contain the record definition. The modules only require the multiplier_pkg and the <module>_pkg.vhd. The units are created by instantiating the <module>_record type signal and corresponding create_<module> procedure.
All of the modules are tested with cyclone 10lp fpga.

I have also written blog posts on the design of the arithmetic modules.

Multiplier :

https://hardwaredescriptions.com/math-be-fruitful-and-multiply/

division : 

https://hardwaredescriptions.com/conquer-the-divide/

Sine and cosine :

https://hardwaredescriptions.com/category/vhdl-integer-arithmetic/sine-and-cosine/

I am currently changing the math_library to use vunit and ghdl.
