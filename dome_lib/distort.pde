// all measurements are in inches

class DomeDistort
{
  PShape qsphere;
  PShader distort_shader;
  PImage source;
  PGraphics target;

  // projection values
  float aspect;
  float fov_angle = radians(26); // vertical fov in radians
  float offset = 1.0; // vertical screen offset

  // units are in inches
  float r_radius = 12.5; // reflector radius
  float d_radius = 100.75; // large dome radius

  float r_distance = 22.0; // distance between dome edge and center of reflector
  float p_distance = 33.0; // projector distance from center of reflector

  // reflector subdivision
  int divs = 64;
  
  // color conversion matrices to YIQ (NTSC luma / chroma)
  // courtesy: http://en.wikipedia.org/wiki/YIQ
  final PMatrix3D yiq_from_rgb = new PMatrix3D(
    0.299, 0.596, 0.212, 0,
    0.587, -0.275, -0.528, 0,
    0.114, -0.321, 0.311, 0,
    0, 0, 0, 1
    );
    
  final PMatrix3D rgb_from_yiq = new PMatrix3D(
    1, 1, 1, 0,
    0.956, -0.272, -1.108, 0,
    0.621, -0.647, 1.705, 0,
    0, 0, 0, 1
    );

  DomeDistort(PGraphics ptarget, PImage psource)
  {
    target = ptarget;
    source = psource;

    qsphere = createQSphere(divs, divs);

    aspect = (float)target.width / (float)target.height;
    distort_shader = loadShader("distort_frag.glsl", "distort_vert.glsl");

    // geometry configuration
    distort_shader.set("p_pos", 0, 6.0, -d_radius + r_distance + p_distance);

    distort_shader.set("r_pos", 0.0, 0.0, -d_radius + r_distance);
    distort_shader.set("r_radius", r_radius);

    distort_shader.set("d_radius", d_radius);

    // defaults for texture parameters
    distort_shader.set("t_extent", 0.9);
    distort_shader.set("t_angle", 0.0);
    
    // defaults for color params
    distort_shader.set("c_matrix", new PMatrix3D());
    distort_shader.set("c_distscale", 160.0);
    distort_shader.set("c_scale", 1.0, 1.0, 1.0);
  }

  void offsetPerspective(float znear, float zfar)
  {
    float ymax = znear * (float) Math.tan(fov_angle / 2);
    float ymin = -ymax;
    float xmin = ymin * aspect;
    float xmax = ymax * aspect;

    target.frustum(xmin, xmax, ymin + offset * ymax, ymax + offset * ymax, znear, zfar);
  }

  void setTexExtent(float ext)
  {
    distort_shader.set("t_extent", ext);
  }

  void setTexRotation(float ang)
  {
    distort_shader.set("t_angle", ang);
  }
  
  void setColorDistScale(float distscale)
  {
    distort_shader.set("c_distscale", distscale);
  }
  
  void setColorScale(float rs, float gs, float bs)
  {
    distort_shader.set("c_scale", rs, gs, bs);
  }
  
  void setColorTransform(PMatrix3D mat)
  {
    distort_shader.set("c_matrix", mat, false);
  }
  
  void setColorTransformIdentity()
  {
    setColorTransform(new PMatrix3D());
  }
  
  void setColorTransformInvert(float val)
  {
    setColorTransform(new PMatrix3D(
      1-2*val, 0, 0, 0,
      0, 1-2*val, 0, 0,
      0, 0, 1-2*val, 0,
      val, val, val, 1 ));
  }
  
  void setColorTransformHSVShift(float hue_shift_deg, float sat_scale, float val_scale)
  {
    PMatrix3D c = new PMatrix3D();
    
    // Hue shift matrix = 
    // RGB_from_YIQ * rotateX(hue) * saturation_scale * value_scale * YIQ_from_RGB
    c = yiq_from_rgb.get();
    c.rotateX(radians(hue_shift_deg));
    c.scale(1.0, sat_scale, sat_scale);
    c.scale(val_scale);
    c.apply(rgb_from_yiq);
    setColorTransform(c);
  }

  void update()
  {
    target.beginDraw();
    target.background(0);

    offsetPerspective(target.width * 1, target.width * p_distance);

    target.translate(target.width/2, target.height/2, 0);
    target.scale(target.height);
    target.scale(1.2, 1.0, 1.0);
    target.rotateX(radians(-13.0));
    target.shader(distort_shader);
    target.shape(qsphere);
    target.endDraw();
  }

  PShape createQSphere(int nx, int ny)
  {
    PVector v1 = new PVector(), v2 = new PVector();

    textureMode(NORMAL);
    PShape sh = createShape();
    sh.beginShape(TRIANGLE_STRIP);
    sh.noStroke();
    sh.texture(source);

    float dx = PI / nx, dy = HALF_PI / ny;

    // generate each strip from the center
    float lon = 0.0;
    for (int i = 0; i < nx; i++)
    {
      float lat = 0.0;

      sh.vertex(0, 0, 1);
      for (int j = 0; j < ny; j++)
      {
        v1.set(cos(lon) * sin(lat), sin(lon) * sin(lat), cos(lat));
        v2.set(cos(lon+dx) * sin(lat), sin(lon+dx) * sin(lat), cos(lat));

        sh.vertex(v1.x, v1.y, v1.z);
        sh.vertex(v2.x, v2.y, v2.z);

        lat += dy;
      }

      lon += dx;
    }

    sh.endShape(); 
    return sh;
  }
}

