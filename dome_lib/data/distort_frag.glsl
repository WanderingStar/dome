#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform sampler2D texture; // texture sampler itself

varying vec2 vertTexCoord;
varying vec3 vertColor;

void main()
{
  // frag shader is a simple passthrough

  // clamp texture lookups to a circle
  vec2 tmp = vertTexCoord - vec2(0.5, 0.5);
  if (tmp.s * tmp.s + tmp.t * tmp.t > 0.5 * 0.5)
    gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
  else
    gl_FragColor = texture2D(texture, vertTexCoord.st) * vec4(vertColor, 1.0);
}

