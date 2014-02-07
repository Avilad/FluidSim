//
//  FLSLiquid.m
//  FluidSim
//
//  Created by SlEePlEs5 on 2/4/14.
//  Copyright (c) 2014 SlEePlEs5. All rights reserved.
//

#import "FLSLiquid.h"
#import "FLSLiquidParticleShader.h"
#import <dispatch/dispatch.h>
#import <unordered_set>
#import <set>
#import <unordered_map>

using namespace std;

#define MAX_PARTICLES 1000
#define RADIUS 0.6f
//#define VISCOSITY 0.004f
#define VISCOSITY 0.000f
#define IDEAL_RADIUS 50.0f

typedef struct FLSParticle
{
    float distances[MAX_PARTICLES];
    int neighbors[MAX_PARTICLES];
    
    GLKVector2 position;
    GLKVector2 velocity;
    BOOL alive;
    int index;
    
    float p;
    float pnear;
    
    int neighborCount;
    int ci;
    int cj;
}
FLSParticle;


@interface FLSLiquid()

// Properties
@property (strong) FLSLiquidParticleShader *liquidParticleShader;

@end


@implementation FLSLiquid


const float DT = 1.0f / 60.0f;

const float MULTIPLIER = IDEAL_RADIUS / RADIUS;
const float IDEAL_RADIUS_SQ = IDEAL_RADIUS * IDEAL_RADIUS;

const float CELL_SIZE = 0.5f;

const int MAX_NEIGHBORS = 75;

const int PARTICLE_ADD_RATE = 4;

float retinaScale;

GLKVector2 _delta[MAX_PARTICLES];
GLKVector2 _scaledPositions[MAX_PARTICLES];
GLKVector2 _scaledVelocities[MAX_PARTICLES];

GLKVector2 _screenSize;

FLSParticle _liquid[MAX_PARTICLES];
GLKVector2 _particlePositions[MAX_PARTICLES];
set<size_t> _activeParticles;

unordered_map<size_t, unordered_map<size_t, unordered_set<size_t>>> _grid;

dispatch_queue_t _globalQueue;
dispatch_queue_t _accumulatedDeltaQueue;

dispatch_group_t _prepareSimGroup;
dispatch_group_t _calcPressureGroup;
dispatch_group_t _calcForceGroup;
dispatch_group_t _moveParticleGroup;

