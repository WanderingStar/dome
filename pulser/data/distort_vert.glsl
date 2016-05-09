#define PROCESSING_TEXTURE_SHADER

// stuff automatically provided by Processing
uniform mat4 transform;
uniform mat4 texMatrix;

attribute vec4 vertex;
attribute vec4 color;
attribute vec2 texCoord;

varying vec2 vertTexCoord;
varying vec3 vertColor;

// projector info
uniform vec3 p_pos; // center of projection position

// reflector info
uniform vec3 r_pos; // position of center of reflector
uniform float r_radius; // radius of reflector

// dome info
uniform float d_radius; // radius of dome

// color modifications
uniform float c_distscale; // scales brightness based on max distance

// texture modifications
uniform float t_angle; // rotates the texture around the dome
uniform float t_extent; // how far down the dome the texture goes (0 - 1)

float ray_sphere_intersect_far(in vec3 o, in vec3 d, in float r)
{
	// intersect the ray o + t*d with the origin-centered sphere ||x|| = r, return t_far
	// assume d is a normalized vector, so dot(d, d) = 1

	float b, c, disc, t;

	b = dot(o, d);
	c = dot(o, o) - r * r;
	disc = b * b - c;

	t = -b + sqrt(disc);

	return t;
}

void main()
{
	// world position of reflector vertex
	vec3 wpos = r_pos + r_radius * vertex.xyz;

	// compute projector-relative vertex position
	vec3 prpos = wpos - p_pos;

	// emit vertex
	gl_Position = transform * vec4(prpos.x, -prpos.y, prpos.z, 1.0); // negate y component cause of Processing's frickin' inverted vertical...
	//vertColor = color.xyz;

	// compute the warp

	// initial ray origin and direction
	vec3 o = wpos;
	vec3 d = wpos - p_pos;
	float dtravel = length(d);
	d /= dtravel;
	//d = normalize(d);
	
	// bounce direction off reflector (assumes unit radius sphere)
	d = reflect(d, vertex.xyz);

	float t;

	// intersect with dome
	t = ray_sphere_intersect_far(o, d, d_radius);
	o += t * d;
	o /= d_radius;

	dtravel += t;
	float color_scale = clamp(dtravel/c_distscale, 0.0, 1.0);
	vertColor = vec3(color_scale);

	// compute texcoords
	vec2 txc = o.xz;

	// rotation
	float st = sin(t_angle), ct = cos(t_angle);
	txc = mat2(ct, st, -st, ct) * txc;

	//txc = 0.5 * t_extent * txc + 0.5; // planar projection

	// spherical projection
	float ell = length(o.xz);
	float phi = asin(ell);
	txc = txc * phi / ell / (2.0 * 1.5707963267949 * t_extent) + 0.5;

	vertTexCoord = txc;
}

