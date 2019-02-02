Snake snake;
Resources res;
float t;
int intendedObstacleCount = 12;
int intendedAppleCount = 3;
int intendedParticleCount = 500;
JSONObject progress = new JSONObject();
String highscoreFilePath = "highscore.json";
String highscoreKey = "high";
ArrayList<Food> foods = new ArrayList<Food>();
ArrayList<Food> foodToRemove = new ArrayList<Food>();
ArrayList<Obstacle> obstacles = new ArrayList<Obstacle>();
ArrayList<Obstacle> obstaclesToRemove = new ArrayList<Obstacle>();
ArrayList<Particle> particles = new ArrayList<Particle>();
ArrayList<Particle> psToRemove = new ArrayList<Particle>();
ArrayList<Flourish> flourishes = new ArrayList<Flourish>();
ArrayList<Flourish> flourishesToRemove = new ArrayList<Flourish>();

public void settings() {
  fullScreen(P3D);
  smooth(8);
}

public void setup() {
  colorMode(HSB, 255, 255, 255, 100);
  res = new Resources();
  ortho();
  background(0);
  snake = new Snake();
  loadProgress();
}

public void draw() {
  noCursor();
  t = radians(frameCount);
  backgroundUpdate();
  snake.mouseInteraction();
  obstaclesUpdate();
  snake.update();
  applesUpdate();
}

void applesUpdate() {
  if (foods.size() < intendedAppleCount) {
    foods.add(new Food());
  }
  for (Food a : foods) {
    a.update();
  }
  foods.removeAll(foodToRemove);
  foodToRemove.clear();
}

void backgroundUpdate() {
  pushMatrix();
  pushStyle();
  hint(DISABLE_DEPTH_TEST);
  imageMode(CORNER);
  noTint();
  image(res.get("background"), 0, 0, width, height);
  hint(ENABLE_DEPTH_TEST);
  for (Particle particle : particles) {
    particle.update();
  }
  while (particles.size() < intendedParticleCount) {
    particles.add(new Particle());
  }
  particles.removeAll(psToRemove);
  psToRemove.clear();

  noLights();

  for (Flourish flourish : flourishes) {
    flourish.update();
  }

  flourishes.removeAll(flourishesToRemove);
  flourishesToRemove.clear();


  hint(DISABLE_DEPTH_TEST);

  textAlign(CENTER, CENTER);
  int score = (snake.intendedBodySize - snake.minimumBodySize);
  fill(100);
  textSize(height * 70 / 1080f + score);
  text("" + score, width * .5f, height * .5f);

  float w = snake.invulnerabilityNormalized * 120;
  stroke(100);
  strokeWeight(10);
  line(width * .5f - w, height * .62f, width * .5f + w, height * .62f);

  textSize(height * 40 / 1080f);
  text("" + (snake.highestSeenBodySize - snake.minimumBodySize), width * .5f, height * .05f);
  hint(ENABLE_DEPTH_TEST);
  popStyle();
  popMatrix();
}

//call this using thread() for responsive GUI
public void saveProgress() {
  progress.put("high", snake.highestSeenBodySize);
  saveJSONObject(progress, highscoreFilePath);
}

void loadProgress() {
  try {
    snake.highestSeenBodySize = (Integer) loadJSONObject(highscoreFilePath).get("high");
  } 
  catch (Exception ex) {
    println("json was not found - a new one will be created as soon as the player gets 1 point");
  }
}

void obstaclesUpdate() {
  if (obstacles.size() < intendedObstacleCount) {
    obstacles.add(new Obstacle());
  }
  for (Obstacle o : obstacles) {
    o.update();
  }
  obstacles.removeAll(obstaclesToRemove);
  obstaclesToRemove.clear();
}

PVector randomPointAwayFromEdges() {
  float offsetFromEdge = 200;
  return new PVector(random(offsetFromEdge, width - offsetFromEdge), random(offsetFromEdge, height - offsetFromEdge));
}

boolean pointRectCollision(float px, float py, float rx, float ry, float rw, float rh) {
  return px >= rx && px <= rx + rw && py >= ry && py <= ry + rh;
}

float normalizedDuration(float start, float duration) {
  return 1 - constrain(map(frameCount, start, start + duration, 0, 1), 0, 1);
}

class Particle {
  float hue = 150 + random(50);
  float sat = 150;
  float br = 100;
  float r = random(5, 10);
  float damp = .98f;
  PVector pos = new PVector(random(width), random(height));
  PVector spd = new PVector();
  PVector acc = new PVector();

  int frameCreated = frameCount;
  int fadeInDuration = 50;

