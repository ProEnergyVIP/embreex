# distutils: language=c++

cimport cython
cimport numpy as np
import numpy as np
import logging
import numbers
from embreex cimport rtcore as rtc
from embreex cimport rtcore_ray as rtcr
from embreex cimport rtcore_geometry as rtcg


log = logging.getLogger('embreex')

cdef void error_printer(void* userPtr, rtc.RTCError code, const char *_str) noexcept:
    """
    error_printer function for Embree4
    """
    log.error("ERROR CAUGHT IN EMBREE")
    rtc.print_error(code)
    log.error("ERROR MESSAGE: %s" % _str)


cdef class EmbreeScene:
    def __init__(self, rtc.EmbreeDevice device=None, robust=False):
        if device is None:
            # We store the embree device inside EmbreeScene to avoid premature deletion
            self.device = rtc.EmbreeDevice()
            device = self.device
        
        # Create a new scene
        self.scene_i = rtcNewScene(device.device_i)
        
        # Set scene flags
        if robust:
            rtcSetSceneFlags(self.scene_i, RTC_SCENE_FLAG_ROBUST)
        else:
            rtcSetSceneFlags(self.scene_i, RTC_SCENE_FLAG_NONE)
        
        # Set build quality (equivalent to RTC_SCENE_STATIC in Embree3)
        rtcSetSceneBuildQuality(self.scene_i, RTC_BUILD_QUALITY_HIGH)
        
        # Set error function
        rtc.rtcSetDeviceErrorFunction(device.device_i, error_printer, NULL)
        
        self.is_committed = 0

    def run(self, np.ndarray[np.float32_t, ndim=2] vec_origins,
                  np.ndarray[np.float32_t, ndim=2] vec_directions,
                  dists=None, query='INTERSECT', output=None):
        """
        Run ray tracing on the scene.
        
        Parameters:
        -----------
        vec_origins : numpy.ndarray
            Origins of the rays
        vec_directions : numpy.ndarray
            Directions of the rays
        dists : float or numpy.ndarray, optional
            Maximum distances for the rays
        query : str, optional
            Type of query: 'INTERSECT', 'OCCLUDED', or 'DISTANCE'
        output : bool, optional
            Whether to return detailed hit information
            
        Returns:
        --------
        dict or numpy.ndarray
            Results of the ray tracing operation
        """

        if self.is_committed == 0:
            rtcCommitScene(self.scene_i)
            self.is_committed = 1

        cdef int nv = vec_origins.shape[0]
        cdef int vd_i, vd_step
        cdef np.ndarray[np.int32_t, ndim=1] intersect_ids
        cdef np.ndarray[np.float32_t, ndim=1] tfars
        cdef rayQueryType query_type

        if query == 'INTERSECT':
            query_type = intersect
        elif query == 'OCCLUDED':
            query_type = occluded
        elif query == 'DISTANCE':
            query_type = distance

        else:
            raise ValueError("Embree ray query type %s not recognized." 
                "\nAccepted types are (INTERSECT,OCCLUDED,DISTANCE)" % (query))

        if dists is None:
            tfars = np.empty(nv, 'float32')
            tfars.fill(1e37)
        elif isinstance(dists, numbers.Number):
            tfars = np.empty(nv, 'float32')
            tfars.fill(dists)
        else:
            tfars = dists

        if output:
            u = np.empty(nv, dtype="float32")
            v = np.empty(nv, dtype="float32")
            Ng = np.empty((nv, 3), dtype="float32")
            primID = np.empty(nv, dtype="int32")
            geomID = np.empty(nv, dtype="uint32")
        else:
            intersect_ids = np.empty(nv, dtype="int32")

        cdef rtcr.RTCRayHit rayhit
        cdef rtcr.RTCRay ray  # Define ray here for occlusion queries
        vd_i = 0
        vd_step = 1
        # If vec_directions is 1 long, we won't be updating it.
        if vec_directions.shape[0] == 1: vd_step = 0

        for i in range(nv):
            # Initialize ray data
            rayhit.ray.org_x = vec_origins[i, 0]
            rayhit.ray.org_y = vec_origins[i, 1]
            rayhit.ray.org_z = vec_origins[i, 2]
            rayhit.ray.dir_x = vec_directions[vd_i, 0]
            rayhit.ray.dir_y = vec_directions[vd_i, 1]
            rayhit.ray.dir_z = vec_directions[vd_i, 2]
            rayhit.ray.tnear = 0.0
            rayhit.ray.tfar = tfars[i]
            rayhit.ray.mask = -1
            rayhit.ray.time = 0
            rayhit.ray.id = 0
            rayhit.ray.flags = 0
            
            # Initialize hit data
            rayhit.hit.geomID = rtcg.RTC_INVALID_GEOMETRY_ID  # Initialize to invalid
            
            vd_i += vd_step

            if query_type == intersect or query_type == distance:
                rtcIntersect1(self.scene_i, &rayhit, NULL)
                if not output:
                    if query_type == intersect:
                        intersect_ids[i] = rayhit.hit.primID
                    else:
                        tfars[i] = rayhit.ray.tfar
                else:
                    primID[i] = rayhit.hit.primID
                    geomID[i] = rayhit.hit.geomID
                    u[i] = rayhit.hit.u
                    v[i] = rayhit.hit.v
                    tfars[i] = rayhit.ray.tfar
                    Ng[i, 0] = rayhit.hit.Ng_x
                    Ng[i, 1] = rayhit.hit.Ng_y
                    Ng[i, 2] = rayhit.hit.Ng_z
            else:
                # For occlusion, we only need the ray part
                ray.org_x = vec_origins[i, 0]
                ray.org_y = vec_origins[i, 1]
                ray.org_z = vec_origins[i, 2]
                ray.dir_x = vec_directions[vd_i, 0]
                ray.dir_y = vec_directions[vd_i, 1]
                ray.dir_z = vec_directions[vd_i, 2]
                ray.tnear = 0.0
                ray.tfar = tfars[i]
                ray.mask = -1
                ray.time = 0
                ray.id = 0
                ray.flags = 0
                
                rtcOccluded1(self.scene_i, &ray, NULL)
                # In Embree4, occlusion sets ray.tfar to -inf when hit occurs
                intersect_ids[i] = 0 if ray.tfar < 0 else 1

        if output:
            return {'u':u, 'v':v, 'Ng': Ng, 'tfar': tfars, 'primID': primID, 'geomID': geomID}
        else:
            if query_type == distance:
                return tfars
            else:
                return intersect_ids

    def __dealloc__(self):
        rtcReleaseScene(self.scene_i)
