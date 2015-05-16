/* dome_lib code by Christian Miller */

import themidibus.*;
import gifAnimation.*;
import java.io.File;

// nanoKontrol 1
final int DIAL1 = 14;
final int DIAL2 = 15;
final int DIAL3 = 16;
final int DIAL4 = 17;
final int DIAL5 = 18;
final int DIAL6 = 19;
final int DIAL7 = 20;
final int DIAL8 = 21;
final int SLIDER1 = 2;
final int SLIDER2 = 3;
final int SLIDER3 = 4;
final int SLIDER4 = 5;
final int SLIDER5 = 6;
final int SLIDER6 = 8;
final int SLIDER7 = 9;
final int SLIDER8 = 12;
final int REWIND = 47;
final int FASTFORWARD = 48;
final int RESET = 49;

// nanoKontrol 2
/*final int DIAL1 = 16;
final int DIAL2 = 17;
final int DIAL3 = 18;
final int DIAL4 = 19;
final int DIAL5 = 20;
final int DIAL6 = 21;
final int DIAL7 = 22;
final int DIAL8 = 23;
final int SLIDER1 = 0;
final int SLIDER2 = 1;
final int SLIDER3 = 2;
final int SLIDER4 = 3;
final int SLIDER5 = 4;
final int SLIDER6 = 5;
final int SLIDER7 = 6;
final int SLIDER8 = 7;
final int REWIND = 43;
final int FASTFORWARD = 44;
final int RESET = 46;*/

// dome distortion
PGraphics src, targ;
DomeDistort dome;

// animation & playback
ArrayList<String> anims = new ArrayList<String>();
PImage[] anim_frames;
int cur_anim = -1;
int cur_frame = 0;
float cur_floatframe = 0.0; // higher-resolution frame number, truncated to get cur_frame
float cur_framerate = 30.0; // can be fractional or negative

// MIDI control
MidiBus kontrol;

// mode flags
boolean line_mode = false;

// color params
float hue_shift_deg = 0.0;
float sat_scale = 1.0;
float val_scale = 1.0;
float invert = 0.0;

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
  File dir = new File(dataPath(""));
  for (String filename : dir.list()) {
    if (filename.endsWith(".gif")) {
      anims.add(filename);
    }
  }
  nextAnim(1);
  
  // configure nanokontrol, if it exists
  MidiBus.list();
  kontrol = new MidiBus(this, "SLIDER/KNOB", "CTRL");
}

void nextAnim(int num)
{
  cur_anim += num;
  if (cur_anim < 0)
    cur_anim += anims.size();
  else if (cur_anim >= anims.size())
    cur_anim -= anims.size();
    
  println("Loaded animation: " + anims.get(cur_anim));
  anim_frames = Gif.getPImages(this, anims.get(cur_anim));
  cur_frame = 0;
  cur_floatframe = 0.0;
}

void keyPressed()
{
  if (key == '\\')
  {
    targ.save("screenshot.png");
    return;
  }
  if (key == 'l') {
    line_mode = !line_mode;
    return;
  }
  if (key == 'r') {
    cur_framerate = 30.0;
    dome_angvel = 0.0;
    hue_shift_deg = 0.0;
    sat_scale = 1.0;
    val_scale = 1.0;
    dome_coverage = 0.9;
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
    case DIAL1:
      cur_framerate = lerp(-60.0, 60.0, fval);
      println("Framerate: "+cur_framerate+" fps");
      break;
    case DIAL2:
      if (value >= 61 && value <= 67)
        dome_angvel = 0.0;
      else
        dome_angvel = lerp(-0.2, 0.2, fval);
        
      println("Dome rotation: "+degrees(dome_angvel)+" deg/s");
      break;
    case DIAL3:
      hue_shift_deg = lerp(0.0, 360.0, fval);
      println("Hue shift: "+hue_shift_deg+" deg");
      break;
    case DIAL4:
      sat_scale = 2.0*fval;
      println("Saturation scale: "+sat_scale);
      break;
    case DIAL5:
      val_scale = 2.0*fval;
      println("Value scale: "+val_scale);
      break;
    case DIAL6:
      invert = fval;
      println("Invert: "+invert);
      break;
    case DIAL7:
      dome_coverage = lerp(0.01, 1.0, fval);
      println("Radial dome coverage: "+dome_coverage);
      break;
    case REWIND:
      if (value > 0)
        nextAnim(-1);
      break;
    case FASTFORWARD:
      if (value > 0)
        nextAnim(1);
      break;
    case RESET:
      if (value > 0)
      {
        cur_framerate = 30.0;
        dome_angvel = 0.0;
        hue_shift_deg = 0.0;
        sat_scale = 1.0;
        val_scale = 1.0;
        invert = 0.0;
        dome_coverage = 0.9;
      }
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
  if (cur_floatframe >= (float)anim_frames.length)
    cur_floatframe -= (float)anim_frames.length;
  else if (cur_floatframe < 0.0)
    cur_floatframe += (float)anim_frames.length;
  cur_frame = (int)cur_floatframe;
  
  // update color transform
  dome.setColorTransformHSVShiftInvert(hue_shift_deg, sat_scale, val_scale, invert);
  
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
  }
  else
    image(targ, 0, 0);
}


