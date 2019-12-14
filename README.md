# Geometric specular anti-aliasing, color noise dithering and specular lightmap occlusion shader
This is a standard lit custom shader for unity that includes the following improvments over standard shader:

- Color Noise Dithering
- Geometric Specular Anti-Aliasing
- Specular Lightmap Occlusion*

It expands on this with a custom shader editor that controls shader feature activation based on provided textures to optimize the runtime performance.

## Note
SLO will only work on lightmapped objects

# Origin note
This is a performance optimized Unity package version basing on the Valve GSAA + dither implementation by Xiexe & TCL under MIT at
https://github.com/Xiexe/PBR_Standard_Dithered_GSAA_SLO