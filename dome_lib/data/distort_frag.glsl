#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform sampler2D texture; // texture sampler itself

uniform mat4 c_matrix; // color transformation matrix

varying vec2 vertTexCoord;
varying vec3 vertColor;

void main()
{
  // clamp texture lookups to a circle
  vec2 tmp = vertTexCoord - vec2(0.5, 0.5);
  if (tmp.s * tmp.s + tmp.t * tmp.t > 0.5 * 0.5)
    gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
  else
  {
	vec3 tex_sample = texture2D(texture, vertTexCoord.st).rgb;
    gl_FragColor = (c_matrix * vec4(tex_sample, 1.0)) * vec4(vertColor, 1.0);
  }
}