  void update() {
    //            applyNoise();
    applyMouse();
    spd.add(acc);
    spd.mult(damp);
    spd.limit(5);
    pos.add(spd);
    acc.mult(0);
    //disappear inside wall
    if ((pos.x < r && spd.x < 0) ||
      (pos.x - r > width && spd.x > 0) ||
      (pos.y < r && spd.y < 0) ||
      (pos.y - r > height && spd.y > 0)) {
      psToRemove.add(this);
    }
    float fadeInNormalized = normalizedDuration(frameCreated, fadeInDuration);
    strokeWeight(r);
    noStroke();
    fill(hue, sat, br, 100 - fadeInNormalized * 100);
    pushMatrix();
    translate(pos.x, pos.y);
    float rotScl = .1f;
    rotateX(noise(pos.x * rotScl + spd.x * rotScl + t * rotScl) * TWO_PI * 2.5f);
    rotateY(noise(pos.y * rotScl + spd.y * rotScl + t * rotScl) * TWO_PI * 2);
    rotateZ(noise(pos.x + rotScl + pos.y * rotScl + t * rotScl) * TWO_PI * 3);
    box(r, r, 0);
    popMatrix();
  }

  void applyNoise() {
    float a = getAngleAt(pos.x, pos.y);
    acc.add(PVector.fromAngle(a).div(r * r).mult(10));
  }

  void applyMouse() {
    float ma = angleBetween(pmouseX, pmouseY, mouseX, mouseY);
    float mm = dist(mouseX, mouseY, pmouseX, pmouseY);
    float md = dist(pos.x, pos.y, mouseX, mouseY);
    acc.add(PVector.fromAngle(ma).mult((10 * mm * mm / (md * md)) / r));
  }

  float getAngleAt(float x, float y) {
    return getNoiseAt(x, y) + HALF_PI;
  }

  float getNoiseAt(float x, float y) {
    float ns = 0.0005f;
    return noise(x * ns, y * ns, t);
  }

  float angleBetween(float x0, float y0, float x1, float y1) {
    return atan2(y1 - y0, x1 - x0);
  }
}

class Food {
  PVector pos;
  float size = 47 * 2;
  int frameCreated;
  int fadeInDurationInFrames = 30;
  boolean grantsInvulnerability = false;

  Food() {
    this.pos = randomPointAwayFromEdges();
    frameCreated = frameCount;
    if (random(1) > .95f) {
      grantsInvulnerability = true;
    }
  }

  void update() {
    PVector head = snake.body.get(0).pos;
    float distanceFromHead = dist(head.x, head.y, pos.x, pos.y);
    if (distanceFromHead < size) {
      foodToRemove.add(this);
      if (!grantsInvulnerability) {
        snake.intendedBodySize++;
        flourishes.add(new Flourish(new PVector(pos.x, pos.y), 
          20, 20, 2, 255, 0, 150, 50, TWO_PI));
      } else {
        snake.intendedBodySize += 3;
        snake.invulnerabilityStartFrame = frameCount;
        flourishes.add(new Flourish(new PVector(pos.x, pos.y), 
          60, 35, 5, 255, 0, 255, 50, TWO_PI));
      }
    }
    if (grantsInvulnerability) {
      size--;
      if (size < 1) {
        foodToRemove.add(this);
      }
    }
    pushMatrix();
    noFill();
    float fadeIn = map(frameCount, frameCreated, frameCreated + fadeInDurationInFrames, 0, 1);
    if (grantsInvulnerability) {
      fadeIn = 1;
    }
    tint(255, 100 * fadeIn);
    translate(pos.x, pos.y);
    if (!grantsInvulnerability) {
      image(res.get("food"), 0, 0, size, size);
    } else {
      image(res.get("ghost"), 0, 0, size, size);
    }
    popMatrix();
  }
}

class Obstacle {
  PVector topLeft;
  PVector size;
  PVector spd;
  float maxSpd = 5;
  float minSpd = 1;
  float rotation;

  Obstacle() {
    float s = random(75, 150);
    size = new PVector(s, s);

    if (random(1) > .5f) {
      //spawn a horizontally moving obstacle

      //spawn on the left or on the right from the screen randomly
      float x = random(1) > .5f ? -size.x : width;
      topLeft = new PVector(x, random(height));
      //go to the right if you spawn on the left and vice versa
      float xSpd = x > width * .5 ? random(-maxSpd, 0) : random(0, maxSpd);
      spd = new PVector(xSpd, 0);
      if (spd.x > -minSpd && spd.x < 0) {
        spd.x = -minSpd;
      }
      if (spd.x < minSpd && spd.x > 0) {
        spd.x = minSpd;
      }
    } else {
      //spawn on the left or on the right from the screen randomly
      float y = random(1) > .5f ? -size.y : height;
      topLeft = new PVector(random(width), y);
      //go to the right if you spawn on the left and vice versa
      float ySpd = y > height * .5 ? random(-maxSpd, 0) : random(0, maxSpd);
      spd = new PVector(0, ySpd);
      if (spd.y > -minSpd && spd.y < 0) {
        spd.y = -minSpd;
      }
      if (spd.y < minSpd && spd.y > 0) {
        spd.y = minSpd;
      }
    }

    float r = random(1);
    if (r < .25) {
      rotation = 0;
    } else if (r < .5) {
      rotation = HALF_PI;
    } else if (r < .75) {
      rotation = PI;
    } else {
      rotation = PI + HALF_PI;
    }
  }

