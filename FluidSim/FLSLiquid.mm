
//
//  FLSLiquid.m
//  FluidSim
//
//  Created by Avilad on 2/4/14.
//  Copyright (c) 2014 Avilad. All rights reserved.
//

#import "FLSLiquid.h"
#import "FLSLiquidParticleShader.h"
#import "FLSLiquidPostShader.h"
#import <CoreMotion/CoreMotion.h>
#import <unordered_set>
#import <vector>
#import <cmath>

#import "FLSGlobalSettings.h"

using namespace std;

//#define FLS_DEBUG

#define MAX_PARTICLES 750
#define RADIUS 0.8f
#define IDEAL_RADIUS 50.0f
#define MULTIPLIER (IDEAL_RADIUS / RADIUS)
#define IDEAL_RADIUS_SQ (IDEAL_RADIUS * IDEAL_RADIUS)
#define CELL_SIZE 0.8f
#define MAX_PRESSURE 0.8f
#define MAX_PRESSURE_NEAR 1.6f
#define PARTICLE_BOUNCINESS 0.2f
#define PARTICLE_BOUNCE_DAMPENING 0.95f

#define PARTICLE_ADD_REMOVE_RATE 4

#define GRAVITY_POLL_FREQUENCY (1.0f / 30.0f)
#define DT (1.0f / 120.0f)
// Probably shouldn't go higher than 1/45, or things blow up rather spectacularly.
// Anything lower is fine though.

typedef struct FLSParticle
{
    float distances[MAX_PARTICLES];
    int neighbors[MAX_PARTICLES];
    
    GLKVector2 position;
    GLKVector2 velocity;
    BOOL alive;
    int index;
    
    float collisionFuzz;
    
    int neighborCount;
    int ci;
    int cj;
}
FLSParticle;
typedef struct FLSGLParticle
{
    GLKVector2 position;
    GLKVector2 velocity;
}
FLSGLParticle;


@interface FLSLiquid()

// Properties
@property (strong) FLSLiquidParticleShader *liquidParticleShader;
@property (strong) FLSLiquidPostShader *liquidPostShader;

@end


@implementation FLSLiquid

GLKVector2 lowestGridCell;
GLKVector2 gridSize;

float retinaScale;

GLuint postFramebuffer;
GLuint postTexture;
GLuint postDepthBuffer;
GLuint particleBuffer;
GLuint postTextureVBO;
GLint defaultFBO;

GLKTextureInfo* particleTexture;
GLKTextureInfo* postEffectTexture;

GLKVector2 _delta[MAX_PARTICLES];
GLKVector2 _scaledPositions[MAX_PARTICLES];
GLKVector2 _scaledVelocities[MAX_PARTICLES];

GLKVector2 _screenSize;
GLKVector2 _worldBounds;

GLKVector2 _gravity;
GLKVector2 _glGravity;
CMMotionManager *motionManager;

FLSParticle _liquid[MAX_PARTICLES];
FLSGLParticle _glParticles[MAX_PARTICLES];
unordered_set<size_t> _activeParticles;
GLushort _activeParticlesGL[MAX_PARTICLES];

vector<vector<unordered_set<size_t>>> _grid;

//float allTimeTopVel = 0.0f;

