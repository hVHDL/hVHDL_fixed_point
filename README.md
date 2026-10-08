# math_library
library of high level synthesizable mathematical functions for example multiplication, division and sin/cos functionalities
The modules are delivered as packages that contain the record definition. The modules only require the multiplier_pkg and the <module>_pkg.vhd. The units are created by instantiating the <module>_record type signal and corresponding create_<module> procedure.
All of the modules are tested with intel cyclone 10lp, efinix titanium and xilinx artix 7 fpgas
  
The modules are simulated using ghdl and vunit

## Layout

The root has the math functions built around fixed_dsp, a multiply-add unit with optional pre-add and product registers. The sine, reciprocal and square root calculators, lut_divider and full_range_sqrt share one fixed_dsp, and new math functions are developed on it. vunit_run.py runs their tests.

legacy/ has the older sources, kept as they are and not developed further:
- legacy/vhdl2008 : the generic package multiplier, division and pi controller, and the adc scaler, with their own vunit_run.py
- legacy/vhdl1993 : the record and procedure based modules, with vunit_run_obsolete.py and ghdl_compile_math_library.bat

real_to_fixed stays in the root, both sets of tests use it.

I have also written blog posts on the design of the arithmetic modules.

Multiplier :

https://hardwaredescriptions.com/math-be-fruitful-and-multiply/

division : 

https://hardwaredescriptions.com/conquer-the-divide/

Sine and cosine :

https://hardwaredescriptions.com/category/vhdl-integer-arithmetic/sine-and-cosine/

Square root :

https://www.embeddedrelated.com/showarticle/1558.php
