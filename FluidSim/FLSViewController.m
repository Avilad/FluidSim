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

NSMutableArray *_liquid;
NSMutableIndexSet *_activeParticles;

NSMutableDictionary *_grid;

BOOL touching = false;
GLKVector2 touchPos;
GLKVector2 screenSize;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    
    
    
    
    
    _activeParticles = [NSMutableIndexSet indexSet];
    _liquid = [NSMutableArray arrayWithCapacity:MAX_PARTICLES];
    
    _grid = [NSMutableDictionary dictionaryWithCapacity:32];
    
    for (int i = 0; i < MAX_PARTICLES; i++)
    {
        
        // Fill _liquid Array
        
        FLSParticle *particle = [[FLSParticle alloc] initWithFile:@"Particle.png" effect:self.effect];
        particle.position = GLKVector2Make(0, 0);
        particle.velocity = GLKVector2Make(0, 0);
        particle.alive = NO;
        particle.index = i;
        [_liquid addObject:particle];
        
        srand(time(0));
        
    }
    
}

- (void)createParticleWithPosX:(float)posX posY:(float)posY {
    
    NSMutableArray *inactiveParticles = [NSMutableArray arrayWithCapacity:MAX_PARTICLES];
    for (FLSParticle *particle in _liquid) {
        if (!particle.alive)
            [inactiveParticles addObject:particle];
    }
    
    if ([inactiveParticles count] >= PARTICLE_ADD_RATE) {
        
        NSRange firstFew;
        firstFew.location = 0;
        firstFew.length = PARTICLE_ADD_RATE;
        inactiveParticles = [NSMutableArray arrayWithArray:[inactiveParticles subarrayWithRange:firstFew]];
        
        for (FLSParticle *particle in inactiveParticles)
        {
            if ([_activeParticles count] < MAX_PARTICLES)
            {
                GLKVector2 jitter = GLKVector2Make(((((float)rand())/((float)RAND_MAX))*2)-1, (((float)rand())/((float)RAND_MAX))-0.5);
                
                particle.position = GLKVector2Add(GLKVector2Make(posX, posY), jitter);
                particle.velocity = GLKVector2Make(0, 0);
                particle.alive = true;
                particle.ci = getGridX(particle.position.x);
                particle.cj = getGridY(particle.position.y);
                
                // Create grid cell if necessary
                if (![[_grid allKeys] containsObject:[NSNumber numberWithInteger:particle.ci]])
                    [_grid setObject:[NSMutableDictionary dictionaryWithCapacity:32] forKey:[NSNumber numberWithInteger:particle.ci]];
                if (![[[_grid objectForKey:[NSNumber numberWithInteger:particle.ci]] allKeys] containsObject:[NSNumber numberWithInteger:particle.cj]])
                    [[_grid objectForKey:[NSNumber numberWithInteger:particle.ci]] setObject:[NSMutableSet setWithCapacity:32] forKey:[NSNumber numberWithInteger:particle.cj]];
                
                [[[_grid objectForKey:[NSNumber numberWithInteger:particle.ci]] objectForKey:[NSNumber numberWithInteger:particle.cj]] addObject:[NSNumber numberWithInteger:particle.index]];
                
                [_activeParticles addIndex:particle.index];
            }
        }
    }
}