void createParticles(float posX, float posY) {
    
    FLSParticle *someInactiveParticles[PARTICLE_ADD_REMOVE_RATE];
    
    int count = 0;
    
    for (size_t i = 0; i < MAX_PARTICLES; i++) {
        if (!_liquid[i].alive) {
            someInactiveParticles[count] = &_liquid[i];
            count++;
        }
        if (count == PARTICLE_ADD_REMOVE_RATE) {
            break;
        }
    }
    
    for (size_t i = 0; i < 4; i++)
    {
        if (_activeParticles.size() < MAX_PARTICLES)
        {
            
            FLSParticle *particle = someInactiveParticles[i];
            
            GLKVector2 jitter = GLKVector2Make(((((float)rand())/((float)RAND_MAX))/2)-0.25, (((float)rand())/((float)RAND_MAX)/2)-0.25);
            
            particle->position = GLKVector2Add(GLKVector2Make(posX, posY), jitter);
            _glParticles[particle->index].position = particle->position;
            _glParticles[particle->index].velocity = particle->velocity;
            particle->velocity = GLKVector2Make(0, 0);
            particle->alive = true;
            
            particle->collisionFuzz = ((float)rand())/((float)RAND_MAX) / 5.0f;
            
            particle->ci = getGridX(particle->position.x);
            particle->cj = getGridY(particle->position.y);
            
            _grid[particle->ci][particle->cj].insert(particle->index);
            
            _activeParticles.insert(particle->index);
            
        }
        else {
            break;
        }
    }
    int i = 0;
    for (size_t index : _activeParticles) {
        _activeParticlesGL[i] = (GLushort)index;
        i++;
    }
}
void removeParticles(float posX, float posY) {
    
    GLKVector2 removalPosition = GLKVector2Make(posX, posY);
    
    int ci = getGridX(posX);
    int cj = getGridY(posY);
    
    vector<size_t> candidatesForRemoval = vector<size_t>();
    
    for (int nx = -1; nx < 2; nx++) {
        
        int x = ci + nx;
        if (x < 0 || x > gridSize.x - 1)
            continue;
        
        for (int ny = -1; ny < 2; ny++) {
            
            int y = cj + ny;
            if (y < 0 || y > gridSize.y - 1)
                continue;
            
            unordered_set<size_t> &gridSquare = _grid[x][y];
            
            for (size_t index : gridSquare) {
                
                FLSParticle *particle = &_liquid[index];
                
                float distance = GLKVector2Distance(particle->position, removalPosition);
                
                if (distance <= RADIUS) {
                    candidatesForRemoval.push_back(index);
                }
            }
        }
    }
    for (size_t i = 0; i < PARTICLE_ADD_REMOVE_RATE; i++) {
        if (candidatesForRemoval.empty())
            break;
        int randomIndex = rand() % candidatesForRemoval.size();
        swap(candidatesForRemoval[randomIndex], candidatesForRemoval.back());
        size_t particleToRemoveIndex = candidatesForRemoval.back();
        
        FLSParticle *particleToRemove = &_liquid[particleToRemoveIndex];
        int neighborCount = particleToRemove->neighborCount;
        int neighbors[neighborCount];
        
        for (int i = 0; i < neighborCount; i++) {
            neighbors[i] = particleToRemove->neighbors[i];
        }
        
        _grid[particleToRemove->ci][particleToRemove->cj].erase(particleToRemoveIndex);
        
        *particleToRemove = {
            .distances = {0},
            .neighbors = {0},
            .position = GLKVector2Make(0, 0),
            .velocity = GLKVector2Make(0, 0),
            .alive = NO,
            .index = (int)particleToRemoveIndex,
            .collisionFuzz = 0.0f,
            .neighborCount = 0,
            .ci = 0,
            .cj = 0
        };
        
        _activeParticles.erase(particleToRemoveIndex);
        
        for (int i = 0; i < neighborCount; i++) {
            findNeighbors(_liquid[neighbors[i]]);
        }
        
        candidatesForRemoval.pop_back();
    }
    int i = 0;
    for (size_t index : _activeParticles) {
        _activeParticlesGL[i] = (GLushort)index;
        i++;
    }
}
void flingParticles(float posX, float posY, float velX, float velY) {
    
    GLKVector2 flingPosition = GLKVector2Make(posX, posY);
    
    int ci = getGridX(posX);
    int cj = getGridY(posY);
    
    unordered_set<size_t> candidatesForFling = unordered_set<size_t>();
    
    for (int nx = -2; nx < 3; nx++) {
        
        int x = ci + nx;
        if (x < 0 || x > gridSize.x - 1)
            continue;
        
        for (int ny = -2; ny < 3; ny++) {
            
            int y = cj + ny;
            if (y < 0 || y > gridSize.y - 1)
                continue;
            
            unordered_set<size_t> &gridSquare = _grid[x][y];
            
            for (size_t index : gridSquare) {
                
                FLSParticle *particle = &_liquid[index];
                
                float distance = GLKVector2Distance(particle->position, flingPosition);
                
                if (distance <= 1.5*RADIUS) {
                    candidatesForFling.insert(index);
                }
            }
        }
    }
    for (size_t index : candidatesForFling) {
        
        FLSParticle *particle = &_liquid[index];
        
        float distance = GLKVector2Distance(particle->position, flingPosition);
        float flingMultiplier = ((1.5*RADIUS) - distance) / (3*RADIUS);
        
        GLKVector2 currentVel = GLKVector2MakeWithArray(particle->velocity.v);
        
        particle->velocity = GLKVector2Make(currentVel.x * (1 - flingMultiplier) + velX * flingMultiplier,
                                            currentVel.y * (1 - flingMultiplier) + velY * flingMultiplier);
        
//        NSLog(@"Current Velocity: (%.3f, %.3f)", currentVel.x, currentVel.y);
//        NSLog(@"Fling Velocity: (%.3f, %.3f)", velX, velY);
        
    }
}
void applyLiquidConstraints() {
    
    // Prepare simulation
    for (size_t index : _activeParticles) {
        
        FLSParticle *particle = &_liquid[index];
        
        // Scale positions and velocities
        _scaledPositions[index] = GLKVector2MultiplyScalar(particle->position, MULTIPLIER);
        _scaledVelocities[index] = GLKVector2MultiplyScalar(particle->velocity, MULTIPLIER);
        
        // Reset deltas
        _delta[index] = GLKVector2Make(0.0f, 0.0f);
    }
    for (size_t index : _activeParticles) {
        
        FLSParticle *particle = &_liquid[index];
        
        findNeighbors(*particle);
        
        // Calculate pressure
        float p = 0.0f;
        float pnear = 0.0f;
        for (int a = 0; a < particle->neighborCount; a++) {
            
            GLKVector2 relativePosition = GLKVector2Subtract(_scaledPositions[particle->neighbors[a]], _scaledPositions[index]);
            float distanceSq = relativePosition.x * relativePosition.x + relativePosition.y * relativePosition.y;
            
            //within idealRad check
            if (distanceSq < IDEAL_RADIUS_SQ) {
                particle->distances[a] = sqrtf(distanceSq);
                
                if (particle->distances[a] < FLT_EPSILON) {
                    particle->distances[a] = IDEAL_RADIUS - .01f;
                }
                
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
        
        pressure = pressure > MAX_PRESSURE ? MAX_PRESSURE : pressure;
        presnear = presnear > MAX_PRESSURE_NEAR ? MAX_PRESSURE_NEAR : presnear;
        
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
                factor = feel_viscosity * oneminusq * DT;
                d = GLKVector2Subtract(d, GLKVector2MultiplyScalar(relativeVelocity, factor));
                _delta[particle->neighbors[a]] = GLKVector2Add(_delta[particle->neighbors[a]], d);
                change = GLKVector2Subtract(change, d);
            }
        }
        _delta[index] = GLKVector2Add(_delta[index], change);
        
        particle->velocity = GLKVector2Add(particle->velocity, GLKVector2MultiplyScalar(_gravity, DT * 60.0f));
        
    }
    
    // Scale deltas
    for (size_t index : _activeParticles) {
        
        _delta[index] = GLKVector2DivideScalar(_delta[index], MULTIPLIER);
        
    }
    
    // Move particles
    
    GLKVector2 topVelocity = GLKVector2Make(0.0f, 0.0f);
    float topVelSq = topVelocity.x * topVelocity.x + topVelocity.y * topVelocity.y;
    
    for (size_t index : _activeParticles) {
        
        FLSParticle *particle = &_liquid[index];
        
        // Update velocity
        particle->velocity = GLKVector2Add(particle->velocity, _delta[index]);
        
        if (particle->velocity.x * particle->velocity.x + particle->velocity.y * particle->velocity.y > topVelSq) {
            topVelSq = particle->velocity.x * particle->velocity.x + particle->velocity.y * particle->velocity.y;
            topVelocity = GLKVector2Make(particle->velocity.x, particle->velocity.y);
        }
        
        // Update position
        particle->position = GLKVector2Add(particle->position, _delta[index]);
        particle->position = GLKVector2Add(particle->position, GLKVector2MultiplyScalar(particle->velocity, DT * 60.0f));
        
    }
//    float topVel = GLKVector2Length(topVelocity);
//    if (topVel > allTimeTopVel) {
//        allTimeTopVel = topVel;
//        NSLog(@"%f", allTimeTopVel);
//    }
    
    // Collisions
    for (size_t index : _activeParticles) {
        
        FLSParticle *particle = &_liquid[index];
        
        if (particle->position.x < -_worldBounds.x + particle->collisionFuzz) {
            particle->position.x = -_worldBounds.x + particle->collisionFuzz;
            particle->velocity.x *= -PARTICLE_BOUNCINESS;
            particle->velocity = GLKVector2MultiplyScalar(particle->velocity, PARTICLE_BOUNCE_DAMPENING);
        }
        if (particle->position.x > _worldBounds.x - particle->collisionFuzz) {
            particle->position.x = _worldBounds.x - particle->collisionFuzz;
            particle->velocity.x *= -PARTICLE_BOUNCINESS;
            particle->velocity = GLKVector2MultiplyScalar(particle->velocity, PARTICLE_BOUNCE_DAMPENING);
        }
        if (particle->position.y < -_worldBounds.y + particle->collisionFuzz) {
            particle->position.y = -_worldBounds.y + particle->collisionFuzz;
            particle->velocity.y *= -PARTICLE_BOUNCINESS;
            particle->velocity = GLKVector2MultiplyScalar(particle->velocity, PARTICLE_BOUNCE_DAMPENING);
        }
        if (particle->position.y > _worldBounds.y - particle->collisionFuzz) {
            particle->position.y = _worldBounds.y - particle->collisionFuzz;
            particle->velocity.y *= -PARTICLE_BOUNCINESS;
            particle->velocity = GLKVector2MultiplyScalar(particle->velocity, PARTICLE_BOUNCE_DAMPENING);
        }

        // For GL purposes
        _glParticles[particle->index].position = particle->position;
        _glParticles[particle->index].velocity = GLKVector2Make(fabsf(particle->velocity.x), fabsf(particle->velocity.y));
        
    }
    
    // Update particle cells
    for (size_t index : _activeParticles) {
        
        FLSParticle *particle = &_liquid[index];
        
        int x = getGridX(particle->position.x);
        int y = getGridY(particle->position.y);
        
        if (particle->ci == x && particle->cj == y)
            continue;
        else {
            
            _grid[particle->ci][particle->cj].erase(index);
            
            _grid[x][y].insert(index);
            particle->ci = x;
            particle->cj = y;
        }
        
    }
}
void findNeighbors(FLSParticle &particle) {
    particle.neighborCount = 0;
    
    for (int nx = -1; nx < 2; nx++) {
        
        int x = particle.ci + nx;
        if (x < 0 || x > gridSize.x - 1)
            continue;
        
        for (int ny = -1; ny < 2; ny++) {
            
            int y = particle.cj + ny;
            if (y < 0 || y > gridSize.y - 1)
                continue;
            
            unordered_set<size_t> &gridSquare = _grid[x][y];
            
            for (size_t neighbourIndex : gridSquare) {
                
                if (neighbourIndex != particle.index) {
                    
                    particle.neighbors[particle.neighborCount] = (int)neighbourIndex;
                    particle.neighborCount++;
                    
                }
            }
        }
    }
}
int getGridX(float x) {
    return (int)floorf(x / CELL_SIZE) + (int)lowestGridCell.x;
}
int getGridY(float y) {
    return (int)floorf(y / CELL_SIZE) + (int)lowestGridCell.y;
}

