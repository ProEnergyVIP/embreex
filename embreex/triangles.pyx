# distutils: language=c++

cimport numpy as np
from embreex cimport rtcore as rtc
from embreex cimport rtcore_ray as rtcr
from embreex cimport rtcore_scene as rtcs
from embreex cimport rtcore_geometry as rtcg
from embreex.rtcore cimport Vertex, Triangle, Vec3f
from libc.stdlib cimport malloc, free

ctypedef Vec3f (*renderPixelFunc)(float x, float y,
                const Vec3f &vx, const Vec3f &vy, const Vec3f &vz,
                const Vec3f &p)

def run_triangles():
    pass

cdef unsigned int addCube(rtcs.RTCScene scene_i):
    # Create a new triangle geometry using NULL for device (scene's device will be used)
    cdef rtcg.RTCGeometry geometry = rtcg.rtcNewGeometry(NULL, rtcg.RTC_GEOMETRY_TYPE_TRIANGLE)
    
    # Set build quality (equivalent to RTC_GEOMETRY_STATIC in Embree3)
    rtcg.rtcSetGeometryBuildQuality(geometry, rtcg.RTC_BUILD_QUALITY_HIGH)
    
    # Set vertex buffer
    cdef Vertex* vertices = <Vertex*> rtcg.rtcSetNewGeometryBuffer(
        geometry, rtcg.RTC_BUFFER_TYPE_VERTEX, 0,
        rtcg.RTC_FORMAT_FLOAT3, sizeof(Vertex), 8)
    
    vertices[0].x = -1
    vertices[0].y = -1
    vertices[0].z = -1

    vertices[1].x = -1
    vertices[1].y = -1
    vertices[1].z = +1

    vertices[2].x = -1
    vertices[2].y = +1
    vertices[2].z = -1

    vertices[3].x = -1
    vertices[3].y = +1
    vertices[3].z = +1

    vertices[4].x = +1
    vertices[4].y = -1
    vertices[4].z = -1

    vertices[5].x = +1
    vertices[5].y = -1
    vertices[5].z = +1

    vertices[6].x = +1
    vertices[6].y = +1
    vertices[6].z = -1

    vertices[7].x = +1
    vertices[7].y = +1
    vertices[7].z = +1


    cdef Vec3f *colors = <Vec3f*> malloc(12*sizeof(Vec3f))

    cdef int tri = 0
    cdef Triangle* triangles = <Triangle*> rtcg.rtcSetNewGeometryBuffer(
        geometry, rtcg.RTC_BUFFER_TYPE_INDEX, 0,
        rtcg.RTC_FORMAT_UINT3, sizeof(Triangle), 12)

    # left side
    colors[tri].x = 1.0
    colors[tri].y = 0.0
    colors[tri].z = 0.0
    triangles[tri].v0 = 0
    triangles[tri].v1 = 2
    triangles[tri].v2 = 1
    tri += 1
    colors[tri].x = 1.0
    colors[tri].y = 0.0
    colors[tri].z = 0.0
    triangles[tri].v0 = 1
    triangles[tri].v1 = 2
    triangles[tri].v2 = 3
    tri += 1

    # right side
    colors[tri].x = 0.0
    colors[tri].y = 1.0
    colors[tri].z = 0.0
    triangles[tri].v0 = 4
    triangles[tri].v1 = 5
    triangles[tri].v2 = 6
    tri += 1
    colors[tri].x = 0.0
    colors[tri].y = 1.0
    colors[tri].z = 0.0
    triangles[tri].v0 = 5
    triangles[tri].v1 = 7
    triangles[tri].v2 = 6
    tri += 1

    # bottom side
    colors[tri].x = 0.5
    colors[tri].y = 0.5
    colors[tri].z = 0.5
    triangles[tri].v0 = 0
    triangles[tri].v1 = 1
    triangles[tri].v2 = 4
    tri += 1
    colors[tri].x = 0.5
    colors[tri].y = 0.5
    colors[tri].z = 0.5
    triangles[tri].v0 = 1
    triangles[tri].v1 = 5
    triangles[tri].v2 = 4
    tri += 1

    # top side
    colors[tri].x = 1.0
    colors[tri].y = 1.0
    colors[tri].z = 1.0
    triangles[tri].v0 = 2
    triangles[tri].v1 = 6
    triangles[tri].v2 = 3
    tri += 1
    colors[tri].x = 1.0
    colors[tri].y = 1.0
    colors[tri].z = 1.0
    triangles[tri].v0 = 3
    triangles[tri].v1 = 6
    triangles[tri].v2 = 7
    tri += 1

    # front side
    colors[tri].x = 0.0
    colors[tri].y = 0.0
    colors[tri].z = 1.0
    triangles[tri].v0 = 0
    triangles[tri].v1 = 4
    triangles[tri].v2 = 2
    tri += 1
    colors[tri].x = 0.0
    colors[tri].y = 0.0
    colors[tri].z = 1.0
    triangles[tri].v0 = 2
    triangles[tri].v1 = 4
    triangles[tri].v2 = 6
    tri += 1

    # back side
    colors[tri].x = 1.0
    colors[tri].y = 1.0
    colors[tri].z = 0.0
    triangles[tri].v0 = 1
    triangles[tri].v1 = 3
    triangles[tri].v2 = 5
    tri += 1
    colors[tri].x = 1.0
    colors[tri].y = 1.0
    colors[tri].z = 0.0
    triangles[tri].v0 = 3
    triangles[tri].v1 = 7
    triangles[tri].v2 = 5
    tri += 1

    # Commit geometry
    rtcg.rtcCommitGeometry(geometry)
    
    # Attach geometry to scene
    cdef unsigned int geomID = rtcg.rtcAttachGeometry(scene_i, geometry)
    
    # Release geometry (scene will retain it)
    rtcg.rtcReleaseGeometry(geometry)

    return geomID

