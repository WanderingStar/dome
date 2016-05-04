import themidibus.*;

// 0 = nanoKontrol 1
// 1 = nanoKontrol 2
// 2 = X-touch midi

public class Controller implements MidiListener
{
  public MidiBus kontrol;

  public Controller() {
  }

  // raw midi handler
  public void rawMidi(byte[] data)
  {
    // debugging for raw data bytes
    /*StringBuilder sb = new StringBuilder();
     for (byte b : data) {
     sb.append(String.format("%02X ", b));
     }
     println("Raw: " + sb.toString());*/

    // parse pitch bend messages (since themidibus doesn't do this for us!?)
    if ((data[0] & 0xF0) == 0xE0)
    {
      int channel = data[0] & 0x0F;
      int bend = ((data[2] & 0x7F) << 7) | (data[1] & 0x7f);
      pitchBend(channel, bend);
    }
  }

  public void noteOn(int channel, int pitch, int velocity)
  {
    println("Note On: "+channel+", "+pitch+": "+velocity );
  }

  public void noteOff(int channel, int pitch, int velocity)
  {
    println("Note Off: "+channel+", "+pitch+": "+velocity );
  }

  public void controllerChange(int channel, int number, int value)
  {
    println("Controller Change: "+channel+", "+number+": "+value );
  }

  public void pitchBend(int channel, int bend)
  {
    println("Pitch bend: "+channel+", "+bend );
  }

  public void refresh() {
  }
}

public class NanoKontrol1 extends Controller
{
  final int DIAL1 = 14;
  final int DIAL2 = 15;
  final int DIAL3 = 16;
  final int DIAL4 = 17;
  final int DIAL5 = 18;
  final int DIAL6 = 19;
  final int DIAL7 = 20;
  final int DIAL8 = 21;
  final int DIAL9 = 22;
  final int BUTTON1H = 23;
  final int BUTTON1L = 33;
  final int BUTTON2H = 24;
  final int BUTTON2L = 34;
  final int BUTTON3H = 25;
  final int BUTTON3L = 35;
  final int BUTTON4H = 26;
  final int BUTTON4L = 36;
  final int BUTTON5H = 27;
  final int BUTTON5L = 37;
  final int BUTTON6H = 28;
  final int BUTTON6L = 38;
  final int BUTTON7H = 29;
  final int BUTTON7L = 39;
  final int BUTTON8H = 30;
  final int BUTTON8L = 40;
  final int BUTTON9H = 31;
  final int BUTTON9L = 41;
  final int SLIDER1 = 2;
  final int SLIDER2 = 3;
  final int SLIDER3 = 4;
  final int SLIDER4 = 5;
  final int SLIDER5 = 6;
  final int SLIDER6 = 8;
  final int SLIDER7 = 9;
  final int SLIDER8 = 12;
  final int SLIDER9 = 13;
  final int RECORD = 44;
  final int PLAY = 45;
  final int STOP = 46;
  final int REWIND = 47;
  final int FASTFORWARD = 48;
  final int RESET = 49;
  final int BUTTON1HSCENE2 = 67;
  final int BUTTON9HSCENE2 = 75;
  final int BUTTON1LSCENE2 = 76;
  final int BUTTON9LSCENE2 = 84;

  public NanoKontrol1()
  {
    kontrol = new MidiBus(this, "SLIDER/KNOB", "CTRL");
  }