  void update() {
    if (!snake.isInvulnerable()) {
      topLeft.add(spd);
      noTint();
    } else {
      tint(255, 50);
      topLeft.add(PVector.mult(spd, 1 - snake.invulnerabilityNormalized));
    }

    //disappear inside wall
    if ((topLeft.x < -size.x && spd.x < 0) ||
      (topLeft.x > width && spd.x > 0) ||
      (topLeft.y < -size.y && spd.y < 0) ||
      (topLeft.y > height && spd.y > 0)) {
      obstaclesToRemove.add(this);
    }

    if (isCollidingWithSnake()) {
      tint(0, 255, 255);
      snake.collide(this);
    }


    pushMatrix();
    translate(topLeft.x + size.x * .5f, topLeft.y + size.y * .5f, 100);
    rotate(rotation);
    imageMode(CENTER);
    image(res.get("obstacle"), 0, 0, size.x, size.y);
    popMatrix();
  }

  boolean isCollidingWithSnake() {
    if (snake.isInvulnerable()) {
      return false;
    }
    for (Segment s : snake.body) {
      if (pointRectCollision(s.pos.x, s.pos.y, topLeft.x, topLeft.y, size.x, size.y)) {

        return true;
      }
    }
    return false;
  }
}

class Snake {
  public int invulnerabilityStartFrame = -500;
  public int invulnerabilityDuration = 300;
  ArrayList<Segment> body = new ArrayList<Segment>();
  boolean locked = true;
  int defaultBodySize = 10;
  int intendedBodySize = defaultBodySize;
  int minimumBodySize = defaultBodySize;
  int highestSeenBodySize = defaultBodySize;
  float displacementMagnitude = 15;
  float mouseDist;
  float requiredMouseDist = 2;
  float lockDist = 15000;
  float lerpMagnitude = .5f;
  float invulnerabilityNormalized;

  Snake() {
    PVector pos = new PVector(width * .5f, height * .5f);
    for (int i = 0; i < intendedBodySize; i++) {
      body.add(new Segment(new PVector(pos.x - i * 2, pos.y), -i));
    }
  }

  void update() {
    mouseDist = dist(mouseX, mouseY, body.get(0).pos.x, body.get(0).pos.y);

    while (body.size() > intendedBodySize) {
      body.remove(body.size() - 1);
    }

    if (intendedBodySize > highestSeenBodySize) {
      highestSeenBodySize = intendedBodySize;
      thread("saveProgress");
    }

    noFill();
    int skipImages = 1;
    int skippedCurrently = 0;
    int imageIndexMin = 1;
    int imageIndexMax = 3;
    int imageIndex = imageIndexMin;
    invulnerabilityNormalized = 1 - map(frameCount, invulnerabilityStartFrame, invulnerabilityStartFrame + invulnerabilityDuration, 
      0, 1);
    invulnerabilityNormalized = constrain(invulnerabilityNormalized, 0, 1);
    for (int i = body.size() - 1; i > 0; i--) {
      if (i != 1) { //must display head which is found at i = 1
        if (skipImages > skippedCurrently) {
          skippedCurrently++;
          continue;
        } else {
          skippedCurrently = 0;
        }
      }

      Segment seg = body.get(i);
      Segment prev = body.get(i - 1);

      //angle in radians facing forward from the last segment to the next
      float angle = atan2(seg.pos.y - prev.pos.y, seg.pos.x - prev.pos.x) % TWO_PI;

      // rotate 90 degrees to find an angle perpendicular
      // to the angle between this and the last segment
      // and translate along that
      float perpendicular = (angle + HALF_PI) % TWO_PI;

      //the wiggly heart of it all
      float xOffset = sin(seg.displacementIndex * .5f + t) * cos(perpendicular);
      float yOffset = sin(seg.displacementIndex * .5f + t) * sin(perpendicular);

      //displace the vertices the more the closer you get to the center
      float normalizedSegmentIndex = 1 - map(i, 1, body.size() - 1, 0, 1);
      //float normalizedDistanceFromCenter = constrain(1 - 2.f * abs(.5f - normalizedSegmentIndex), 0, 1);

      if (i != 1) { //head is not affected by the sinewave movement of the body
        xOffset *= displacementMagnitude;
        yOffset *= displacementMagnitude;
      }

      stroke(130 + (255 - 130) * (1 - normalizedSegmentIndex), 200, 255);

      pushMatrix();
      imageMode(CENTER);
      translate(seg.pos.x + xOffset, seg.pos.y + yOffset);

      if (angle > -HALF_PI && angle < HALF_PI) {
        scale(1, -1);
        rotate(-angle + PI);
      } else {
        rotate(angle + PI);
      }
      float invulnerabilityAlphaOffset = 80 * (snake.isInvulnerable() ? (.5f + .5f * sin(radians(frameCount * 8))) : 0);
      tint(255, 100 - invulnerabilityAlphaOffset);
      if (i == 1) {
        image(res.get("head"), 0, 0);
      } else {
        image(res.get("body_" + imageIndex++), 0, 0);
        if (imageIndex > imageIndexMax) {
          imageIndex = imageIndexMin;
        }
      }
      popMatrix();
    }
  }

