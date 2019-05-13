import processing.core.*;
import java.awt.*;
import java.util.ArrayList;
import java.util.Random;



    /************************
    * Start of "Processing" *
    ************************/

    boolean newGame = true;
    boolean endGame = false;
    boolean levelUp = false;
    boolean sUP, sDOWN, sRIGHT, sLEFT;
    int newRoids;
    float roidSpeed;
    int startingRoids = 4;
    float startingSpeed = 1;
    ArrayList<Asteroid> asteroids = new ArrayList();
    ArrayList<Bullet> bullets = new ArrayList();
    ArrayList<Asteroid> addRoids = new ArrayList();
    ArrayList<Asteroid> removeRoids = new ArrayList();
    Ship playerShip;
    int playerSize = 15; // player size as a factor (not actual size in pixels)

    /**********************
     * Processing Methods *
     **********************/

    public void settings(){
        size(1200,1200);
    }

    public void setup(){
        background(0);
        // load high score from a file
    }

    public void draw(){
        background(0);

        if (newGame){
            // TODO: 10/05/2019 have a menu display on launch to start a new game or exit, also display a high score

            // On menu activate start a new game
            newRoids = startingRoids;
            roidSpeed = startingSpeed;
            populateAsteroids(newRoids,roidSpeed);
            playerShip = new Ship(playerSize);

            int[] test = {5,5};

            newGame = false;
        }


        if (endGame){
            // TODO: 10/05/2019 make a menu that handles a 'new high score', and one that displays the current high
            //  score as well as options to start a new game or exit
            System.exit(2);
        }

        if (levelUp){
            // TODO: 10/05/2019 assess difficulty progression
            ++newRoids;
            populateAsteroids(newRoids, roidSpeed);
        }

        // Draw everything
        for (Asteroid roid : asteroids) {
            roid.updatePosition();
        }
        for (Bullet bullet : bullets) {
            bullet.updatePosition();
        }
        playerShip.updatePosition();

        // Game progress update

        // Reset the asteroids on a higher difficulty if they are all gone
        if (asteroids.size() == 0){
            levelUp = true;
        }

        // Loop over each asteroid and check if the player ship has collided, end the game if it has
        for (Asteroid roid : asteroids) {
            if(collisionDetection(playerShip, roid)){
                endGame = true;
            }
        }
        // Loop over each bullet and asteroid and check for collision
        for (Asteroid roid : asteroids) {
            for (Bullet bullet : bullets) {
                if (collisionDetection(bullet, roid)){
                    System.out.println("Break"); //Testing
                    // breakAsteroid(roid); Currently not working
                    break;
                }
            }
        }

        // Currently not working
        /*
        asteroids.removeAll(removeRoids);
        removeRoids = new ArrayList();
        asteroids.addAll(addRoids);
        addRoids = new ArrayList();
        */

    }

    // Keyboard methods used to handle player ship movement (source: A3 sample code)
    public void keyPressed(){
        if (key == CODED) {
            if (keyCode == UP) {
                sUP=true;
            }
            if (keyCode == DOWN) {
                sDOWN=true;
            }
            if (keyCode == RIGHT) {
                sRIGHT=true;
            }
            if (keyCode == LEFT) {
                sLEFT=true;
            }
        }
        if (key == 'f') {
            bullets.add(new Bullet());
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
        }
    }

    /******************
     * Custom Methods *
     ******************/

    /**
     * Method to generate a new set of asteroids at the start of a new game or on a completion reset
     * Takes arguments to adjust difficulty
     * @param numberOfAsteroids integer number of asteroids
     * @param speedFactor ratio of default speed
     */
    void populateAsteroids(int numberOfAsteroids, float speedFactor){
        // Create a bunch of asteroids

        // TODO: 09/05/2019 stop asteroids for spawning close to player

        for (int i = 0; i < numberOfAsteroids; i++) {
            // Generate random values for new set of Asteroids
            float[] location = new float[2];
            float[] direction = new float[2];

            location[0] = random(width);
            location[1] = random(height);
            direction[0] = random(-1,1);
            direction[1] = random(-1,1);

            // Add new Asteroids to main array
            asteroids.add(new Asteroid(3,location,direction,speedFactor));
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
    // TODO: 10/05/2019 look into offset issue 
    boolean collisionDetection(Ship ship, Asteroid roid){
        Polygon roidPoly = roidToPoly(roid);

        // Polygon.contains() takes java.awt.Point as an argument - make an array of points out of the ship's hitbox
        Point[] shipPoints = new Point[ship.hitBox.length];
        for (int i = 0; i < shipPoints.length; i++) {
            // Similar to the roid, use the location data stored in ship to transform the shape information
            // into real coordinates, but populate an array of points instead of a polygon
            int tempX = round(ship.hitBox[i][0]+ship.shipLocation.x);
            int tempY = round(ship.hitBox[i][1]+ship.shipLocation.y);
            shipPoints[i] = new Point(tempX,tempY);
        }

        // If any ship points are inside an asteroid, return true
        for (Point point : shipPoints) {
            return (roidPoly.contains(point));
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
    boolean collisionDetection(Bullet bullet, Asteroid roid){
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
    Polygon roidToPoly(Asteroid roid){
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
        roidPoly = new Polygon(tempX,tempY,roid.hitBox.length);

        return roidPoly;
    }


    /**
     * Method for breaking an asteroid into three smaller asteroids when hit with a bullet
     * @param brokenRoid Asteroid object that has been hit
     */
    void breakAsteroid(Asteroid brokenRoid){
        float[] radians = {PI*(float)0.66,PI*(float)0.66*2,0};

        if (brokenRoid.size > 1){
            int newSize = brokenRoid.size-1;
            float[] oldPos = {brokenRoid.location.x,brokenRoid.location.y};
            removeRoids.add(brokenRoid);
            for (int i = 0; i < radians.length; i++) {
                PVector newDirection = PVector.fromAngle(radians[i]);
                addRoids.add(new Asteroid(newSize,oldPos,new float[]{newDirection.x,newDirection.y},roidSpeed));
            }
        }
    }

    /******************
     * Custom Classes *
     ******************/

    /**
     * Class to manage the player ship
     */
    class Ship{
        float[][] hitBox;
        PShape shipShape;
        PVector shipVelocity;
        float shipHeading = 0 - (PI/2);
        PVector shipLocation;
        PVector shipDirection;
        PVector shipAcceleration;
        float topSpeed = (float)4.0;

        /**
         * Constructor for ship, newly created ships start in the middle at a stop
         *
         * @param size Integer input used to determine the initial vertex locations
         */
        Ship(int size){
            shipLocation = new PVector(width/(float)2.0, height/(float)2.0);
            shipVelocity = new PVector(0,0);
            shipAcceleration = new PVector(0,0);
            shipDirection = new PVector(0,0);

            // Transform matrix so ship can be centered on 0,0 (Note - ship initialises before anything else)
            translate(shipLocation.x,shipLocation.y);

            // Variables to make the triangle call easier to read
            float top = 0 - size;
            float bottom = size;
            float left = (size/(float)2.0)*-1;
            float right = (size/(float)2.0);

            // Docs - https://processing.org/reference/triangle_.html
            this.shipShape = createShape(TRIANGLE,0,top,left,bottom,right,bottom);
            hitBox = new float[3][2];
            hitBox[0] = new float[]{0,top};
            hitBox[1] = new float[]{left,bottom};
            hitBox[2] = new float[]{right,bottom};

            // Save matrix
            pushMatrix();
        }

        /**
         * Method for handling the movement of the ship
         * Utilises matrix transformations
         * source: vaguely based on examples from lectures and Processing.org PVector tutorial
         */
        void updatePosition(){
            float rotSpeed = (float)0.1;

            // Keep the heading variable an expression of positive radians <2PI
            if (shipHeading < 0) {
                shipHeading = shipHeading * -1;
                shipHeading = shipHeading % (2*PI);
                shipHeading = (2*PI) - shipHeading;
            } else {
                shipHeading = shipHeading % (2*PI);
            }

            // Get a vector from the heading
            shipDirection = PVector.fromAngle(shipHeading);

            // Drawing
            popMatrix();

            // Screen edge detection - warp to other side
            if (shipLocation.x <= 0){
                translate(width,0);
                shipLocation.x = shipLocation.x+width;
            }
            if (shipLocation.x >= width){
                translate(width*-1,0);
                shipLocation.x = shipLocation.x-width;
            }
            if (shipLocation.y <= 0){
                translate(0,height);
                shipLocation.y = shipLocation.y+height;
            }
            if (shipLocation.y >= height){
                translate(0,height*-1);
                shipLocation.y = shipLocation.y-height;
            }


            noStroke();
            fill(255);
            shape(shipShape);
            noFill();

            // Take input for acceleration
            if (sUP){
                shipAcceleration.add(shipDirection);
            } else if(sDOWN) {
                shipAcceleration.sub(shipDirection);
            } else {
                shipAcceleration.set(0,0);
            }

            // Calculate movement
            shipAcceleration.setMag((float)0.1);
            shipVelocity.add(shipAcceleration);
            shipVelocity.limit(topSpeed);
            translate(shipVelocity.x,shipVelocity.y);

            // Save the matrix, and adjust the shipLocation variable, which tracks the ships location in the
            // 'normal' matrix coordinates
            pushMatrix();
            shipLocation.add(shipVelocity);

            // Take input for rotation
            if (sRIGHT){
                shipShape.rotate(rotSpeed);
                shipHeading += rotSpeed;
            }

            if (sLEFT){
                shipShape.rotate(rotSpeed*-1);
                shipHeading -= rotSpeed;
            }
        }
    }

    /**
     *
     */
    class Bullet{

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
        Bullet(){

            location = new PVector(playerShip.shipLocation.x, playerShip.shipLocation.y);
            direction = new PVector(playerShip.shipDirection.x*speed, playerShip.shipDirection.y*speed);

            // bullets are small enough for a single vertex to be used for hit detection
            hitBox = new float[][] {{0,0}};
        }

        /**
         * Method for updating the position of bullets
         * PVector motion using intitialised conditions
         */
        void updatePosition(){
            location.add(direction);
            fill(255);
            ellipse(location.x, location.y,size,size);
        }
    }

    /**
     *
     */
    class Asteroid{

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
        Asteroid(int size, float[] position, float[] direction, float speed){

            if (size != 1 && size != 2 && size != 3){
                throw new IllegalArgumentException();
            }
            this.speed = speed;
            this.size = size;
            location = new PVector(position[0],position[1]);
            roidDirection = new PVector(direction[0],direction[1]);
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
            // TODO: 08/05/2019 fix first vertex 
            for (int i = 0; i < 10; i++) {
                PVector vertexDirection = PVector.fromAngle(angle);
                vertexDistance = (size*sizeFactor - rand.nextInt(sizeFactor) );
                PVector vertexLocation = vertexDirection.mult(vertexDistance);
                angle = angle + tenth;
                roidShape.vertex(vertexLocation.x,vertexLocation.y);
                hitBox[i] = new float[]{vertexLocation.x, vertexLocation.y};
            }
            roidShape.endShape(CLOSE);
        }

        /**
         * Uses the current speed and direction to update
         * the aseroid's position on the screen
         *
         * will warp to other side of screen when it hits the edge
         */

        void updatePosition(){
            roidShape.setFill(0);
            roidShape.setStroke(255);
            location.add(roidDirection);
            shape(roidShape,location.x, location.y);

            // Screen edge detection -  warp to other side

            if (location.x <= 0 - roidShape.width){
                location.x = width;
            }

            if (location.x >= width + roidShape.width){
                location.x = 0;
            }

            if (location.y <= 0 - roidShape.height){
                location.y = width;
            }

            if (location.y >= height + roidShape.height){
                location.y = 0;
            }
        }
    }


    /************************
     *  End of "Processing" *
     ************************/
