import processing.sound.*;
import processing.core.*;
import java.awt.*;
import java.util.ArrayList;
import java.util.Random;
import de.bezier.data.sql.*;

/*********************


Made by
Andrew McIntosh
&
Daniel Moore

Libraries:
Bezier SQLib
Processing Sound Library

Breakdown video:
https://www.youtube.com/watch?v=WIO3eUx3-fM

***********************/


/************************
 * Start of "Processing" *
 ************************/

boolean newGame = true;
boolean endGame = false;
boolean sUP, sDOWN, sRIGHT, sLEFT; 
String scene = "menu_scene";
ArrayList<Star> stars = new ArrayList();
File dbFile; // declared to create it in global scope
SQLite db;
int score;
int[] highscores;
int newRoids;
float roidSpeed;
int startingRoids = 4;
float startingSpeed = 1;
ArrayList<Asteroid> asteroids = new ArrayList();
ArrayList<Bullet> bullets = new ArrayList();
Asteroid hitRoid;
Bullet brokenBullet;
Ship playerShip;
int playerSize = 15; // player size as a factor (not actual size in pixels)
SoundFile moving;
SoundFile breaking;
SoundFile shooting;

/**********************
 * Processing Methods *
 **********************/

public void settings() {
  size(1920, 1080);
}

public void setup() {
  background(0);

  //set in setup to avoid file path being in root processing folder
  dbFile = new File(sketchPath("db.sql")); 

  if ( !dbFile.exists() ) {
    try {
      dbFile.createNewFile();
    } 
    catch( IOException ioe ) {
      System.out.println("Exception ");
      ioe.printStackTrace();
    }
  }

  db = new SQLite( this, "db.sql" );
  if( db.connect() ){
    db.execute( "CREATE TABLE IF NOT EXISTS highscores (highscore INTEGER NOT NULL)" );
  }

  for ( int i = 0; i < 200; i++) {
    Star star_temp = new Star();
    stars.add(star_temp);
  }

  // load sound files
  moving = new SoundFile(this, "engine.wav"); //source: asteroids demo video (https://www.youtube.com/watch?v=WYSupJ5r2zo)
  breaking = new SoundFile(this, "break.wav"); //source: asteroids demo video (https://www.youtube.com/watch?v=WYSupJ5r2zo)
  shooting = new SoundFile(this, "shoot.wav"); //source: asteroids demo video (https://www.youtube.com/watch?v=WYSupJ5r2zo)
}
public void draw() {
  background(0);

  switch( scene ) {
  case "game_scene":
    gameScene();  
    break;

  case "highscore_scene":
    highScoreScene();
    break;

  case "endgame_scene":
    endGameScene();
    break;

  case "menu_scene":
    menuScene();
    break;
  }
}

// Keyboard methods used to handle player ship movement (source: A3 sample code)
public void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      playMoving();
      sUP=true;
    }
    if (keyCode == DOWN) {
      playMoving();
      sDOWN=true;
    }
    if (keyCode == RIGHT) {
      playMoving();
      sRIGHT=true;
    } 
    if (keyCode == LEFT) {
      playMoving();
      sLEFT=true;
    }
  }

  if (key == 'f') {
    playShooting();
    bullets.add(new Bullet());
  }

  if (key == ESC) {
    key = 0; //Stop the game auto closing
    scene = "menu_scene";
  }
}

public void keyReleased() {
  if (key == CODED) {
    if (keyCode == UP) {
      sUP=false;
    }
    if (keyCode == DOWN) {
      sDOWN=false;
    }
    if (keyCode == RIGHT) {
      sRIGHT=false;
    }
    if (keyCode == LEFT) {
      sLEFT=false;
    }
    stopMoving(); // Stops playing the moving sound if appropriate
  }
}

