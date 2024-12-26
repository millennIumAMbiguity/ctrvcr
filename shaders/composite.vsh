#version 130

varying vec2 texcoord_vs;

void main() {
    texcoord_vs = gl_MultiTexCoord0.xy;

    gl_Position = ftransform();
}