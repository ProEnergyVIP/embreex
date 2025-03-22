# cython: embedsignature=True
# distutils: language=c++

cimport numpy as np
from embreex cimport rtcore as rtc
from embreex cimport rtcore_ray as rtcr
from embreex cimport rtcore_scene as rtcs
from embreex cimport rtcore_geometry as rtcg
from embreex.rtcore cimport Vertex, Triangle


cdef extern from "mesh_construction.h":
    int triangulate_hex[12][3]
    int triangulate_tetra[4][3]

cdef class TriangleMesh:
    r'''

    This class constructs a polygon mesh with triangular elements and
    adds it to the scene.

    Parameters
    ----------

    scene : EmbreeScene
        This is the scene to which the constructed polygons will be
        added.
    vertices : a np.ndarray of floats.
        This specifies the x, y, and z coordinates of the vertices in
        the polygon mesh. This should either have the shape
        (num_triangles, 3, 3), or the shape (num_vertices, 3), depending
        on the value of the `indices` parameter.
    indices : either None, or a np.ndarray of ints
        If None, then vertices must have the shape (num_triangles, 3, 3).
        In this case, `vertices` specifices the coordinates of each
        vertex of each triangle in the mesh, with vertices being
        duplicated if they are shared between triangles. For example,
        if indices is None, then vertices[2][1][0] should give you
        the x-coordinate of the 2nd vertex of the 3rd triangle.
        If indices is a np.ndarray, then it must have the shape
        (num_triangles, 3), and `vertices` must have the shape
        (num_vertices, 3). In this case, indices[2][1] tells you
        the index of the 2nd vertex of the 3rd triangle in `indices`,
        while vertices[5][2] tells you the z-coordinate of the 6th
        vertex in the mesh. Note that the indexing is assumed to be
        zero-based. In this setup, vertices can be shared between
        triangles, and the number of vertices can be less than 3 times
        the number of triangles.

    '''

    cdef Vertex* vertices
    cdef Triangle* indices
    cdef rtcg.RTCGeometry geometry
    cdef unsigned int geomID

    def __init__(self, rtcs.EmbreeScene scene,
                 np.ndarray vertices,
                 np.ndarray indices = None):

        if indices is None:
            self._build_from_flat(scene, vertices)
        else:
            self._build_from_indices(scene, vertices, indices)

    cdef void _build_from_flat(self, rtcs.EmbreeScene scene,
                               np.ndarray tri_vertices):
        cdef int i, j
        cdef int nt = tri_vertices.shape[0]
        # In this scheme, we don't share any vertices.  This leads to cracks,
        # but also means we have exactly three times as many vertices as
        # triangles.
        
        # Create a new triangle geometry
        self.geometry = rtcg.rtcNewGeometry(scene.device.device_i, rtcg.RTC_GEOMETRY_TYPE_TRIANGLE)
        
        # Set build quality (equivalent to RTC_GEOMETRY_STATIC in Embree3)
        rtcg.rtcSetGeometryBuildQuality(self.geometry, rtcg.RTC_BUILD_QUALITY_HIGH)
        
        # Set vertex buffer
        cdef Vertex* vertices = <Vertex*> rtcg.rtcSetNewGeometryBuffer(
            self.geometry, 
            rtcg.RTC_BUFFER_TYPE_VERTEX, 
            0,  # slot
            rtcg.RTC_FORMAT_FLOAT3, 
            sizeof(Vertex), 
            nt*3
        )

        for i in range(nt):
            for j in range(3):
                vertices[i*3 + j].x = tri_vertices[i,j,0]
                vertices[i*3 + j].y = tri_vertices[i,j,1]
                vertices[i*3 + j].z = tri_vertices[i,j,2]

        # Set index buffer
        cdef Triangle* triangles = <Triangle*> rtcg.rtcSetNewGeometryBuffer(
            self.geometry, 
            rtcg.RTC_BUFFER_TYPE_INDEX, 
            0,  # slot
            rtcg.RTC_FORMAT_UINT3, 
            sizeof(Triangle), 
            nt
        )
        
        for i in range(nt):
            triangles[i].v0 = i*3 + 0
            triangles[i].v1 = i*3 + 1
            triangles[i].v2 = i*3 + 2

        # Commit the geometry
        rtcg.rtcCommitGeometry(self.geometry)
        
        # Attach the geometry to the scene
        self.geomID = rtcg.rtcAttachGeometry(scene.scene_i, self.geometry)
        
        # Store the pointers for later use
        self.vertices = vertices
        self.indices = triangles

    cdef void _build_from_indices(self, rtcs.EmbreeScene scene,
                                  np.ndarray tri_vertices,
                                  np.ndarray tri_indices):
        cdef int i
        cdef int nv = tri_vertices.shape[0]
        cdef int nt = tri_indices.shape[0]

        # Create a new triangle geometry
        self.geometry = rtcg.rtcNewGeometry(scene.device.device_i, rtcg.RTC_GEOMETRY_TYPE_TRIANGLE)
        
        # Set build quality (equivalent to RTC_GEOMETRY_STATIC in Embree3)
        rtcg.rtcSetGeometryBuildQuality(self.geometry, rtcg.RTC_BUILD_QUALITY_HIGH)
        
        # Set vertex buffer
        cdef Vertex* vertices = <Vertex*> rtcg.rtcSetNewGeometryBuffer(
            self.geometry, 
            rtcg.RTC_BUFFER_TYPE_VERTEX, 
            0,  # slot
            rtcg.RTC_FORMAT_FLOAT3, 
            sizeof(Vertex), 
            nv
        )

        for i in range(nv):
            vertices[i].x = tri_vertices[i, 0]
            vertices[i].y = tri_vertices[i, 1]
            vertices[i].z = tri_vertices[i, 2]

        # Set index buffer
        cdef Triangle* triangles = <Triangle*> rtcg.rtcSetNewGeometryBuffer(
            self.geometry, 
            rtcg.RTC_BUFFER_TYPE_INDEX, 
            0,  # slot
            rtcg.RTC_FORMAT_UINT3, 
            sizeof(Triangle), 
            nt
        )

        for i in range(nt):
            triangles[i].v0 = tri_indices[i][0]
            triangles[i].v1 = tri_indices[i][1]
            triangles[i].v2 = tri_indices[i][2]

        # Commit the geometry
        rtcg.rtcCommitGeometry(self.geometry)
        
        # Attach the geometry to the scene
        self.geomID = rtcg.rtcAttachGeometry(scene.scene_i, self.geometry)
        
        # Store the pointers for later use
        self.vertices = vertices
        self.indices = triangles