//Mouse inputs to determine which button was pressed
public void mousePressed() {
  float[] rWidth = {(width-400)/2, 400};
  if ( mouseX > rWidth[0] && mouseX < rWidth[0]+rWidth[1] ) {
    
    switch( scene ){
      case "menu_scene":
        //start
        if ( mouseY > 200 && mouseY < 250 ) {
          newGame = true;
          scene = "game_scene";
        }
    
        //highscore
        if ( mouseY > 300 && mouseY < 350 ) {
          
          highscores = new int[5];
          int i = 0;
          db.query( "SELECT highscore FROM highscores ORDER BY highscore DESC LIMIT 5" );
          while(db.next()){
            highscores[i] = db.getInt("highscore");
            i++;
          }
          
          scene = "highscore_scene";
        }
    
        //exit
        if ( mouseY > 400 && mouseY < 450) {
          System.exit(2);
        }
        break;
      case "endgame_scene":
        //highscore
        if ( mouseY > 300 && mouseY < 350 ) {
          
          highscores = new int[5];
          int i = 0;
          db.query( "SELECT highscore FROM highscores ORDER BY highscore DESC LIMIT 5" );
          while(db.next()){
            highscores[i] = db.getInt("highscore");
            i++;
          }
          
          scene = "highscore_scene";
        }
        
        //back
        if ( mouseY > 400 && mouseY < 450) {
          scene = "menu_scene";
        }
        break;
      case "highscore_scene":
        if( mouseY > 420 && mouseY < 470 ) {
          scene = "menu_scene";
        }
    }
  }
}

/*********************
 * Draw loop Methods *
 *********************/

/**
 * These methods provide the draw loop the main code of the game
 * in order to keep the draw loop tidy
 */

void menuScene() {
  for ( Star star : stars) {
    star.move();
  }
  float[] rWidth = {(width-400)/2, 400};
  stroke( 255, 255, 255, 255);

  //start
  textSize(32);
  fill( 0, 0, 0, 255);
  rect( rWidth[0], 200, rWidth[1], 50 ); 
  fill( 255, 255, 255, 255);
  text( "start", width / 2 - 40, 235 );
  
  //highscore
  fill( 0, 0, 0, 255);
  rect( rWidth[0], 300, rWidth[1], 50 ); 
  fill( 255, 255, 255, 255);
  text( "highscore", width / 2 - 85, 335 );

  //exit
  fill( 0, 0, 0, 255);
  rect( rWidth[0], 400, rWidth[1], 50 );
  fill( 255, 255, 255, 255);
  text( "exit", width / 2 - 30, 435 );
  
}

void gameScene() {
  // Reset everything if starting a new game
  if (newGame) {
    score = 0;
    asteroids = null;
    asteroids = new ArrayList();
    playerShip = null;
    playerShip = new Ship(playerSize);
    newRoids = startingRoids;
    roidSpeed = startingSpeed;
    populateAsteroids(newRoids, roidSpeed);
    newGame = false;
  }

  // Draw everything
  for (Asteroid roid : asteroids) {
    roid.updatePosition();
  }

  for (Bullet bullet : bullets) {
    bullet.updatePosition();
  }

  textSize(32);
  fill( 255, 255, 255, 255);
  text( "Score: " + score, 0, 32 );
  fill( 0, 0, 0, 0);

  playerShip.updatePosition();

  // Game progress update

  // Draw increasing numbers of asteroids as they are cleared
  // Note - speed adjustment not currently used
  if (asteroids.size() == 0) {
    roidSpeed *= 1.2;
    ++newRoids;
    populateAsteroids(newRoids, roidSpeed);
  }

  // Loop over each asteroid and check if the player ship has collided, end the game if it has
  for (Asteroid roid : asteroids) {
    if (collisionDetection(playerShip, roid)) {
      pushMatrix();
      scene = "endgame_scene";
      db.execute("INSERT INTO highscores (highscore) VALUES(" + score + ")");
    }
  }
  // Loop over each bullet and asteroid and check for collision
  for (Asteroid roid : asteroids) {
    for (Bullet bullet : bullets) {
      if (collisionDetection(bullet, roid)) {
        playBreaking();
        hitRoid = roid;
        brokenBullet = bullet;
        score++;
        break;
      }
    }
  }
  
  
  // Resolve bullet collision with asteroids
  bullets.remove(brokenBullet);
  brokenBullet = null;
  breakAsteroid(hitRoid);
  hitRoid = null;
}