  public void controllerChange(int channel, int number, int value) 
  {
    float fval = (float)value/127.0;

    // all number are in scene 1
    switch (number) {
    case DIAL1:
    case SLIDER1:
      cur_framerate = lerp(-60.0, 60.0, fval);
      println("Framerate: "+cur_framerate+" fps");
      break;
    case DIAL2:
    case SLIDER2:
      if (value >= 61 && value <= 67)
        dome_angvel = 0.0;
      else
        dome_angvel = lerp(-6.28, 6.28, fval);

      println("Dome rotation: "+degrees(dome_angvel)+" deg/s");
      break;
    case DIAL3:
    case SLIDER3:
      hue_shift_deg = lerp(0.0, 360.0, fval);
      println("Hue shift: "+hue_shift_deg+" deg");
      break;
    case DIAL4:
    case SLIDER4:
      sat_scale = 2.0*fval;
      println("Saturation scale: "+sat_scale);
      break;
    case DIAL5:
    case SLIDER5:
      val_scale = 2.0*fval;
      println("Value scale: "+val_scale);
      break;
    case DIAL6:
    case SLIDER6:
      invert = value < 64 ? 0 : 1;
      println("Invert: "+invert);
      break;
    case DIAL7:
    case SLIDER7:
      dome_coverage = lerp(0.01, 1.0, fval);
      println("Radial dome coverage: "+dome_coverage);
      break;
    case DIAL8:
    case SLIDER8:
      dome_rotation = lerp(0.01, 6.28, fval);
      println("Rotation: "+dome_rotation);
      break;
    case DIAL9:
    case SLIDER9:
      refresh = (int) lerp(10, 300, fval);
      println("Refresh rate: "+refresh);
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
        resetDefaults();
      }
      break;
    case STOP:
      if (value > 0)
      {
        moveFile("Trash");
        nextAnim(0);
      }
      break;
    default:
      break;
    }
  }
}

public class NanoKontrol2 extends Controller
{
  final int DIAL1 = 16;
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
  final int BUTTON1S = 32;
  final int BUTTON1M = 48;
  final int BUTTON1R = 64;
  final int BUTTON2S = 33;
  final int BUTTON2M = 49;
  final int BUTTON2R = 65;
  final int BUTTON3S = 34;
  final int BUTTON3M = 50;
  final int BUTTON3R = 66;
  final int BUTTON4S = 35;
  final int BUTTON4M = 51;
  final int BUTTON4R = 67;
  final int BUTTON5S = 36;
  final int BUTTON5M = 52;
  final int BUTTON5R = 68;
  final int BUTTON6S = 37;
  final int BUTTON6M = 53;
  final int BUTTON6R = 69;
  final int BUTTON7S = 38;
  final int BUTTON7M = 54;
  final int BUTTON7R = 70;
  final int BUTTON8S = 39;
  final int BUTTON8M = 55;
  final int BUTTON8R = 71;
  final int STOP = 42;
  final int REWIND = 43;
  final int FASTFORWARD = 44;
  final int RECORD = 45;
  final int RESET = 46;

  final int DIAL9 = -1;
  final int SLIDER9 = -2;

  public NanoKontrol2()
  {
    kontrol = new MidiBus(this, "SLIDER/KNOB", "CTRL");
  }

  public void controllerChange(int channel, int number, int value)
  {
    float fval = (float)value/127.0;

    // all number are in scene 1
    switch (number) {
    case DIAL1:
    case SLIDER1:
      cur_framerate = lerp(-60.0, 60.0, fval);
      println("Framerate: "+cur_framerate+" fps");
      break;
    case DIAL2:
    case SLIDER2:
      if (value >= 61 && value <= 67)
        dome_angvel = 0.0;
      else
        dome_angvel = lerp(-6.28, 6.28, fval);

      println("Dome rotation: "+degrees(dome_angvel)+" deg/s");
      break;
    case DIAL3:
    case SLIDER3:
      hue_shift_deg = lerp(0.0, 360.0, fval);
      println("Hue shift: "+hue_shift_deg+" deg");
      break;
    case DIAL4:
    case SLIDER4:
      sat_scale = 2.0*fval;
      println("Saturation scale: "+sat_scale);
      break;
    case DIAL5:
    case SLIDER5:
      val_scale = 2.0*fval;
      println("Value scale: "+val_scale);
      break;
    case DIAL6:
    case SLIDER6:
      invert = value < 64 ? 0 : 1;
      println("Invert: "+invert);
      break;
    case DIAL7:
    case SLIDER7:
      dome_coverage = lerp(0.01, 1.0, fval);
      println("Radial dome coverage: "+dome_coverage);
      break;
    case DIAL8:
    case SLIDER8:
      dome_rotation = lerp(0.01, 6.28, fval);
      println("Rotation: "+dome_rotation);
      break;
    case DIAL9:
    case SLIDER9:
      refresh = (int) lerp(10, 300, fval);
      println("Refresh rate: "+refresh);
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
        resetDefaults();
      }
      break;
    case STOP:
      if (value > 0)
      {
        moveFile("Trash");
        nextAnim(0);
      }
      break;
    default:
      break;
    }
  }
}

