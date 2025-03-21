# rtcore_scene.pxd wrapper

cimport cython
cimport numpy as np
cimport rtcore as rtc
cimport rtcore_ray as rtcr

cdef extern from "embree4/rtcore_scene.h":

    ctypedef struct RTCRay
    ctypedef struct RTCRay4
    ctypedef struct RTCRay8
    ctypedef struct RTCRay16
    
    # Add missing type definitions
    ctypedef struct RTCRayHit
    ctypedef struct RTCRayHit4
    ctypedef struct RTCRayHit8
    ctypedef struct RTCRayHit16
    
    ctypedef struct RTCIntersectArguments
    ctypedef struct RTCOccludedArguments

    cdef enum RTCSceneFlags:
        RTC_SCENE_FLAG_NONE
        RTC_SCENE_FLAG_DYNAMIC
        RTC_SCENE_FLAG_COMPACT
        RTC_SCENE_FLAG_ROBUST
        RTC_SCENE_FLAG_CONTEXT_FILTER_FUNCTION

    cdef enum RTCBuildQuality:
        RTC_BUILD_QUALITY_LOW
        RTC_BUILD_QUALITY_MEDIUM
        RTC_BUILD_QUALITY_HIGH
        RTC_BUILD_QUALITY_REFIT

    # ctypedef void* RTCDevice
    ctypedef void* RTCScene

    RTCScene rtcNewScene(rtc.RTCDevice device)

    void rtcSetSceneFlags(RTCScene scene, RTCSceneFlags flags)
    void rtcSetSceneBuildQuality(RTCScene scene, RTCBuildQuality quality)

    ctypedef bint (*RTCProgressMonitorFunction)(void* ptr, double n)

    void rtcSetSceneProgressMonitorFunction(RTCScene scene, RTCProgressMonitorFunction progress, void* userPtr)

    void rtcCommitScene(RTCScene scene)

    void rtcJoinCommitScene(RTCScene scene)

    # Updated function signatures for Embree4
    void rtcIntersect1(RTCScene scene, RTCRayHit* rayhit, void* args)
    void rtcOccluded1(RTCScene scene, RTCRay* ray, void* args)
    
    # Packet variants (simplified signatures)
    void rtcIntersect4(RTCScene scene, RTCRayHit4* rayhit, void* args)
    void rtcIntersect8(RTCScene scene, RTCRayHit8* rayhit, void* args)
    void rtcIntersect16(RTCScene scene, RTCRayHit16* rayhit, void* args)

    void rtcOccluded4(RTCScene scene, RTCRay4* ray, void* args)
    void rtcOccluded8(RTCScene scene, RTCRay8* ray, void* args)
    void rtcOccluded16(RTCScene scene, RTCRay16* ray, void* args)

    void rtcRetainScene(RTCScene scene)
    void rtcReleaseScene(RTCScene scene)

cdef class EmbreeScene:
    cdef RTCScene scene_i
    # Optional device used if not given, it should be as input of EmbreeScene
    cdef public int is_committed
    cdef rtc.EmbreeDevice device

cdef enum rayQueryType:
    intersect,
    occluded,
    distance