void endGameScene() {
  float[] rWidth = {(width-400)/2, 400};
  fill( 255, 255 ,255 ,255);
  textSize(48);
  text( "Your score is", width / 2 - 160, 150);
  textSize(64);
  text( score, width / 2 - 60, 250);
  textSize(32);
  
  //highscore
  fill( 255, 255, 255, 255);
  text( "highscore", width / 2 - 85, 335 );
  fill( 0, 0, 0, 0);
  rect( rWidth[0], 300, rWidth[1], 50 );
  
  //back
  fill( 255, 255, 255, 255);
  text( "back", width / 2 - 30, 435 );
  fill( 0, 0, 0, 0);
  rect( rWidth[0], 400, rWidth[1], 50 );
}

void highScoreScene() {
  
  
  
  fill( 255, 255, 255, 255);
  textSize(32);
  text("Highscores", width / 2 - 70, 150);
  for(int i = 0; i < highscores.length; i++){
    text( (i+1)+"."+highscores[i], width / 2 - 70, 200+(50*i));
  }
  
  //back
  fill( 255, 255, 255, 255);
  text( "back", width / 2 - 30, 455 );
  fill( 0, 0, 0, 0);
  rect( (width-400)/2, 420, 400, 50 );
}



/******************
 * Custom Methods *
 ******************/

/**
 * playMoving and stopMoving ensure the smooth playing of moving sounds
 */
void playMoving() {
  if (!moving.isPlaying()) {
    moving.loop(1, 0, 0.5);
  }
}

void stopMoving() {
  if (!sLEFT && !sRIGHT && !sUP && !sDOWN) {
    moving.stop();
  }
}

/**
 * Method to resolve conflicts in moving/shooting
 */
void playShooting() {
  if (shooting.isPlaying()) {  
    shooting.jump(0);
  } else {
    shooting.play();
  }
}

/**
 * Method to resolve conflicts in moving/breaking
 */
void playBreaking() {
  if (breaking.isPlaying()) {  
    breaking.jump(0);
  } else {
    breaking.play();
  }
}

/**
 * Method to generate a new set of asteroids at the start of a new game or on a completion reset
 * Takes arguments to adjust difficulty
 * @param numberOfAsteroids integer number of asteroids
 * @param speedFactor ratio of default speed
 */
void populateAsteroids(int numberOfAsteroids, float speedFactor) {

  for (int i = 0; i < numberOfAsteroids; i++) {
    // Generate random values for new set of Asteroids
    float[] location = new float[2];
    float[] direction = new float[2];

    // Pick random locations such that they are not within a quater of the map of the player
    location[0] = random(playerShip.shipLocation.x + (width*0.25), 
      playerShip.shipLocation.x + (width*0.75));
    location[1] = random(playerShip.shipLocation.y + (height*0.25), 
      playerShip.shipLocation.x + (height*0.75));
    location[0] = location[0] % width;
    location[1] = location[0] % height;
    direction[0] = random(-1, 1);
    direction[1] = random(-1, 1);

    // Add new Asteroids to main array
    asteroids.add(new Asteroid(3, location, direction, speedFactor));
  }
}

/**
 * Method to determine contact between two objects
 * Note Ship, Bullet and Asteroid contain their own hitbox information
 * Function uses java.awt.Polygon
 * Polygon.contains() looks to see if a point is inside the polygon, and given the context of the game it makes
 * the most sense to test if vertices of the ship, or bullets are 'inside' asteroids. pixel level calculations
 * allow this to look like registering 'hits'
 *
 * Polygon() docs - https://docs.oracle.com/en/java/javase/11/docs/api/java.desktop/java/awt/Polygon.html
 *
 * @param ship Active player ship to pull hitbox from
 * @param roid Asteroid object to pull asteroid hitbox from
 * @return returns true on contact between objects, false otherwise
 */