-(id)initWithScreenSize:(GLKVector2)screenSize {
    
    if ((self = [super init])) {
        
        lowestGridCell = GLKVector2Make(0, 0);
        _gravity = GLKVector2Make(0, 0);
        _glGravity = GLKVector2Make(0, 0);
        
        glGetIntegerv(GL_FRAMEBUFFER_BINDING, &defaultFBO);
        
        _screenSize = screenSize;
        
        _worldBounds = GLKVector2Make(_screenSize.x/(2*scale), _screenSize.y/(2*scale));
        
        motionManager = [[CMMotionManager alloc] init];
        motionManager.accelerometerUpdateInterval = GRAVITY_POLL_FREQUENCY;
        
#ifndef FLS_DEBUG
        [motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            
            GLKVector3 gravity3D = GLKVector3Make(accelerometerData.acceleration.x,
                                                  accelerometerData.acceleration.y,
                                                  accelerometerData.acceleration.z);
            
            _gravity = GLKVector2Make(gravity3D.x / 40.0f * feel_gravity, gravity3D.y / 40.0f * feel_gravity);
            
            if ((gravity3D.x * gravity3D.x) + (gravity3D.y * gravity3D.y) + (gravity3D.z * gravity3D.z) > 1.0f) {
                gravity3D = GLKVector3Normalize(gravity3D);
            }
            
            _glGravity = GLKVector2Make(gravity3D.x * 0.5 + _glGravity.x * 0.5,
                                        gravity3D.y * 0.5 + _glGravity.y * 0.5);
            
        }];
#else
        _gravity = GLKVector2Make(0.0f, -0.01f);
//        _gravity = GLKVector2Make(0.00005f, -0.00005f);
#endif
        
        if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        {
            retinaScale = [UIScreen mainScreen].scale;
        } else {
            retinaScale = 1.0f;
        }
        
        [self loadShaders];
        [self loadParticleTexture:@"Particle.png"];
        [self setupRTT];
        
        _activeParticles = unordered_set<size_t>();
        GLKVector2 tmpHighestGridCell = GLKVector2Make(getGridX(_worldBounds.x), getGridY(_worldBounds.y));
        lowestGridCell = GLKVector2Make(-getGridX(-_worldBounds.x), -getGridY(-_worldBounds.y));
        gridSize = GLKVector2Make(tmpHighestGridCell.x + lowestGridCell.x + 1, tmpHighestGridCell.y + lowestGridCell.y + 1);
        
        _grid = vector<vector<unordered_set<size_t>>>(gridSize.x, vector<unordered_set<size_t>>(gridSize.y, unordered_set<size_t>()));
//        _grid = unordered_map<size_t, unordered_map<size_t, unordered_set<size_t>>>();
        
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
                .collisionFuzz = 0.0f,
                .neighborCount = 0,
                .ci = 0,
                .cj = 0
            };
            _liquid[i] = particle;
            
            // Fill _particlePositions Array
            _glParticles[i].position = particle.position;
            _glParticles[i].velocity = particle.velocity;
            
        }
        
        [self setupVBOs];
        
    }
    return self;
    
}
-(void)setupGLAndAccelerometer {
    
}
-(void)update {
    
    applyLiquidConstraints();
    applyLiquidConstraints();
    
}
-(void)render {
    
    glBindFramebuffer(GL_FRAMEBUFFER, postFramebuffer);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glUseProgram(self.liquidParticleShader.program);
    glBindBuffer(GL_ARRAY_BUFFER, particleBuffer);
    glBindTexture(GL_TEXTURE_2D, particleTexture.name);
    
    // 1
    // Create Projection Matrix
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeScale(2*scale/_screenSize.x, 2*scale/_screenSize.y, 1.0f);
    
    // 2
    // Uniforms
    glUniformMatrix4fv(self.liquidParticleShader.uProjectionMatrix, 1, 0, projectionMatrix.m);
    glUniform1f(self.liquidParticleShader.uRetinaScale, retinaScale);
    glUniform1i(self.liquidParticleShader.uTexture, 0);
    
    
    // 2.5
    // Re-send vertex position data to GPU
    glBufferData(GL_ARRAY_BUFFER, sizeof(_glParticles), _glParticles, GL_DYNAMIC_DRAW);
    
    
    // 3
    // Attributes
    glEnableVertexAttribArray(self.liquidParticleShader.aPosition);
    glEnableVertexAttribArray(self.liquidParticleShader.aVelocity);
    glVertexAttribPointer(self.liquidParticleShader.aPosition,                // Set pointer
                          2,                                        // Two components per particle
                          GL_FLOAT,                                 // Data is floating point type
                          GL_FALSE,                                 // No fixed point scaling
                          sizeof(FLSGLParticle),                         // Gaps in data
                          (void *)offsetof(FLSGLParticle, position));      // Start from "position" offset within bound buffer
    glVertexAttribPointer(self.liquidParticleShader.aVelocity,                // Set pointer
                          2,                                        // Two components per particle
                          GL_FLOAT,                                 // Data is floating point type
                          GL_FALSE,                                 // No fixed point scaling
                          sizeof(FLSGLParticle),                         // Gaps in data
                          (void *)offsetof(FLSGLParticle, velocity));      // Start from "position" offset within bound buffer
    
    // 4
    // Draw particles
    
//    glDrawArrays(GL_POINTS, 0, (int)_activeParticles.size());
    glDrawElements(GL_POINTS, (int)_activeParticles.size(), GL_UNSIGNED_SHORT, _activeParticlesGL);
    glDisableVertexAttribArray(self.liquidParticleShader.aPosition);
    glDisableVertexAttribArray(self.liquidParticleShader.aVelocity);
    
    // POST
    
    glBindFramebuffer(GL_FRAMEBUFFER, 2);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glUseProgram(self.liquidPostShader.program);
    glBindTexture(GL_TEXTURE_2D, postTexture);
    glUniform1i(self.liquidPostShader.fbo_texture, /*GL_TEXTURE*/0);
    glUniform2fv(self.liquidPostShader.uScreenSize, 1, _screenSize.v);
    
    float gravityLen = GLKVector2Length(_glGravity);
    float shimmerMultiplierLen = cbrt(gravityLen);
    
    GLKVector2 shimmerMultiplier = GLKVector2MultiplyScalar(_glGravity, shimmerMultiplierLen / gravityLen);
    
    glUniform2fv(self.liquidPostShader.uGravity, 1, _glGravity.v);
    glUniform2fv(self.liquidPostShader.uShimmer, 1, shimmerMultiplier.v);
    
    glUniform3fv(self.liquidPostShader.uLook_BaseColor, 1, look_baseColor.v);
    glUniform1f(self.liquidPostShader.uLook_Clarity, look_clarity);
    glUniform1f(self.liquidPostShader.uLook_Shimmer, look_shimmer);
    glUniform1f(self.liquidPostShader.uLook_Foam, look_foam);
    
//    NSLog(@"(%f, %f) vs. (%f, %f)", gravity.x, gravity.y, scaledGravity.x, scaledGravity.y);
    
    glEnableVertexAttribArray(self.liquidPostShader.v_coord);
    
    glBindBuffer(GL_ARRAY_BUFFER, postTextureVBO);
    glVertexAttribPointer(
                          self.liquidPostShader.v_coord,  // attribute
                          2,                  // number of elements per vertex, here (x,y)
                          GL_FLOAT,           // the type of each element
                          GL_FALSE,           // take our values as-is
                          0,                  // no extra data between each position
                          0                   // offset of first element
                          );
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glDisableVertexAttribArray(self.liquidPostShader.v_coord);
    
}
#pragma mark - Load Shader

