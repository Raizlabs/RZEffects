//
//  RZQuadMesh.m
//
//  Created by Rob Visentin on 1/10/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/EAGL.h>

#import "RZQuadMesh.h"

typedef struct _RZBufferSet {
    GLuint vbo, ibo;
} RZBufferSet;

NSInteger const kRZQuadMeshMaxSubdivisions = 8;

static const GLfloat *s_CachedVertices[kRZQuadMeshMaxSubdivisions];
static const GLushort *s_CachedIndexes[kRZQuadMeshMaxSubdivisions];
static const GLint *s_RefCounts[kRZQuadMeshMaxSubdivisions];

static dispatch_semaphore_t s_Semaphore;

void RZGenerateQuadMesh(NSInteger subdivisions, GLvoid **vertices, GLuint *numVerts, GLvoid **indices, GLuint *numIdxs);

@interface RZQuadMesh ()

@property (assign, nonatomic) GLuint vao;
@property (assign, nonatomic) RZBufferSet bufferSet;

@property (assign, nonatomic) GLuint vertexCount;
@property (assign, nonatomic) GLuint indexCount;

@property (assign, nonatomic) GLvoid *vertexData;
@property (assign, nonatomic) GLvoid *indexData;

@property (assign, nonatomic) NSInteger subdivisions;

@end

@implementation RZQuadMesh

#pragma mark - lifecycle

+ (void)load
{
    s_Semaphore = dispatch_semaphore_create(1);
}

+ (instancetype)quad
{
    return [self quadWithSubdivisionLevel:0];
}

+ (instancetype)quadWithSubdivisionLevel:(NSInteger)subdivisons
{
    RZQuadMesh *mesh = nil;
    
    if ( [EAGLContext currentContext] != nil ) {
        mesh = [[self alloc] initWithSubdivisionLevel:subdivisons];
    }
    else {
        NSLog(@"Failed to initialize %@: No active EAGLContext.", NSStringFromClass(self));
    }
    
    return mesh;
}

- (void)dealloc
{
    dispatch_semaphore_wait(s_Semaphore, DISPATCH_TIME_FOREVER);
    
    s_RefCounts[_subdivisions]--;
    
    if ( s_RefCounts[_subdivisions] <= 0 ) {
        free((void *)s_CachedVertices[_subdivisions]);
        s_CachedVertices[_subdivisions] = NULL;
        
        free((void *)s_CachedIndexes[_subdivisions]);
        s_CachedIndexes[_subdivisions] = NULL;
    }
    
    dispatch_semaphore_signal(s_Semaphore);
}

#pragma mark - RZOpenGLObject

- (void)setupGL
{
    if ( [EAGLContext currentContext] != nil ) {
        [self teardownGL];
        
        glGenVertexArraysOES(1, &_vao);
        glGenBuffers(2, &_bufferSet.vbo);
        
        glBindVertexArrayOES(_vao);
        
        glBindBuffer(GL_ARRAY_BUFFER, _bufferSet.vbo);
        glBufferData(GL_ARRAY_BUFFER, 5 * _vertexCount * sizeof(GLfloat), _vertexData, GL_STATIC_DRAW);
        
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _bufferSet.ibo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, _indexCount * sizeof(GLushort), _indexData, GL_STATIC_DRAW);
        
        glEnableVertexAttribArray(kRZVertexAttribPosition);
        glVertexAttribPointer(kRZVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), (const GLvoid *)0);
        
        glEnableVertexAttribArray(kRZVertexAttribTexCoord);
        glVertexAttribPointer(kRZVertexAttribTexCoord, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), (const GLvoid *)12);
        
        glBindVertexArrayOES(0);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
    else {
        NSLog(@"Failed to setup %@: No active EAGLContext.", NSStringFromClass([self class]));
    }
}

- (void)bindGL
{
    glBindVertexArrayOES(_vao);
    glBindBuffer(GL_ARRAY_BUFFER, _bufferSet.vbo);
}

- (void)teardownGL
{
    if ( _vao != 0 ) {
        glDeleteVertexArraysOES(1, &_vao);
        glDeleteBuffers(2, &_bufferSet.vbo);
    }
}

#pragma mark - RZRenderable

- (void)render
{
    [self bindGL];
    
    glDrawElements(GL_TRIANGLES, _indexCount, GL_UNSIGNED_SHORT, NULL);
    
    glBindVertexArrayOES(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

#pragma mark - private methods

- (instancetype)initWithSubdivisionLevel:(NSInteger)subdivisions
{
    self = [super init];
    if ( self ) {
        subdivisions = MAX(0, MIN(subdivisions, kRZQuadMeshMaxSubdivisions));
        RZGenerateQuadMesh(subdivisions, &_vertexData, &_vertexCount, &_indexData, &_indexCount);
        
        _subdivisions = subdivisions;
    }
    return self;
}

void RZGenerateQuadMesh(NSInteger subdivisions, GLvoid **vertices, GLuint *numVerts, GLvoid **indices, GLuint *numIdxs)
{
    GLuint subs = pow(2.0, subdivisions);
    GLuint pts = subs + 1;
    
    GLfloat ptStep = 2.0f / subs;
    GLfloat texStep = 1.0f / subs;
    
    *numVerts = pts * pts;
    *numIdxs = 6 * subs * subs;
    
    if ( s_CachedVertices[subdivisions] == NULL ) {
        GLfloat *verts = (GLfloat *)malloc(5 * *numVerts * sizeof(GLfloat));
        GLushort *idxs = (GLushort *)malloc(*numIdxs * sizeof(GLushort));
        
        int v = 0;
        int i = 0;
        
        for ( int y = 0; y < pts; y++ ) {
            for ( int x = 0; x < pts; x++ ) {
                verts[v++] = -1.0f + ptStep * x;
                verts[v++] = 1.0f - ptStep * y;
                verts[v++] = 0.0f;
                verts[v++] = texStep * x;
                verts[v++] = 1.0f - texStep * y;
                
                if ( x < subs && y < subs ) {
                    idxs[i++] = y * pts + x;
                    idxs[i++] = (y + 1) * pts + x;
                    idxs[i++] = y * pts + x + 1;
                    idxs[i++] = y * pts + x + 1;
                    idxs[i++] = (y + 1) * pts + x;
                    idxs[i++] = (y + 1) * pts + x + 1;
                }
            }
        }
        
        dispatch_semaphore_wait(s_Semaphore, DISPATCH_TIME_FOREVER);
        
        s_CachedVertices[subdivisions] = verts;
        s_CachedIndexes[subdivisions] = idxs;
    }
    else {
        dispatch_semaphore_wait(s_Semaphore, DISPATCH_TIME_FOREVER);
    }

    *vertices = (GLvoid *)s_CachedVertices[subdivisions];
    *indices = (GLvoid *)s_CachedIndexes[subdivisions];
    
    s_RefCounts[subdivisions]++;
    
    dispatch_semaphore_signal(s_Semaphore);
}

@end