// Behringer XTouch MIDI controller in MC MODE
public class XTouchMidi extends Controller
{
  // X-touch midi
  final int DIAL1 = 16;
  final int DIAL2 = 17;
  final int DIAL3 = 18;
  final int DIAL4 = 19;
  final int DIAL5 = 20;
  final int DIAL6 = 21;
  final int DIAL7 = 22;
  final int DIAL8 = 23;
  final int BUTTONDIAL1 = 32;
  final int BUTTONDIAL2 = 33;
  final int BUTTONDIAL3 = 34;
  final int BUTTONDIAL4 = 35;
  final int BUTTONDIAL5 = 36;
  final int BUTTONDIAL6 = 37;
  final int BUTTONDIAL7 = 38;
  final int BUTTONDIAL8 = 39;
  final int BUTTON1H = 89;
  final int BUTTON1L = 87;
  final int BUTTON2H = 90;
  final int BUTTON2L = 88;
  final int BUTTON3H = 40;
  final int BUTTON3L = 91;
  final int BUTTON4H = 41;
  final int BUTTON4L = 92;
  final int BUTTON5H = 42;
  final int BUTTON5L = 86;
  final int BUTTON6H = 43;
  final int BUTTON6L = 93;
  final int BUTTON7H = 44;
  final int BUTTON7L = 94;
  final int BUTTON8H = 45;
  final int BUTTON8L = 95;
  final int BUTTONA = 84;
  final int BUTTONB = 85;

  // dial led fill modes
  // MODE_SINGLE : individual lights
  // MODE_PAN    : fill from center
  // MODE_FAN    : fill from left
  // MODE_SPREAD : fill symmetrically
  final int MODE_SINGLE = 0;
  final int MODE_PAN    = 1;
  final int MODE_FAN    = 2;
  final int MODE_SPREAD = 3;

  // int val must be in the range [0, 11] inclusive, 0 means off
  void setDialLedsRaw(int dial, int mode, int val) {
    kontrol.sendControllerChange(0, 0x30+dial-DIAL1, (mode << 4) | val);
  }

  // float val must be 0-1, and will get mapped automatically to the correct integer value
  void setDialLeds(int dial, int mode, float val) {
    setDialLedsRaw(dial, mode, (int)lerp(1.0, 12.0 - 1e-5, val));
  }

  void setButtonLed(int button, boolean on) {
    kontrol.sendNoteOn(0, button, on ? 127 : 0);
  }

  public XTouchMidi() {
    kontrol = new MidiBus(this, "X-TOUCH MINI", "X-TOUCH MINI");
    kontrol.sendControllerChange(0, 127, 1); // ensure MC mode (CC 127 = 1)
    refreshDials();
  }

  public void refreshDials() {
    setDialLeds(DIAL1, MODE_PAN, map(cur_framerate, -60, 60, 0, 1));
    setDialLeds(DIAL2, MODE_PAN, map(dome_angvel, -2.0*PI, 2.0*PI, 0, 1));
    setDialLeds(DIAL3, MODE_SINGLE, map((hue_shift_deg+180.0)%360.0, 0.0, 360.0, 0, 1));
    setDialLeds(DIAL4, MODE_PAN, map(sat_scale, 0, 2, 0, 1));
    setDialLeds(DIAL5, MODE_PAN, map(val_scale, 0, 2, 0, 1));
    setDialLedsRaw(DIAL6, MODE_SINGLE, (invert > 0.0) ? 10 : 2);
    setDialLeds(DIAL7, MODE_FAN, dome_coverage);
    setDialLeds(DIAL8, MODE_SINGLE, map(dome_rotation, 0.0, 2.0*PI, 0, 1));
  }