boolean collisionDetection(Ship ship, Asteroid roid) {
  Polygon roidPoly = roidToPoly(roid);
  float[][] shipHitBox = ship.getHitBox();

  // Polygon.contains() takes java.awt.Point as an argument - make an array of points out of the ship's hitbox
  Point[] shipPoints = new Point[shipHitBox.length];
  for (int i = 0; i < shipPoints.length; i++) {
    // Similar to the roid, use the location data stored in ship to transform the shape information
    // into real coordinates, but populate an array of points instead of a polygon
    int tempX = round(shipHitBox[i][0]+ship.shipLocation.x);
    int tempY = round(shipHitBox[i][1]+ship.shipLocation.y);
    shipPoints[i] = new Point(tempX, tempY);
  }

  // If any ship points are inside an asteroid, return true
  for (Point point : shipPoints) {
    if (roidPoly.contains(point)) {
      return true;
    }
  }
  // Return false otherwise
  return false;
}

/**
 * Overloaded version of collision detection for bullets instead of ship
 *
 * @param bullet bullet being tested for hitting an asteroid
 * @param roid Asteroid object to pull asteroid hitbox from
 * @return returns true on contact between objects, false otherwise
 */
boolean collisionDetection(Bullet bullet, Asteroid roid) {
  Polygon roidPoly = roidToPoly(roid);

  Point bulletPoint = new Point(round(bullet.location.x), round(bullet.location.y));

  if (roidPoly.contains(bulletPoint)) return true;

  return false;
}

/**
 * Method for creating java.awt.Polygons out of Asteroids
 *
 * @param roid Asteroid object to be turning into a Polygon
 * @return Polygon object created using Asteroid's data
 */
Polygon roidToPoly(Asteroid roid) {
  Polygon roidPoly;

  // Making int arrays for the Polygon constructor
  int[] tempX = new int[roid.hitBox.length];
  int[] tempY = new int[roid.hitBox.length];
  for (int i = 0; i < roid.hitBox.length; i++) {
    // roid.hitbox is the locations of the vertices relative to the location (PShape)
    // add the location data to get their location on the sketch
    tempX[i] = round(roid.hitBox[i][0]+roid.location.x);
    tempY[i] = round(roid.hitBox[i][1]+roid.location.y);
  }
  // Finally create the Polygon
  roidPoly = new Polygon(tempX, tempY, roid.hitBox.length);

  return roidPoly;
}

/**
 * Method for breaking an asteroid into three smaller asteroids when hit with a bullet
 * @param brokenRoid Asteroid object that has been hit
 */
void breakAsteroid(Asteroid brokenRoid) {
  if (!(brokenRoid==null)) {
    float[] radians = {random(0, 1), random(2, 3), random(4, 5)};

    if (brokenRoid.size > 1) {
      int newSize = brokenRoid.size-1;
      float[] oldPos = {brokenRoid.location.x, brokenRoid.location.y};
      asteroids.remove(brokenRoid);
      for (int i = 0; i < radians.length; i++) {
        PVector newDirection = PVector.fromAngle(radians[i]);
        asteroids.add(new Asteroid(newSize, oldPos, new float[]{newDirection.x, newDirection.y}, roidSpeed));
      }
    } else {
      asteroids.remove(brokenRoid);
    }
  }
}

/******************
 * Custom Classes *
 ******************/

/**
 * Class to manage the player ship
 */
class Ship {
  PShape shipShape;
  PVector shipVelocity;
  float shipHeading = 0 - (PI/2);
  PVector shipLocation;
  PVector shipDirection;
  PVector shipAcceleration;
  float topSpeed = 4.0;
  float[] distances = new float[3]; // Distance variables needed for hitbox rotation (clockwise starting at top)

