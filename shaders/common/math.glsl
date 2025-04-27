float luma(vec3 color) {
   return dot(vec3(0.299, 0.587, 0.114), color);
}

float rescale(float x, float a, float b) {
   return clamp((x - a) / (b - a), 0.0, 1.0);
}

vec3 rescale(vec3 x, vec3 a, vec3 b) {
   return clamp((x - a) / (b - a), vec3(0.0), vec3(1.0));
}

float squaredLength(vec3 v) {
   return dot(v, v);
}

float bandify(float value, float bands) {
   return floor(bands*value) / (bands - 1.0);
}

vec3 nvec3(vec4 pos) {
   return pos.xyz / pos.w;
}

vec3 contrast(vec3 color, float contrast) {
   return contrast * (color.rgb - 0.5) + 0.5;
}

float invpow2(float x) {
   return 1.0 - x*x;
}

float smoothe(float x) {
   return x*x*(3.0 - 2.0*x);
}

float pow2(float x) {
   return x*x;
}

float pow3(float x) {
   return x*x*x;
}