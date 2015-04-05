// all measurements are in inches

class DomeDistort
{
  PShape qsphere;
  PShader distort_shader;
  PImage source;
  PGraphics target;
  
  // projection values
  float aspect;
  float fov_angle = radians(25.0); // vertical fov in radians
  float offset = 1.1; // vertical screen offset
  
  // units are in inches
  float r_radius = 13.0; // reflector radius
  float d_radius = 100.75; // large dome radius
  float p_distance = 26.0; // projector distance from center of reflector

  // reflector subdivision
  int divs = 64;
  
  DomeDistort(PGraphics ptarget, PImage psource)
  {
    target = ptarget;
    source = psource;
    
    qsphere = createQSphere(divs, divs);
    
    aspect = (float)target.width / (float)target.height;
    distort_shader = loadShader("distort_frag.glsl", "distort_vert.glsl");
    
    // geometry configuration
    distort_shader.set("p_pos", 0, 0, -d_radius + p_distance);
    
    distort_shader.set("r_pos", 0.0, 0.0, -d_radius);
    distort_shader.set("r_radius", r_radius);
    
    distort_shader.set("d_radius", d_radius);
    
    // reasonable defaults for these parameters
    distort_shader.set("t_extent", 0.9);
    distort_shader.set("t_angle", 0.0);
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
  
  void update()
  {
    target.beginDraw();
    target.background(0);
    
    offsetPerspective(target.width * 1, target.width * p_distance);

    target.translate(target.width/2, target.height/2, 0);
    target.scale(target.height);
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