  void mouseInteraction() {
    if (mouseX == 0 && mouseY == 0) {
      //happens at game start - keeps the dragon in the center as default mouse coords are 0,0
      mouseX = floor(width * .5f);
      mouseY = floor(height * .5f);
    }

    if (locked && mouseDist > requiredMouseDist) {
      float amount = lerpMagnitude;
      float newX = lerp(body.get(0).pos.x, mouseX, amount);
      float newY = lerp(body.get(0).pos.y, mouseY, amount);
      float distanceFromOldHead = dist(newX, newY, body.get(0).pos.x, body.get(0).pos.y);
      float maxDistanceFromOldHeadAsFarAsDisplacementIndexIsConcerned = 10;
      distanceFromOldHead = constrain(distanceFromOldHead, 0, maxDistanceFromOldHeadAsFarAsDisplacementIndexIsConcerned);
      float normalizedDistanceFromOldHead = map(distanceFromOldHead, 0, 10, 0, 1);
      float displacementIndex = body.get(0).displacementIndex - 1 * normalizedDistanceFromOldHead;
      body.add(0, new Segment(new PVector(newX, newY), displacementIndex));
    }

    /*
            if (mousePressed && !snake.locked) {
     locked = true;
     }
     if (!mousePressed) {
     locked = false;
     }*/
  }

  public void collide(Obstacle obstacle) {
    if (intendedBodySize > minimumBodySize) {
      intendedBodySize--;
    }
  }

  public boolean isInvulnerable() {
    return invulnerabilityNormalized > 0.01f;
  }
}

class Segment {
  PVector pos;
  float displacementIndex;

  Segment(PVector pos, float displacementIndex) {
    this.pos = pos;
    this.displacementIndex = displacementIndex;
  }
}

class Flourish {
  int h, s, b;
  float strokeWeight, lineLength, radius, arc;
  float frameStarted, durationInFrames;
  PVector pos;

  Flourish(PVector pos, int durationInFrames, float lineLength, float strokeWeight, int h, int s, int b, float radius, float arc) {
    this.pos = pos;
    this.durationInFrames = durationInFrames;
    this.lineLength = lineLength;
    this.strokeWeight = strokeWeight;
    this.h = h;
    this.s = s;
    this.b = b;
    this.radius = radius;
    this.arc = arc;
    frameStarted = frameCount;
  }

  public void update() {
    pushMatrix();
    float intensity = normalizedDuration(frameStarted, durationInFrames);
    stroke(h * 255, s * 255, b * 255);
    strokeWeight(strokeWeight);
    if (intensity > 0) {
      translate(pos.x, pos.y);
      float r0 = radius + lineLength - lineLength * intensity;
      float r1 = radius + lineLength;
      for (float a = TWO_PI - arc; a <= TWO_PI; a += TWO_PI / 12f) {
        float x0 = r0 * cos(a);
        float y0 = r0 * sin(a);
        float x1 = r1 * cos(a);
        float y1 = r1 * sin(a);
        line(x0, y0, x1, y1);
      }
    } else {
      flourishesToRemove.add(this);
    }
    popMatrix();
  }
}

class Resources {
  HashMap<String, PImage> images = new HashMap<String, PImage>();

  Resources() {
    images.put("head", loadImage("head.png"));
    images.put("body_1", loadImage("body_1.png"));
    images.put("body_2", loadImage("body_2.png"));
    images.put("body_3", loadImage("body_3.png"));
    images.put("ghost", loadImage("ghost.png"));
    images.put("food", loadImage("food.png"));
    images.put("obstacle", loadImage("obstacle.png"));
    images.put("background", loadImage("background.png"));
  }

  public PImage get(String name) {
    return images.get(name);
  }
}
