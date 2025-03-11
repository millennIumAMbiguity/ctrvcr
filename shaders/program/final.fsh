uniform sampler2D colortex0;

varying vec4 color;
varying vec2 coord0;

void main()
{
    gl_FragData[0] = color * texture2D(colortex0,coord0);
}