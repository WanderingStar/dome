import themidibus.*;
import gifAnimation.*;
import java.io.File;

// dome distortion
PGraphics src, targ;
DomeDistort dome;

// animation & playback
//ArrayList<String> anims = new ArrayList<String>();
ProjectApiClient client = new ProjectApiClient("http://localhost:5000");
PImage[] anim_frames;
int cur_anim = 0;
int cur_frame = 0;
float cur_floatframe = 0.0; // higher-resolution frame number, truncated to get cur_frame
float cur_framerate = 30.0; // can be fractional or negative
int reps = 0;
long started;

// MIDI control
MidiBus kontrol;

// mode flags
boolean invert = false; 
boolean line_mode = false;

// color params
float hue_shift_deg = 0.0;
float sat_scale = 1.0;
float val_scale = 1.0;

// dome mapping params
float dome_rotation = 0.0; // current rotation of dome (radians)
float dome_angvel = 0.0; // rotation speed of dome, in rad / s
float dome_coverage = 0.9; // radial extent of dome covered by texture

void setup()
{
  //size(1024, 1024, P3D);
  //size(1920, 1080, P3D);
  size(1280, 720, P3D);
  //size(854, 480, P3D);
  //size(960, 540, P3D);

  frameRate(60); // framerate at 60 by default, we advance frames at a different rate

  // set up source buffer for the actual frame data
  src = createGraphics(1024, 1024, P3D);

  // set up target buffer to render into
  targ = createGraphics(width, height, P3D);

  // create and configure the distortion object
  dome = new DomeDistort(targ, src);
  dome.setTexExtent(0.9); // set to < 1.0 to shrink towards center of dome
  dome.setTexRotation(0); // set to desired rotation angle in radians

  println(dataPath(""));

  // make list of animations
  client.addDirectory(dataPath("content"));
  loadAnimation();

  // configure nanokontrol, if it exists
  MidiBus.list();
  kontrol = new MidiBus(this, "SLIDER/KNOB", "CTRL");
}

void loadAnimation()
{
  String filename = client.getCurrentFilename();
  println("Loading animation: " + filename);
  anim_frames = Gif.getPImages(this, filename);
  cur_frame = 0;
  cur_floatframe = 0.0;
  reps = 0;
  started = System.currentTimeMillis() / 1000;
  client.addToHistory(started, 0, 0);
}

void nextAnim(int num)
{
  long stopped = System.currentTimeMillis() / 1000;
  println(started);
  println(stopped);
  client.addToHistory(started, stopped, reps);
  if (num < 0) {
    client.prev();
  } else {
    client.next();
  }
  loadAnimation();
}

void keyPressed()
{
  if (key == '\\')
  {
    targ.save("screenshot.png");
    return;
  }
  if (key == 'i') {
    invert = !invert;
    dome.setColorTransformInvert(invert ? 1 : 0);
    return;
  }
  if (key == 'l') {
    line_mode = !line_mode;
    return;
  }
  if (key == CODED && keyCode == LEFT) {
    nextAnim(-1);
    return;
  }
  if (key == CODED && keyCode == RIGHT) {
    nextAnim(1);
    return;
  }

  // fall through to move to the next animation
  nextAnim(1);
}

// midi input callback
void controllerChange(int channel, int number, int value) {
  println("Controller Change: "+channel+", "+number+": "+value );

  float fval = (float)value/127.0;

  // all number are in scene 1
  switch (number) {
  case 14: // dial 1
    cur_framerate = lerp(-60.0, 60.0, fval);
    println("Framerate: "+cur_framerate+" fps");
    break;
  case 15: // dial 2
    if (value >= 63 && value <= 65)
      dome_angvel = 0.0;
    else
      dome_angvel = lerp(-1.0, 1.0, fval);
    println("Dome rotation: "+degrees(dome_angvel)+" deg/s");
    break;
  case 16: // dial 3
    hue_shift_deg = lerp(0.0, 360.0, fval);
    println("Hue shift: "+hue_shift_deg+" deg");
    break;
  case 17: // dial 4
    sat_scale = 2.0*fval;
    println("Saturation scale: "+sat_scale);
    break;
  case 18: // dial 5
    val_scale = 2.0*fval;
    println("Value scale: "+val_scale);
    break;
  case 19: // dial 6
    dome_coverage = lerp(0.01, 1.0, fval);
    println("Radial dome coverage: "+dome_coverage);
    break;
  case 47: // rewind
    if (value > 0)
      nextAnim(-1);
    break;
  case 48: // fast forward
    if (value > 0)
      nextAnim(1);
    break;
  default:
    break;
  }
}

// stretches an image over the entire target canvas
void drawFullscreenQuad(PGraphics t, PImage i)
{
  t.beginShape();
  t.texture(i);
  t.vertex(0, 0, 0, 0);
  t.vertex(t.width, 0, i.width, 0);
  t.vertex(t.width, t.height, i.width, i.height);
  t.vertex(0, t.height, 0, i.height);
  t.endShape();
}

void draw()
{
  // draw pattern into source texture
  // also, blend together adjacent frames (looks better at slow speeds)
  src.beginDraw();
  src.background(0);
  int next_frame = (cur_frame == anim_frames.length-1) ? 0 : cur_frame+1;
  float partial = cur_floatframe - (float)cur_frame;
  src.tint(255, 255);
  drawFullscreenQuad(src, anim_frames[cur_frame]);
  src.tint(255, 255 * partial);
  drawFullscreenQuad(src, anim_frames[next_frame]);
  src.endDraw();

  // update animation
  cur_floatframe += cur_framerate / 60.0;
  if (cur_floatframe >= (float)anim_frames.length) {
    cur_floatframe -= (float)anim_frames.length;
    reps++;
  } else if (cur_floatframe < 0.0) {
    cur_floatframe += (float)anim_frames.length;
    reps++;
  }
  cur_frame = (int)cur_floatframe;

  // update color transform
  dome.setColorTransformHSVShift(hue_shift_deg, sat_scale, val_scale);

  // update texture params
  dome_rotation += dome_angvel / 60.0;
  dome.setTexRotation(dome_rotation);
  dome.setTexExtent(dome_coverage);

  // distort into target image
  dome.update();

  // draw distorted image to screen
  background(0);

  // override image if we're in line mode
  if (line_mode)
  {
    stroke(255);
    line(width/2, 0, width/2, height);
  } else
    image(targ, 0, 0);
}