void createParticle(float posX, float posY) {
    
    FLSParticle *someInactiveParticles[PARTICLE_ADD_RATE];
    
    int count = 0;
    
    for (size_t i = 0; i < MAX_PARTICLES; i++) {
        if (!_liquid[i].alive) {
            someInactiveParticles[count] = &_liquid[i];
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
            _particlePositions[particle->index] = particle->position;
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
void prepareSimulationForParticle(size_t index) {
    
    FLSParticle *particle = &_liquid[index];
    
    // Find neighbors
    findNeighbors(*particle);
    
    // Scale positions and velocities
    _scaledPositions[index] = GLKVector2MultiplyScalar(particle->position, MULTIPLIER);
    _scaledVelocities[index] = GLKVector2MultiplyScalar(particle->velocity, MULTIPLIER);
    
    // Reset deltas
    _delta[index] = GLKVector2Make(0, 0);
    
    // Reset pressures
    particle->p = 0;
    particle->pnear = 0;
    
}
void calculatePressureForParticle(size_t index) {
    
    FLSParticle *particle = &_liquid[index];
    
    // Calculate pressure
    for (int a = 0; a < particle->neighborCount; a++) {
        
        GLKVector2 relativePosition = GLKVector2Subtract(_scaledPositions[particle->neighbors[a]], _scaledPositions[index]);
        float distanceSq = relativePosition.v[0] * relativePosition.v[0] + relativePosition.v[1] * relativePosition.v[1];
        
        //within idealRad check
        if (distanceSq < IDEAL_RADIUS_SQ) {
            particle->distances[a] = sqrtf(distanceSq);
            //if (particle.distances[a] < Settings.EPSILON) particle.distances[a] = IDEAL_RADIUS - .01f;
            float oneminusq = 1.0f - (particle->distances[a] / IDEAL_RADIUS);
            particle->p = (particle->p + oneminusq * oneminusq);
            particle->pnear = (particle->pnear + oneminusq * oneminusq * oneminusq);
        }
        else {
            particle->distances[a] = MAXFLOAT;
        }
    }
    
}
void calculateForceForParticle(int index, GLKVector2 *accumulatedDelta) {
    
    FLSParticle *particle = &_liquid[index];
    
    // Apply forces
    float pressure = (particle->p - 5.0f) / 2.0f; //normal pressure term
    float presnear = particle->pnear / 2.0f; //near particles term
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
            accumulatedDelta[particle->neighbors[a]] = GLKVector2Add(accumulatedDelta[particle->neighbors[a]], d);
            change = GLKVector2Subtract(change, d);
        }
    }
    accumulatedDelta[index] = GLKVector2Add(accumulatedDelta[index], change);

}
void moveParticle(int index) {
    
    FLSParticle *particle = &_liquid[index];
    
    particle->position = GLKVector2Add(particle->position, GLKVector2MultiplyScalar(_delta[index], 1 / MULTIPLIER));
    _particlePositions[particle->index] = particle->position;
    particle->velocity = GLKVector2Add(particle->velocity, GLKVector2MultiplyScalar(_delta[index], 1 / (MULTIPLIER * DT)));
    
    // Update particle cell
    int x = getGridX(particle->position.x);
    int y = getGridY(particle->position.y);
    
    if (particle->ci == x && particle->cj == y)
        return;
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
void findNeighbors(FLSParticle &particle) {
    particle.neighborCount = 0;
    
    for (int nx = -1; nx < 2; nx++) {
        
        for (int ny = -1; ny < 2; ny++) {
            
            int x = particle.ci + nx;
            int y = particle.cj + ny;
            //if (grid.TryGetValue(x, out gridX) && gridX.TryGetValue(y, out gridY)) {
            if (_grid.find(x) != _grid.end()) {
                
                unordered_map<size_t, unordered_set<size_t>> &gridX = _grid.at(x);
                if (gridX.find(y) != gridX.end()) {
                    unordered_set<size_t> &gridY = gridX.at(y);
                    
                    for (size_t neighbourIndex : gridY) {
                        
                        if (neighbourIndex != particle.index) {
                            
                            particle.neighbors[particle.neighborCount] = (int)neighbourIndex;
                            particle.neighborCount++;
                            
                            if (particle.neighborCount >= MAX_NEIGHBORS)
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

-(id)initWithScreenSize:(GLKVector2)screenSize {
    
    if ((self = [super init])) {
        
        _screenSize = screenSize;
        
        _globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        _accumulatedDeltaQueue = dispatch_queue_create("com.sleeples5.AccumulatedDeltaQueue", NULL);
        
        _prepareSimGroup = dispatch_group_create();
        _calcPressureGroup = dispatch_group_create();
        _calcForceGroup = dispatch_group_create();
        _moveParticleGroup = dispatch_group_create();
        
        if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
            ([UIScreen mainScreen].scale == 2.0))
        {
            retinaScale = 2.0f;
        } else {
            retinaScale = 1.0f;
        }
        
        [self loadShader];
        
        _activeParticles = set<size_t>();
        
        _grid = unordered_map<size_t, unordered_map<size_t, unordered_set<size_t>>>();
        
        for (int i = 0; i < MAX_PARTICLES; i++)
        {
            
            // Fill _liquid Array
            
            FLSParticle particle = {
                .distances = {0},
                .neighbors = {0},
                .position = GLKVector2Make(0, 0),
                .velocity = GLKVector2Make(0, 0),
                .alive = NO,
                .index = i,
                .neighborCount = 0,
                .ci = 0,
                .cj = 0
            };
            _liquid[i] = particle;
            
            // Fill _particlePositions Array
            _particlePositions[i] = particle.position;
            
        }
        
        [self setupVBO];
        
    }
    return self;
    
}
-(void)update {
    
    for (size_t index : _activeParticles) {
        dispatch_group_async(_prepareSimGroup, _globalQueue, ^{
            prepareSimulationForParticle(index);
        });
    }
    dispatch_group_wait(_prepareSimGroup, DISPATCH_TIME_FOREVER);
    for (size_t index : _activeParticles) {
        dispatch_group_async(_calcPressureGroup, _globalQueue, ^{
            calculatePressureForParticle(index);
        });
    }
    dispatch_group_wait(_calcPressureGroup, DISPATCH_TIME_FOREVER);
    for (size_t index : _activeParticles) {
        dispatch_group_async(_calcForceGroup, _globalQueue, ^{
            
            GLKVector2 accumulatedDelta[MAX_PARTICLES] = {0};
            calculateForceForParticle(index, accumulatedDelta);
            GLKVector2 *accumulatedDeltaAsPointer = accumulatedDelta;
            dispatch_sync(_accumulatedDeltaQueue, ^{
                for (size_t index : _activeParticles) {
                    _delta[index] = GLKVector2Add(_delta[index], accumulatedDeltaAsPointer[index]);
                }
            });
            
        });
    }
    dispatch_group_wait(_calcForceGroup, DISPATCH_TIME_FOREVER);
    for (size_t index : _activeParticles) {
        
        moveParticle(index);
        
    }
    //applyLiquidConstraints();
    
}
-(void)render {
    
    // 1
    // Create Projection Matrix
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeScale(2*scale/_screenSize.x, 2*scale/_screenSize.y, 1.0f);
    
    // 2
    // Uniforms
    glUniformMatrix4fv(self.liquidParticleShader.uProjectionMatrix, 1, 0, projectionMatrix.m);
    glUniform1f(self.liquidParticleShader.uRetinaScale, retinaScale);
    
    
    // 2.5
    // Re-send vertex position data to GPU
    glBufferData(GL_ARRAY_BUFFER, sizeof(_particlePositions), _particlePositions, GL_DYNAMIC_DRAW);
    
    
    
    // 3
    // Attributes
    glEnableVertexAttribArray(self.liquidParticleShader.aPosition);
    glVertexAttribPointer(self.liquidParticleShader.aPosition,                // Set pointer
                          2,                                        // One component per particle
                          GL_FLOAT,                                 // Data is floating point type
                          GL_FALSE,                                 // No fixed point scaling
                          sizeof(GLKVector2),                         // No gaps in data
                          0);      // Start from "position" offset within bound buffer
    
    // 4
    // Draw particles
    glDrawArrays(GL_POINTS, 0, _activeParticles.size());
    glDisableVertexAttribArray(self.liquidParticleShader.aPosition);
    
}
#pragma mark - Load Shader

-(void)loadShader
{
    self.liquidParticleShader = [[FLSLiquidParticleShader alloc] init];
    [self.liquidParticleShader loadShader];
    glUseProgram(self.liquidParticleShader.program);
}
-(void)setupVBO {
    
    // Create Vertex Buffer Object (VBO)
    GLuint particleBuffer = 0;
    glGenBuffers(1, &particleBuffer);                   // Generate particle buffer
    glBindBuffer(GL_ARRAY_BUFFER, particleBuffer);      // Bind particle buffer
    glBufferData(                                       // Fill bound buffer with particles
                 GL_ARRAY_BUFFER,                       // Buffer target
                 sizeof(_particlePositions),                       // Buffer data size
                 _particlePositions,                               // Buffer data pointer
                 GL_DYNAMIC_DRAW);                      // Usage - Data changes
    
}
-(void)createParticleWithPosX:(float)posX posY:(float)posY {
    
    createParticle((posX - _screenSize.x/2)/scale, (_screenSize.y/2 - posY)/scale);
    
}

@end
