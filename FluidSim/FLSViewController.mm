//
//  FLSViewController.m
//  FluidSim
//
//  Created by SlEePlEs5 on 1/28/14.
//  Copyright (c) 2014 SlEePlEs5. All rights reserved.
//

#import "FLSViewController.h"
#import "FLSParticle.h"
#import "FLSGlobals.h"
#import <array>
#import <unordered_set>
#import <unordered_map>

using namespace std;

@interface FLSViewController ()

@property (strong, nonatomic) EAGLContext *context;
@property (strong) GLKBaseEffect *effect;

@end

@implementation FLSViewController

@synthesize context = _context;

const float RADIUS = 0.6f;
const float VISCOSITY = 0.000f;
const float DT = 1.0f / 60.0f;

const float IDEAL_RADIUS = 50.0f;
const float MULTIPLIER = IDEAL_RADIUS / RADIUS;
const float IDEAL_RADIUS_SQ = IDEAL_RADIUS * IDEAL_RADIUS;

const float CELL_SIZE = 0.5f;

const int MAX_NEIGHBORS = 75;

const int PARTICLE_ADD_RATE = 4;

GLKVector2 _delta[MAX_PARTICLES];
GLKVector2 _scaledPositions[MAX_PARTICLES];
GLKVector2 _scaledVelocities[MAX_PARTICLES];

FLSParticle* _liquid[MAX_PARTICLES];
unordered_set<size_t> _activeParticles;

unordered_map<size_t, unordered_map<size_t, unordered_set<size_t>>> _grid;

BOOL touching = false;
GLKVector2 touchPos;
GLKVector2 screenSize;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    srand(time(0));
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    [EAGLContext setCurrentContext:self.context];
    
    self.effect = [[GLKBaseEffect alloc] init];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, screenRect.size.width, 0, screenRect.size.height, -1024, 1024);
    
    screenSize = GLKVector2Make(screenRect.size.width, screenRect.size.height);
    
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    
    
    
    
    // Now, simulation stuff!
    
    
    
    
    
    _activeParticles = unordered_set<size_t>();
    
    _grid = unordered_map<size_t, unordered_map<size_t, unordered_set<size_t>>>();
    
    for (int i = 0; i < MAX_PARTICLES; i++)
    {
        
        // Fill _liquid Array
        
        FLSParticle *particle = [[FLSParticle alloc] initWithFile:@"Particle.png" effect:self.effect];
        particle->position = GLKVector2Make(0, 0);
        particle->velocity = GLKVector2Make(0, 0);
        particle->alive = NO;
        particle->index = i;
        _liquid[i] = particle;
        
    }
    
}