-(void)loadShaders
{
    self.liquidParticleShader = [[FLSLiquidParticleShader alloc] init];
    [self.liquidParticleShader loadShader];
    
    self.liquidPostShader = [[FLSLiquidPostShader alloc] init];
    [self.liquidPostShader loadShader];
}
-(void)setupVBOs {
    
    // Create Vertex Buffer Object (VBO)
    glGenBuffers(1, &particleBuffer);                   // Generate particle buffer
    glBindBuffer(GL_ARRAY_BUFFER, particleBuffer);      // Bind particle buffer
    glBufferData(                                       // Fill bound buffer with particles
                 GL_ARRAY_BUFFER,                       // Buffer target
                 sizeof(_glParticles),                  // Buffer data size
                 _glParticles,                          // Buffer data pointer
                 GL_DYNAMIC_DRAW);                      // Usage - Data changes
    
    GLfloat fbo_vertices[] = {
        -1, -1,
        1, -1,
        -1,  1,
        1,  1,
    };
    glGenBuffers(1, &postTextureVBO);
    glBindBuffer(GL_ARRAY_BUFFER, postTextureVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(fbo_vertices), fbo_vertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
}

#pragma mark - Render To Texture

-(void)setupRTT {
    
    /* Create back-buffer, used for post-processing */
    
    /* Texture */
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &postTexture);
    glBindTexture(GL_TEXTURE_2D, postTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _screenSize.x * retinaScale, _screenSize.y * retinaScale, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    /* Depth buffer */
    glGenRenderbuffers(1, &postDepthBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, postDepthBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, _screenSize.x * retinaScale, _screenSize.y * retinaScale);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    
    /* Framebuffer to link everything together */
    glGenFramebuffers(1, &postFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, postFramebuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, postTexture, 0);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, postDepthBuffer);
    GLenum status;
    if ((status = glCheckFramebufferStatus(GL_FRAMEBUFFER)) != GL_FRAMEBUFFER_COMPLETE) {
        fprintf(stderr, "glCheckFramebufferStatus: error %u", status);
        return;
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
}

#pragma mark - Load Texture

- (void)loadParticleTexture:(NSString *)fileName
{
    NSDictionary* options = @{[NSNumber numberWithBool:YES] : GLKTextureLoaderOriginBottomLeft};
    
    NSError* error;
    NSString* path = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
    particleTexture = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
    if(particleTexture == nil)
    {
        NSLog(@"Error loading file: %@", [error localizedDescription]);
    }
}
-(void)addFluidAtPosX:(float)posX posY:(float)posY {
    
    createParticles((posX - _screenSize.x/2)/scale, (_screenSize.y/2 - posY)/scale);
    
}
-(void)removeFluidAtPosX:(float)posX posY:(float)posY {
    
    removeParticles((posX - _screenSize.x/2)/scale, (_screenSize.y/2 - posY)/scale);
    
}
-(void)flingFluidAtPosX:(float)posX posY:(float)posY withVelX:(float)velX velY:(float)velY {
    
    flingParticles((posX - _screenSize.x/2)/scale, (_screenSize.y/2 - posY)/scale,
                   -velX / scale, velY / scale);
    
}
-(FLSTouchOperation)operationForTouch:(float)posX posY:(float)posY {
    
    float worldX = (posX - _screenSize.x/2) / scale;
    float worldY = (_screenSize.y/2 - posY) / scale;
    
    int ci = getGridX(worldX);
    int cj = getGridY(worldY);
    
    unordered_set<size_t> &gridSquare = _grid[ci][cj];
            
    if (gridSquare.empty())
        return FLSTouchAddFluid;
    else
        return FLSTouchRemoveFluid;
    
}
-(void)dealloc {
    
//    glDeleteBuffers(1, &particleBuffer);
//    glDeleteBuffers(1, &postTextureVBO);
//    glDeleteTextures(1, &postTexture);
//    glDeleteRenderbuffers(1, &postDepthBuffer);
//    glDeleteFramebuffers(1, &postFramebuffer);
    
}

@end