# Python wrapper for addCube
def add_cube(object scene_i):
    """Add a cube to the scene and return the geometry ID."""
    return addCube(<rtcs.RTCScene>scene_i)

cdef unsigned int addGroundPlane(rtcs.RTCScene scene_i):
    # Create a new triangle geometry using NULL for device (scene's device will be used)
    cdef rtcg.RTCGeometry geometry = rtcg.rtcNewGeometry(NULL, rtcg.RTC_GEOMETRY_TYPE_TRIANGLE)
    
    # Set build quality (equivalent to RTC_GEOMETRY_STATIC in Embree3)
    rtcg.rtcSetGeometryBuildQuality(geometry, rtcg.RTC_BUILD_QUALITY_HIGH)
    
    # Set vertex buffer
    cdef Vertex* vertices = <Vertex*> rtcg.rtcSetNewGeometryBuffer(
        geometry, rtcg.RTC_BUFFER_TYPE_VERTEX, 0,
        rtcg.RTC_FORMAT_FLOAT3, sizeof(Vertex), 4)
    
    vertices[0].x = -10
    vertices[0].y = -2
    vertices[0].z = -10

    vertices[1].x = -10
    vertices[1].y = -2
    vertices[1].z = +10

    vertices[2].x = +10
    vertices[2].y = -2
    vertices[2].z = -10

    vertices[3].x = +10
    vertices[3].y = -2
    vertices[3].z = +10

    # Set index buffer
    cdef Triangle* triangles = <Triangle*> rtcg.rtcSetNewGeometryBuffer(
        geometry, rtcg.RTC_BUFFER_TYPE_INDEX, 0,
        rtcg.RTC_FORMAT_UINT3, sizeof(Triangle), 2)
    
    triangles[0].v0 = 0
    triangles[0].v1 = 2
    triangles[0].v2 = 1
    triangles[1].v0 = 1
    triangles[1].v1 = 2
    triangles[1].v2 = 3

    # Commit geometry
    rtcg.rtcCommitGeometry(geometry)
    
    # Attach geometry to scene
    cdef unsigned int geomID = rtcg.rtcAttachGeometry(scene_i, geometry)
    
    # Release geometry (scene will retain it)
    rtcg.rtcReleaseGeometry(geometry)

    return geomID