void createParticle(float posX, float posY) {
    
    FLSParticle* someInactiveParticles[PARTICLE_ADD_RATE];
    
    int count = 0;
    
    for (size_t i = 0; i < MAX_PARTICLES; i++) {
        if (!_liquid[i]->alive) {
            someInactiveParticles[count] = _liquid[i];
            count++;
        }
        if (count == PARTICLE_ADD_RATE) {
            break;
        }
    }
    
    for (size_t i = 0; i < 4; i++)
    {
        if (_activeParticles.size() < MAX_PARTICLES)
        {
            
            FLSParticle *particle = someInactiveParticles[i];
            
            GLKVector2 jitter = GLKVector2Make(((((float)rand())/((float)RAND_MAX))*2)-1, (((float)rand())/((float)RAND_MAX))-0.5);
            
            particle->position = GLKVector2Add(GLKVector2Make(posX, posY), jitter);
            particle->velocity = GLKVector2Make(0, 0);
            particle->alive = true;
            particle->ci = getGridX(particle->position.x);
            particle->cj = getGridY(particle->position.y);
            
            // Create grid cell if necessary
            if (_grid.find(particle->ci) == _grid.end()) {
                _grid.insert(make_pair(particle->ci,unordered_map<size_t, unordered_set<size_t>>()));
            }
            if (_grid.at(particle->ci).find(particle->cj) == _grid.at(particle->ci).end()) {
                _grid.at(particle->ci).insert(make_pair(particle->cj,unordered_set<size_t>()));
            }
            _grid.at(particle->ci).at(particle->cj).insert(particle->index);
            
            _activeParticles.insert(particle->index);
            
        }
        else {
            break;
        }
    }
}
void applyLiquidConstraints() {
    
    // Prepare simulation
    for (int index : _activeParticles) {
        
        FLSParticle *particle = _liquid[index];
        
        // Scale positions and velocities
        _scaledPositions[index] = GLKVector2MultiplyScalar(particle->position, MULTIPLIER);
        _scaledVelocities[index] = GLKVector2MultiplyScalar(particle->velocity, MULTIPLIER);
        
        // Reset deltas
        _delta[index] = GLKVector2Make(0, 0);
    }
    for (int index : _activeParticles) {
        
        FLSParticle *particle = _liquid[index];
        
        findNeighbors(particle);
        
        // Calculate pressure
        float p = 0.0f;
        float pnear = 0.0f;
        for (int a = 0; a < particle->neighborCount; a++) {
            
            GLKVector2 relativePosition = GLKVector2Subtract(_scaledPositions[particle->neighbors[a]], _scaledPositions[index]);
            float distanceSq = relativePosition.v[0] * relativePosition.v[0] + relativePosition.v[1] * relativePosition.v[1];
            
            //within idealRad check
            if (distanceSq < IDEAL_RADIUS_SQ) {
                particle->distances[a] = sqrtf(distanceSq);
                //if (particle.distances[a] < Settings.EPSILON) particle.distances[a] = IDEAL_RADIUS - .01f;
                float oneminusq = 1.0f - (particle->distances[a] / IDEAL_RADIUS);
                p = (p + oneminusq * oneminusq);
                pnear = (pnear + oneminusq * oneminusq * oneminusq);
            }
            else {
                particle->distances[a] = MAXFLOAT;
            }
        }
        
        // Apply forces
        float pressure = (p - 5.0f) / 2.0f; //normal pressure term
        float presnear = pnear / 2.0f; //near particles term
        GLKVector2 change = GLKVector2Make(0, 0);
        for (int a = 0; a < particle->neighborCount; a++)
        {
            GLKVector2 relativePosition = GLKVector2Subtract(_scaledPositions[particle->neighbors[a]], _scaledPositions[index]);
            
            if (particle->distances[a] < IDEAL_RADIUS)
            {
                float q = particle->distances[a] / IDEAL_RADIUS;
                float oneminusq = 1.0f - q;
                float factor = oneminusq * (pressure + presnear * oneminusq) / (2.0F * particle->distances[a]);
                GLKVector2 d = GLKVector2MultiplyScalar(relativePosition, factor);
                GLKVector2 relativeVelocity = GLKVector2Subtract(_scaledVelocities[particle->neighbors[a]], _scaledVelocities[index]);
                factor = VISCOSITY * oneminusq * DT;
                d = GLKVector2Subtract(d, GLKVector2MultiplyScalar(relativeVelocity, factor));
                _delta[particle->neighbors[a]] = GLKVector2Add(_delta[particle->neighbors[a]], d);
                change = GLKVector2Subtract(change, d);
            }
        }
        _delta[index] = GLKVector2Add(_delta[index], change);
    }
    
    // Move particles
    for (int index : _activeParticles) {
        
        FLSParticle *particle = _liquid[index];
        
        particle->position = GLKVector2Add(particle->position, GLKVector2MultiplyScalar(_delta[index], 1 / MULTIPLIER));
        particle->velocity = GLKVector2Add(particle->velocity, GLKVector2MultiplyScalar(_delta[index], 1 / (MULTIPLIER * DT)));
        
        // Update particle cell
        int x = getGridX(particle->position.x);
        int y = getGridY(particle->position.y);
        
        if (particle->ci == x && particle->cj == y)
        continue;
        else {
            
            _grid.at(particle->ci).at(particle->cj).erase(index);
            
            if (_grid.at(particle->ci).at(particle->cj).empty()) {
                
                _grid.at(particle->ci).erase(particle->cj);
                
                if (_grid.at(particle->ci).empty()) {
                    _grid.erase(particle->ci);
                }
            }
            
            if (_grid.find(x) == _grid.end())
            _grid.insert(make_pair(x, unordered_map<size_t, unordered_set<size_t>>()));
            if (_grid.at(x).find(y) == _grid.at(x).end())
            _grid.at(x).insert(make_pair(y, unordered_set<size_t>()));
            _grid.at(x).at(y).insert(index);
            particle->ci = x;
            particle->cj = y;
        }
    }
}
void findNeighbors(FLSParticle *particle) {
    particle->neighborCount = 0;
    
    for (int nx = -1; nx < 2; nx++) {
        
        for (int ny = -1; ny < 2; ny++) {
            
            int x = particle->ci + nx;
            int y = particle->cj + ny;
            //if (grid.TryGetValue(x, out gridX) && gridX.TryGetValue(y, out gridY)) {
            if (_grid.find(x) != _grid.end()) {
                
                unordered_map<size_t, unordered_set<size_t>> &gridX = _grid.at(x);
                if (gridX.find(y) != gridX.end()) {
                    unordered_set<size_t> &gridY = gridX.at(y);
                    
                    for (size_t neighbourIndex : gridY) {
                        
                        if (neighbourIndex != particle->index) {
                            
                            particle->neighbors[particle->neighborCount] = neighbourIndex;
                            particle->neighborCount++;
                            
                            if (particle->neighborCount >= MAX_NEIGHBORS)
                            return;
                        }
                    }
                }
            }
        }
    }
}
int getGridX(float x) {
    return (int)floorf(x / CELL_SIZE);
}
int getGridY(float y) {
    return (int)floorf(y / CELL_SIZE);
}

// End sim stuff.





- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    glClearColor(1, 1, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    
    for (size_t i : _activeParticles) {
        
        [_liquid[i] render];
        
    }
}



#pragma mark - GLKViewControllerDelegate

- (void)update {
    
    //MouseState mouseState = Mouse.GetState();
    
    //_mouse = new Vector2(mouseState.X, mouseState.Y) / _scale;
    //if (mouseState.LeftButton == ButtonState.Pressed)
    
    if (touching)
        createParticle(touchPos.x/scale, (screenSize.y-touchPos.y)/scale);
    
    applyLiquidConstraints();
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    touching = YES;
    
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:[UIApplication sharedApplication].keyWindow];
    
    touchPos = GLKVector2Make(touchLocation.x, touchLocation.y);
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    touching = NO;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:[UIApplication sharedApplication].keyWindow];
    
    touchPos = GLKVector2Make(touchLocation.x, touchLocation.y);
}

@end