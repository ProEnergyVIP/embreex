# rtcore_ray.pxd wrapper

cimport cython
cimport numpy as np

cdef extern from "embree4/rtcore_ray.h":
    # RTCORE_ALIGN(16)
    # This is for a *single* ray
    cdef struct RTCRay:
        # Ray data
        float org_x
        float org_y
        float org_z
        float tnear

        float dir_x
        float dir_y
        float dir_z
        float time

        float tfar
        unsigned int mask
        unsigned int id
        unsigned int flags

    # Hit data
    cdef struct RTCHit:
        float Ng_x
        float Ng_y
        float Ng_z
        float u
        
        float v
        unsigned int primID
        unsigned int geomID
        unsigned int instID

    # Combined ray and hit data
    cdef struct RTCRayHit:
        RTCRay ray
        RTCHit hit

    # This is for a packet of 4 rays
    cdef struct RTCRay4:
        # Ray data
        float orgx[4]
        float orgy[4]
        float orgz[4]
        float align0

        float dirx[4]
        float diry[4]
        float dirz[4]
        float align1

        float tnear[4]
        float tfar[4]

        float time[4]
        unsigned int mask[4]

        unsigned int id[4]
        unsigned int flags[4]

    # Hit data for 4 rays
    cdef struct RTCHit4:
        float Ngx[4]
        float Ngy[4]
        float Ngz[4]
        float align0

        float u[4]
        float v[4]

        unsigned int primID[4]
        unsigned int geomID[4]
        unsigned int instID[4]

    # Combined ray and hit data for 4 rays
    cdef struct RTCRayHit4:
        RTCRay4 ray
        RTCHit4 hit

    # This is for a packet of 8 rays
    cdef struct RTCRay8:
        # Ray data
        float orgx[8]
        float orgy[8]
        float orgz[8]
        float align0

        float dirx[8]
        float diry[8]
        float dirz[8]
        float align1

        float tnear[8]
        float tfar[8]

        float time[8]
        unsigned int mask[8]

        unsigned int id[8]
        unsigned int flags[8]

    # Hit data for 8 rays
    cdef struct RTCHit8:
        float Ngx[8]
        float Ngy[8]
        float Ngz[8]
        float align0

        float u[8]
        float v[8]

        unsigned int primID[8]
        unsigned int geomID[8]
        unsigned int instID[8]

    # Combined ray and hit data for 8 rays
    cdef struct RTCRayHit8:
        RTCRay8 ray
        RTCHit8 hit

    # This is for a packet of 16 rays
    cdef struct RTCRay16:
        # Ray data
        float orgx[16]
        float orgy[16]
        float orgz[16]
        float align0

        float dirx[16]
        float diry[16]
        float dirz[16]
        float align1

        float tnear[16]
        float tfar[16]

        float time[16]
        unsigned int mask[16]

        unsigned int id[16]
        unsigned int flags[16]

    # Hit data for 16 rays
    cdef struct RTCHit16:
        float Ngx[16]
        float Ngy[16]
        float Ngz[16]
        float align0

        float u[16]
        float v[16]

        unsigned int primID[16]
        unsigned int geomID[16]
        unsigned int instID[16]

    # Combined ray and hit data for 16 rays
    cdef struct RTCRayHit16:
        RTCRay16 ray
        RTCHit16 hit