  /**
   * Constructor for ship, newly created ships start in the middle at a stop
   *
   * @param size Integer input used to determine the initial vertex locations
   */
  Ship(int size) {
    shipLocation = new PVector(width/2.0, height/2.0);
    shipVelocity = new PVector(0, 0);
    shipAcceleration = new PVector(0, 0);
    shipDirection = new PVector(0, 0);

    // Transform matrix so ship can be centered on 0,0 (Note - ship initialises before anything else)
    translate(shipLocation.x, shipLocation.y);

    // Variables to make the triangle call easier to read
    float top = 0 - size;
    float bottom = size;
    float left = (size/2.0)*-1;
    float right = (size/2.0);
    // Setting distance variables based on size (clockwise starting at top)
    distances[0] = size;
    distances[1] = PVector.dist(new PVector(0, 0), new PVector(right, bottom));
    distances[2] = PVector.dist(new PVector(0, 0), new PVector(left, bottom));


    // Docs - https://processing.org/reference/triangle_.html
    this.shipShape = createShape(TRIANGLE, 0, top, left, bottom, right, bottom);

    // Save matrix
    pushMatrix();
  }

  /**
   * Method to call the ship's hitbox
   * The ship's hitbox needs to take into account rotation, which occurs on a different matrix
   *  therefore it is calculated as it is called
   */
  float[][] getHitBox() {
    float[][] hitBox = new float[3][2];
    float[] DIRECTIONS = {0, 1.1+(0.5*PI), 2.03+(0.5*PI)}; // Pre calculated directions based on shape of ship
    PVector vertexDirection;

    // Use PVector to create rotated vertex locations (clockwise starting at top)         
    for (int i = 0; i < 3; i++) {

      vertexDirection = PVector.fromAngle(DIRECTIONS[i] + shipHeading);
      vertexDirection.mult(distances[i]);
      hitBox[i][0] = vertexDirection.x;
      hitBox[i][1] = vertexDirection.y;
      vertexDirection = null;
    }
    return hitBox;
  }

  /**
   * Method for handling the movement of the ship
   * Utilises matrix transformations
   * source: vaguely based on examples from lectures and Processing.org PVector tutorial
   */
  void updatePosition() {
    float rotSpeed = 0.1;

    // Keep the heading variable an expression of positive radians <2PI
    if (shipHeading < 0) {
      shipHeading = shipHeading * -1;
      shipHeading = shipHeading % (2*PI);
      shipHeading = (2*PI) - shipHeading;
    } else {
      shipHeading = shipHeading % (2*PI);
    }

    // Drawing
    popMatrix();

    // Take input for rotation
    if (sRIGHT) {
      shipShape.rotate(rotSpeed);
      shipHeading += rotSpeed;
    }

    if (sLEFT) {
      shipShape.rotate(rotSpeed*-1);
      shipHeading -= rotSpeed;
    }

    // Take input for acceleration
    if (sUP) {
      shipAcceleration.add(shipDirection);
    } else if (sDOWN) {
      shipAcceleration.sub(shipDirection);
    } else {
      shipAcceleration.set(0, 0);
    }

    // Calculate movement
    shipAcceleration.setMag(0.1);
    shipVelocity.add(shipAcceleration);
    shipVelocity.limit(topSpeed);
    translate(shipVelocity.x, shipVelocity.y);

    // Screen edge detection - warp to other side
    if (shipLocation.x <= 0) {
      translate(width, 0);
      shipLocation.x = shipLocation.x+width;
    }
    if (shipLocation.x >= width) {
      translate(width*-1, 0);
      shipLocation.x = shipLocation.x-width;
    }
    if (shipLocation.y <= 0) {
      translate(0, height);
      shipLocation.y = shipLocation.y+height;
    }
    if (shipLocation.y >= height) {
      translate(0, height*-1);
      shipLocation.y = shipLocation.y-height;
    }

    // Save the matrix, and adjust the shipLocation and shipDirection variables 
    // which track the ships location in th'normal' matrix coordinates
    pushMatrix();
    shipLocation.add(shipVelocity);
    shipDirection = PVector.fromAngle(shipHeading);

    // Draw the ship
    shape(shipShape);
  }
}

