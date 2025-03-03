float Random_float(vec2 Seed)
{
	return fract(sin(dot(Seed,vec2(12.9898,78.233)))*43758.5453123);
}

float Random_float_t(vec2 Seed, float t)
{
	return fract(sin(dot(Seed,vec2(12.9898,78.233) * t)) * 43758.5453123);
}

// more consistent random function
float hash(vec2 p, float time) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y + time);
}