cdef class ElementMesh(TriangleMesh):
    r'''

    Currently, we handle non-triangular mesh types by converting them
    to triangular meshes. This class performs this transformation.
    Currently, this is implemented for hexahedral and tetrahedral
    meshes.

    Parameters
    ----------

    scene : EmbreeScene
        This is the scene to which the constructed polygons will be
        added.
    vertices : a np.ndarray of floats.
        This specifies the x, y, and z coordinates of the vertices in
        the polygon mesh. This should either have the shape
        (num_vertices, 3). For example, vertices[2][1] should give the
        y-coordinate of the 3rd vertex in the mesh.
    indices : a np.ndarray of ints
        This should either have the shape (num_elements, 4) or
        (num_elements, 8) for tetrahedral and hexahedral meshes,
        respectively. For tetrahedral meshes, each element will
        be represented by four triangles in the scene. For hex meshes,
        each element will be represented by 12 triangles, 2 for each
        face. For hex meshes, we assume that the node ordering is as
        defined here:
        http://homepages.cae.wisc.edu/~tautges/papers/cnmev3.pdf

    '''

    def __init__(self, rtcs.EmbreeScene scene,
                 np.ndarray vertices,
                 np.ndarray indices):
        # We need now to figure out if we've been handed quads or tetrahedra.
        # If it's quads, we can build the mesh slightly differently.
        # http://stackoverflow.com/questions/23723993/converting-quadriladerals-in-an-obj-file-into-triangles
        if indices.shape[1] == 8:
            self._build_from_hexahedra(scene, vertices, indices)
        elif indices.shape[1] == 4:
            self._build_from_tetrahedra(scene, vertices, indices)
        else:
            raise NotImplementedError

    cdef void _build_from_hexahedra(self, rtcs.EmbreeScene scene,
                                    np.ndarray quad_vertices,
                                    np.ndarray quad_indices):

        cdef int i, j
        cdef int nv = quad_vertices.shape[0]
        cdef int ne = quad_indices.shape[0]

        # There are six faces for every quad.  Each of those will be divided
        # into two triangles.
        cdef int nt = 6*2*ne

        # Create a new triangle geometry
        self.geometry = rtcg.rtcNewGeometry(scene.device.device_i, rtcg.RTC_GEOMETRY_TYPE_TRIANGLE)
        
        # Set build quality (equivalent to RTC_GEOMETRY_STATIC in Embree3)
        rtcg.rtcSetGeometryBuildQuality(self.geometry, rtcg.RTC_BUILD_QUALITY_HIGH)
        
        # Set vertex buffer
        cdef Vertex* vertices = <Vertex*> rtcg.rtcSetNewGeometryBuffer(
            self.geometry, 
            rtcg.RTC_BUFFER_TYPE_VERTEX, 
            0,  # slot
            rtcg.RTC_FORMAT_FLOAT3, 
            sizeof(Vertex), 
            nv
        )

        for i in range(nv):
            vertices[i].x = quad_vertices[i, 0]
            vertices[i].y = quad_vertices[i, 1]
            vertices[i].z = quad_vertices[i, 2]

        # Set index buffer
        cdef Triangle* triangles = <Triangle*> rtcg.rtcSetNewGeometryBuffer(
            self.geometry, 
            rtcg.RTC_BUFFER_TYPE_INDEX, 
            0,  # slot
            rtcg.RTC_FORMAT_UINT3, 
            sizeof(Triangle), 
            nt
        )

        # now build up the triangles
        cdef int tri_idx = 0
        cdef int v0, v1, v2, v3, v4, v5, v6, v7
        for i in range(ne):
            v0 = quad_indices[i, 0]
            v1 = quad_indices[i, 1]
            v2 = quad_indices[i, 2]
            v3 = quad_indices[i, 3]
            v4 = quad_indices[i, 4]
            v5 = quad_indices[i, 5]
            v6 = quad_indices[i, 6]
            v7 = quad_indices[i, 7]

            # face 0 (bottom): 0 3 2 1
            triangles[tri_idx].v0 = v0
            triangles[tri_idx].v1 = v3
            triangles[tri_idx].v2 = v2
            tri_idx += 1
            triangles[tri_idx].v0 = v0
            triangles[tri_idx].v1 = v2
            triangles[tri_idx].v2 = v1
            tri_idx += 1

            # face 1 (top): 4 5 6 7
            triangles[tri_idx].v0 = v4
            triangles[tri_idx].v1 = v5
            triangles[tri_idx].v2 = v6
            tri_idx += 1
            triangles[tri_idx].v0 = v4
            triangles[tri_idx].v1 = v6
            triangles[tri_idx].v2 = v7
            tri_idx += 1

            # face 2 (front): 0 1 5 4
            triangles[tri_idx].v0 = v0
            triangles[tri_idx].v1 = v1
            triangles[tri_idx].v2 = v5
            tri_idx += 1
            triangles[tri_idx].v0 = v0
            triangles[tri_idx].v1 = v5
            triangles[tri_idx].v2 = v4
            tri_idx += 1

            # face 3 (right): 1 2 6 5
            triangles[tri_idx].v0 = v1
            triangles[tri_idx].v1 = v2
            triangles[tri_idx].v2 = v6
            tri_idx += 1
            triangles[tri_idx].v0 = v1
            triangles[tri_idx].v1 = v6
            triangles[tri_idx].v2 = v5
            tri_idx += 1

            # face 4 (back): 2 3 7 6
            triangles[tri_idx].v0 = v2
            triangles[tri_idx].v1 = v3
            triangles[tri_idx].v2 = v7
            tri_idx += 1
            triangles[tri_idx].v0 = v2
            triangles[tri_idx].v1 = v7
            triangles[tri_idx].v2 = v6
            tri_idx += 1

            # face 5 (left): 3 0 4 7
            triangles[tri_idx].v0 = v3
            triangles[tri_idx].v1 = v0
            triangles[tri_idx].v2 = v4
            tri_idx += 1
            triangles[tri_idx].v0 = v3
            triangles[tri_idx].v1 = v4
            triangles[tri_idx].v2 = v7
            tri_idx += 1

        # Commit the geometry
        rtcg.rtcCommitGeometry(self.geometry)
        
        # Attach the geometry to the scene
        self.geomID = rtcg.rtcAttachGeometry(scene.scene_i, self.geometry)
        
        # Store the pointers for later use
        self.vertices = vertices
        self.indices = triangles

    cdef void _build_from_tetrahedra(self, rtcs.EmbreeScene scene,
                                     np.ndarray tet_vertices,
                                     np.ndarray tet_indices):
        cdef int i, j
        cdef int nv = tet_vertices.shape[0]
        cdef int ne = tet_indices.shape[0]

        # There are four faces for every tetrahedron.
        cdef int nt = 4*ne

        # Create a new triangle geometry
        self.geometry = rtcg.rtcNewGeometry(scene.device.device_i, rtcg.RTC_GEOMETRY_TYPE_TRIANGLE)
        
        # Set build quality (equivalent to RTC_GEOMETRY_STATIC in Embree3)
        rtcg.rtcSetGeometryBuildQuality(self.geometry, rtcg.RTC_BUILD_QUALITY_HIGH)
        
        # Set vertex buffer
        cdef Vertex* vertices = <Vertex*> rtcg.rtcSetNewGeometryBuffer(
            self.geometry, 
            rtcg.RTC_BUFFER_TYPE_VERTEX, 
            0,  # slot
            rtcg.RTC_FORMAT_FLOAT3, 
            sizeof(Vertex), 
            nv
        )

        for i in range(nv):
            vertices[i].x = tet_vertices[i, 0]
            vertices[i].y = tet_vertices[i, 1]
            vertices[i].z = tet_vertices[i, 2]

        # Set index buffer
        cdef Triangle* triangles = <Triangle*> rtcg.rtcSetNewGeometryBuffer(
            self.geometry, 
            rtcg.RTC_BUFFER_TYPE_INDEX, 
            0,  # slot
            rtcg.RTC_FORMAT_UINT3, 
            sizeof(Triangle), 
            nt
        )

        # now build up the triangles
        cdef int tri_idx = 0
        cdef int v0, v1, v2, v3
        for i in range(ne):
            v0 = tet_indices[i, 0]
            v1 = tet_indices[i, 1]
            v2 = tet_indices[i, 2]
            v3 = tet_indices[i, 3]

            # face 0: 0 1 2
            triangles[tri_idx].v0 = v0
            triangles[tri_idx].v1 = v1
            triangles[tri_idx].v2 = v2
            tri_idx += 1

            # face 1: 0 1 3
            triangles[tri_idx].v0 = v0
            triangles[tri_idx].v1 = v1
            triangles[tri_idx].v2 = v3
            tri_idx += 1

            # face 2: 0 2 3
            triangles[tri_idx].v0 = v0
            triangles[tri_idx].v1 = v2
            triangles[tri_idx].v2 = v3
            tri_idx += 1

            # face 3: 1 2 3
            triangles[tri_idx].v0 = v1
            triangles[tri_idx].v1 = v2
            triangles[tri_idx].v2 = v3
            tri_idx += 1

        # Commit the geometry
        rtcg.rtcCommitGeometry(self.geometry)
        
        # Attach the geometry to the scene
        self.geomID = rtcg.rtcAttachGeometry(scene.scene_i, self.geometry)
        
        # Store the pointers for later use
        self.vertices = vertices
        self.indices = triangles