  public void controllerChange(int channel, int number, int value) {
    super.controllerChange(channel, number, value);

    // handle the weird encoding of negative control knob values
    if (value > 64)
      value = -(value - 64);

    float fval = (float)value/127.0;

    // all number are in scene 1
    switch (number) {
    case DIAL1:
      cur_framerate = constrain(cur_framerate + value, -60.0, 60.0);
      println("Framerate: "+cur_framerate+" fps");
      break;
    case DIAL2:
      dome_angvel = constrain(dome_angvel + value * 2.0*PI / 40.0, -2.0*PI, 2.0*PI);
      println("Dome rotation: "+degrees(dome_angvel)+" deg/s");
      break;
    case DIAL3:
      hue_shift_deg = hue_shift_deg + value * 360.0 / 40.0;
      if (hue_shift_deg < 0.0)
        hue_shift_deg += 360.0;
      else if (hue_shift_deg > 360.0)
        hue_shift_deg -= 360.0;
      println("Hue shift: "+hue_shift_deg+" deg");
      break;
    case DIAL4:
      sat_scale = constrain(sat_scale + value * 2.0 / 40.0, 0.0, 2.0);
      println("Saturation scale: "+sat_scale);
      break;
    case DIAL5:
      val_scale = constrain(val_scale + value * 2.0 / 40.0, 0.0, 2.0);
      println("Value scale: "+val_scale);
      break;
    case DIAL6:
      invert = value < 0 ? 0 : 1;
      println("Invert: "+invert);
      break;
    case DIAL7:
      dome_coverage = constrain(dome_coverage + value * 1.0 / 40.0, 0.01, 1.0);
      println("Radial dome coverage: "+dome_coverage);
      break;
    case DIAL8:
      dome_rotation = dome_rotation + value * 2.0*PI / 60.0;
      if (dome_rotation < 0.0)
        dome_rotation += 2.0*PI;
      else if (dome_rotation > 2.0*PI)
        dome_rotation -= 2.0*PI;
      println("Rotation: "+dome_rotation);
      break;
    default:
      break;
    }
    refreshDials();
  }

  public void noteOn(int channel, int pitch, int velocity)
  {
    super.noteOn(channel, pitch, velocity);

    if (velocity > 0) {
      switch (pitch) {
      case BUTTONB:
      case BUTTON3L:
        nextAnim(-1);
        break;
      case BUTTONA:
      case BUTTON4L:
        nextAnim(1);
        break;
      case BUTTONDIAL1:
        cur_framerate = DEFAULT_CUR_FRAMERATE;
        break;
      case BUTTONDIAL2:
        dome_angvel = DEFAULT_DOME_ANGVEL;
        break;
      case BUTTONDIAL3:
        hue_shift_deg = DEFAULT_HUE_SHIFT_DEG;
        break;
      case BUTTONDIAL4:
        sat_scale = DEFAULT_SAT_SCALE;
        break;
      case BUTTONDIAL5:
        val_scale = DEFAULT_VAL_SCALE;
        break;
      case BUTTONDIAL6:
        invert = DEFAULT_INVERT;
        break;
      case BUTTONDIAL7:
        dome_coverage = DEFAULT_DOME_COVERAGE;
        break;
      case BUTTONDIAL8:
        dome_rotation = 0.0;
        break;
      default:
        break;
      }
    }
    refreshDials();
  }

  public void pitchBend(int channel, int bend)
  {
    super.pitchBend(channel, bend);
  }

  public void refresh() {
    refreshDials();
  }
}