/**
 *
 */
class Bullet {

  float[][] hitBox;
  PVector direction;
  PVector location;
  PShape bulletShape;
  float size = 3; // For changing overall size in development (size in pixels / 2)
  float speed = 6;

  /**
   * Contructor for bullets
   * Get's all input from the active player ship object
   */
  Bullet() {

    location = new PVector(playerShip.shipLocation.x, playerShip.shipLocation.y);
    direction = new PVector(playerShip.shipDirection.x*speed, playerShip.shipDirection.y*speed);

    // bullets are small enough for a single vertex to be used for hit detection
    hitBox = new float[][] {{0, 0}};
  }

  /**
   * Method for updating the position of bullets
   * PVector motion using intitialised conditions
   */
  void updatePosition() {
    location.add(direction);
    fill(255);
    ellipse(location.x, location.y, size, size);
  }
}

/**
 *
 */
class Asteroid {

  float[][] hitBox;
  int size;
  float speed;
  int sizeFactor = 15; // for adjusting overall size factor in development
  float tenth = (2*PI)/10;  // one tenth of a circle
  PVector location;
  Random rand = new Random();
  PVector roidDirection;
  PShape roidShape;

  /**
   * Constructor for Asteroid class
   * @param size integer 1 2 or 3 representing tier of asteroid (1 small 3 big)
   * @param position int array containing start position (x,y)
   * @param direction int array direction in pixels 'per speed' on axis (x,y)
   * @param speed integer representing speed factor
   */
  Asteroid(int size, float[] position, float[] direction, float speed) {

    if (size != 1 && size != 2 && size != 3) {
      throw new IllegalArgumentException();
    }
    this.speed = speed;
    this.size = size;
    location = new PVector(position[0], position[1]);
    roidDirection = new PVector(direction[0], direction[1]);
    roidDirection.normalize();
    roidDirection.mult(speed);

    // Randomly generate the general shape of the Asteroid
    roidShape = createShape();
    roidShape.beginShape();

    float angle = rand.nextFloat();
    float vertexDistance;
    hitBox = new float[10][2];

    // Loop over 10 vertices, using PVector to determine coordinates
    // based on set direction and random distance
    for (int i = 0; i < 10; i++) {
      PVector vertexDirection = PVector.fromAngle(angle);
      vertexDistance = random((size*sizeFactor*2)/3, size*sizeFactor);
      PVector vertexLocation = vertexDirection.mult(vertexDistance);
      angle = angle + tenth;
      roidShape.vertex(vertexLocation.x, vertexLocation.y);
      hitBox[i] = new float[]{vertexLocation.x, vertexLocation.y};
    }
    roidShape.stroke(255);
    roidShape.fill(0);
    roidShape.endShape(CLOSE);
  }

  /**
   * Uses the current speed and direction to update
   * the aseroid's position on the screen
   *
   * will warp to other side of screen when it hits the edge
   */
  void updatePosition() {

    location.add(roidDirection);
    shape(roidShape, location.x, location.y);

    // Screen edge detection -  warp to other side

    if (location.x <= 0 - roidShape.width) {
      location.x = width;
    }

    if (location.x >= width + roidShape.width) {
      location.x = 0;
    }

    if (location.y <= 0 - roidShape.height) {
      location.y = height;
    }

    if (location.y >= height + roidShape.height) {
      location.y = 0;
    }
  }
}

/*******************************************
 * Class for the cool stars in the menu UI *
 *******************************************/
class Star {

  float x = random(width);
  float y = random(height);
  float speed = random(5, 20);

  void move( ) {
    y += speed;
    if ( y > height) {
      y = 0;
      speed = random( 5, 20 );
    }
    stroke( 255, 255, 255, 255);
    line( x, y, x, y + 5);
  }
}


/************************
 *  End of "Processing" *
 ************************/