- (void)applyLiquidConstraints {
    
    NSUInteger index=[_activeParticles firstIndex];
    
    while(index != NSNotFound)
    {
        
        // Prepare simulation
        
        FLSParticle *particle = [_liquid objectAtIndex:index];
        
        // Scale positions and velocities
        _scaledPositions[index] = GLKVector2MultiplyScalar(particle.position, MULTIPLIER);
        _scaledVelocities[index] = GLKVector2MultiplyScalar(particle.velocity, MULTIPLIER);
        
        // Reset deltas
        _delta[index] = GLKVector2Make(0, 0);
        
        index = [_activeParticles indexGreaterThanIndex:index];
        
    }
    
    index=[_activeParticles firstIndex];
    
    while(index != NSNotFound)
    {
        
        
        // Calculate pressure
        
        FLSParticle *particle = [_liquid objectAtIndex:index];
        
        [self findNeighbors:particle];
        
        float p = 0.0f;
        float pnear = 0.0f;
        
        for (int a = 0; a < particle.neighborCount; a++)
        {
            GLKVector2 relativePosition = GLKVector2Subtract(_scaledPositions[particle->neighbors[a]], _scaledPositions[index]);
            float distanceSq = relativePosition.v[0] * relativePosition.v[0] + relativePosition.v[1] * relativePosition.v[1]; // THIS WAS v[0], CAUSING ALL THE ERRORS. FML
            
            //within idealRad check
            if (distanceSq < IDEAL_RADIUS_SQ)
            {
                particle->distances[a] = sqrt(distanceSq);
                //if (particle.distances[a] < Settings.EPSILON) particle.distances[a] = IDEAL_RADIUS - .01f;
                float oneminusq = 1.0f - (particle->distances[a] / IDEAL_RADIUS);
                p = (p + oneminusq * oneminusq);
                pnear = (pnear + oneminusq * oneminusq * oneminusq);
                
                if (!(p <= 50 || p >= -50)) {
                    NSLog(@"here");
                }
                
            }
            else
            {
                particle->distances[a] = MAXFLOAT;
            }
        }
        
        // Apply forces
        
        float pressure = (p - 5.0f) / 2.0f; //normal pressure term
        float presnear = pnear / 2.0f; //near particles term
        
        GLKVector2 change = GLKVector2Make(0, 0);
        for (int a = 0; a < particle.neighborCount; a++)
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
        
        index = [_activeParticles indexGreaterThanIndex:index];
        
    }
    
    // Move particles
    
    index=[_activeParticles firstIndex];
    
    while(index != NSNotFound)
    {
        
        FLSParticle *particle = [_liquid objectAtIndex:index];
        
        particle.position = GLKVector2Add(particle.position, GLKVector2DivideScalar(_delta[index], MULTIPLIER));
        particle.velocity = GLKVector2Add(particle.velocity, GLKVector2DivideScalar(_delta[index], MULTIPLIER * DT));
        
        // Update particle cell
        
        int x = getGridX(particle.position.x);
        int y = getGridY(particle.position.x);
        
        if (particle.ci == x && particle.cj == y) {
            
            index = [_activeParticles indexGreaterThanIndex:index];
            continue;

        }
        else
        {
            
            [[[_grid objectForKey:[NSNumber numberWithInteger:particle.ci]] objectForKey:[NSNumber numberWithInteger:particle.cj]] removeObject:[NSNumber numberWithInteger:index]];
            
            if ([[[_grid objectForKey:[NSNumber numberWithInteger:particle.ci]] objectForKey:[NSNumber numberWithInteger:particle.cj]] count] == 0)
            {
                [[_grid objectForKey:[NSNumber numberWithInteger:particle.ci]] removeObjectForKey:[NSNumber numberWithInteger:particle.cj]];
                
                if ([[_grid objectForKey:[NSNumber numberWithInteger:particle.ci]] count] == 0)
                {
                    [_grid removeObjectForKey:[NSNumber numberWithInteger:particle.ci]];
                }
            }
            
            if (![[_grid allKeys] containsObject:[NSNumber numberWithInteger:x]])
                [_grid setObject:[NSMutableDictionary dictionaryWithCapacity:32] forKey:[NSNumber numberWithInteger:x]];
            if (![[[_grid objectForKey:[NSNumber numberWithInteger:x]] allKeys] containsObject:[NSNumber numberWithInteger:y]])
                [[_grid objectForKey:[NSNumber numberWithInteger:x]] setObject:[NSMutableSet setWithCapacity:32] forKey:[NSNumber numberWithInteger:y]];
            
            [[[_grid objectForKey:[NSNumber numberWithInteger:x]] objectForKey:[NSNumber numberWithInteger:y]] addObject:[NSNumber numberWithInteger:index]];
            
            particle.ci = x;
            particle.cj = y;
            
        }
        
        index = [_activeParticles indexGreaterThanIndex:index];
        
    }
    
}

- (void)findNeighbors:(FLSParticle*)particle
{
    particle.neighborCount = 0;
    NSSet *gridY;
    
    for (int nx = -1; nx < 2; nx++)
    {
        for (int ny = -1; ny < 2; ny++)
        {
            int x = particle.ci + nx;
            int y = particle.cj + ny;
            
            gridY = [[_grid objectForKey:[NSNumber numberWithInteger:x]] objectForKey:[NSNumber numberWithInteger:y]];
            
            if (gridY != nil) {
                
                for (NSNumber *gridYa in gridY)
                {
                    
                    int particleIndex = [gridYa integerValue];
                    
                    if (particleIndex != particle.index)
                    {
                        particle->neighbors[particle.neighborCount] = particleIndex;
                        particle.neighborCount++;
                        
                        if (particle.neighborCount >= MAX_NEIGHBORS)
                        return;
                    }
                }
            }
        }
    }
}

int getGridX(float x) { return (int)floorf(x / CELL_SIZE); }
int getGridY(float y) { return (int)floorf(y / CELL_SIZE); }


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
    
    NSUInteger i=[_activeParticles firstIndex];
    
    while(i != NSNotFound)
    {
        
        [[_liquid objectAtIndex:i] render];
        i = [_activeParticles indexGreaterThanIndex:i];
        
    }
}



#pragma mark - GLKViewControllerDelegate

- (void)update {
    
    //MouseState mouseState = Mouse.GetState();
    
    //_mouse = new Vector2(mouseState.X, mouseState.Y) / _scale;
    //if (mouseState.LeftButton == ButtonState.Pressed)
    
    if (touching)
        [self createParticleWithPosX:touchPos.x/scale posY:(screenSize.y-touchPos.y)/scale];
    
    [self applyLiquidConstraints];
    
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