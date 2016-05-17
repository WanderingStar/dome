import themidibus.*;

// 0 = nanoKontrol 1
// 1 = nanoKontrol 2
// 2 = X-touch midi

public class Controller implements MidiListener
{
  public MidiBus kontrol;
  public HashMap<String, Float> config;

  public Controller(HashMap<String, Float> config) {
    this.config = config;
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

  public void sendControllerChange(int channel, int number, int value) {
    kontrol.sendControllerChange(channel, number, value);
  }

  public void refresh() {
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

  final int REWIND = 43;
  final int FASTFORWARD = 44;
  final int STOP = 42;
  final int PLAY = 41;
  final int RECORD = 45;
  
  final int CYCLE = 46;

  final int MARKER_SET = 60;
  final int MARKER_LEFT = 61;
  final int MARKER_RIGHT = 62;

  final int DIAL9 = -1;
  final int SLIDER9 = -2;

  int[] sliders = { 0, 0, 0, 0, 0, 0, 0, 0 };
  int[] dials = { 127, 127, 127, 127, 127, 127, 127, 127 };

  int lastChange = 0;
  int repeatStart = 0;

  public NanoKontrol2(HashMap<String, Float> config)
  {
    super(config);
    kontrol = new MidiBus(this, "SLIDER/KNOB", "CTRL");
  }

  public void controllerChange(int channel, int number, int value)
  {
    super.controllerChange(channel, number, value);
    if (number <= SLIDER8) {
      int index = number;
      sliders[index] = value;
      return;
    } else if (number <= DIAL8) {
      int index = number - DIAL1;
      dials[index] = value;
      return;
    }
    switch (number) {
    case CYCLE:
      if (value == 0) {
        int elapsed = millis() - repeatStart;
        println("repeat: " + elapsed);
        config.put(REPEAT, (float) elapsed);
        start = millis();
      } else {
        repeatStart = millis();
      }
      break;
    case REWIND:
      if (pulses.size() > 0) {
        pulses.remove(pulses.size() - 1);
      }
      break;
    case STOP:
      pulses = new ArrayList<Pulse>();
      break;
    default:
      if (value == 0) {
        return;
      }
      // debounce
      if (millis() - lastChange < 100) {
        return;
      }
      lastChange = millis();

      Pulse p;
      switch (number % 16) {
        case 1:
          p = new Polygon(3);
          break;
        case 2:
          p = new Polygon(4);
          break;
        case 3:
          p = new Polygon(5);
          break;
        case 4:
          p = new Polygon(6);
          break;
        default:
          p = new Ring();
      }
      p.time = millis() - start;
      synchronized (pulses) {
        pulses.add(p);
      }
      p.c = color(dials[0], dials[1], dials[2], 240);
      p.dRadius = max(1.0/300.0, sliders[0]/2550.0);
      p.dTheta = sliders[1]/255.0 * PI;
      p.width = number > 63 ? 32 : number > 47 ? 16 : 8;
      print("Pulse color(" + hue(p.c) + " dR " + p.dRadius + " dT " + p.dTheta);
    }
  }
}